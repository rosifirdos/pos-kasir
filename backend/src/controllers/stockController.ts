import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const adjustStock = async (req: Request, res: Response) => {
  try {
    const { productId, adjustmentType, quantity, note } = req.body;

    if (!['IN', 'OUT'].includes(adjustmentType)) {
      return res.status(400).json({ error: 'adjustmentType must be IN or OUT' });
    }

    const result = await prisma.$transaction(async (tx) => {
      // Create record
      const adjustment = await tx.stockAdjustment.create({
        data: {
          productId,
          adjustmentType,
          quantity,
          note
        }
      });

      // Update product stock
      const product = await tx.product.update({
        where: { id: productId },
        data: {
          currentStock: {
            [adjustmentType === 'IN' ? 'increment' : 'decrement']: quantity
          }
        }
      });

      return { adjustment, product };
    });

    res.status(201).json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getAdjustments = async (req: Request, res: Response) => {
  try {
    const adjustments = await prisma.stockAdjustment.findMany({
      include: { product: true },
      orderBy: { createdAt: 'desc' }
    });
    res.json(adjustments);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
