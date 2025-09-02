//==============================================================
// RDT_Position.mqh — position management (trail, BE, TP tweaks)
//==============================================================
#ifndef RDT_POSITION_MQH
#define RDT_POSITION_MQH
#include <Trade/Trade.mqh>
#include "RDT_FeatureFlags.mqh"
#include "RDT_Indicators.mqh"
#include "RDT_Risk.mqh"
#include "RDT_Utils.mqh"

#ifdef RDT_FEAT_POSITION

// impl
int CountOpenPositionsForSymbol()
{
   int cnt=0;
   for(int i=PositionsTotal()-1;i>=0;--i)
   {
      if(!SelectPositionByIndex(i)) continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol && PositionGetInteger(POSITION_MAGIC)==MagicNumber) ++cnt;
   }
   return cnt;
}

void UpdateTrailingStops()
{
   double f5,s5,df5,f15,s15,df15;
   if(!GetCurrentMAValues(FastMA_M5_Handle,SlowMA_M5_Handle,f5,s5,df5)) return;
   if(!GetCurrentMAValues(FastMA_M15_Handle,SlowMA_M15_Handle,f15,s15,df15)) return;

   double totalProfit = AccumulatedProfit;
   for(int i=PositionsTotal()-1;i>=0;--i)
   {
      if(!SelectPositionByIndex(i)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      totalProfit += PositionGetDouble(POSITION_PROFIT);
   }

   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxAllowedSlippage);

   for(int i=PositionsTotal()-1;i>=0;--i)
   {
      if(!SelectPositionByIndex(i)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      long   type      = PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double price     = PositionGetDouble(POSITION_PRICE_CURRENT);
      double curSL     = PositionGetDouble(POSITION_SL);
      double curTP     = PositionGetDouble(POSITION_TP);
      double curPnL    = PositionGetDouble(POSITION_PROFIT);

      double newSL = curSL, newTP = curTP;

      if(type==POSITION_TYPE_BUY)
      {
         newSL = (curSL==0.0)? s15 : MathMax(curSL, s15);

         // ✅ Set TP on special reason: if TP not set and price under FastMA M15, secure quick TP (100 PT)
         if(curTP == 0.0 && price <= f15)
         {
            double specialTP = openPrice + 100.0 * point;
            newTP = specialTP;
         }
         else if(curTP != 0.0)
         {
            newTP = curTP; // preserve existing TP
         }

#ifdef RDT_FEAT_BREAKEVEN
         if(UseBreakEven)
         {
            if((SymbolInfoDouble(_Symbol,SYMBOL_BID)-openPrice) >= BreakEvenTriggerPoints*point
               && (curSL==0.0 || curSL<openPrice))
            {
               double beSL = openPrice + BreakEvenOffsetPoints*point;
               newSL = MathMax(newSL, beSL);
            }
         }
#endif
#ifdef RDT_FEAT_ATR_TRAILING
         if(UseATRTrailing)
         {
            double atr = GetATR();
            if(atr>0.0)
            {
               double atrSL = SymbolInfoDouble(_Symbol,SYMBOL_BID) - atr*ATR_Multiplier;
               newSL = MathMax(newSL, atrSL);
            }
         }
#endif
      }
      else if(type==POSITION_TYPE_SELL)
      {
         newSL = (curSL==0.0)? s15 : MathMin(curSL, s15);

         // ✅ Set TP on special reason: if TP not set and price above FastMA M15, secure quick TP (100 PT)
         if(curTP == 0.0 && price >= f15)
         {
            double specialTP = openPrice - 100.0 * point;
            newTP = specialTP;
         }
         else if(curTP != 0.0)
         {
            newTP = curTP; // preserve existing TP
         }

#ifdef RDT_FEAT_BREAKEVEN
         if(UseBreakEven)
         {
            if((openPrice - SymbolInfoDouble(_Symbol,SYMBOL_ASK)) >= BreakEvenTriggerPoints*point
               && (curSL==0.0 || curSL>openPrice))
            {
               double beSL = openPrice - BreakEvenOffsetPoints*point;
               newSL = MathMin(newSL, beSL);
            }
         }
#endif
#ifdef RDT_FEAT_ATR_TRAILING
         if(UseATRTrailing)
         {
            double atr = GetATR();
            if(atr>0.0)
            {
               double atrSL = SymbolInfoDouble(_Symbol,SYMBOL_ASK) + atr*ATR_Multiplier;
               newSL = (curSL==0.0)? atrSL : MathMin(newSL, atrSL);
            }
         }
#endif
      }

      newSL = NormalizeDouble(newSL,(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
      newTP = NormalizeDouble(newTP,(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));

      if(newSL!=curSL || newTP!=curTP)
      {
         if(!trade.PositionModify(_Symbol,(newSL!=curSL?newSL:curSL),(newTP!=curTP?newTP:curTP)))
            Print("❌ SL/TP update failed. Retcode=", trade.ResultRetcode(), " (", GetRetcodeDescription(trade.ResultRetcode()), ")");
         else
            Print("✅ SL/TP updated | SL:",DoubleToString(newSL,_Digits)," | TP:",DoubleToString(newTP,_Digits)," | PosPnL:",DoubleToString(curPnL,2)," | Total:",DoubleToString(totalProfit,2));
      }
   }
}

#endif // RDT_FEAT_POSITION
#endif // RDT_POSITION_MQH
