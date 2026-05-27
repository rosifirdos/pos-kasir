import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const category1 = await prisma.category.create({
    data: { name: 'Makanan Ringan' },
  });
  
  const category2 = await prisma.category.create({
    data: { name: 'Minuman' },
  });

  await prisma.product.createMany({
    data: [
      {
        categoryId: category1.id,
        sku: 'SNK-001',
        name: 'Keripik Kentang',
        buyPrice: 3000,
        sellPrice: 5000,
        currentStock: 100,
      },
      {
        categoryId: category1.id,
        sku: 'SNK-002',
        name: 'Biskuit Cokelat',
        buyPrice: 4000,
        sellPrice: 7000,
        currentStock: 50,
      },
      {
        categoryId: category2.id,
        sku: 'BEV-001',
        name: 'Air Mineral',
        buyPrice: 2000,
        sellPrice: 3500,
        currentStock: 200,
      },
      {
        categoryId: category2.id,
        sku: 'BEV-002',
        name: 'Kopi Dingin',
        buyPrice: 5000,
        sellPrice: 8000,
        currentStock: 40,
      },
    ],
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
