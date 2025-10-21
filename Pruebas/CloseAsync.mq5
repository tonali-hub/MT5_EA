#include <Trade/Trade.mqh>

void OnStart()
{
    ulong st = GetMicrosecondCount();

    CTrade sTrade;
    sTrade.SetAsyncMode(true);      // true:Async, false:Sync

    for(int cnt = PositionsTotal()-1; cnt >= 0 && !IsStopped(); cnt-- )
    {
        if(PositionGetTicket(cnt))
        {
            sTrade.PositionClose(PositionGetInteger(POSITION_TICKET),100);
            uint code = sTrade.ResultRetcode();
            Print(IntegerToString(code));
        }
    }
        
    for(int i=0; i<100; i++)
    {
        Print(IntegerToString(GetMicrosecondCount()-st) +"micro "+ IntegerToString(PositionsTotal()));
        if(PositionsTotal()<=0){ break; }
            Sleep(100);
    }
}