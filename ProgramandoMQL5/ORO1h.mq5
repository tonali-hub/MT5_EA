//+------------------------------------------------------------------+
//|                                                        ORO1h.mq5 |
//|                                                           Tonali |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

uchar indicador_a_probar = 3;

input double SL = 30;
input double TP = 200;
input int cars = 1;    

double Close[];
double Open[];

//******* HULL *******
int length = 55; //Length(180-200 for floating S/R , 55 for swing entry)
float lengthMult = 1.0;//Length multiplier (Used to view higher timeframes with straight band)
bool switchColor = true; //Color Hull according to trend?
bool candleCol = false; //Color candles based on Hull\'s Trend?
bool visualSwitch = true; //Show as a Band?
int thicknesSwitch = 1; //Line Thickness
int transpSwitch = 40; //Band Transparency


//FUNCTIONS
//HMA
/*fucntion HMA(_src, _length)
    ta.wma(2 * ta.wma(_src, _length / 2) - ta.wma(_src, _length), math.round(math.sqrt(_length)))
*/

//hull = HMA(src, int(length*lengthMult));





//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
float hull = (int)(length*lengthMult);
Print("hull = ",hull);

   
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
