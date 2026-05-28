import express from 'express';
import { openShift, closeShift, getActiveShift, getAllShifts } from '../controllers/shiftController';
import { authenticateToken, requireRole } from '../middlewares/authMiddleware';

const router = express.Router();

router.use(authenticateToken);

router.get('/active', getActiveShift);
router.post('/open', openShift);
router.post('/close', closeShift);

router.get('/', requireRole('ADMIN'), getAllShifts);

export default router;
