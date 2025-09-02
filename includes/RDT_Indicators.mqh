//==============================================================
// RDT_Indicators.mqh — indicator handles & signal logic
//==============================================================
#ifndef RDT_INDICATORS_MQH
#define RDT_INDICATORS_MQH
#include "RDT_FeatureFlags.mqh"

#ifdef RDT_FEAT_INDICATORS

// --- Implementation
bool InitializeIndicators()
{
   if(FastMA_M1_Handle  != INVALID_HANDLE) IndicatorRelease(FastMA_M1_Handle);
   if(SlowMA_M1_Handle  != INVALID_HANDLE) IndicatorRelease(SlowMA_M1_Handle);
   if(FastMA_M5_Handle  != INVALID_HANDLE) IndicatorRelease(FastMA_M5_Handle);
   if(SlowMA_M5_Handle  != INVALID_HANDLE) IndicatorRelease(SlowMA_M5_Handle);
   if(FastMA_M15_Handle != INVALID_HANDLE) IndicatorRelease(FastMA_M15_Handle);
   if(SlowMA_M15_Handle != INVALID_HANDLE) IndicatorRelease(SlowMA_M15_Handle);
   if(ATR_M15_Handle    != INVALID_HANDLE) IndicatorRelease(ATR_M15_Handle);

   FastMA_M1_Handle  = iMA(_Symbol, PERIOD_M1,  FastMAPeriod, MAShift, MAMethod, PRICE_CLOSE);
   SlowMA_M1_Handle  = iMA(_Symbol, PERIOD_M1,  SlowMAPeriod, MAShift, MAMethod, PRICE_CLOSE);
   FastMA_M5_Handle  = iMA(_Symbol, PERIOD_M5,  FastMAPeriod, MAShift, MAMethod, PRICE_CLOSE);
   SlowMA_M5_Handle  = iMA(_Symbol, PERIOD_M5,  SlowMAPeriod, MAShift, MAMethod, PRICE_CLOSE);
   FastMA_M15_Handle = iMA(_Symbol, PERIOD_M15, FastMAPeriod, MAShift, MAMethod, PRICE_CLOSE);
   SlowMA_M15_Handle = iMA(_Symbol, PERIOD_M15, SlowMAPeriod, MAShift, MAMethod, PRICE_CLOSE);

   bool ok = (FastMA_M1_Handle  != INVALID_HANDLE && SlowMA_M1_Handle  != INVALID_HANDLE &&
              FastMA_M5_Handle  != INVALID_HANDLE && SlowMA_M5_Handle  != INVALID_HANDLE &&
              FastMA_M15_Handle != INVALID_HANDLE && SlowMA_M15_Handle != INVALID_HANDLE);

#ifdef RDT_FEAT_ATR_TRAILING
   if(UseATRTakeProfit || UseATRTrailing)
   {
      ATR_M15_Handle = iATR(_Symbol, PERIOD_M15, ATR_Period);
      ok = ok && (ATR_M15_Handle != INVALID_HANDLE);
   }
   else ATR_M15_Handle = INVALID_HANDLE;
#endif

   if(!ok) { Print("❌ Failed to create indicators. Err=", GetLastError()); return false; }
   Print("✅ Indicators initialized.");
   return true;
}

void ReleaseIndicators()
{
   if(FastMA_M1_Handle  != INVALID_HANDLE) IndicatorRelease(FastMA_M1_Handle);
   if(SlowMA_M1_Handle  != INVALID_HANDLE) IndicatorRelease(SlowMA_M1_Handle);
   if(FastMA_M5_Handle  != INVALID_HANDLE) IndicatorRelease(FastMA_M5_Handle);
   if(SlowMA_M5_Handle  != INVALID_HANDLE) IndicatorRelease(SlowMA_M5_Handle);
   if(FastMA_M15_Handle != INVALID_HANDLE) IndicatorRelease(FastMA_M15_Handle);
   if(SlowMA_M15_Handle != INVALID_HANDLE) IndicatorRelease(SlowMA_M15_Handle);
   if(ATR_M15_Handle    != INVALID_HANDLE) IndicatorRelease(ATR_M15_Handle);
}

void OnTimerIndicatorsRetry()
{
   if(InitializeIndicators()) { Print("✅ Indicators loaded on retry."); EventKillTimer(); }
}

