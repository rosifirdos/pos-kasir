import { Router } from 'express';
import { getDailySummary, getTopProducts } from '../controllers/reportController';

const router = Router();

router.get('/daily-summary', getDailySummary);
router.get('/top-products', getTopProducts);

export default router;
