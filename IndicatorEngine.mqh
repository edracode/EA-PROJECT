//+------------------------------------------------------------------+
//|                                              IndicatorEngine.mqh |
//|                                  EMSR ECLIPSED QUANT EA v1.0.0   |
//+------------------------------------------------------------------+
#include "Defines.mqh"

class CIndicatorEngine
{
private:
   int m_hEma20_M15, m_hEma50_M15;
   int m_hEma20_H1,  m_hEma50_H1;
   int m_hAdx_M15,   m_hAtr_M15;

public:
   bool Init(const string symbol)
   {
      m_hEma20_M15 = iMA(symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
      m_hEma50_M15 = iMA(symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
      m_hEma20_H1  = iMA(symbol, PERIOD_H1,  20, 0, MODE_EMA, PRICE_CLOSE);
      m_hEma50_H1  = iMA(symbol, PERIOD_H1,  50, 0, MODE_EMA, PRICE_CLOSE);
      m_hAdx_M15   = iADX(symbol, PERIOD_M15, 14);
      m_hAtr_M15   = iATR(symbol, PERIOD_M15, 14);

      if(m_hEma20_M15 == INVALID_HANDLE || m_hEma50_M15 == INVALID_HANDLE ||
         m_hEma20_H1  == INVALID_HANDLE || m_hEma50_H1  == INVALID_HANDLE ||
         m_hAdx_M15   == INVALID_HANDLE || m_hAtr_M15   == INVALID_HANDLE)
      {
         Print("[IND ERROR] Gagal menginisialisasi handle indikator MQL5.");
         return false;
      }
      return true;
   }

   bool GetM15Data(const string symbol, double &ema20, double &ema50, double &adx, double &plusDi, double &minusDi, double &atr)
   {
      double bEma20[1], bEma50[1], bAdx[1], bPlusDi[1], bMinusDi[1], bAtr[1];

      if(CopyBuffer(m_hEma20_M15, 0, 1, 1, bEma20) <= 0 ||
         CopyBuffer(m_hEma50_M15, 0, 1, 1, bEma50) <= 0 ||
         CopyBuffer(m_hAdx_M15, 0, 1, 1, bAdx) <= 0 ||
         CopyBuffer(m_hAdx_M15, 1, 1, 1, bPlusDi) <= 0 ||
         CopyBuffer(m_hAdx_M15, 2, 1, 1, bMinusDi) <= 0 ||
         CopyBuffer(m_hAtr_M15, 0, 1, 1, bAtr) <= 0)
      {
         return false;
      }

      ema20   = bEma20[0];
      ema50   = bEma50[0];
      adx     = bAdx[0];
      plusDi  = bPlusDi[0];
      minusDi = bMinusDi[0];
      atr     = bAtr[0];
      return true;
   }

   bool GetH1Trend(double &ema20, double &ema50)
   {
      double bEma20[1], bEma50[1];
      if(CopyBuffer(m_hEma20_H1, 0, 1, 1, bEma20) <= 0 ||
         CopyBuffer(m_hEma50_H1, 0, 1, 1, bEma50) <= 0) return false;

      ema20 = bEma20[0];
      ema50 = bEma50[0];
      return true;
   }
};
