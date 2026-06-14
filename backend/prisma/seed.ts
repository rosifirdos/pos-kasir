import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding data...');

  // Delete existing data to prevent unique constraint violations on re-seed
  // Order of deletion matters due to foreign key constraints
  await prisma.recipe.deleteMany();
  await prisma.rawMaterial.deleteMany();
  await prisma.unit.deleteMany();
  await prisma.promoItem.deleteMany();
  await prisma.promo.deleteMany();
  await prisma.transactionDetail.deleteMany();
  await prisma.transaction.deleteMany();
  await prisma.stockAdjustment.deleteMany();
  await prisma.activityLog.deleteMany();
  await prisma.product.deleteMany();
  await prisma.category.deleteMany();

  // Create Units
  const unitGram = await prisma.unit.create({ data: { name: 'Gram', abbreviation: 'g' } });
  const unitMl = await prisma.unit.create({ data: { name: 'Milliliter', abbreviation: 'ml' } });
  const unitPcs = await prisma.unit.create({ data: { name: 'Piece', abbreviation: 'pcs' } });
  const unitSlice = await prisma.unit.create({ data: { name: 'Slice', abbreviation: 'slice' } });

  // Create Raw Materials
  const rmCoffeeBeans = await prisma.rawMaterial.create({ data: { name: 'Biji Kopi Arabica', unitId: unitGram.id, stockQuantity: 5000, minimumStock: 1000, costPerUnit: 200 } });
  const rmMilk = await prisma.rawMaterial.create({ data: { name: 'Susu UHT', unitId: unitMl.id, stockQuantity: 10000, minimumStock: 2000, costPerUnit: 20 } });
  const rmWater = await prisma.rawMaterial.create({ data: { name: 'Air Mineral', unitId: unitMl.id, stockQuantity: 50000, minimumStock: 5000, costPerUnit: 1 } });
  const rmSugarSyrup = await prisma.rawMaterial.create({ data: { name: 'Sirup Gula', unitId: unitMl.id, stockQuantity: 3000, minimumStock: 500, costPerUnit: 30 } });
  const rmPalmSugar = await prisma.rawMaterial.create({ data: { name: 'Gula Aren Cair', unitId: unitMl.id, stockQuantity: 3000, minimumStock: 500, costPerUnit: 40 } });
  const rmIce = await prisma.rawMaterial.create({ data: { name: 'Es Batu', unitId: unitPcs.id, stockQuantity: 500, minimumStock: 100, costPerUnit: 500 } });
  const rmMatcha = await prisma.rawMaterial.create({ data: { name: 'Bubuk Matcha', unitId: unitGram.id, stockQuantity: 2000, minimumStock: 500, costPerUnit: 300 } });
  const rmTea = await prisma.rawMaterial.create({ data: { name: 'Daun Teh', unitId: unitGram.id, stockQuantity: 2000, minimumStock: 500, costPerUnit: 100 } });
  const rmVanillaSyrup = await prisma.rawMaterial.create({ data: { name: 'Sirup Vanila', unitId: unitMl.id, stockQuantity: 3000, minimumStock: 500, costPerUnit: 50 } });
  const rmChocolatePowder = await prisma.rawMaterial.create({ data: { name: 'Bubuk Cokelat', unitId: unitGram.id, stockQuantity: 2000, minimumStock: 500, costPerUnit: 250 } });
  const rmPeachSyrup = await prisma.rawMaterial.create({ data: { name: 'Sirup Persik', unitId: unitMl.id, stockQuantity: 2000, minimumStock: 500, costPerUnit: 60 } });
  const rmSpaghetti = await prisma.rawMaterial.create({ data: { name: 'Pasta Spaghetti', unitId: unitGram.id, stockQuantity: 5000, minimumStock: 1000, costPerUnit: 10 } });
  const rmCarbonaraSauce = await prisma.rawMaterial.create({ data: { name: 'Saus Carbonara', unitId: unitMl.id, stockQuantity: 5000, minimumStock: 1000, costPerUnit: 30 } });
  const rmSmokedBeef = await prisma.rawMaterial.create({ data: { name: 'Daging Asap', unitId: unitPcs.id, stockQuantity: 200, minimumStock: 50, costPerUnit: 1500 } });
  const rmRoti = await prisma.rawMaterial.create({ data: { name: 'Roti Slice', unitId: unitSlice.id, stockQuantity: 100, minimumStock: 20, costPerUnit: 500 } });
  const rmKeju = await prisma.rawMaterial.create({ data: { name: 'Keju Cheddar Slice', unitId: unitSlice.id, stockQuantity: 100, minimumStock: 20, costPerUnit: 1000 } });
  
  // Create Categories
  const catCoffee = await prisma.category.create({ data: { name: 'Coffee & Espresso' } });
  const catNonCoffee = await prisma.category.create({ data: { name: 'Non-Coffee Beverages' } });
  const catTea = await prisma.category.create({ data: { name: 'Tea & Mocktails' } });
  const catPastry = await prisma.category.create({ data: { name: 'Pastry & Bakery' } });
  const catMainCourse = await prisma.category.create({ data: { name: 'Main Course' } });
  const catSnacks = await prisma.category.create({ data: { name: 'Snacks & Bites' } });

  // Create Products
  const espressoSingle = await prisma.product.create({ data: { categoryId: catCoffee.id, sku: 'COF-001', name: 'Espresso Single Shot', buyPrice: 4000, sellPrice: 15000, currentStock: 0, isRecipeBased: true, imageUrl: '/uploads/1781423859431-769445641.jpeg' } });
  const icedLatte = await prisma.product.create({ data: { categoryId: catCoffee.id, sku: 'COF-008', name: 'Iced Caffe Latte', buyPrice: 10000, sellPrice: 30000, currentStock: 0, isRecipeBased: true, imageUrl: '/uploads/1781423894758-597559757.jpeg' } });
  const kopiSusu = await prisma.product.create({ data: { categoryId: catCoffee.id, sku: 'COF-012', name: 'Kopi Susu Gula Aren', buyPrice: 8000, sellPrice: 25000, currentStock: 0, isRecipeBased: true, imageUrl: '/uploads/1781423930262-221669602.jpeg' } });
  const icedMatcha = await prisma.product.create({ data: { categoryId: catNonCoffee.id, sku: 'NCF-002', name: 'Iced Matcha Latte', buyPrice: 12000, sellPrice: 32000, currentStock: 0, isRecipeBased: true, imageUrl: '/uploads/1781423956834-870249688.jpeg' } });
  const icedTea = await prisma.product.create({ data: { categoryId: catTea.id, sku: 'TEA-006', name: 'Iced Lemon Tea', buyPrice: 5000, sellPrice: 20000, currentStock: 0, isRecipeBased: true, imageUrl: '/uploads/1781424002841-215933063.jpeg' } });
  
  // 7 New Products (Recipe-Based)
  const icedAmericano = await prisma.product.create({ data: { categoryId: catCoffee.id, sku: 'COF-015', name: 'Iced Americano', buyPrice: 5000, sellPrice: 20000, currentStock: 0, isRecipeBased: true } });
  const cappuccino = await prisma.product.create({ data: { categoryId: catCoffee.id, sku: 'COF-016', name: 'Cappuccino', buyPrice: 8000, sellPrice: 28000, currentStock: 0, isRecipeBased: true } });
  const vanillaLatte = await prisma.product.create({ data: { categoryId: catCoffee.id, sku: 'COF-017', name: 'Vanilla Latte', buyPrice: 9500, sellPrice: 30000, currentStock: 0, isRecipeBased: true } });
  const icedChocolate = await prisma.product.create({ data: { categoryId: catNonCoffee.id, sku: 'NCF-005', name: 'Iced Chocolate', buyPrice: 9000, sellPrice: 28000, currentStock: 0, isRecipeBased: true } });
  const peachEarlGrey = await prisma.product.create({ data: { categoryId: catTea.id, sku: 'TEA-008', name: 'Peach Earl Grey Tea', buyPrice: 6500, sellPrice: 24000, currentStock: 0, isRecipeBased: true } });
  const spaghettiCarbonara = await prisma.product.create({ data: { categoryId: catMainCourse.id, sku: 'MNC-005', name: 'Spaghetti Carbonara', buyPrice: 18000, sellPrice: 42000, currentStock: 0, isRecipeBased: true } });
  const smokedBeefSandwich = await prisma.product.create({ data: { categoryId: catSnacks.id, sku: 'SNK-005', name: 'Smoked Beef Sandwich', buyPrice: 8000, sellPrice: 25000, currentStock: 0, isRecipeBased: true } });

  // Non-recipe items
  await prisma.product.createMany({
    data: [
      { categoryId: catPastry.id, sku: 'PST-001', name: 'Butter Croissant', buyPrice: 12000, sellPrice: 22000, currentStock: 30, isRecipeBased: false, imageUrl: '/uploads/1781424042795-481496641.jpeg' },
      { categoryId: catMainCourse.id, sku: 'MNC-001', name: 'Nasi Goreng Spesial', buyPrice: 20000, sellPrice: 38000, currentStock: 40, isRecipeBased: false, imageUrl: '/uploads/1781424066593-633096329.jpeg' },
      { categoryId: catSnacks.id, sku: 'SNK-001', name: 'French Fries', buyPrice: 10000, sellPrice: 22000, currentStock: 50, isRecipeBased: false, imageUrl: '/uploads/1781424107181-746505785.jpeg' },
    ],
  });

  // Create Recipes
  await prisma.recipe.createMany({
    data: [
      // Espresso Single
      { productId: espressoSingle.id, rawMaterialId: rmCoffeeBeans.id, quantityNeeded: 18 },
      { productId: espressoSingle.id, rawMaterialId: rmWater.id, quantityNeeded: 30 },
      
      // Iced Caffe Latte
      { productId: icedLatte.id, rawMaterialId: rmCoffeeBeans.id, quantityNeeded: 18 },
      { productId: icedLatte.id, rawMaterialId: rmMilk.id, quantityNeeded: 150 },
      { productId: icedLatte.id, rawMaterialId: rmIce.id, quantityNeeded: 1 }, // 1 scoop / 1 portion
      
      // Kopi Susu Gula Aren
      { productId: kopiSusu.id, rawMaterialId: rmCoffeeBeans.id, quantityNeeded: 18 },
      { productId: kopiSusu.id, rawMaterialId: rmMilk.id, quantityNeeded: 120 },
      { productId: kopiSusu.id, rawMaterialId: rmPalmSugar.id, quantityNeeded: 30 },
      { productId: kopiSusu.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },
      
      // Iced Matcha Latte
      { productId: icedMatcha.id, rawMaterialId: rmMatcha.id, quantityNeeded: 20 },
      { productId: icedMatcha.id, rawMaterialId: rmMilk.id, quantityNeeded: 150 },
      { productId: icedMatcha.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },

      // Iced Lemon Tea
      { productId: icedTea.id, rawMaterialId: rmTea.id, quantityNeeded: 10 },
      { productId: icedTea.id, rawMaterialId: rmWater.id, quantityNeeded: 200 },
      { productId: icedTea.id, rawMaterialId: rmSugarSyrup.id, quantityNeeded: 20 },
      { productId: icedTea.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },

      // 1. Iced Americano
      { productId: icedAmericano.id, rawMaterialId: rmCoffeeBeans.id, quantityNeeded: 18 },
      { productId: icedAmericano.id, rawMaterialId: rmWater.id, quantityNeeded: 150 },
      { productId: icedAmericano.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },

      // 2. Cappuccino
      { productId: cappuccino.id, rawMaterialId: rmCoffeeBeans.id, quantityNeeded: 18 },
      { productId: cappuccino.id, rawMaterialId: rmWater.id, quantityNeeded: 30 },
      { productId: cappuccino.id, rawMaterialId: rmMilk.id, quantityNeeded: 120 },

      // 3. Vanilla Latte
      { productId: vanillaLatte.id, rawMaterialId: rmCoffeeBeans.id, quantityNeeded: 18 },
      { productId: vanillaLatte.id, rawMaterialId: rmMilk.id, quantityNeeded: 120 },
      { productId: vanillaLatte.id, rawMaterialId: rmVanillaSyrup.id, quantityNeeded: 20 },
      { productId: vanillaLatte.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },

      // 4. Iced Chocolate
      { productId: icedChocolate.id, rawMaterialId: rmChocolatePowder.id, quantityNeeded: 25 },
      { productId: icedChocolate.id, rawMaterialId: rmMilk.id, quantityNeeded: 150 },
      { productId: icedChocolate.id, rawMaterialId: rmSugarSyrup.id, quantityNeeded: 20 },
      { productId: icedChocolate.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },

      // 5. Peach Earl Grey Tea
      { productId: peachEarlGrey.id, rawMaterialId: rmTea.id, quantityNeeded: 10 },
      { productId: peachEarlGrey.id, rawMaterialId: rmWater.id, quantityNeeded: 200 },
      { productId: peachEarlGrey.id, rawMaterialId: rmPeachSyrup.id, quantityNeeded: 25 },
      { productId: peachEarlGrey.id, rawMaterialId: rmIce.id, quantityNeeded: 1 },

      // 6. Spaghetti Carbonara
      { productId: spaghettiCarbonara.id, rawMaterialId: rmSpaghetti.id, quantityNeeded: 100 },
      { productId: spaghettiCarbonara.id, rawMaterialId: rmCarbonaraSauce.id, quantityNeeded: 100 },
      { productId: spaghettiCarbonara.id, rawMaterialId: rmSmokedBeef.id, quantityNeeded: 3 },

      // 7. Smoked Beef Sandwich
      { productId: smokedBeefSandwich.id, rawMaterialId: rmRoti.id, quantityNeeded: 2 },
      { productId: smokedBeefSandwich.id, rawMaterialId: rmKeju.id, quantityNeeded: 1 },
      { productId: smokedBeefSandwich.id, rawMaterialId: rmSmokedBeef.id, quantityNeeded: 2 },
    ]
  });

  console.log('Seed data successfully inserted.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
