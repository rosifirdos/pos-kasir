import { Request, Response } from 'express';
import prisma from '../config/prisma';
import { logActivity } from '../utils/activityLogger';

export const getProducts = async (req: Request, res: Response) => {
  try {
    const products = await prisma.product.findMany({
      where: { deletedAt: null },
      include: { category: true }
    });
    res.json(products);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createProduct = async (req: Request, res: Response) => {
  try {
    const { categoryId, sku, name, buyPrice, sellPrice, currentStock, imageUrl } = req.body;
    
    let finalImageUrl = imageUrl;
    if (req.file) {
      finalImageUrl = `/uploads/${req.file.filename}`;
    }

    const product = await prisma.product.create({
      data: {
        categoryId: Number(categoryId),
        sku,
        name,
        buyPrice,
        sellPrice,
        currentStock: Number(currentStock) || 0,
        imageUrl: finalImageUrl
      }
    });
    await logActivity('ADD_PRODUCT', 'Product', product.id, `Created product ${product.name}`);
    res.status(201).json(product);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { categoryId, sku, name, buyPrice, sellPrice, currentStock, imageUrl } = req.body;

    let finalImageUrl = imageUrl;
    if (req.file) {
      finalImageUrl = `/uploads/${req.file.filename}`;
    }

    const product = await prisma.product.update({
      where: { id: Number(id) },
      data: { 
        categoryId: categoryId ? Number(categoryId) : undefined, 
        sku, 
        name, 
        buyPrice, 
        sellPrice, 
        currentStock: currentStock !== undefined ? Number(currentStock) : undefined,
        imageUrl: finalImageUrl 
      }
    });
    await logActivity('UPDATE_PRODUCT', 'Product', product.id, `Updated product ${product.name}`);
    res.json(product);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const deleteProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const productId = Number(id);

    await prisma.product.update({
      where: { id: productId },
      data: { deletedAt: new Date() }
    });

    await logActivity('DELETE_PRODUCT', 'Product', productId, `Deleted product ID ${productId}`);
    res.json({ message: 'Product soft-deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
