#define EXPERT_MAGIC 123456  // MagicNumber of the expert
//+------------------------------------------------------------------+
//| Close all positions by opposite positions                        |
//+------------------------------------------------------------------+
//https://www.mql5.com/en/forum/390306/page2#comment_28196978
void OnStart()
  {
//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);                                    // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                      // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);            // ticket of the position
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                               // volume of the position
      double sl=PositionGetDouble(POSITION_SL);                                       // Stop Loss of the position
      double tp=PositionGetDouble(POSITION_TP);                                       // Take Profit of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position
      //--- output information about the position
      PrintFormat("1. #%I64u %s  %s  %.2f  %s  sl: %s  tp: %s  [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  DoubleToString(sl,digits),
                  DoubleToString(tp,digits),
                  magic);
      //--- if the MagicNumber matches
      if(magic==EXPERT_MAGIC)
        {
         for(int j=0; j<i; j++)
           {
            string symbol=PositionGetSymbol(j); // symbol of the opposite position
            //--- if the symbols of the opposite and initial positions match
            if(symbol==position_symbol && PositionGetInteger(POSITION_MAGIC)==EXPERT_MAGIC)
              {
               //--- set the type of the opposite position
               ENUM_POSITION_TYPE type_by=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               //--- leave, if the types of the initial and opposite positions match
               if(type==type_by)
                  continue;
               //--- zeroing the request and result values
               ZeroMemory(request);
               ZeroMemory(result);
               //--- setting the operation parameters
               request.action=TRADE_ACTION_CLOSE_BY;                         // type of trade operation
               request.position=position_ticket;                             // ticket of the position
               request.position_by=PositionGetInteger(POSITION_TICKET);      // ticket of the opposite position
               //request.symbol     =position_symbol;
               request.magic=EXPERT_MAGIC;                                   // MagicNumber of the position
               //--- output information about the closure by opposite position
               PrintFormat("Close #%I64d %s %s by #%I64d",position_ticket,position_symbol,EnumToString(type),request.position_by);
               //--- send the request
               if(!OrderSend(request,result))
                  PrintFormat("OrderSend error %d",GetLastError()); // if unable to send the request, output the error code
 
               //--- information about the operation   
               PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+