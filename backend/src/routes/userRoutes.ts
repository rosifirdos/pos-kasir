import express from 'express';
import { getUsers, createUser, resetPassword, updateUser, deleteUser } from '../controllers/userController';
import { authenticateToken, requireRole } from '../middlewares/authMiddleware';

const router = express.Router();

router.use(authenticateToken);
router.use(requireRole('ADMIN'));

router.get('/', getUsers);
router.post('/', createUser);
router.put('/:id', updateUser);
router.delete('/:id', deleteUser);
router.put('/:id/reset-password', resetPassword);

export default router;
