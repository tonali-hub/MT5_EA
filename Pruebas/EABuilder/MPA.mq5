//+------------------------------------------------------------------+
//|                                                Strategy: MPA.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+

/*
SL: colocar al minimo anterior
TP: distancia apertura - SL * ratio
Trail: activarlo al momento que el precio pasa del 32% de la distancia de apertura - SL


*/
#property copyright "Created with EABuilder.com"
#property link      "https://www.eabuilder.com"
#property version   "1.00"
#property description ""

//****** ATRs ******
#resource "\\Indicators\\MPA\\MiMPA_stoc.ex5"
#resource "\\Indicators\\MPA\\MiMPA_ATRs.ex5"
input group "ATR 1"
input int   InpAtrPeriod_1 = 5;                        // ATR period
input       ENUM_MA_METHOD InpModeATR_MA_1 = MODE_SMA;  // Modo ATR
input group "Media movil"
input int   InpMAPeriod_1 = 50;                         // MA period
input       ENUM_MA_METHOD InpModeMA_1 = MODE_SMA;      // Modo MA
input bool  InpHighSourceMA_1 = false;                   // Source High  (0: high  | 1: highMA)
input bool  InpLowSourceMA_1 = false;                    // Source Low   (0: low   | 1: LowMA)
input bool  InpCloseSourceMA_1 = true;                  // Source Close (0: close | 1: CloseMA)

input group "ATR 2"
input int   InpAtrPeriod_2 = 10;                        // ATR period
input       ENUM_MA_METHOD InpModeATR_MA_2 = MODE_SMA;  // Modo ATR
input group "Media movil"
input int   InpMAPeriod_2 = 100;                        // MA period
input       ENUM_MA_METHOD InpModeMA_2 = MODE_SMA;      // Modo MA
input bool  InpHighSourceMA_2 = false;                   // Source High  (0: high  | 1: highMA)
input bool  InpLowSourceMA_2 = false;                    // Source Low   (0: low   | 1: LowMA)
input bool  InpCloseSourceMA_2 = true;                  // Source Close (0: close | 1: CloseMA)


//****** Stochastic ******
input group "Stochastic"
input int      InpKPeriod = 22;                          // K period
input int      InpDPeriod = 3;                           // D period
input int      InpSlowing = 3;                           // Slowing
input double   InpPendiente_stoch = 1.20;
input int      InpStochVelaRef1 = 0;
input int      InpStochLookback = 1;

//****** Ichimoku ******
input group "Ichimoku"
input int      InpTenkan = 9;                            // Tenkan-sen
input int      InpKijun = 26;                            // Kijun-sen
input int      InpSenkou = 52;                           // Senkou Span B
input bool     InpUsarShift = false;                     // Ver shift

input bool     InpVerComentariosMPA_stoc = false;

input group "Operativa"
input int      SR_Interval = 50;
input int      Trail_Interval = 12;
//input double   TP_Points = 100;
input double   InpRatio = 1.0;
input double   InpInicioTrail = 0.6;
input bool     InpOperarLongs = true;
input bool     InpOperarShorts = true;
input double   InpSLRangoPorcentaje = 0.5;

int            handleMPA;
int            handleMiMPA_ATRs;
double         MPA_BUYBuffer[];
double         MPA_SELLBuffer[];

double iniciarTrail = 0;



int LotDigits; //initialized in OnInit
int MagicNumber = 1217727;
input double MM_Percent = 1;
int MaxSlippage = 3; //slippage, adjusted in OnInit
int MaxSlippage_;
int MaxOpenTrades = 1000;
input int MaxLongTrades = 10;
input int MaxShortTrades = 10;
int MaxPendingOrders = 1000;
int MaxLongPendingOrders = 1000;
int MaxShortPendingOrders = 1000;
bool Hedging = false;
int OrderRetry = 5; //# of retries if sending order returns error
int OrderWait = 5; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit


double MM_Size(double SL) //Risk % per trade, SL = relative Stop Loss to calculate risk
  {
   double MaxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double MinLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double tickvalue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double ticksize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double lots = MM_Percent * 1.0 / 100 * AccountInfoDouble(ACCOUNT_BALANCE) / (SL / ticksize * tickvalue);
   if(lots > MaxLot) lots = MaxLot;
   if(lots < MinLot) lots = MinLot;
   return(lots);
  }

