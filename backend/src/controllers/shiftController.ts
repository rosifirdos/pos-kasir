import { Request, Response } from 'express';
import prisma from '../config/prisma';
import { AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../utils/activityLogger';

export const openShift = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { startingCash } = req.body;

    // Check if there is already an open shift for this user
    const existingShift = await prisma.shift.findFirst({
      where: { userId, status: 'OPEN' }
    });

    if (existingShift) {
      return res.status(400).json({ error: 'You already have an open shift.' });
    }

    const shift = await prisma.shift.create({
      data: {
        userId,
        startingCash,
      }
    });

    await logActivity('SHIFT_OPEN', 'Shift', shift.id, `Opened shift with starting cash ${startingCash}`);
    res.status(201).json(shift);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const closeShift = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { actualCash } = req.body;

    const shift = await prisma.shift.findFirst({
      where: { userId, status: 'OPEN' }
    });

    if (!shift) {
      return res.status(404).json({ error: 'No open shift found.' });
    }

    // Calculate expected cash
    // We get all transactions during this shift
    const transactions = await prisma.transaction.findMany({
      where: { shiftId: shift.id, status: 'COMPLETED', paymentMethod: 'CASH' }
    });

    const totalCashSales = transactions.reduce((sum, tx) => sum + Number(tx.totalAmount), 0);
    const expectedCash = Number(shift.startingCash) + totalCashSales;

    const closedShift = await prisma.shift.update({
      where: { id: shift.id },
      data: {
        endTime: new Date(),
        status: 'CLOSED',
        expectedCash,
        actualCash,
      }
    });

    await logActivity('SHIFT_CLOSE', 'Shift', closedShift.id, `Closed shift`);
    res.json(closedShift);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getActiveShift = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const shift = await prisma.shift.findFirst({
      where: { userId, status: 'OPEN' }
    });
    
    if (!shift) {
      return res.json(null);
    }
    res.json(shift);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getAllShifts = async (req: Request, res: Response) => {
  try {
    const shifts = await prisma.shift.findMany({
      include: { user: { select: { username: true } } },
      orderBy: { startTime: 'desc' },
      take: 50
    });
    res.json(shifts);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
