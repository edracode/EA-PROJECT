//+------------------------------------------------------------------+
//|                                                  Environment.mqh |
//|                                  EMSR ECLIPSED QUANT EA v1.0.0   |
//+------------------------------------------------------------------+
#include "Defines.mqh"

class CEnvironmentEngine
{
public:
   static bool GetSymbolParams(const string symbol, StSymbolParams &params)
   {
      params.symbol       = symbol;
      params.pointSize    = SymbolInfoDouble(symbol, SYMBOL_POINT);
      params.tickSize     = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      params.tickValue    = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      params.contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      params.minVolume    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      params.maxVolume    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      params.volumeStep   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      params.digits       = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

      if(params.tickSize <= 0 || params.tickValue <= 0 || params.volumeStep <= 0)
      {
         PrintFormat("[ENV ERROR] Spesifikasi simbol %s tidak valid!", symbol);
         return false;
      }
      return true;
   }
};
