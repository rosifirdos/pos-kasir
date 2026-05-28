import { Router } from 'express';
import { getProducts, createProduct, updateProduct, deleteProduct } from '../controllers/productController';
import { upload } from '../config/multer';
import { requireRole } from '../middlewares/authMiddleware';

const router = Router();

router.get('/', getProducts);
router.post('/', upload.single('image'), createProduct);
router.put('/:id', upload.single('image'), updateProduct);
router.delete('/:id', requireRole('ADMIN'), deleteProduct);

export default router;
