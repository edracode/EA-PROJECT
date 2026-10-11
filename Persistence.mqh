//+------------------------------------------------------------------+
//|                                                  Persistence.mqh |
//|                                  EMSR ECLIPSED QUANT EA v1.0.0   |
//+------------------------------------------------------------------+
#include "Defines.mqh"

class CPersistenceEngine
{
private:
   string m_fileName;
   string m_gvPrefix;

public:
   CPersistenceEngine()
   {
      m_fileName = "EMSR_State_v100.bin";
      m_gvPrefix = "EMSR_LOCK_";
   }

   bool SaveState(const StDailyState &state)
   {
      // 1. Simpan ke Global Variables
      GlobalVariableSet(m_gvPrefix + "EQUITY", state.startingEquity);
      GlobalVariableSet(m_gvPrefix + "LOCKED", state.isLocked ? 1.0 : 0.0);
      GlobalVariableSet(m_gvPrefix + "SAFE",   state.isSafeMode ? 1.0 : 0.0);

      // 2. Simpan ke File Biner Lokal
      int handle = FileOpen(m_fileName, FILE_WRITE|FILE_BIN);
      if(handle == INVALID_HANDLE) return false;

      FileWriteStruct(handle, state);
      FileClose(handle);
      return true;
   }

   bool LoadState(StDailyState &state)
   {
      StDailyState fileState;
      ZeroMemory(fileState);

      int handle = FileOpen(m_fileName, FILE_READ|FILE_BIN);
      bool fileValid = false;

      if(handle != INVALID_HANDLE)
      {
         if(FileReadStruct(handle, fileState) > 0) fileValid = true;
         FileClose(handle);
      }

      double gvEquity = GlobalVariableGet(m_gvPrefix + "EQUITY");
      double gvLocked = GlobalVariableGet(m_gvPrefix + "LOCKED");
      double gvSafe   = GlobalVariableGet(m_gvPrefix + "SAFE");

      if(!fileValid || gvEquity == 0)
      {
         state.isSafeMode = true;
         Print("[PERSISTENCE WARNING] Discrepancy detected! Activating SAFE MODE.");
         return false;
      }

      state = fileState;
      return true;
   }
};
