import { Request, Response } from 'express';
import prisma from '../config/prisma';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { AuthRequest } from '../middlewares/authMiddleware';

const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-key-for-pos';

export const login = async (req: Request, res: Response) => {
  try {
    const { username, password } = req.body;
    const user = await prisma.user.findUnique({ where: { username } });

    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '12h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
      }
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const verifyPin = async (req: AuthRequest, res: Response) => {
  try {
    const { pin } = req.body;
    
    // Find an admin user
    const adminUser = await prisma.user.findFirst({
      where: { role: 'ADMIN', pin: { not: null } }
    });

    if (!adminUser || !adminUser.pin) {
      return res.status(400).json({ error: 'No admin PIN configured' });
    }

    const validPin = await bcrypt.compare(pin, adminUser.pin);
    if (!validPin) {
      return res.status(403).json({ error: 'Invalid PIN' });
    }

    res.json({ success: true, authorizerId: adminUser.id });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
