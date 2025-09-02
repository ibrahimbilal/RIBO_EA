//==============================================================
// RDT_Risk.mqh — risk & position sizing utilities
//==============================================================
#ifndef RDT_RISK_MQH
#define RDT_RISK_MQH

#include "RDT_FeatureFlags.mqh"

#ifdef RDT_FEAT_RISK

double CalculateLotSize()
{
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double step      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLotBrk = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double capMax    = MathMin(maxLotBrk, MaxLotSize);

   double lots = UseAutoIncrimentLots
                 ? MathFloor(((balance/100.0)*MinLotSize)/step)*step
                 : MinLotSize;

   lots = MathMax(lots, MinLotSize);
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, capMax);
   lots = MathFloor(lots/step)*step;
   return lots;
}

bool CheckMarginAvailable(const double lotSize)
{
   double marginRequired=0.0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,lotSize,SymbolInfoDouble(_Symbol,SYMBOL_ASK),marginRequired))
   { Print("❌ Margin calc failed. Err=", GetLastError()); return false; }
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(marginRequired>freeMargin)
   { PrintFormat("❌ Not enough margin. Required: %.2f Free: %.2f", marginRequired, freeMargin); return false; }
   return true;
}

double TargetToPoints(const double targetEUR, const double lotSize)
{
#ifdef RDT_FEAT_TP_FROM_MONEY
   return 0.0;
#else
   const double tv = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   const double ts = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tv<=0.0 || ts<=0.0 || point<=0.0 || lotSize<=0.0) return 0.0;
   double priceDelta = (targetEUR/(tv*lotSize))*ts; // price distance
   return priceDelta/point; // in points
#endif
}

double ComputeTPPrice(int dir, double entry, double lot)
{
#ifdef RDT_FEAT_TP_FROM_MONEY
   return 0.0;
#else
   double tpPts = TargetToPoints(ProfitTargetPerTrade, lot);
   double raw   = entry + (dir==0 ? 1 : -1) * tpPts * point;
   double minP  = entry + (dir==0 ? 1 : -1) * MinTP * point;
   return NormalizeDouble((dir==0 ? MathMax(raw,minP) : MathMin(raw,minP)), (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
#endif
}

#endif // RDT_FEAT_RISK
#endif // RDT_RISK_MQH
