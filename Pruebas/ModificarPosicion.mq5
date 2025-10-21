//+------------------------------------------------------------------+
//|                                            ModificarPosicion.mq5 |
//|                                                           Tonali |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade/Trade.mqh>

//Elementos para operar
CTrade trade;     //Crear una instancia de Ctrade
double Ask, Bid;  //Crear variabl5s para precio de ASK (compra) y BID (venta)
ulong positionTicket = 0;

int OnStart()
  {
   
   return(INIT_SUCCEEDED);
  }


void OnTick()
  {
   //Precios para operar
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);   //Calculamos el precio de compra (ASK)
   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);   //Calculamos el precio de venta (BID)
   
   if (PositionsTotal()==0){
      bool buyConfirm = trade.Buy(0.10, NULL, Ask, (Ask-300 * _Point),(Ask+300 * _Point), NULL);
      positionTicket = trade.ResultOrder();
   }
   
   //for (int i=0; i<3; i++){
      //PositionSelectByTicket(positionTicket);
      //Sleep(2000);
      
      //trade.PositionModify(PositionGetInteger(POSITION_TICKET), PositionGetDouble(POSITION_SL)-100*_Point, PositionGetDouble(POSITION_TP)+100*_Point);
      
      //Alert("La modificacion esta hecha");
     
   //}
   
   PositionSelectByTicket(positionTicket);
   if (PositionGetDouble(POSITION_PRICE_CURRENT) > (PositionGetDouble(POSITION_PRICE_OPEN)+250*_Point)){   
      trade.PositionModify(PositionGetInteger(POSITION_TICKET), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_PRICE_OPEN)+300*_Point);
   }
   Comment(
               "Precio actual= ", PositionGetDouble(POSITION_PRICE_CURRENT), "\n",
               "Precio entrada= ", PositionGetDouble(POSITION_PRICE_OPEN), "\n",
               "Precio be= ", PositionGetDouble(POSITION_PRICE_OPEN)+250*_Point, "\n"
      );
   
  }
//+------------------------------------------------------------------+
