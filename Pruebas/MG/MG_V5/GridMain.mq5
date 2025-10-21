//+------------------------------------------------------------------+
//|                                                     GridMain.mq5 |
//|                                                           Tonali |
//|                         https://es.tradingview.com/u/Cignus_LOC/ |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      "https://es.tradingview.com/u/Cignus_LOC/"
#property version   "1.00"

#include "LordOfTheGrid_v5.mq5"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   mInicializacion = false;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll(0, "LinePivote_", 0, -1);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   LordOfTheGrid();
  }
//+------------------------------------------------------------------+
