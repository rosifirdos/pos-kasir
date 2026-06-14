import express from 'express';
import { getRawMaterials, createRawMaterial, updateRawMaterial, deleteRawMaterial } from '../controllers/rawMaterialController';
import { requireRole } from '../middlewares/authMiddleware';

const router = express.Router();

router.get('/', getRawMaterials);
router.post('/', requireRole('admin'), createRawMaterial);
router.put('/:id', requireRole('admin'), updateRawMaterial);
router.delete('/:id', requireRole('admin'), deleteRawMaterial);

export default router;
