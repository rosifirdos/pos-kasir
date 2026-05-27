import { Router } from 'express';
import { adjustStock, getAdjustments } from '../controllers/stockController';

const router = Router();

router.get('/', getAdjustments);
router.post('/', adjustStock);

export default router;
