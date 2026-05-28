import { Router } from 'express';
import { createTransaction, getTransactions, voidTransaction } from '../controllers/transactionController';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

router.use(authenticateToken);

router.get('/', getTransactions);
router.post('/', createTransaction);
router.post('/:id/void', voidTransaction);

export default router;
