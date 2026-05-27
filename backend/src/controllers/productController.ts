import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const getProducts = async (req: Request, res: Response) => {
  try {
    const products = await prisma.product.findMany({
      include: { category: true }
    });
    res.json(products);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createProduct = async (req: Request, res: Response) => {
  try {
    const { categoryId, sku, name, buyPrice, sellPrice, currentStock } = req.body;
    const product = await prisma.product.create({
      data: {
        categoryId,
        sku,
        name,
        buyPrice,
        sellPrice,
        currentStock: currentStock || 0
      }
    });
    res.status(201).json(product);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { categoryId, sku, name, buyPrice, sellPrice, currentStock } = req.body;
    const product = await prisma.product.update({
      where: { id: Number(id) },
      data: { categoryId, sku, name, buyPrice, sellPrice, currentStock }
    });
    res.json(product);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
