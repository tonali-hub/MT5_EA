//+------------------------------------------------------------------+
//|                                             Strategy: Prueba.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "Created with EABuilder.com"
#property link      "https://www.eabuilder.com"
#property version   "1.00"
#property description ""
#property tester_indicator "Ventana_v1"
#property tester_indicator "LineasPivote_EABuilder"


input ENUM_TIMEFRAMES InpTFVentana = PERIOD_M1;
input double InpTP = 10;
input bool InpOperarLongs = true;
input bool InpOperarShorts = true;
input double InpAncho = 5;
int LotDigits; //initialized in OnInit
int MagicNumber = 966016;
int NextOpenTradeAfterTOD_Hour = 00; //next open trade after time of the day
int NextOpenTradeAfterTOD_Min = 00; //next open trade after time of the day
datetime NextTradeTime = 0;
double TradeSize = 0.1;
int MaxSlippage = 3; //slippage, adjusted in OnInit
int MaxSlippage_;
int MaxOpenTrades = 1000;
int MaxLongTrades = 1000;
int MaxShortTrades = 1000;
int MaxPendingOrders = 1000;
int MaxLongPendingOrders = 1000;
int MaxShortPendingOrders = 1000;
bool Hedging = true;
int OrderRetry = 5; //# of retries if sending order returns error
int OrderWait = 5; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit
int Ventana_v1_handle;
double Ventana_v1_1[];
int LineasPivote_EABuilder_handle;
double LineasPivote_EABuilder_2[];

void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | Prueba @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
  }

int TradesCount(ENUM_ORDER_TYPE type) //returns # of open trades for order type, current symbol and magic number
  {
   if(type <= 1)
     {
      int result = 0;
      int total = PositionsTotal();
      for(int i = 0; i < total; i++)
        {
         if(PositionGetTicket(i) <= 0) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != Symbol() || PositionGetInteger(POSITION_TYPE) != type) continue;
         result++;
        }
      return(result);
     }
   else
     {
      int result = 0;
      int total = OrdersTotal();
      for(int i = 0; i < total; i++)
        {
         if(OrderGetTicket(i) <= 0) continue;
         if(OrderGetInteger(ORDER_MAGIC) != MagicNumber || OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_TYPE) != type) continue;
         result++;
        }
      return(result);
     }
  }

double LastTradePrice(int direction)
  {
   double result = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      if(PositionGetTicket(i) <= 0) continue;
      if(PositionGetInteger(POSITION_TYPE) > 1) continue;
      if((direction < 0 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) || (direction > 0 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)) continue;
      if(PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         result = PositionGetDouble(POSITION_PRICE_OPEN);
         break;
        }
     } 
   return(result);
  }

