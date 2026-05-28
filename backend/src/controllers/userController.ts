import { Request, Response } from 'express';
import prisma from '../config/prisma';
import bcrypt from 'bcrypt';
import { logActivity } from '../utils/activityLogger';

export const getUsers = async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, username: true, role: true, createdAt: true }
    });
    res.json(users);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createUser = async (req: Request, res: Response) => {
  try {
    const { username, password, role } = req.body;
    const passwordHash = await bcrypt.hash(password, 10);
    
    const user = await prisma.user.create({
      data: {
        username,
        passwordHash,
        role: role || 'KASIR',
      },
      select: { id: true, username: true, role: true }
    });

    await logActivity('ADD_USER', 'User', user.id, `Created user ${username} with role ${role}`);
    res.status(201).json(user);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const resetPassword = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { password } = req.body;
    const passwordHash = await bcrypt.hash(password, 10);

    const user = await prisma.user.update({
      where: { id: Number(id) },
      data: { passwordHash },
      select: { id: true, username: true }
    });

    await logActivity('UPDATE_USER', 'User', user.id, `Reset password for user ${user.username}`);
    res.json({ message: 'Password reset successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
