import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const getRawMaterials = async (req: Request, res: Response) => {
  try {
    const rawMaterials = await prisma.rawMaterial.findMany({
      include: {
        unit: true
      },
      orderBy: { name: 'asc' }
    });
    res.json(rawMaterials);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createRawMaterial = async (req: Request, res: Response) => {
  try {
    const { name, unitId, stockQuantity, minimumStock, costPerUnit } = req.body;
    const rawMaterial = await prisma.rawMaterial.create({
      data: {
        name,
        unitId: Number(unitId),
        stockQuantity: Number(stockQuantity),
        minimumStock: Number(minimumStock),
        costPerUnit: Number(costPerUnit)
      },
      include: { unit: true }
    });
    res.status(201).json(rawMaterial);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateRawMaterial = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, unitId, stockQuantity, minimumStock, costPerUnit } = req.body;
    const rawMaterial = await prisma.rawMaterial.update({
      where: { id: Number(id) },
      data: {
        name,
        unitId: Number(unitId),
        stockQuantity: Number(stockQuantity),
        minimumStock: Number(minimumStock),
        costPerUnit: Number(costPerUnit)
      },
      include: { unit: true }
    });
    res.json(rawMaterial);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const deleteRawMaterial = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await prisma.rawMaterial.delete({
      where: { id: Number(id) }
    });
    res.json({ message: 'Raw material deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
