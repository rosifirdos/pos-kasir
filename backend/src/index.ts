import express from 'express';
import cors from 'cors';
import 'dotenv/config';

import categoryRoutes from './routes/categoryRoutes';
import productRoutes from './routes/productRoutes';
import transactionRoutes from './routes/transactionRoutes';
import stockRoutes from './routes/stockRoutes';
import reportRoutes from './routes/reportRoutes';
import activityRoutes from './routes/activityRoutes';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import shiftRoutes from './routes/shiftRoutes';
import { authenticateToken } from './middlewares/authMiddleware';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/shifts', shiftRoutes);

app.use('/api/categories', authenticateToken, categoryRoutes);
app.use('/api/products', authenticateToken, productRoutes);
app.use('/api/transactions', transactionRoutes); // Transaction routes use authenticateToken internally
app.use('/api/stocks', authenticateToken, stockRoutes);
app.use('/api/reports', authenticateToken, reportRoutes);
app.use('/api/activities', authenticateToken, activityRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
