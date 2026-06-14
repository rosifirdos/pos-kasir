import { Request, Response } from 'express';
import prisma from '../config/prisma';
import { logActivity } from '../utils/activityLogger';

export const getPromos = async (req: Request, res: Response) => {
  try {
    const promos = await prisma.promo.findMany({
      include: {
        promoItems: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                sku: true,
              }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(promos);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getActivePromos = async (req: Request, res: Response) => {
  try {
    const now = new Date();
    const promos = await prisma.promo.findMany({
      where: {
        isActive: true,
        OR: [
          { startDate: null },
          { startDate: { lte: now } },
        ],
        AND: [
          {
            OR: [
              { endDate: null },
              { endDate: { gte: now } },
            ],
          },
          {
            OR: [
              { quota: null },
              { usedCount: { lt: prisma.promo.fields.quota } },
            ],
          }
        ]
      },
      include: {
        promoItems: {
          select: {
            productId: true
          }
        }
      }
    });
    res.json(promos);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createPromo = async (req: Request, res: Response) => {
  try {
    const {
      name,
      description,
      type,
      value,
      maxDiscount,
      minPurchase,
      startDate,
      endDate,
      startTime,
      endTime,
      quota,
      isActive,
      isStackable,
      productIds, // array of product IDs
    } = req.body;

    const promo = await prisma.$transaction(async (tx) => {
      const created = await tx.promo.create({
        data: {
          name,
          description,
          type,
          value: Number(value),
          maxDiscount: maxDiscount ? Number(maxDiscount) : null,
          minPurchase: minPurchase ? Number(minPurchase) : null,
          startDate: startDate ? new Date(startDate) : null,
          endDate: endDate ? new Date(endDate) : null,
          startTime: startTime || null,
          endTime: endTime || null,
          quota: quota ? Number(quota) : null,
          isActive: isActive !== undefined ? Boolean(isActive) : true,
          isStackable: isStackable !== undefined ? Boolean(isStackable) : false,
        }
      });

      if (productIds && Array.isArray(productIds) && productIds.length > 0) {
        await tx.promoItem.createMany({
          data: productIds.map((productId: number) => ({
            promoId: created.id,
            productId,
          }))
        });
      }

      return tx.promo.findUnique({
        where: { id: created.id },
        include: {
          promoItems: {
            include: {
              product: {
                select: {
                  id: true,
                  name: true,
                }
              }
            }
          }
        }
      });
    });

    await logActivity('ADD_PROMO', 'Promo', promo!.id, `Created promo ${promo!.name}`);
    res.status(201).json(promo);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updatePromo = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      name,
      description,
      type,
      value,
      maxDiscount,
      minPurchase,
      startDate,
      endDate,
      startTime,
      endTime,
      quota,
      isActive,
      isStackable,
      productIds,
    } = req.body;

    const promoId = Number(id);

    const promo = await prisma.$transaction(async (tx) => {
      const updated = await tx.promo.update({
        where: { id: promoId },
        data: {
          name,
          description,
          type,
          value: value !== undefined ? Number(value) : undefined,
          maxDiscount: maxDiscount !== undefined ? (maxDiscount ? Number(maxDiscount) : null) : undefined,
          minPurchase: minPurchase !== undefined ? (minPurchase ? Number(minPurchase) : null) : undefined,
          startDate: startDate !== undefined ? (startDate ? new Date(startDate) : null) : undefined,
          endDate: endDate !== undefined ? (endDate ? new Date(endDate) : null) : undefined,
          startTime: startTime !== undefined ? (startTime || null) : undefined,
          endTime: endTime !== undefined ? (endTime || null) : undefined,
          quota: quota !== undefined ? (quota ? Number(quota) : null) : undefined,
          isActive: isActive !== undefined ? Boolean(isActive) : undefined,
          isStackable: isStackable !== undefined ? Boolean(isStackable) : undefined,
        }
      });

      if (productIds && Array.isArray(productIds)) {
        // Delete existing items and recreate
        await tx.promoItem.deleteMany({
          where: { promoId }
        });

        if (productIds.length > 0) {
          await tx.promoItem.createMany({
            data: productIds.map((pId: number) => ({
              promoId,
              productId: pId,
            }))
          });
        }
      }

      return tx.promo.findUnique({
        where: { id: promoId },
        include: {
          promoItems: {
            include: {
              product: {
                select: {
                  id: true,
                  name: true,
                }
              }
            }
          }
        }
      });
    });

    await logActivity('UPDATE_PROMO', 'Promo', promo!.id, `Updated promo ${promo!.name}`);
    res.json(promo);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const deletePromo = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const promoId = Number(id);

    const promo = await prisma.promo.delete({
      where: { id: promoId },
    });

    await logActivity('DELETE_PROMO', 'Promo', promoId, `Deleted promo ${promo.name}`);
    res.json({ message: 'Promo deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