bool GetCurrentMAValues(const int fastHandle, const int slowHandle,
                        double &fastMA, double &slowMA, double &diffPct)
{
   double fastArr[], slowArr[];
   if(CopyBuffer(fastHandle, 0, MAShift, 1, fastArr) != 1) { Print("Fast MA copy failed. Err=", GetLastError()); return false; }
   if(CopyBuffer(slowHandle, 0, MAShift, 1, slowArr) != 1) { Print("Slow MA copy failed. Err=", GetLastError()); return false; }
   fastMA = fastArr[0]; slowMA = slowArr[0];
   diffPct = (slowMA!=0.0) ? MathAbs(fastMA-slowMA)/slowMA*100.0 : 0.0;
   return true;
}

bool GetPrevMAValues(const int fastHandle, const int slowHandle,
                     double &fastPrev, double &slowPrev, double &diffPrev)
{
   double fArr[], sArr[];
   if(CopyBuffer(fastHandle,0,MAShift,PreviousCandlesToCheck,fArr)!=PreviousCandlesToCheck) return false;
   if(CopyBuffer(slowHandle,0,MAShift,PreviousCandlesToCheck,sArr)!=PreviousCandlesToCheck) return false;
   fastPrev=fArr[0]; slowPrev=sArr[0];
   diffPrev=(slowPrev!=0.0)?MathAbs(fastPrev-slowPrev)/slowPrev*100.0:0.0;
   return true;
}

int GetMATrendDirection(const int fastHandle, const int slowHandle)
{
#ifndef RDT_FEAT_MTF_TREND
   return -1;
#else
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double f,s,d, fp,sp,dp;
   if(!GetCurrentMAValues(fastHandle,slowHandle,f,s,d)) return -1;
   if(!GetPrevMAValues   (fastHandle,slowHandle,fp,sp,dp)) return -1;
   if(price < f && price > s) return -1; // trapped between MAs
   if(f>s && f>fp && s>sp && price>f) return 0;
   if(f<s && f<fp && s<sp && price<f) return 1;
   return -1;
#endif
}

int GetFramesTrendDirection()
{
#ifndef RDT_FEAT_MTF_TREND
   return -1;
#else
   int d1=GetMATrendDirection(FastMA_M1_Handle,SlowMA_M1_Handle);
   int d5=GetMATrendDirection(FastMA_M5_Handle,SlowMA_M5_Handle);
   int d15=GetMATrendDirection(FastMA_M15_Handle,SlowMA_M15_Handle);
   if(d1==-1||d5==-1||d15==-1) return -1;
   if(d1!=d5) return -1;
   double f5,s5,df5,f15,s15,df15;
   if(!GetCurrentMAValues(FastMA_M5_Handle,SlowMA_M5_Handle,f5,s5,df5)) return -1;
   if(!GetCurrentMAValues(FastMA_M15_Handle,SlowMA_M15_Handle,f15,s15,df15)) return -1;
   if(df5<MADifferenceMinThreshold || df15<MADifferenceMinThreshold) return -1;
   return d5;
#endif
}

bool IsTrendEnding()
{
   double f,s,d, fp,sp,dp;
   if(!GetCurrentMAValues(FastMA_M5_Handle, SlowMA_M15_Handle, f,s,d))   return false;
   if(!GetPrevMAValues  (FastMA_M5_Handle, SlowMA_M15_Handle, fp,sp,dp)) return false;
   return (d<dp);
}

bool IsCandlesInDirection()
{
   int dir = GetFramesTrendDirection();
   if(dir==-1) return false;
   double h0=iHigh(NULL,PERIOD_M5,0), h1=iHigh(NULL,PERIOD_M5,1), h2=iHigh(NULL,PERIOD_M5,2);
   double c0=iClose(NULL,PERIOD_M5,0),c1=iClose(NULL,PERIOD_M5,1),c2=iClose(NULL,PERIOD_M5,2);
   if(dir==0) return (h0>h1 && h1>h2 && c0>c1 && c1>c2);
   if(dir==1) return (h0<h1 && h1<h2 && c0<c1 && c1<c2);
   return false;
}

bool IsLongCandle()
{
#ifndef RDT_FEAT_LONG_CANDLE_FILTER
   return false;
#else
   double ph=iHigh(NULL,PERIOD_M15,1); double pl=iLow(NULL,PERIOD_M15,1);
   return ((ph-pl) >= LongCandlePoints*point);
#endif
}

double GetATR()
{
#ifndef RDT_FEAT_ATR_TRAILING
   return 0.0;
#else
   if(ATR_M15_Handle==INVALID_HANDLE) return 0.0;
   double buf[]; if(CopyBuffer(ATR_M15_Handle,0,0,1,buf)<=0) return 0.0;
   return buf[0];
#endif
}

#endif // RDT_FEAT_INDICATORS
#endif // RDT_INDICATORS_MQH
