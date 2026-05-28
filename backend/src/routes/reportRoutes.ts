import { Router } from 'express';
import { getDailySummary, getTopProducts } from '../controllers/reportController';
import { requireRole } from '../middlewares/authMiddleware';

const router = Router();

router.use(requireRole('ADMIN'));

router.get('/daily-summary', getDailySummary);
router.get('/top-products', getTopProducts);

export default router;
