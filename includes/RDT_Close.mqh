//==============================================================//
//=  SESSION-BASED PROFIT-ONLY CLOSER — Points-based           =//
//==============================================================//
#include <Trade/Trade.mqh>

double RDT_GetPointsPLByTicket(const ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return 0.0;
   string sym = PositionGetString(POSITION_SYMBOL);
   long   tp  = (long)PositionGetInteger(POSITION_TYPE);
   double op  = PositionGetDouble(POSITION_PRICE_OPEN);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   return (tp==POSITION_TYPE_BUY) ? (bid-op)/point : (op-ask)/point;
}

bool RDT_CloseIfPointsProfitByTicket(const ulong ticket, const double minPts)
{
   if(!PositionSelectByTicket(ticket)) return false;
   if((long)PositionGetInteger(POSITION_MAGIC) != MagicNumber) return false;

   double pts = RDT_GetPointsPLByTicket(ticket);
   if(pts <= minPts) return false;

   static CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxAllowedSlippage);

   bool ok = trade.PositionClose(ticket);
   if(!ok){ Sleep(50); ok = trade.PositionClose(ticket); }

   Print(ok ? "Closed (forbidden session, pts>0): " : "Close failed: ",
        "ticket=", ticket, " pts=", DoubleToString(pts,1));
   return ok;
}

void RDT_CloseProfitablePositions_WhenSessionOff()
{
   if(RDT_IsTradingAllowedNow()) return;
   for(int i=PositionsTotal()-1;i>=0;--i)
   {
      ulong tk = PositionGetTicket(i); if(tk==0) continue;
      RDT_CloseIfPointsProfitByTicket(tk, MinPointsToClose);
   }
}
