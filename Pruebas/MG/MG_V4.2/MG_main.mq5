//+------------------------------------------------------------------+
//|                                                      MG_main.mq5 |
//|                                                           Tonali |
//|                         https://es.tradingview.com/u/Cignus_LOC/ |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      "https://es.tradingview.com/u/Cignus_LOC/"
#property version   "1.00"

#include  "TradeProcessor_v1.mq5"
#include  "MGZonas_v4.2.mq5"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(magicNumber);
   //Visualizar botones   
    botonesMG();
   //Otener en cual grafico esta instalado el EA    
   mChartID = ChartID();
   //Print("The EA is running on chart ID: ", mChartID);   
   
   InitCounters();
   SimpleTradeProcessor();   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Comment("");
   BorrarBotones();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---   
   //Calculamos el precio de compra (ASK)
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   //Calculamos el precio de venta (BID)
   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
   
   MGZonas();
   //Comment("\n Contador de iteraciones: ");
  }
//+------------------------------------------------------------------+
