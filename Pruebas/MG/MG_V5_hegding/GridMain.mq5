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
//--- check if autotrading is allowed 
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) 
     { 
      Alert("Autotrading in the terminal is disabled, Expert Advisor will be removed."); 
      ExpertRemove();       
     } 
//--- unable to trade on a real account 
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL
   //&& (!MQLInfoInteger(MQL_TESTER) || !MQLInfoInteger(MQL_OPTIMIZATION))
   ) 
     { 
      Alert("A QUE CARAY, PRIMERO DEMO Y LUEGO REAL!"); 
      ExpertRemove(); 
     } 
//--- check if it is possible to trade on this account (for example, trading is impossible when using an investor password) 
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) 
     { 
      Alert("Trading on this account is disabled"); 
      ExpertRemove(); 
     } 
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
   Comment("");
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
