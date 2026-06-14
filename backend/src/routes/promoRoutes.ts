import { Router } from 'express';
import { getPromos, getActivePromos, createPromo, updatePromo, deletePromo } from '../controllers/promoController';
import { authenticateToken, requireRole } from '../middlewares/authMiddleware';

const router = Router();

// Apply auth token validation to all promo routes
router.use(authenticateToken);

// Active promos (available for Cashier/POS)
router.get('/active', getActivePromos);

// Admin-only management routes
router.get('/', requireRole('ADMIN'), getPromos);
router.post('/', requireRole('ADMIN'), createPromo);
router.put('/:id', requireRole('ADMIN'), updatePromo);
router.delete('/:id', requireRole('ADMIN'), deletePromo);

export default router;
