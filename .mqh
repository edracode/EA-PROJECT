//+------------------------------------------------------------------+
//|                                                      Defines.mqh |
//|                                  EMSR ECLIPSED QUANT EA v1.0.0   |
//+------------------------------------------------------------------+
#property copyright "EMSR Quant Team"
#property version   "1.00"

enum ENUM_MARKET_REGIME
{
   REGIME_NO_TRADE = 0,
   REGIME_TREND_BULLISH,
   REGIME_TREND_BEARISH,
   REGIME_RANGING,
   REGIME_HIGH_VOLATILITY
};

enum ENUM_LOCK_STATE
{
   LOCK_STATE_CLEAR = 0,
   LOCK_STATE_LOCKED,
   LOCK_STATE_SAFE_MODE
};

enum ENUM_TRADE_SIGNAL
{
   SIGNAL_NO_TRADE = 0,
   SIGNAL_BUY,
   SIGNAL_SELL
};

struct StSymbolParams
{
   string   symbol;
   double   pointSize;
   double   tickSize;
   double   tickValue;
   double   contractSize;
   double   minVolume;
   double   maxVolume;
   double   volumeStep;
   int      digits;
};

struct StTradeRisk
{
   double   rawLot;
   double   adjustedLot;
   double   monetaryRisk;
   double   costInR;
   double   slPrice;
   double   tpPrice;
   bool     isValid;
   string   rejectionReason;
};

struct StDailyState
{
   datetime lastResetTime;
   double   startingEquity;
   double   realizedPL;
   double   floatingPL;
   bool     isLocked;
   bool     isSafeMode;
};
