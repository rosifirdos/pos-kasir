"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateProduct = exports.createProduct = exports.getProducts = void 0;
const prisma_1 = __importDefault(require("../config/prisma"));
const getProducts = async (req, res) => {
    try {
        const products = await prisma_1.default.product.findMany({
            include: { category: true }
        });
        res.json(products);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.getProducts = getProducts;
const createProduct = async (req, res) => {
    try {
        const { categoryId, sku, name, buyPrice, sellPrice, currentStock } = req.body;
        const product = await prisma_1.default.product.create({
            data: {
                categoryId,
                sku,
                name,
                buyPrice,
                sellPrice,
                currentStock: currentStock || 0
            }
        });
        res.status(201).json(product);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.createProduct = createProduct;
const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { categoryId, sku, name, buyPrice, sellPrice, currentStock } = req.body;
        const product = await prisma_1.default.product.update({
            where: { id: Number(id) },
            data: { categoryId, sku, name, buyPrice, sellPrice, currentStock }
        });
        res.json(product);
    }
    catch (error) {
        res.status(500).json({ error: error.message });
    }
};
exports.updateProduct = updateProduct;
