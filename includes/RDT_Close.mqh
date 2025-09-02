//==============================================================//
//=           SESSION-BASED PROFIT-ONLY CLOSER (RIBO)          =//
//==============================================================//
#include <Trade/Trade.mqh>

//--------------------------------------------------------------//
// Utility: Close a single position by ticket if it's profitable
//--------------------------------------------------------------//
bool RDT_CloseIfProfitableByTicket(const ulong ticket)
{
    CTrade trade;
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(MaxAllowedSlippage);

   // Select the position by its ticket
   if(!PositionSelectByTicket(ticket))
      return false;

   // Read required fields
   double profitNet = PositionGetDouble(POSITION_PROFIT);   // Net of swaps & commissions
   long   type      = (long)PositionGetInteger(POSITION_TYPE);

   // Only close if net profit >= threshold
   if(profitNet < 600.0)
      return false;

   // Attempt to close the position
   bool closed = trade.PositionClose(ticket);
   if(!closed)
   {
      // Optional: a very lightweight retry if first attempt fails
      // (network hiccup / requote scenarios)
      Sleep(50);
      closed = trade.PositionClose(ticket);
   }
   return closed;
}

//-------------------------------------------------------------------//
// Core: If session is OFF, close only profitable positions (no loss)
//-------------------------------------------------------------------//
void RDT_CloseProfitablePositions_WhenSessionOff()
{
   // If feature disabled or session still allowed, do nothing
   if(RDT_IsTradingAllowedNow())      return;

   // Iterate positions from last to first (safe for closures while iterating)
   const int total = PositionsTotal();
   for(int i = total - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      // Close only if profitable (net) and meets MinCloseProfit
      RDT_CloseIfProfitableByTicket(ticket);
   }
}
