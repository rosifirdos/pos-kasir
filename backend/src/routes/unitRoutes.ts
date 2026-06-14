import express from 'express';
import { getUnits, createUnit, updateUnit, deleteUnit } from '../controllers/unitController';
import { requireRole } from '../middlewares/authMiddleware';

const router = express.Router();

router.get('/', getUnits);
router.post('/', requireRole('admin'), createUnit);
router.put('/:id', requireRole('admin'), updateUnit);
router.delete('/:id', requireRole('admin'), deleteUnit);

export default router;
