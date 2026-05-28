import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Hash password & PIN
  const passwordHash = await bcrypt.hash('password123', 10);
  const pinHash = await bcrypt.hash('123456', 10);

  // Check if admin exists
  let admin = await prisma.user.findUnique({
    where: { username: 'admin' },
  });

  if (!admin) {
    admin = await prisma.user.create({
      data: {
        username: 'admin',
        passwordHash,
        role: 'ADMIN',
        pin: pinHash,
      },
    });
    console.log('Admin user created:', admin.username);
  } else {
    console.log('Admin user already exists');
  }

  // Assign existing transactions without a cashier to this admin
  const result = await prisma.transaction.updateMany({
    where: { cashierId: null },
    data: { cashierId: admin.id },
  });

  console.log(`Assigned ${result.count} transactions to admin.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
