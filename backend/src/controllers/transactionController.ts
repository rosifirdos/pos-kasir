import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const createTransaction = async (req: Request, res: Response) => {
  try {
    const { paymentMethod, items } = req.body;
    
    // items should be an array of { productId, quantity, unitPrice }
    
    if (!items || items.length === 0) {
      return res.status(400).json({ error: 'Transaction must have at least one item' });
    }

    // Calculate total
    let totalAmount = 0;
    const details = items.map((item: any) => {
      const subtotal = item.quantity * item.unitPrice;
      totalAmount += subtotal;
      return {
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal
      };
    });

    // Generate Invoice Number (e.g., INV-YYYYMMDD-HHMMSS-RANDOM)
    const invoiceNumber = `INV-${new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 14)}-${Math.floor(Math.random() * 1000)}`;

    // Execute Interactive Transaction for ACID properties
    const result = await prisma.$transaction(async (tx) => {
      // 1. Create Transaction Header
      const transaction = await tx.transaction.create({
        data: {
          invoiceNumber,
          totalAmount,
          paymentMethod: paymentMethod || 'CASH',
          details: {
            create: details
          }
        },
        include: {
          details: true
        }
      });

      // 2. Reduce Stock
      for (const item of details) {
        // Fetch current stock to prevent negative stock (optional, but good for validation)
        const product = await tx.product.findUnique({ where: { id: item.productId } });
        if (!product || product.currentStock < item.quantity) {
          throw new Error(`Insufficient stock for Product ID ${item.productId}`);
        }

        await tx.product.update({
          where: { id: item.productId },
          data: {
            currentStock: {
              decrement: item.quantity
            }
          }
        });
      }

      return transaction;
    });

    res.status(201).json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getTransactions = async (req: Request, res: Response) => {
  try {
    const transactions = await prisma.transaction.findMany({
      include: { details: { include: { product: true } } },
      orderBy: { createdAt: 'desc' }
    });
    res.json(transactions);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
