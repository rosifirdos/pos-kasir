import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const getDailySummary = async (req: Request, res: Response) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Total Pendapatan & Jumlah Transaksi hari ini
    const transactions = await prisma.transaction.findMany({
      where: {
        createdAt: {
          gte: today,
        },
      },
      include: {
        details: {
          include: {
            product: true,
          },
        },
      },
    });

    let totalRevenue = 0;
    let totalMargin = 0;
    const transactionCount = transactions.length;

    transactions.forEach((tx) => {
      totalRevenue += Number(tx.totalAmount);
      let txDetailMargin = 0;
      tx.details.forEach((detail) => {
        const buyPrice = Number(detail.product.buyPrice);
        const sellPrice = Number(detail.unitPrice);
        const itemDiscount = Number(detail.discountAmount || 0);
        const margin = ((sellPrice - buyPrice) * detail.quantity) - itemDiscount;
        txDetailMargin += margin;
      });
      const txDiscount = Number(tx.discountAmount || 0);
      totalMargin += (txDetailMargin - txDiscount);
    });

    res.json({
      date: today,
      transactionCount,
      totalRevenue,
      totalMargin,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getTopProducts = async (req: Request, res: Response) => {
  try {
    // Menghitung produk terlaris berdasarkan total quantity terjual
    const topProducts = await prisma.transactionDetail.groupBy({
      by: ['productId'],
      _sum: {
        quantity: true,
      },
      orderBy: {
        _sum: {
          quantity: 'desc',
        },
      },
      take: 5,
    });

    // Ambil detail nama produk untuk tiap ID
    const productDetails = await Promise.all(
      topProducts.map(async (item) => {
        const product = await prisma.product.findUnique({
          where: { id: item.productId },
          select: { name: true },
        });
        return {
          name: product?.name || 'Unknown',
          totalSold: item._sum.quantity,
        };
      })
    );

    res.json(productDetails);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
