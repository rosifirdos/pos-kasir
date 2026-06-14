import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const getUnits = async (req: Request, res: Response) => {
  try {
    const units = await prisma.unit.findMany({
      orderBy: { name: 'asc' }
    });
    res.json(units);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createUnit = async (req: Request, res: Response) => {
  try {
    const { name, abbreviation } = req.body;
    const unit = await prisma.unit.create({
      data: { name, abbreviation }
    });
    res.status(201).json(unit);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateUnit = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, abbreviation } = req.body;
    const unit = await prisma.unit.update({
      where: { id: Number(id) },
      data: { name, abbreviation }
    });
    res.json(unit);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const deleteUnit = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await prisma.unit.delete({
      where: { id: Number(id) }
    });
    res.json({ message: 'Unit deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
