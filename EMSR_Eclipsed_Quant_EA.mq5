//+------------------------------------------------------------------+
//|                                 EMSR_Eclipsed_Quant_EA.mq5       |
//|                                  EMSR ECLIPSED QUANT EA v1.0.0   |
//+------------------------------------------------------------------+
#include "Include/Defines.mqh"
#include "Include/Environment.mqh"
#include "Include/IndicatorEngine.mqh"
#include "Include/RiskEngine.mqh"
#include "Include/Persistence.mqh"
#include <Trade/Trade.mqh>

input double InpInitialCapital    = 500000.0; // Modal Acuan (Rp)
input double InpRiskPerTradePct   = 0.25;     // Risiko per Transaksi (%)
input double InpDailyLossLimitPct = 2.0;      // Batas Kerugian Harian (%)
input double InpMaxCostRatioR     = 0.12;     // Maksimal Biaya Transaksi (R)
input ulong  InpMagicNumber       = 20261011;

CIndicatorEngine   g_indicators;
CPersistenceEngine g_persistence;
CTrade             g_trade;
StDailyState       g_dailyState;
datetime           g_lastBarTime;

int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   if(!g_indicators.Init(_Symbol)) return INIT_FAILED;

   if(!g_persistence.LoadState(g_dailyState))
   {
      g_dailyState.startingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_dailyState.lastResetTime  = TimeCurrent();
      g_dailyState.isLocked       = false;
      g_dailyState.isSafeMode     = false;
      g_persistence.SaveState(g_dailyState);
   }

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   g_persistence.SaveState(g_dailyState);
}

void OnTick()
{
   // 1. Verifikasi Reset Tanggal Server
   MqlDateTime dtCurrent, dtLast;
   TimeToStruct(TimeCurrent(), dtCurrent);
   TimeToStruct(g_dailyState.lastResetTime, dtLast);

   if(dtCurrent.day != dtLast.day && PositionsTotal() == 0)
   {
      g_dailyState.startingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_dailyState.lastResetTime  = TimeCurrent();
      g_dailyState.isLocked       = false;
      g_persistence.SaveState(g_dailyState);
      Print("[DAILY RESET] Reset harian berhasil dilaksanakan.");
   }

   // 2. Evaluasi Proteksi Kerugian Harian
   double maxDailyLossAllowed = InpInitialCapital * (InpDailyLossLimitPct / 100.0);
   double currentEquity       = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentDailyLoss    = MathMax(0.0, g_dailyState.startingEquity - currentEquity);

   if(currentDailyLoss >= maxDailyLossAllowed)
   {
      g_dailyState.isLocked = true;
      g_persistence.SaveState(g_dailyState);
   }

   if(g_dailyState.isLocked || g_dailyState.isSafeMode) return;

   // 3. Eksekusi Hanya Pada Bar Baru M15
   datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
   if(currentBarTime == g_lastBarTime) return;
   g_lastBarTime = currentBarTime;

   // 4. Analisis Multi-Timeframe (H1 & M15)
   double ema20_h1, ema50_h1;
   if(!g_indicators.GetH1Trend(ema20_h1, ema50_h1)) return;

   double ema20_m15, ema50_m15, adx_m15, pDi, mDi, atr_m15;
   if(!g_indicators.GetM15Data(_Symbol, ema20_m15, ema50_m15, adx_m15, pDi, mDi, atr_m15)) return;

   bool isH1Bullish = (ema20_h1 > ema50_h1);
   bool isH1Bearish = (ema20_h1 < ema50_h1);
   bool isM15Bull   = (ema20_m15 > ema50_m15) && (adx_m15 >= 25.0) && (pDi > mDi);
   bool isM15Bear   = (ema20_m15 < ema50_m15) && (adx_m15 >= 25.0) && (mDi > pDi);

   ENUM_TRADE_SIGNAL signal = SIGNAL_NO_TRADE;
   if(isH1Bullish && isM15Bull) signal = SIGNAL_BUY;
   else if(isH1Bearish && isM15Bear) signal = SIGNAL_SELL;

   if(signal == SIGNAL_NO_TRADE || PositionsTotal() > 0) return;

   // 5. Kalkulasi Stop-Loss Berbasis Swing Point & ATR
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double rawSl = 0.0;
   double targetRisk = InpInitialCapital * (InpRiskPerTradePct / 100.0);

   if(signal == SIGNAL_BUY)
   {
      double swingLow = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, 10, 1));
      rawSl = swingLow - (0.2 * atr_m15);
      if((ask - rawSl) < (1.0 * atr_m15)) return; // Validasi Jarak SL Minimum ATR

      StTradeRisk risk;
      CRiskEngine::CalculateOrder(_Symbol, ORDER_TYPE_BUY, ask, rawSl, targetRisk, InpMaxCostRatioR, risk);
      if(risk.isValid)
      {
         g_trade.Buy(risk.adjustedLot, _Symbol, ask, risk.slPrice, risk.tpPrice, "EMSR_v100_BUY");
      }
   }
   else if(signal == SIGNAL_SELL)
   {
      double swingHigh = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, 10, 1));
      rawSl = swingHigh + (0.2 * atr_m15);
      if((rawSl - bid) < (1.0 * atr_m15)) return; // Validasi Jarak SL Minimum ATR

      StTradeRisk risk;
      CRiskEngine::CalculateOrder(_Symbol, ORDER_TYPE_SELL, bid, rawSl, targetRisk, InpMaxCostRatioR, risk);
      if(risk.isValid)
      {
         g_trade.Sell(risk.adjustedLot, _Symbol, bid, risk.slPrice, risk.tpPrice, "EMSR_v100_SELL");
      }
   }
}
