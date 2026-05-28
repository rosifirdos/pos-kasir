import express from 'express';
import { login, verifyPin } from '../controllers/authController';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = express.Router();

router.post('/login', login);
router.post('/verify-pin', authenticateToken, verifyPin);

export default router;
