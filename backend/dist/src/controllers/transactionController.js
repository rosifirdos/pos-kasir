"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTransactions = exports.createTransaction = void 0;
const prisma_1 = __importDefault(require("../config/prisma"));
const createTransaction = async (req, res) => {
    try {
        const { paymentMethod, items } = req.body;
        // items should be an array of { productId, quantity, unitPrice }
        if (!items || items.length === 0) {
            return res.status(400).json({ error: 'Transaction must have at least one item' });
        }
        // Calculate total
        let totalAmount = 0;
        const details = items.map((item) => {
            const subtotal = item.quantity * item.unitPrice;
            totalAmount += subtotal;
            return {
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal
            };
        });
        // Generate Invoice Number (e.g., INV-YYYYMMDD-HHMMSS-RANDOM)
        const invoiceNumber = `INV-${new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 14)}-${Math.floor(Math.random() * 1000)}`;
        // Execute Interactive Transaction for ACID properties
        const result = await prisma_1.default.$transaction(async (tx) => {
            // 1. Create Transaction Header
            const transaction = await tx.transaction.create({
                data: {
                    invoiceNumber,
                    totalAmount,
                    paymentMethod: paymentMethod || 'CASH',
                    details: {
                        create: details
                    }
                },
                include: {
                    details: true
                }
            });
            // 2. Reduce Stock
            for (const item of details) {
                // Fetch current stock to prevent negative stock (optional, but good for validation)
                const product = await tx.product.findUnique({ where: { id: item.productId } });
                if (!product || product.currentStock < item.quantity) {
                    throw new Error(`Insufficient stock for Product ID ${item.productId}`);
                }
                await tx.product.update({
                    where: { id: item.productId },
                    data: {
                        currentStock: {
                            decrement: item.quantity
                        }
                    }
                });
            }
            return transaction;
        });
        res.status(201).json(result);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.createTransaction = createTransaction;
const getTransactions = async (req, res) => {
    try {
        const transactions = await prisma_1.default.transaction.findMany({
            include: { details: { include: { product: true } } },
            orderBy: { createdAt: 'desc' }
        });
        res.json(transactions);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.getTransactions = getTransactions;
