//==============================================================
// RDT_Core.mqh — lifecycle, gating & order execution
//==============================================================
#ifndef RDT_CORE_MQH
#define RDT_CORE_MQH
#include <Trade/Trade.mqh>
#include "RDT_FeatureFlags.mqh"
#include "RDT_Risk.mqh"
#include "RDT_Indicators.mqh"
#include "RDT_Position.mqh"
#include "RDT_History.mqh"
#include "RDT_Dashboard.mqh"
#include "RDT_Utils.mqh"

#ifdef RDT_FEAT_CORE

// --- Session gating
bool RDT_IsTradingAllowedNow()
{
   MqlDateTime tm; TimeToStruct(TimeCurrent(), tm);
   bool day_allowed=false;
   switch(tm.day_of_week)
   {
      case 1: day_allowed=Allowed_Monday; break; 
      case 2: day_allowed=Allowed_Tuesday; break;
      case 3: day_allowed=Allowed_Wednesday; break; 
      case 4: day_allowed=Allowed_Thursday; break;
      case 5: day_allowed=Allowed_Friday; break; 
      default: day_allowed=false;
   }
   bool hour_allowed=(tm.hour>=StartHour && tm.hour<EndHour);

   bool specialHours_1=(tm.hour>=6 && tm.hour<8); // example quiet hour
   bool specialHours_2=(tm.hour>=9 && tm.hour<11); // example quiet hour
   bool specialHours_3=(tm.hour>=12 && tm.hour<14); // example quiet hour
   bool specialHours_4=(tm.hour>=16 && tm.hour<18); // example quiet hour

   // stop trading on Monday Morning
   bool specialDateTime = (tm.hour>=1 && tm.hour<6 && tm.day_of_week == 1);

   return (day_allowed && hour_allowed && !specialHours_1 && !specialHours_2 && !specialHours_3 && !specialHours_4 && !specialDateTime);
}

bool ShouldEnterTrade()
{
   if(IsTradingStopped || freezeCandles>0 || tradeJustClosed) return false;
   double lot = UseAutoIncrimentLots ? CalculateLotSize() : MinLotSize;
   if(!CheckMarginAvailable(lot)) return false;
   if(CountOpenPositionsForSymbol() >= MaxAllowedTradesInTrend) return false;
   int dir = GetFramesTrendDirection(); if(dir==-1) return false;
   if(!RDT_IsTradingAllowedNow()) return false;
   if(!IsCandlesInDirection()) return false;
   if(IsTrendEnding()) return false;
   if(GetATR() <= 3.0) return false;
#ifdef RDT_FEAT_LONG_CANDLE_FILTER
   if(IsLongCandle()) return false;
#endif
   double f15,s15,d15; if(!GetCurrentMAValues(FastMA_M15_Handle,SlowMA_M15_Handle,f15,s15,d15)) return false;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK), bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double cur=(dir==0?ask:bid);
   if( (dir==0 && !(cur>f15)) || (dir==1 && !(cur<f15)) ) return false;
   return true;
}

void ExecuteMarketOrder(const int direction)
{
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   const double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const double entry=(direction==0?ask:bid);
   double lot = UseAutoIncrimentLots ? CalculateLotSize() : MinLotSize;

   const double slDist = InitialSLPoints*point;
   const double initSL = (direction==0? entry - slDist : entry + slDist);

   double initTP=0.0;
#ifdef RDT_FEAT_ATR_TRAILING
   if(UseATRTakeProfit)
   {
      double atr=GetATR();
      if(atr>0.0) initTP=(direction==0? entry + atr*ATR_TP_Multiplier : entry - atr*ATR_TP_Multiplier);
      else initTP = ComputeTPPrice(direction,entry,lot);
   }
   else
#endif
   {
      initTP = ComputeTPPrice(direction,entry,lot);
   }

   double f15,s15,d15; if(!GetCurrentMAValues(FastMA_M15_Handle,SlowMA_M15_Handle,f15,s15,d15)) return;
   string cmt = StringFormat("Entry: FastMA=%.5f, SlowMA=%.5f, Lot=%.2f, SL=%.5f", f15,s15,lot,initSL);

   CTrade trade; trade.SetExpertMagicNumber(MagicNumber); trade.SetDeviationInPoints(MaxAllowedSlippage);
   bool sent = (direction==0) ? trade.Buy(lot,_Symbol,entry,initSL,initTP,cmt)
                              : trade.Sell(lot,_Symbol,entry,initSL,initTP,cmt);
   if(!sent) { Print("❌ Order send failed. Retcode=", trade.ResultRetcode(), " (", GetRetcodeDescription(trade.ResultRetcode()), ")"); return; }
   Print("✅ Market order opened: ", (direction==0?"BUY":"SELL"), " @ ", DoubleToString(entry,_Digits));
}

#endif // RDT_FEAT_CORE
#endif // RDT_CORE_MQH