void myAlert(string type, string message)
  {
   int handle;
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | MPA @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
      handle = FileOpen("MPA.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
      if(handle != INVALID_HANDLE)
        {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, type+" | MPA @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
         FileClose(handle);
        }
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

int myOrderModifyRel(ENUM_ORDER_TYPE type, ulong ticket, double SL, double TP) //works for positions and orders, modify SL and TP (relative to open price), zero targets do not modify, ticket is irrelevant for open positions
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
   //prepare to modify order, convert relative to absolute
   double openprice = (type <= 1) ? PositionGetDouble(POSITION_PRICE_OPEN) : OrderGetDouble(ORDER_PRICE_OPEN);
   if(((type <= 1) ? PositionGetInteger(POSITION_TYPE) : OrderGetInteger(ORDER_TYPE)) % 2 == 0) //buy
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = openprice - SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = openprice + TP;
     }
   else //sell
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = openprice + SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = openprice - TP;
     }
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

void DrawLine(string objname, double price, int count, int start_index) //creates or modifies existing object if necessary
  {
   if((price < 0) && ObjectFind(0, objname) >= 0)
     {
      ObjectDelete(0, objname);
     }
   else if(ObjectFind(0, objname) >= 0 && ObjectGetInteger(0, objname, OBJPROP_TYPE) == OBJ_TREND)
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectSetInteger(0, objname, OBJPROP_TIME, cTime[start_index]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objname, OBJPROP_TIME, 1, cTime[start_index+count-1]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, 1, price);
     }
   else
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectCreate(0, objname, OBJ_TREND, 0, cTime[start_index], price, cTime[start_index+count-1], price);
      ObjectSetInteger(0, objname, OBJPROP_RAY_LEFT, 0);
      ObjectSetInteger(0, objname, OBJPROP_RAY_RIGHT, 0);
      ObjectSetInteger(0, objname, OBJPROP_COLOR, C'0x00,0x00,0xFF');
      ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
     }
  }

