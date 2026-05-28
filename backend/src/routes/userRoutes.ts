import express from 'express';
import { getUsers, createUser, resetPassword } from '../controllers/userController';
import { authenticateToken, requireRole } from '../middlewares/authMiddleware';

const router = express.Router();

router.use(authenticateToken);
router.use(requireRole('ADMIN'));

router.get('/', getUsers);
router.post('/', createUser);
router.put('/:id/reset-password', resetPassword);

export default router;
