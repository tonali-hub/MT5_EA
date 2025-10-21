//+------------------------------------------------------------------+
//|                                                    RSI_MA_EA.mq5 |
//|                                                           Tonali |
//|                         https://es.tradingview.com/u/Cignus_LOC/ |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      "https://es.tradingview.com/u/Cignus_LOC/"
#property version   "1.00"

input int                inpPeriod       = 14;          // RSI period
input ENUM_APPLIED_PRICE inpPrice        = PRICE_CLOSE; // Price
input ENUM_MA_METHOD     inpMaMethod     = MODE_SMMA;   // RSI average method
input int                inpFastMa       = 8;           // Fast MA period (<=0 - no average)
//input enMaTypes          inpFastMaMethod = ma_smma;   // Fast MA method
input ENUM_MA_METHOD     inpFastMaMethod = MODE_SMMA;   // Fast MA method
input int                inpSlowMa       = 8;           // Slow MA period (<=0 - no average)
//input enMaTypes          inpSlowMaMethod = ma_smma;   // Slow MA method
input ENUM_MA_METHOD     inpSlowMaMethod = MODE_SMMA;   // Slow MA method
input int                InpShift        = 0;           // Shit MA iRSI 
input int                InpToCalculate  = 100;         // Values to calculate
input int                InpVelaDatos    = 0;           // Vela a ver datos 
input bool               InpVerComentarios = true;

//--- buffers and global variables declarations
double val[],valc[],avg1[],avg2[],prices[];
string _avgNames[]={"SMA","EMA","SMMA","LWMA"};

int    handleRSI;
int    handleMA;

double iRSIBuffer[];
double iMABuffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   handleRSI = iRSI(_Symbol,PERIOD_CURRENT,inpPeriod,inpPrice);
   handleMA = iMA(_Symbol,_Period,inpFastMa,InpShift,inpFastMaMethod,handleRSI);
   
   Print("Handle iRSI =   ",handleRSI, "  error = ",GetLastError());
   Print("Handle iMA =    ",handleMA, "  error = ",GetLastError());    
   
   ArrayResize(val,InpToCalculate);
   ArrayResize(valc,InpToCalculate);
   ArrayResize(avg1,InpToCalculate);
   ArrayResize(avg2,InpToCalculate);
   ArrayResize(prices,InpToCalculate);
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
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   CopyBuffer(handleRSI,0,0,InpToCalculate,iRSIBuffer);
   CopyBuffer(handleMA,0,0,InpToCalculate,iMABuffer);
         
   //int i=(int)MathMax(prev_calculated-1,1); 
   int i = 0;
   int rates_total = InpToCalculate;
   for(; i<rates_total && !_StopFlag; i++)
     {
      //prices[i]=getPrice(inpPrice,open,close,high,low,i,rates_total);
      prices[i] = iClose(_Symbol,PERIOD_CURRENT,InpToCalculate-1-i);
      
      double _price1 = prices[i];
      double _price2 = (i>0) ? prices[i-1] : prices[i];

      double _bulls = 0.5*(MathAbs(_price1-_price2)+(_price1-_price2));
      double _bears = 0.5*(MathAbs(_price1-_price2)-(_price1-_price2));
      double _avgBulls = iCustomMa(inpMaMethod,_bulls,inpPeriod,i,rates_total,0);
      double _avgBears = iCustomMa(inpMaMethod,_bears,inpPeriod,i,rates_total,1);

      val[i] = (_avgBulls!=0) ? 100.0/(1+_avgBears/_avgBulls) : 0;
      valc[i]=(i>0) ?(val[i]>val[i-1]) ? 0 :(val[i]<val[i-1]) ? 1 : valc[i-1]: 0;
      avg1[i] = (inpFastMa>0) ? iCustomMa(inpFastMaMethod,val[i],inpFastMa,i,rates_total,2) : EMPTY_VALUE;
      avg2[i] = (inpSlowMa>0) ? iCustomMa(inpSlowMaMethod,val[i],inpSlowMa,i,rates_total,3) : EMPTY_VALUE;
     }
   
   if(InpVerComentarios)
      {
       Comment("\n -- Stop Loss --",
               "\n Valores a calcular: ", InpToCalculate,
               "\n RSI calculo: ", val[InpToCalculate-1-InpVelaDatos],
               "\n MA RSI calculo: ", avg1[InpToCalculate-1-InpVelaDatos],
               "\n iRSI: ", iRSIBuffer[InpToCalculate-1-InpVelaDatos],
               "\n iMA RSI: ", iMABuffer[InpToCalculate-1-InpVelaDatos]
                        
               );
      }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
#define _maInstances 4
#define _maWorkBufferx1 1*_maInstances
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iCustomMa(int mode,double price,double length,int r,int bars,int instanceNo=0)
  {
   switch(mode)
     {
      case MODE_SMA   : return(iSma(price,(int)length,r,bars,instanceNo));
      case MODE_EMA   : return(iEma(price,length,r,bars,instanceNo));
      case MODE_SMMA  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case MODE_LWMA  : return(iLwma(price,(int)length,r,bars,instanceNo));
      /*
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      */      
      default       : return(price);
     }
  }

//
//
//
//
//
double workSma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iSma(double price,int period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSma,0)!=_bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo]=price;
   double avg=price; int k=1; for(; k<period && (r-k)>=0; k++) avg+=workSma[r-k][instanceNo];
   return(avg/(double)k);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workEma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iEma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=_bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workSmma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iSmma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSmma,0)!=_bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo]=price;
   if(r>1 && period>1)
      workSmma[r][instanceNo]=workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workLwma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iLwma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workLwma,0)!=_bars) ArrayResize(workLwma,_bars);

   workLwma[r][instanceNo] = price; if(period<1) return(price);
   double sumw = period;
   double sum  = period*price;

   for(int k=1; k<period && (r-k)>=0; k++)
     {
      double weight=period-k;
      sumw  += weight;
      sum   += weight*workLwma[r-k][instanceNo];
     }
   return(sum/sumw);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   switch(tprice)
     {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
     }
   return(0);
  }
//+------------------------------------------------------------------+