ulong myOrderSend(ENUM_ORDER_TYPE type, double price, double volume, string ordername) //send order, return ticket ("price" is irrelevant for market orders)
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return(0);
   int retries = 0;
   int long_trades = TradesCount(ORDER_TYPE_BUY);
   int short_trades = TradesCount(ORDER_TYPE_SELL);
   int long_pending = TradesCount(ORDER_TYPE_BUY_LIMIT) + TradesCount(ORDER_TYPE_BUY_STOP) + TradesCount(ORDER_TYPE_BUY_STOP_LIMIT);
   int short_pending = TradesCount(ORDER_TYPE_SELL_LIMIT) + TradesCount(ORDER_TYPE_SELL_STOP) + TradesCount(ORDER_TYPE_SELL_STOP_LIMIT);
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   //test Hedging
   if(!Hedging && ((type % 2 == 0 && short_trades + short_pending > 0) || (type % 2 == 1 && long_trades + long_pending > 0)))
     {
      myAlert("print", "Order"+ordername_+" not sent, hedging not allowed");
      return(0);
     }
   //test maximum trades
   if((type % 2 == 0 && long_trades >= MaxLongTrades)
   || (type % 2 == 1 && short_trades >= MaxShortTrades)
   || (long_trades + short_trades >= MaxOpenTrades)
   || (type > 1 && type % 2 == 0 && long_pending >= MaxLongPendingOrders)
   || (type > 1 && type % 2 == 1 && short_pending >= MaxShortPendingOrders)
   || (type > 1 && long_pending + short_pending >= MaxPendingOrders)
   )
     {
      myAlert("print", "Order"+ordername_+" not sent, maximum reached");
      return(0);
     }
   //prepare to send order
   MqlTradeRequest request;
   ZeroMemory(request);
   request.action = (type <= 1) ? TRADE_ACTION_DEAL : TRADE_ACTION_PENDING;
   
   //set allowed filling type
   int filling = (int)SymbolInfoInteger(Symbol(),SYMBOL_FILLING_MODE);
   if(request.action == TRADE_ACTION_DEAL && (filling & 1) != 1)
      request.type_filling = ORDER_FILLING_IOC;

   request.magic = MagicNumber;
   request.symbol = Symbol();
   request.volume = NormalizeDouble(volume, LotDigits);
   request.sl = 0;
   request.tp = 0;
   request.deviation = MaxSlippage_;
   request.type = type;
   request.comment = ordername;

   int expiration=(int)SymbolInfoInteger(Symbol(), SYMBOL_EXPIRATION_MODE);
   if((expiration & SYMBOL_EXPIRATION_GTC) != SYMBOL_EXPIRATION_GTC)
     {
      request.type_time = ORDER_TIME_DAY;  
      request.type_filling = ORDER_FILLING_RETURN;
     }

   MqlTradeResult result;
   ZeroMemory(result);
   while(!OrderSuccess(result.retcode) && retries < OrderRetry+1)
     {
      //refresh price before sending order
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      if(type == ORDER_TYPE_BUY)
         price = last_tick.ask;
      else if(type == ORDER_TYPE_SELL)
         price = last_tick.bid;
      else if(price < 0) //invalid price for pending order
        {
         myAlert("order", "Order"+ordername_+" not sent, invalid price for pending order");
	      return(0);
        }
      request.price = NormalizeDouble(price, Digits());     
      if(!OrderSend(request, result) || !OrderSuccess(result.retcode))
        {
         myAlert("print", "OrderSend"+ordername_+" error: "+result.comment);
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(!OrderSuccess(result.retcode))
     {
      myAlert("error", "OrderSend"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error: "+result.comment);
      return(0);
     }
   string typestr[8] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop", "Buy Stop Limit", "Sell Stop Limit"};
   myAlert("order", "Order sent"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
   return(result.order);
  }

int myOrderModify(ENUM_ORDER_TYPE type, ulong ticket, double SL, double TP) //modify SL and TP (absolute price), zero targets do not modify
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return(-1);
   bool netting = AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   int retries = 0;
   int err = 0;
   SL = NormalizeDouble(SL, Digits());
   TP = NormalizeDouble(TP, Digits());
   if(SL < 0) SL = 0;
   if(TP < 0) TP = 0;
   //prepare to select order
   Sleep(10);
   if((type <= 1 && ((netting && !PositionSelect(Symbol())) || (!netting && !PositionSelectByTicket(ticket)))) || (type > 1 && !OrderSelect(ticket)))
     {
      err = GetLastError();
      myAlert("error", "PositionSelect / OrderSelect failed; error #"+IntegerToString(err));
      return(-1);
     }
   //ignore open positions other than "type"
   if (type <= 1 && PositionGetInteger(POSITION_TYPE) != type) return(0);
   //prepare to modify order
   double currentSL = (type <= 1) ? PositionGetDouble(POSITION_SL) : OrderGetDouble(ORDER_SL);
   double currentTP = (type <= 1) ? PositionGetDouble(POSITION_TP) : OrderGetDouble(ORDER_TP);
   if(NormalizeDouble(SL, Digits()) == 0) SL = currentSL; //not to modify
   if(NormalizeDouble(TP, Digits()) == 0) TP = currentTP; //not to modify
   if(NormalizeDouble(SL - currentSL, Digits()) == 0
   && NormalizeDouble(TP - currentTP, Digits()) == 0)
      return(0); //nothing to do
   MqlTradeRequest request;
   ZeroMemory(request);
   request.action = (type <= 1) ? TRADE_ACTION_SLTP : TRADE_ACTION_MODIFY;
   if (type > 1)
      request.order = ticket;
   else
      request.position = PositionGetInteger(POSITION_TICKET);
   request.symbol = Symbol();
   request.price = (type <= 1) ? PositionGetDouble(POSITION_PRICE_OPEN) : OrderGetDouble(ORDER_PRICE_OPEN);
   request.sl = NormalizeDouble(SL, Digits());
   request.tp = NormalizeDouble(TP, Digits());
   request.deviation = MaxSlippage_;
   MqlTradeResult result;
   ZeroMemory(result);
   while(!OrderSuccess(result.retcode) && retries < OrderRetry+1)
     {
      if(!OrderSend(request, result) || !OrderSuccess(result.retcode))
        {
         err = GetLastError();
         myAlert("print", "OrderModify error #"+IntegerToString(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(!OrderSuccess(result.retcode))
     {
      myAlert("error", "OrderModify failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err));
      return(-1);
     }
   string alertstr = "Order modify: ticket="+IntegerToString(ticket);
   if(NormalizeDouble(SL, Digits()) != 0) alertstr = alertstr+" SL="+DoubleToString(SL);
   if(NormalizeDouble(TP, Digits()) != 0) alertstr = alertstr+" TP="+DoubleToString(TP);
   myAlert("modify", alertstr);
   return(0);
  }

void myOrderClose(ENUM_ORDER_TYPE type, double volumepercent, string ordername) //close open orders for current symbol, magic number and "type" (ORDER_TYPE_BUY or ORDER_TYPE_SELL)
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
   if (type > 1)
     {
      myAlert("error", "Invalid type in myOrderClose");
      return;
     }
   bool success = false;
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   int total = PositionsTotal();
   ulong orderList[][2];
   int orderCount = 0;
   for(int i = 0; i < total; i++)
     {
      if(PositionGetTicket(i) <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != Symbol() || PositionGetInteger(POSITION_TYPE) != type) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = PositionGetInteger(POSITION_TIME);
      orderList[orderCount - 1][1] = PositionGetInteger(POSITION_TICKET);
     }
   if(orderCount > 0)
      ArraySort(orderList);
   for(int i = 0; i < orderCount; i++)
     {
      int retries = 0;
      MqlTradeResult result;
      ZeroMemory(result);
      
      while(!OrderSuccess(result.retcode) && retries < OrderRetry+1)
        {
         if(!PositionSelectByTicket(orderList[i][1])) continue;
         MqlTick last_tick;
         SymbolInfoTick(Symbol(), last_tick);
         double price = (type == ORDER_TYPE_SELL) ? last_tick.ask : last_tick.bid;
         MqlTradeRequest request;
         ZeroMemory(request);
         request.action = TRADE_ACTION_DEAL;
         request.position = PositionGetInteger(POSITION_TICKET);
      
         //set allowed filling type
         int filling = (int)SymbolInfoInteger(Symbol(),SYMBOL_FILLING_MODE);
         if(request.action == TRADE_ACTION_DEAL && (filling & 1) != 1)
            request.type_filling = ORDER_FILLING_IOC;
   
         request.magic = MagicNumber;
         request.symbol = Symbol();
         request.volume = NormalizeDouble(PositionGetDouble(POSITION_VOLUME)*volumepercent * 1.0 / 100, LotDigits);
         if (NormalizeDouble(request.volume, LotDigits) == 0) return;
         request.price = NormalizeDouble(price, Digits());
         request.sl = 0;
         request.tp = 0;
         request.deviation = MaxSlippage_;
         request.type = (ENUM_ORDER_TYPE)(1-type); //opposite type
         request.comment = ordername;
         
         success = OrderSend(request, result) && OrderSuccess(result.retcode);
         if(!success)
           {
            myAlert("error", "OrderClose"+ordername_+" failed; error: "+result.comment);
            Sleep(OrderWait*1000);
           }
         retries++;
        }

      if(!OrderSuccess(result.retcode))
        {
         myAlert("error", "OrderClose"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error: "+result.comment);
        }

     }
   string typestr[8] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop", "Buy Stop Limit", "Sell Stop Limit"};
   if (success) myAlert("order", "Orders closed"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

bool OrderSuccess(uint retcode)
  {
   return(retcode == TRADE_RETCODE_PLACED || retcode == TRADE_RETCODE_DONE
      || retcode == TRADE_RETCODE_DONE_PARTIAL || retcode == TRADE_RETCODE_NO_CHANGES);
  }

double getBid()
  {
   MqlTick last_tick;
   SymbolInfoTick(Symbol(), last_tick);
   return(last_tick.bid);
  }

double getAsk()
  {
   MqlTick last_tick;
   SymbolInfoTick(Symbol(), last_tick);
   return(last_tick.ask);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {   
   MaxSlippage_ = MaxSlippage;
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
      MaxSlippage_ *= 10;
     }
   //initialize LotDigits
   double LotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   if(NormalizeDouble(LotStep, 3) == round(LotStep))
      LotDigits = 0;
   else if(NormalizeDouble(10*LotStep, 3) == round(10*LotStep))
      LotDigits = 1;
   else if(NormalizeDouble(100*LotStep, 3) == round(100*LotStep))
      LotDigits = 2;
   else LotDigits = 3;
   NextTradeTime = 0;
   Ventana_v1_handle = iCustom(NULL, PERIOD_CURRENT, "Ventana_v1", 1, 0, true, 0, -5, true, 0, 09, 30, false, false, 10, 30, true, false, false, true, true, true, true, true, true, true);
   if(Ventana_v1_handle < 0)
     {
      Print("The creation of Ventana_v1 has failed: Ventana_v1_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   LineasPivote_EABuilder_handle = iCustom(NULL, PERIOD_CURRENT, "LineasPivote_EABuilder", 2069, 5, 10, PERIOD_CURRENT, true, 0, 0, true, clrGray, false, false);
   if(LineasPivote_EABuilder_handle < 0)
     {
      Print("The creation of LineasPivote_EABuilder has failed: LineasPivote_EABuilder_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ulong ticket = 0;
   double price;   
   double SL;
   
   if(CopyBuffer(Ventana_v1_handle, 1, 0, 200, Ventana_v1_1) <= 0) return;
   ArraySetAsSeries(Ventana_v1_1, true);
   if(CopyBuffer(LineasPivote_EABuilder_handle, 2, 0, 200, LineasPivote_EABuilder_2) <= 0) return;
   ArraySetAsSeries(LineasPivote_EABuilder_2, true);
   
   //Close Long Positions
   if(getBid() > LastTradePrice(1) + InpTP //Price > Last Open Trade Price (Long) + fixed value
   )
     {   
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED))
        myOrderClose(ORDER_TYPE_BUY, 100, "");
      else //not autotrading => only send alert
         myAlert("order", "");
     }
   
   //Close Short Positions
   if(getAsk() < LastTradePrice(-1) - InpTP //Price < Last Open Trade Price (Short) - fixed value
   )
     {   
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED))
        myOrderClose(ORDER_TYPE_SELL, 100, "");
      else //not autotrading => only send alert
         myAlert("order", "");
     }
   
   //Open Buy Order
   if(Ventana_v1_1[0] == 1 //Ventana_v1 is equal to fixed value
   && InpOperarLongs == true //Custom Code
   )
     {
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      price = last_tick.ask;
      SL = LineasPivote_EABuilder_2[0] - InpAncho; //Stop Loss = LineasPivote_EABuilder - fixed value
      if(TimeCurrent() <= NextTradeTime) return; //next open trade after time of the day   
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         ticket = myOrderSend(ORDER_TYPE_BUY, price, TradeSize, "");
         if(ticket == 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "");
      NextTradeTime = StringToTime(IntegerToString(NextOpenTradeAfterTOD_Hour)+":"+IntegerToString(NextOpenTradeAfterTOD_Min));
      while(NextTradeTime <= TimeCurrent()) NextTradeTime += 86400;
      myOrderModify(ORDER_TYPE_BUY, ticket, SL, 0);
     }
   
   //Open Sell Order
   if(Ventana_v1_1[0] == 1 //Ventana_v1 is equal to fixed value
   && InpOperarShorts == true //Custom Code
   )
     {
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      price = last_tick.bid;
      if(TimeCurrent() <= NextTradeTime) return; //next open trade after time of the day   
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         ticket = myOrderSend(ORDER_TYPE_SELL, price, TradeSize, "");
         if(ticket == 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "");
      NextTradeTime = StringToTime(IntegerToString(NextOpenTradeAfterTOD_Hour)+":"+IntegerToString(NextOpenTradeAfterTOD_Min));
      while(NextTradeTime <= TimeCurrent()) NextTradeTime += 86400;
     }
  }
//+------------------------------------------------------------------+