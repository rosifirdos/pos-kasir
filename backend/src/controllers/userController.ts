import { Request, Response } from 'express';
import prisma from '../config/prisma';
import bcrypt from 'bcrypt';
import { logActivity } from '../utils/activityLogger';

export const getUsers = async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, username: true, role: true, pin: true, createdAt: true }
    });
    res.json(users);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const createUser = async (req: Request, res: Response) => {
  try {
    const { username, password, role, pin } = req.body;
    const passwordHash = await bcrypt.hash(password, 10);
    const pinHash = pin ? await bcrypt.hash(pin, 10) : null;
    
    const user = await prisma.user.create({
      data: {
        username,
        passwordHash,
        role: role || 'KASIR',
        pin: pinHash,
      },
      select: { id: true, username: true, role: true }
    });

    await logActivity('ADD_USER', 'User', user.id, `Created user ${username} with role ${role}`);
    res.status(201).json(user);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { username, role, pin, password } = req.body;

    const existingUser = await prisma.user.findUnique({
      where: { id: Number(id) }
    });

    if (!existingUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    const data: any = {};
    if (username !== undefined) data.username = username;
    if (role !== undefined) data.role = role;
    if (password !== undefined && password.trim() !== '') {
      data.passwordHash = await bcrypt.hash(password, 10);
    }
    if (pin !== undefined) {
      data.pin = pin.trim() !== '' ? await bcrypt.hash(pin, 10) : null;
    }

    const user = await prisma.user.update({
      where: { id: Number(id) },
      data,
      select: { id: true, username: true, role: true }
    });

    await logActivity('UPDATE_USER', 'User', user.id, `Updated user ${username || existingUser.username}`);
    res.json(user);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const deleteUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const existingUser = await prisma.user.findUnique({
      where: { id: Number(id) }
    });

    if (!existingUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Integrity checks
    const shiftsCount = await prisma.shift.count({ where: { userId: Number(id) } });
    const txCount = await prisma.transaction.count({
      where: {
        OR: [
          { cashierId: Number(id) },
          { voidAuthorizedBy: Number(id) }
        ]
      }
    });

    if (shiftsCount > 0 || txCount > 0) {
      return res.status(400).json({
        error: 'Tidak dapat menghapus pegawai yang memiliki riwayat transaksi atau shift.'
      });
    }

    await prisma.user.delete({
      where: { id: Number(id) }
    });

    await logActivity('DELETE_USER', 'User', Number(id), `Deleted user ${existingUser.username}`);
    res.json({ message: 'User deleted successfully' });
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
