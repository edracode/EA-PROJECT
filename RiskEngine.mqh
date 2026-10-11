//+------------------------------------------------------------------+
//|                                                   RiskEngine.mqh |
//|                                  EMSR ECLIPSED QUANT EA v1.0.0   |
//+------------------------------------------------------------------+
#include "Defines.mqh"
#include "Environment.mqh"

class CRiskEngine
{
public:
   static void CalculateOrder(const string symbol,
                             const ENUM_ORDER_TYPE orderType,
                             const double entryPrice,
                             const double rawSlPrice,
                             const double targetRiskMonetary,
                             const double maxCostRatio,
                             StTradeRisk &outRisk)
   {
      outRisk.isValid = false;
      StSymbolParams p;
      if(!CEnvironmentEngine::GetSymbolParams(symbol, p))
      {
         outRisk.rejectionReason = "ERR_ENV_FAILED";
         return;
      }

      double priceRisk = MathAbs(entryPrice - rawSlPrice);
      if(priceRisk <= 0)
      {
         outRisk.rejectionReason = "ERR_INVALID_SL_PRICE";
         return;
      }

      double ticksAtRisk = priceRisk / p.tickSize;
      double riskPerLot  = ticksAtRisk * p.tickValue;

      if(riskPerLot <= 0)
      {
         outRisk.rejectionReason = "ERR_ZERO_RISK_PER_LOT";
         return;
      }

      outRisk.rawLot = targetRiskMonetary / riskPerLot;
      double steppedLot = MathFloor(outRisk.rawLot / p.volumeStep) * p.volumeStep;

      if(steppedLot < p.minVolume)
      {
         outRisk.rejectionReason = "REJECT_LOT_BELOW_MINIMUM";
         return;
      }

      outRisk.adjustedLot = MathMin(steppedLot, p.maxVolume);
      outRisk.monetaryRisk = outRisk.adjustedLot * riskPerLot;

      if(outRisk.monetaryRisk > targetRiskMonetary)
      {
         outRisk.rejectionReason = "REJECT_RISK_EXCEEDS_TARGET";
         return;
      }

      // Perhitungan Biaya Transaksi dalam R
      double spreadPoints = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      double spreadMonetary = spreadPoints * p.pointSize * (p.tickValue / p.tickSize) * outRisk.adjustedLot;
      double commissionEst = 0.0; // Disesuaikan dengan struktur komisi broker jika ada
      double totalCostMonetary = spreadMonetary + commissionEst;

      outRisk.costInR = totalCostMonetary / targetRiskMonetary;

      if(outRisk.costInR > maxCostRatio)
      {
         outRisk.rejectionReason = "REJECT_TRANSACTION_COST_TOO_HIGH";
         return;
      }

      outRisk.slPrice = NormalizeDouble(rawSlPrice, p.digits);
      if(orderType == ORDER_TYPE_BUY)
         outRisk.tpPrice = NormalizeDouble(entryPrice + 3.0 * (entryPrice - outRisk.slPrice), p.digits);
      else
         outRisk.tpPrice = NormalizeDouble(entryPrice - 3.0 * (outRisk.slPrice - entryPrice), p.digits);

      outRisk.isValid = true;
      outRisk.rejectionReason = "NONE";
   }
};
