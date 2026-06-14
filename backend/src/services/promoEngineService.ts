import prisma from '../config/prisma';

export interface CartItemInput {
  productId: number;
  quantity: number;
  unitPrice: number;
}

export interface PromoEvaluationResult {
  totalOriginalAmount: number;
  totalDiscountAmount: number;
  totalFinalAmount: number;
  appliedPromoId: number | null; // Transaction-level promo
  items: Array<{
    productId: number;
    quantity: number;
    unitPrice: number;
    discountAmount: number;
    subtotal: number;
    promoId: number | null; // Item-level promo
  }>;
}

export class PromoEngineService {
  /**
   * Evaluates the cart and applies the Best Deal (non-stackable) promotion logic.
   */
  static async evaluateCart(items: CartItemInput[]): Promise<PromoEvaluationResult> {
    const now = new Date();
    
    // Format current time as HH:MM for Happy Hour check
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTimeStr = `${String(currentHour).padStart(2, '0')}:${String(currentMinute).padStart(2, '0')}`;

    // Fetch active promotions
    const activePromos = await prisma.promo.findMany({
      where: {
        isActive: true,
        OR: [
          { startDate: null },
          { startDate: { lte: now } },
        ],
        AND: [
          {
            OR: [
              { endDate: null },
              { endDate: { gte: now } },
            ],
          },
          {
            OR: [
              { quota: null },
              { usedCount: { lt: prisma.promo.fields.quota } },
            ],
          }
        ]
      },
      include: {
        promoItems: true,
      },
    });

    // Calculate original total amount
    let totalOriginalAmount = 0;
    for (const item of items) {
      totalOriginalAmount += item.quantity * item.unitPrice;
    }

    // Split promos into item-level and transaction-level
    // Transaction-level: PERCENTAGE or FIXED_AMOUNT with NO specific promoItems
    // Item-level: BOGO, HAPPY_HOUR, or PERCENTAGE/FIXED_AMOUNT with specific promoItems
    const itemLevelPromos = activePromos.filter(
      (p) => p.type === 'BOGO' || p.type === 'HAPPY_HOUR' || p.promoItems.length > 0
    );

    const transactionLevelPromos = activePromos.filter(
      (p) => (p.type === 'PERCENTAGE' || p.type === 'FIXED_AMOUNT') && p.promoItems.length === 0
    );

    // ==========================================
    // SCENARIO A: Calculate Item-Level Discounts
    // ==========================================
    let scenarioAItems = items.map((item) => {
      let bestDiscount = 0;
      let bestPromoId: number | null = null;

      // Find eligible promos for this specific product
      const eligiblePromos = itemLevelPromos.filter((promo) => {
        // 1. Check if the promo applies to this product
        const hasItem = promo.promoItems.some((pi) => pi.productId === item.productId);
        const appliesToAll = promo.promoItems.length === 0;
        if (!hasItem && !appliesToAll) return false;

        // 2. Additional type-specific checks
        if (promo.type === 'HAPPY_HOUR') {
          if (promo.startTime && promo.endTime) {
            return currentTimeStr >= promo.startTime && currentTimeStr <= promo.endTime;
          }
        }

        return true;
      });

      // Calculate discount for each eligible promo and pick the best one
      for (const promo of eligiblePromos) {
        let discount = 0;
        const val = Number(promo.value);

        if (promo.type === 'BOGO') {
          // value is buy quantity X (e.g. buy 1, get 1 free). Total block = X + 1
          const buyQty = val > 0 ? val : 1;
          const freeQty = Math.floor(item.quantity / (buyQty + 1));
          discount = freeQty * item.unitPrice;
        } else if (promo.type === 'PERCENTAGE' || promo.type === 'HAPPY_HOUR') {
          discount = item.quantity * item.unitPrice * (val / 100);
        } else if (promo.type === 'FIXED_AMOUNT') {
          discount = item.quantity * val;
        }

        // Apply item-level max discount cap if defined
        if (promo.maxDiscount) {
          const maxDisc = Number(promo.maxDiscount);
          if (discount > maxDisc) {
            discount = maxDisc;
          }
        }

        if (discount > bestDiscount) {
          bestDiscount = discount;
          bestPromoId = promo.id;
        }
      }

      const subtotal = (item.quantity * item.unitPrice) - bestDiscount;

      return {
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountAmount: bestDiscount,
        subtotal: subtotal > 0 ? subtotal : 0,
        promoId: bestPromoId,
      };
    });

    const scenarioATotalDiscount = scenarioAItems.reduce((sum, item) => sum + item.discountAmount, 0);

    // ==========================================
    // SCENARIO B: Calculate Transaction-Level Discounts
    // ==========================================
    let bestTxDiscount = 0;
    let bestTxPromoId: number | null = null;

    for (const promo of transactionLevelPromos) {
      // Check minimum purchase
      const minPurch = promo.minPurchase ? Number(promo.minPurchase) : 0;
      if (totalOriginalAmount < minPurch) continue;

      let discount = 0;
      const val = Number(promo.value);

      if (promo.type === 'PERCENTAGE') {
        discount = totalOriginalAmount * (val / 100);
      } else if (promo.type === 'FIXED_AMOUNT') {
        discount = val;
      }

      // Apply max discount cap
      if (promo.maxDiscount) {
        const maxDisc = Number(promo.maxDiscount);
        if (discount > maxDisc) {
          discount = maxDisc;
        }
      }

      if (discount > bestTxDiscount) {
        bestTxDiscount = discount;
        bestTxPromoId = promo.id;
      }
    }

    // ==========================================
    // BEST DEAL DECISION: Scenario A vs Scenario B
    // ==========================================
    if (scenarioATotalDiscount >= bestTxDiscount) {
      // Scenario A wins: Item-level discounts are applied
      const totalDiscountAmount = scenarioATotalDiscount;
      const totalFinalAmount = totalOriginalAmount - totalDiscountAmount;

      return {
        totalOriginalAmount,
        totalDiscountAmount,
        totalFinalAmount: totalFinalAmount > 0 ? totalFinalAmount : 0,
        appliedPromoId: null,
        items: scenarioAItems,
      };
    } else {
      // Scenario B wins: Transaction-level discount is applied
      const totalDiscountAmount = bestTxDiscount;
      const totalFinalAmount = totalOriginalAmount - totalDiscountAmount;

      // Reset item-level discounts because transaction-level wins
      const scenarioBItems = items.map((item) => ({
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountAmount: 0,
        subtotal: item.quantity * item.unitPrice,
        promoId: null,
      }));

      return {
        totalOriginalAmount,
        totalDiscountAmount,
        totalFinalAmount: totalFinalAmount > 0 ? totalFinalAmount : 0,
        appliedPromoId: bestTxPromoId,
        items: scenarioBItems,
      };
    }
  }
}
