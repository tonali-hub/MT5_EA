//+------------------------------------------------------------------+
//|                                     OroVentana_Alembert_v1.1.mq5 |
//|                                                           Tonali |
//|                         https://es.tradingview.com/u/Cignus_LOC/ |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      "https://es.tradingview.com/u/Cignus_LOC/"
#property version   "1.00"

#include<Trade/Trade.mqh>
#resource "\\Indicators\\Heiken_Ashi.ex5"//_Oro00_v2.ex5"

CTrade trade;     //Crear una instancia de Ctrade

//Handlers
int handleHeiken;




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   handleHeiken         = iCustom(_Symbol, _Period, "::Indicators\\Heiken_Ashi.ex5");//_Oro00_v2.ex5"); 
   //int hola = CopyBuffer(handleHeiken,3,0,3,closePrice);
   trade.Buy(1,NULL);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+

/*
 Ventana_v1_handle = iCustom(NULL, PERIOD_CURRENT, "Ventana_v1", "-- Ventana --", InpNumVentana, InpGMTServidor, InpHayDSTServidor, 0, InpGMTEstrategia, InpHayDSTEstrategia, 0, InpVentanaAperturaHora, InpVentanaAperturaMin, InpVentanaDiaria, InpCierreVentanaAlCerrarVela, InpVentanaCierreHora, InpVentanaCierreMin, InpVerLineasVentana, InpVerComentariosVentana, InpVerComentariosVentana, "-- Dias --",InpLunes, InpMartes, InpMiercoles, InpJueves, InpViernes, InpSabado, InpDomingo);
if(MA[0] < MA2[0] && MA[1] > MA2[1]//Cross(0, MA[0] < MA2[0] && MA[1] > MA2[1] ) //Moving Average crosses below Moving Average
&& AperturaVentanaDetectada(0,Ventana_v1[0] == 1)
double MultAlembert = TradesCount(ORDER_TYPE_BUY) == 0 ? 1.0 : (InpAplicarAlembert ? TradesCount(ORDER_TYPE_BUY)+1 : 1.0);
         ticket = myOrderSend(ORDER_TYPE_BUY, price, TradeSize * Position_Percent * MultAlembert / 100, "");         
*/  