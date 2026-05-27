"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAdjustments = exports.adjustStock = void 0;
const prisma_1 = __importDefault(require("../config/prisma"));
const adjustStock = async (req, res) => {
    try {
        const { productId, adjustmentType, quantity, note } = req.body;
        if (!['IN', 'OUT'].includes(adjustmentType)) {
            return res.status(400).json({ error: 'adjustmentType must be IN or OUT' });
        }
        const result = await prisma_1.default.$transaction(async (tx) => {
            // Create record
            const adjustment = await tx.stockAdjustment.create({
                data: {
                    productId,
                    adjustmentType,
                    quantity,
                    note
                }
            });
            // Update product stock
            const product = await tx.product.update({
                where: { id: productId },
                data: {
                    currentStock: {
                        [adjustmentType === 'IN' ? 'increment' : 'decrement']: quantity
                    }
                }
            });
            return { adjustment, product };
        });
        res.status(201).json(result);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.adjustStock = adjustStock;
const getAdjustments = async (req, res) => {
    try {
        const adjustments = await prisma_1.default.stockAdjustment.findMany({
            include: { product: true },
            orderBy: { createdAt: 'desc' }
        });
        res.json(adjustments);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.getAdjustments = getAdjustments;
