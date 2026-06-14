import express from 'express';
import { getRecipesByProduct, saveRecipes } from '../controllers/recipeController';
import { requireRole } from '../middlewares/authMiddleware';

const router = express.Router();

router.get('/product/:productId', getRecipesByProduct);
router.post('/product/:productId', requireRole('admin'), saveRecipes);

export default router;
