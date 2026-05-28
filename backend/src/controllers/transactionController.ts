import { Request, Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/prisma';
import { logActivity } from '../utils/activityLogger';

export const createTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { paymentMethod, items } = req.body;
    
    // items should be an array of { productId, quantity, unitPrice }
    
    if (!items || items.length === 0) {
      return res.status(400).json({ error: 'Transaction must have at least one item' });
    }

    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Not authenticated' });

    const shift = await prisma.shift.findFirst({
      where: { userId, status: 'OPEN' }
    });

    if (!shift) {
      return res.status(400).json({ error: 'You must open a shift before making transactions' });
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
          cashierId: userId,
          shiftId: shift.id,
          details: {
            create: details
          }
        },
        include: {
          details: {
            include: {
              product: true
            }
          }
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

    await logActivity('TRANSACTION', 'Transaction', result.id, `Completed transaction ${invoiceNumber} for Rp ${totalAmount}`);
    res.status(201).json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getTransactions = async (req: Request, res: Response) => {
  try {
    const transactions = await prisma.transaction.findMany({
      include: { 
        details: { include: { product: true } },
        cashier: { select: { username: true } },
        voidAuthorizer: { select: { username: true } }
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json(transactions);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const voidTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { pin } = req.body;
    const user = req.user!;

    let authorizerId = null;

    if (user.role === 'ADMIN') {
      authorizerId = user.id;
    } else {
      if (!pin) return res.status(403).json({ error: 'Admin PIN required to void transaction' });
      
      const adminUser = await prisma.user.findFirst({
        where: { role: 'ADMIN', pin: { not: null } }
      });

      if (!adminUser || !adminUser.pin) {
        return res.status(400).json({ error: 'No admin PIN configured' });
      }

      const bcrypt = await import('bcrypt');
      const validPin = await bcrypt.compare(pin, adminUser.pin!);
      if (!validPin) return res.status(403).json({ error: 'Invalid PIN' });

      authorizerId = adminUser.id;
    }

    await processVoid(Number(id), authorizerId, res);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

async function processVoid(transactionId: number, authorizerId: number, res: Response) {
  try {
    const transaction = await prisma.transaction.findUnique({
      where: { id: transactionId },
      include: { details: true }
    });

    if (!transaction) return res.status(404).json({ error: 'Transaction not found' });
    if (transaction.status === 'VOID') return res.status(400).json({ error: 'Transaction is already voided' });

    const result = await prisma.$transaction(async (tx) => {
      const voided = await tx.transaction.update({
        where: { id: transactionId },
        data: {
          status: 'VOID',
          voidAuthorizedBy: authorizerId
        }
      });

      // Restore stock
      for (const item of transaction.details) {
        await tx.product.update({
          where: { id: item.productId },
          data: {
            currentStock: {
              increment: item.quantity
            }
          }
        });
      }
      return voided;
    });

    await logActivity('VOID_TRANSACTION', 'Transaction', result.id, `Voided transaction ${transaction.invoiceNumber}`);
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
