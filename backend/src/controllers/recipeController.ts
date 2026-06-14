import { Request, Response } from 'express';
import prisma from '../config/prisma';

export const getRecipesByProduct = async (req: Request, res: Response) => {
  try {
    const { productId } = req.params;
    const recipes = await prisma.recipe.findMany({
      where: { productId: Number(productId) },
      include: {
        rawMaterial: {
          include: { unit: true }
        }
      }
    });
    res.json(recipes);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const saveRecipes = async (req: Request, res: Response) => {
  try {
    const { productId } = req.params;
    const { recipes } = req.body; // Array of { rawMaterialId, quantityNeeded }

    // Use a transaction to delete existing recipes for the product and insert new ones
    const result = await prisma.$transaction(async (tx) => {
      // Set the product as recipe based
      await tx.product.update({
        where: { id: Number(productId) },
        data: { isRecipeBased: true }
      });

      // Delete existing recipes
      await tx.recipe.deleteMany({
        where: { productId: Number(productId) }
      });

      if (!recipes || recipes.length === 0) {
        // If empty, set it back to false
        await tx.product.update({
          where: { id: Number(productId) },
          data: { isRecipeBased: false }
        });
        return [];
      }

      // Insert new recipes
      const newRecipes = recipes.map((r: any) => ({
        productId: Number(productId),
        rawMaterialId: Number(r.rawMaterialId),
        quantityNeeded: Number(r.quantityNeeded)
      }));

      await tx.recipe.createMany({
        data: newRecipes
      });

      return await tx.recipe.findMany({
        where: { productId: Number(productId) },
        include: {
          rawMaterial: {
            include: { unit: true }
          }
        }
      });
    });

    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
