//+------------------------------------------------------------------+
//|                                                PruebaVentana.mq5 |
//|                                                           Tonali |
//|                         https://es.tradingview.com/u/Cignus_LOC/ |
//+------------------------------------------------------------------+
#property copyright "Tonali"
#property link      "https://es.tradingview.com/u/Cignus_LOC/"
#property version   "1.00"

#include <Trade/Trade.mqh>

CTrade trade;

//****** Prueba ventana ******
input bool     InpResetPrueba = false;

//****** Ventana operativa ******
#resource "\\Indicators\\Ventana_v1.01.ex5"
input group "-- Ventana --"
enum REGION {
    USA        = 0,
    Europa     = 1,    
    VeranoPermanente  = 2,
    NoUsaDST   = 3,
};
//Identificador de ventana
input ENUM_TIMEFRAMES InpTFVentana = PERIOD_M1; //Perido ventana
input int      InpNumVentana = 1;            //Identificador de ventana
//Ajustes de horario de acuerdo al servidor donde este el EA
input int      InpGMTServidor = 0;           //GMT base servidor
input bool     InpHayDSTServidor = true;     //Hay DST servidor (false ignora region)
input REGION   InpRegionServidor = 0;        //Region ubicacion servidor
//Ajustes de horario de acuerdo a la zona horaria de la estrategia
input int      InpGMTEstrategia = -5;        //GMT base estrategia
input bool     InpHayDSTEstrategia = true;   //Hay DST estrategia (false ignora region)
input REGION   InpRegionEstrategia = 0;      //Region ubicacion estrategia
//Elementos para tiempo apertura en horario normal (antes de DST)
//tiempo de apertura de ventana
input int      InpVentanaAperturaHora = 09;           //Hora apertura 
input int      InpVentanaAperturaMin  = 30;           //Min apertura
//tiempo de cierre de ventana
input bool     InpVentanaDiaria = false;              //Ventana x el dia (1: ignora siguientes cierres)
input bool     InpCierreVentanaAlCerrarVela  = false; //Cierre ventana (1: al cierre de vela / 0: valores definidos)
input int      InpVentanaCierreHora = 10;             //Hora cierre
input int      InpVentanaCierreMin  = 30;             //Min cierre

input bool     InpVerLineasVentana  = true;
input bool     InpVerComentariosVentana = false;
input bool     InpBorrarComentariosVentana = false;

input group "-- Dias --"
input bool     InpLunes = true;
input bool     InpMartes = true;
input bool     InpMiercoles = true;
input bool     InpJueves = true;
input bool     InpViernes = true;
input bool     InpSabado = true;
input bool     InpDomingo = true;


//--- Handlers y variables
int            handleVentana;       
//--- Ventana
double         mVentanaAbierta[];
//bool           mVentanaDetectada = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   handleVentana = iCustom(_Symbol, _Period, 
                           "::Indicators\\Ventana_v1.01.ex5",
                           //"Ventana_v1",
                           "-- Ventana --",
                           InpTFVentana,
                           InpNumVentana,                           
                           InpGMTServidor,   InpHayDSTServidor,   InpRegionServidor,
                           InpGMTEstrategia, InpHayDSTEstrategia, InpRegionEstrategia,
                           InpVentanaAperturaHora, InpVentanaAperturaMin,
                           InpVentanaDiaria, InpCierreVentanaAlCerrarVela,
                           InpVentanaCierreHora,   InpVentanaCierreMin,
                           InpVerLineasVentana, false, false,//InpVerComentariosVentana, InpBorrarComentariosVentana,
                           "-- Dias --",
                           //false,false);
                           InpLunes, InpMartes, InpMiercoles, InpJueves, InpViernes, InpSabado, InpDomingo);
     
   if(InpVerComentariosVentana) Print("Ventana_handle_v1.01 =   ",handleVentana, "  error = ",GetLastError());  

    
   
//---
   //mVentanaDetectada = false;

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
   ArraySetAsSeries(mVentanaAbierta, true);
   CopyBuffer(handleVentana,0,0,1,mVentanaAbierta);
   
   static bool mVentanaDetectada = false;
   if(InpResetPrueba)
     {
      mVentanaDetectada = false;
     }
   
   
   if(mVentanaAbierta[0]==1 && PositionsTotal()==0 && !mVentanaDetectada && !InpResetPrueba)
     {
      Print("Se detecto ventana en ", AccountInfoString(ACCOUNT_SERVER), " en el tiempo: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
      trade.Sell(0.1,_Symbol,SymbolInfoDouble(_Symbol, SYMBOL_BID),0);
      mVentanaDetectada = true;
     } 
  }
//+------------------------------------------------------------------+
