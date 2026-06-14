import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding data...');

  // Delete existing data to prevent unique constraint violations on re-seed
  // Order of deletion matters due to foreign key constraints
  await prisma.promoItem.deleteMany();
  await prisma.promo.deleteMany();
  await prisma.transactionDetail.deleteMany();
  await prisma.transaction.deleteMany();
  await prisma.stockAdjustment.deleteMany();
  await prisma.activityLog.deleteMany();
  await prisma.product.deleteMany();
  await prisma.category.deleteMany();

  // Create Categories
  const catCoffee = await prisma.category.create({ data: { name: 'Coffee & Espresso' } });
  const catNonCoffee = await prisma.category.create({ data: { name: 'Non-Coffee Beverages' } });
  const catTea = await prisma.category.create({ data: { name: 'Tea & Mocktails' } });
  const catPastry = await prisma.category.create({ data: { name: 'Pastry & Bakery' } });
  const catMainCourse = await prisma.category.create({ data: { name: 'Main Course' } });
  const catSnacks = await prisma.category.create({ data: { name: 'Snacks & Bites' } });

  // Create Products
  await prisma.product.createMany({
    data: [
      // Coffee & Espresso
      { categoryId: catCoffee.id, sku: 'COF-001', name: 'Espresso Single Shot', buyPrice: 5000, sellPrice: 15000, currentStock: 100 },
      { categoryId: catCoffee.id, sku: 'COF-002', name: 'Espresso Double Shot', buyPrice: 8000, sellPrice: 20000, currentStock: 100 },
      { categoryId: catCoffee.id, sku: 'COF-003', name: 'Americano Hot', buyPrice: 6000, sellPrice: 22000, currentStock: 150 },
      { categoryId: catCoffee.id, sku: 'COF-004', name: 'Iced Americano', buyPrice: 7000, sellPrice: 24000, currentStock: 150 },
      { categoryId: catCoffee.id, sku: 'COF-005', name: 'Cappuccino Hot', buyPrice: 10000, sellPrice: 28000, currentStock: 80 },
      { categoryId: catCoffee.id, sku: 'COF-006', name: 'Iced Cappuccino', buyPrice: 12000, sellPrice: 30000, currentStock: 80 },
      { categoryId: catCoffee.id, sku: 'COF-007', name: 'Caffe Latte Hot', buyPrice: 10000, sellPrice: 28000, currentStock: 120 },
      { categoryId: catCoffee.id, sku: 'COF-008', name: 'Iced Caffe Latte', buyPrice: 12000, sellPrice: 30000, currentStock: 120 },
      { categoryId: catCoffee.id, sku: 'COF-009', name: 'Caramel Macchiato', buyPrice: 14000, sellPrice: 35000, currentStock: 60 },
      { categoryId: catCoffee.id, sku: 'COF-010', name: 'Vanilla Latte', buyPrice: 13000, sellPrice: 33000, currentStock: 70 },
      { categoryId: catCoffee.id, sku: 'COF-011', name: 'Hazelnut Latte', buyPrice: 13000, sellPrice: 33000, currentStock: 70 },
      { categoryId: catCoffee.id, sku: 'COF-012', name: 'Kopi Susu Gula Aren', buyPrice: 10000, sellPrice: 25000, currentStock: 200 },

      // Non-Coffee Beverages
      { categoryId: catNonCoffee.id, sku: 'NCF-001', name: 'Matcha Latte Hot', buyPrice: 12000, sellPrice: 30000, currentStock: 90 },
      { categoryId: catNonCoffee.id, sku: 'NCF-002', name: 'Iced Matcha Latte', buyPrice: 14000, sellPrice: 32000, currentStock: 90 },
      { categoryId: catNonCoffee.id, sku: 'NCF-003', name: 'Taro Latte Hot', buyPrice: 11000, sellPrice: 28000, currentStock: 60 },
      { categoryId: catNonCoffee.id, sku: 'NCF-004', name: 'Iced Taro Latte', buyPrice: 13000, sellPrice: 30000, currentStock: 60 },
      { categoryId: catNonCoffee.id, sku: 'NCF-005', name: 'Chocolate Classic Hot', buyPrice: 12000, sellPrice: 28000, currentStock: 80 },
      { categoryId: catNonCoffee.id, sku: 'NCF-006', name: 'Iced Chocolate Classic', buyPrice: 14000, sellPrice: 30000, currentStock: 80 },
      { categoryId: catNonCoffee.id, sku: 'NCF-007', name: 'Red Velvet Latte', buyPrice: 12000, sellPrice: 30000, currentStock: 50 },

      // Tea & Mocktails
      { categoryId: catTea.id, sku: 'TEA-001', name: 'English Breakfast Tea', buyPrice: 5000, sellPrice: 18000, currentStock: 100 },
      { categoryId: catTea.id, sku: 'TEA-002', name: 'Earl Grey Tea', buyPrice: 6000, sellPrice: 20000, currentStock: 100 },
      { categoryId: catTea.id, sku: 'TEA-003', name: 'Chamomile Tea', buyPrice: 6000, sellPrice: 22000, currentStock: 80 },
      { categoryId: catTea.id, sku: 'TEA-004', name: 'Iced Lychee Tea', buyPrice: 9000, sellPrice: 25000, currentStock: 120 },
      { categoryId: catTea.id, sku: 'TEA-005', name: 'Iced Peach Tea', buyPrice: 9000, sellPrice: 25000, currentStock: 120 },
      { categoryId: catTea.id, sku: 'TEA-006', name: 'Iced Lemon Tea', buyPrice: 7000, sellPrice: 20000, currentStock: 150 },
      { categoryId: catTea.id, sku: 'TEA-007', name: 'Virgin Mojito Mocktail', buyPrice: 12000, sellPrice: 32000, currentStock: 50 },
      { categoryId: catTea.id, sku: 'TEA-008', name: 'Sunset Paradise Mocktail', buyPrice: 14000, sellPrice: 35000, currentStock: 40 },

      // Pastry & Bakery
      { categoryId: catPastry.id, sku: 'PST-001', name: 'Butter Croissant', buyPrice: 12000, sellPrice: 22000, currentStock: 30 },
      { categoryId: catPastry.id, sku: 'PST-002', name: 'Almond Croissant', buyPrice: 15000, sellPrice: 28000, currentStock: 20 },
      { categoryId: catPastry.id, sku: 'PST-003', name: 'Pain au Chocolat', buyPrice: 14000, sellPrice: 26000, currentStock: 25 },
      { categoryId: catPastry.id, sku: 'PST-004', name: 'Cinnamon Roll', buyPrice: 13000, sellPrice: 25000, currentStock: 20 },
      { categoryId: catPastry.id, sku: 'PST-005', name: 'New York Cheesecake', buyPrice: 20000, sellPrice: 38000, currentStock: 15 },
      { categoryId: catPastry.id, sku: 'PST-006', name: 'Red Velvet Slice', buyPrice: 18000, sellPrice: 35000, currentStock: 15 },
      { categoryId: catPastry.id, sku: 'PST-007', name: 'Fudgy Brownie', buyPrice: 10000, sellPrice: 20000, currentStock: 30 },

      // Main Course
      { categoryId: catMainCourse.id, sku: 'MNC-001', name: 'Nasi Goreng Spesial', buyPrice: 20000, sellPrice: 38000, currentStock: 40 },
      { categoryId: catMainCourse.id, sku: 'MNC-002', name: 'Spaghetti Aglio Olio', buyPrice: 18000, sellPrice: 42000, currentStock: 30 },
      { categoryId: catMainCourse.id, sku: 'MNC-003', name: 'Spaghetti Carbonara', buyPrice: 22000, sellPrice: 45000, currentStock: 30 },
      { categoryId: catMainCourse.id, sku: 'MNC-004', name: 'Chicken Cordon Bleu', buyPrice: 25000, sellPrice: 55000, currentStock: 20 },
      { categoryId: catMainCourse.id, sku: 'MNC-005', name: 'Beef Rice Bowl', buyPrice: 22000, sellPrice: 48000, currentStock: 35 },
      { categoryId: catMainCourse.id, sku: 'MNC-006', name: 'Chicken Katsu Curry', buyPrice: 20000, sellPrice: 45000, currentStock: 30 },

      // Snacks & Bites
      { categoryId: catSnacks.id, sku: 'SNK-001', name: 'French Fries', buyPrice: 10000, sellPrice: 22000, currentStock: 50 },
      { categoryId: catSnacks.id, sku: 'SNK-002', name: 'Truffle Fries', buyPrice: 15000, sellPrice: 32000, currentStock: 40 },
      { categoryId: catSnacks.id, sku: 'SNK-003', name: 'Chicken Wings (6pcs)', buyPrice: 18000, sellPrice: 38000, currentStock: 30 },
      { categoryId: catSnacks.id, sku: 'SNK-004', name: 'Onion Rings', buyPrice: 12000, sellPrice: 25000, currentStock: 40 },
      { categoryId: catSnacks.id, sku: 'SNK-005', name: 'Platter Mix', buyPrice: 25000, sellPrice: 55000, currentStock: 20 },
      { categoryId: catSnacks.id, sku: 'SNK-006', name: 'Dimsum Ayam (4pcs)', buyPrice: 12000, sellPrice: 24000, currentStock: 40 },
    ],
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