double Support(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / PeriodSeconds();
   if(fixed_tod)
     {
      datetime start_time;
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, Bars(Symbol(), Period())-count, cTime);
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = cTime[shift-1];
      datetime dt = StringToTime(TimeToString(start_time, TIME_DATE)+" "+IntegerToString(hh)+":"+IntegerToString(mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(Symbol(), Period(), dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > cTime[Bars(Symbol(), Period())-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(Symbol(), Period(), dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(Symbol(), Period(), dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double cLow[];
   ArraySetAsSeries(cLow, true);
   CopyLow(Symbol(), Period(), start_index, count, cLow);
   double ret = cLow[ArrayMinimum(cLow, 0, count)];
   if (draw) DrawLine("Support", ret, count, start_index);
   return(ret);
  }

double Resistance(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / PeriodSeconds();
   if(fixed_tod)
     {
      datetime start_time;
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, Bars(Symbol(), Period())-count, cTime);
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = cTime[shift-1];
      datetime dt = StringToTime(TimeToString(start_time, TIME_DATE)+" "+IntegerToString(hh)+":"+IntegerToString(mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(Symbol(), Period(), dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > cTime[Bars(Symbol(), Period())-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(Symbol(), Period(), dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(Symbol(), Period(), dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double cHigh[];
   ArraySetAsSeries(cHigh, true);
   CopyHigh(Symbol(), Period(), start_index, count, cHigh);
   double ret = cHigh[ArrayMaximum(cHigh, 0, count)];
   if (draw) DrawLine("Resistance", ret, count, start_index);
   return(ret);
  }

void TrailingStopSet(ENUM_ORDER_TYPE type, double newSL) //set Stop Loss at "price"
  {
   int total = PositionsTotal();
   for(int i = total-1; i >= 0; i--)
     {
      if(PositionGetTicket(i) <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != Symbol() || PositionGetInteger(POSITION_TYPE) != type) continue;
      double SL = PositionGetDouble(POSITION_SL);
      double TP = PositionGetDouble(POSITION_TP);
      double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      double price = last_tick.ask;
      //int signo = type == ORDER_TYPE_BUY ? 1 : -1;
      iniciarTrail = priceOpen + (TP-priceOpen)*InpInicioTrail;
      if(SL == 0
      //|| (type == ORDER_TYPE_BUY && (NormalizeDouble(SL, Digits()) <= 0 || price > SL))
      //|| (type == ORDER_TYPE_SELL && (NormalizeDouble(SL, Digits()) <= 0 || price < SL)))
      || (type == ORDER_TYPE_BUY && (NormalizeDouble(SL, Digits()) <= 0 || price > iniciarTrail))
      || (type == ORDER_TYPE_SELL && (NormalizeDouble(SL, Digits()) <= 0 || price < iniciarTrail)))
         myOrderModify(type, ticket, newSL, 0);
     }
  }


void TrailingStopTrail(ENUM_ORDER_TYPE type, double TS, double step, bool aboveBE, double aboveBEval) //set Stop Loss to "TS" if price is going your way with "step"
  {
   TS = NormalizeDouble(TS, Digits());
   step = NormalizeDouble(step, Digits());
   int total = PositionsTotal();
   for(int i = total-1; i >= 0; i--)
     {
      if(PositionGetTicket(i) <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != Symbol() || PositionGetInteger(POSITION_TYPE) != type) continue;
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      double SL = PositionGetDouble(POSITION_SL);
      double openprice = PositionGetDouble(POSITION_PRICE_OPEN);
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      if(type == ORDER_TYPE_BUY && (!aboveBE || last_tick.bid > openprice + TS + aboveBEval) && (NormalizeDouble(SL, Digits()) <= 0 || last_tick.bid > SL + TS + step))
         myOrderModify(ORDER_TYPE_BUY, ticket, last_tick.bid - TS, 0);
      else if(type == ORDER_TYPE_SELL && (!aboveBE || last_tick.ask < openprice - TS - aboveBEval) && (NormalizeDouble(SL, Digits()) <= 0 || last_tick.ask < SL - TS - step))
         myOrderModify(ORDER_TYPE_SELL, ticket, last_tick.ask + TS, 0);
     }
  }

bool NewBar()
  {
   datetime cTime[];
   ArraySetAsSeries(cTime, true);
   CopyTime(Symbol(), Period(), 0, 1, cTime);
   static datetime LastTime = 0;
   bool ret = cTime[0] > LastTime && LastTime > 0;
   LastTime = cTime[0];
   return(ret);
  }

bool OrderSuccess(uint retcode)
  {
   return(retcode == TRADE_RETCODE_PLACED || retcode == TRADE_RETCODE_DONE
      || retcode == TRADE_RETCODE_DONE_PARTIAL || retcode == TRADE_RETCODE_NO_CHANGES);
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

   
   handleMPA = iCustom(_Symbol, _Period,
                       "::Indicators\\MPA\\MiMPA_stoc.ex5",
                       "ATR 1",
                       InpAtrPeriod_1, InpModeATR_MA_1,
                       "Media movil",
                       InpMAPeriod_1, InpModeMA_1, InpHighSourceMA_1, InpLowSourceMA_1, InpCloseSourceMA_1,
                       "ATR 2",
                       InpAtrPeriod_2, InpModeATR_MA_2,
                       "Media movil",
                       InpMAPeriod_2, InpModeMA_2, InpHighSourceMA_2, InpLowSourceMA_2, InpCloseSourceMA_2,                       
                       "Stochastic",
                       InpKPeriod, InpDPeriod, InpSlowing,
                       InpPendiente_stoch, InpStochVelaRef1, InpStochLookback,
                       "Ichimoku", 
                       InpTenkan, InpKijun, InpSenkou, InpUsarShift);
                       
   if(handleMPA < 0)
     {
      Print("The creation of MPA has failed: handleMPA=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   
   handleMiMPA_ATRs = iCustom(_Symbol, _Period,
                       "::Indicators\\MPA\\MiMPA_ATRs.ex5",
                       "ATR 1",
                       InpAtrPeriod_1, InpModeATR_MA_1,
                       "Media movil",
                       InpMAPeriod_1, InpModeMA_1, InpHighSourceMA_1, InpLowSourceMA_1, InpCloseSourceMA_1,
                       "ATR 2",
                       InpAtrPeriod_2, InpModeATR_MA_2,
                       "Media movil",
                       InpMAPeriod_2, InpModeMA_2, InpHighSourceMA_2, InpLowSourceMA_2, InpCloseSourceMA_2);
   if(handleMiMPA_ATRs < 0)
     {
      Print("The creation of MPA_ATRs has failed: handleMiMPA_ATRs=", INVALID_HANDLE);
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
   double TradeSize;
   double SL;
   double TP;
   double resistencia;
   double soporte;
   double rango;
   bool isNewBar = NewBar();
   

   if(CopyBuffer(handleMPA, 2, 0, 2, MPA_BUYBuffer) <= 0) return;
   ArraySetAsSeries(MPA_BUYBuffer, true);
   if(CopyBuffer(handleMPA, 3, 0, 2, MPA_SELLBuffer) <= 0) return;
   ArraySetAsSeries(MPA_SELLBuffer, true);
   
   /*
   if(isNewBar) TrailingStopSet(ORDER_TYPE_BUY, Support(Trail_Interval * PeriodSeconds(), false, 00, 00, true, 0)); //Trailing Stop = Support
   if(isNewBar) TrailingStopSet(ORDER_TYPE_SELL, Resistance(Trail_Interval * PeriodSeconds(), false, 00, 00, true, 0)); //Trailing Stop = Resistance
   TrailingStopTrail(ORDER_TYPE_BUY, Trail_Points * myPoint, Trail_Step * myPoint, true, 0 * myPoint); //Trailing Stop = trail
   TrailingStopTrail(ORDER_TYPE_SELL, Trail_Points * myPoint, Trail_Step * myPoint, true, 0 * myPoint); //Trailing Stop = trail
   */
   
   //Open Buy Order
   if(MPA_BUYBuffer[0] != 0 //Custom Code
     && InpOperarLongs
     && isNewBar
   )
     {
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      price = last_tick.ask;
      resistencia = Resistance(SR_Interval * PeriodSeconds(), false, 00, 00, true, 0); //Stop Loss = Resistance
      soporte = Support(SR_Interval * PeriodSeconds(), false, 00, 00, true, 0); //Stop Loss = Support
      rango = resistencia - soporte;
      SL = (price - soporte) <= InpSLRangoPorcentaje*rango ? price - (resistencia-price) : soporte;      
      //SL = Support(SR_Interval * PeriodSeconds(), false, 00, 00, true, 0); //Stop Loss = Support
      TradeSize = MM_Size(price - SL);
      //TP = TP_Points * myPoint; //Take Profit = value in points (relative to price)
      TP = price + (MathAbs(price-SL))*InpRatio; 
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         ticket = myOrderSend(ORDER_TYPE_BUY, price, TradeSize, "");
         if(ticket == 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "");
      myOrderModify(ORDER_TYPE_BUY, ticket, SL, TP);
      //myOrderModifyRel(ORDER_TYPE_BUY, ticket, 0, TP);
     }
   
   //Open Sell Order
   if(MPA_SELLBuffer[0] != 0 //Custom Code
     && InpOperarShorts
     && isNewBar
   )
     {
      MqlTick last_tick;
      SymbolInfoTick(Symbol(), last_tick);
      price = last_tick.bid;
      resistencia = Resistance(SR_Interval * PeriodSeconds(), false, 00, 00, true, 0); //Stop Loss = Resistance
      soporte = Support(SR_Interval * PeriodSeconds(), false, 00, 00, true, 0); //Stop Loss = Support
      rango = resistencia - soporte;
      SL = (resistencia-price) <= InpSLRangoPorcentaje*rango ? price + (price-soporte) : resistencia;      
      //SL = Resistance(SR_Interval * PeriodSeconds(), false, 00, 00, true, 0); //Stop Loss = Resistance
      TradeSize = MM_Size(SL - price);
      //TP = TP_Points * myPoint; //Take Profit = value in points (relative to price)
      TP = price - (MathAbs(price-SL))*InpRatio;
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         ticket = myOrderSend(ORDER_TYPE_SELL, price, TradeSize, "");
         if(ticket == 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "");
      myOrderModify(ORDER_TYPE_SELL, ticket, SL,  TP);
      //myOrderModifyRel(ORDER_TYPE_SELL, ticket, 0, TP);
     }
     
     
   Comment("IniciarTrail:", iniciarTrail);
     
  }
//+------------------------------------------------------------------+