import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const logActivity = async (
  action: string,
  entityType: string,
  entityId?: number,
  details?: string
) => {
  try {
    await prisma.activityLog.create({
      data: {
        action,
        entityType,
        entityId,
        details,
      },
    });
  } catch (error) {
    console.error('Failed to log activity:', error);
  }
};
