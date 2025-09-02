//==============================================================
// RDT_Dashboard.mqh — on-chart UI widgets
//==============================================================
#ifndef RDT_DASHBOARD_MQH
#define RDT_DASHBOARD_MQH
#include "RDT_FeatureFlags.mqh"
#include "RDT_Indicators.mqh"

#ifdef RDT_FEAT_DASHBOARD

// impl
void CreateInfoPanel()
{
   ObjectsDeleteAll(0, "RDT_");
   ObjectCreate(0, "RDT_Background", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_XDISTANCE, 3);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_XSIZE, DashboardSize_X);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_YSIZE, DashboardSize_Y);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_BGCOLOR, DashboardColor_BG);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "RDT_Background", OBJPROP_BORDER_COLOR, clrGoldenrod);

   CreateLabel("lblInfoBalance",10,25,  "Target: €0.00/"+DoubleToString(TotalProfitTarget,2));
   CreateLabel("lblInfoTrades", 10,45,  "W: 0 | L: 0 | Total: 0");
   CreateLabel("lblInfoAvgs",   10,65,  "AvgW: 0.0 | AvgL: 0.0 | RR: 0.0");
   CreateLabel("lblInfoTime",   10,85,  "Time: 0m");

   CreateLabel("lblInfoMA_M1",      10,105, "Status M1: UNKNOWN");
   CreateLabel("lblInfoMA_M5",      10,125, "Status M5: UNKNOWN");
   CreateLabel("lblInfoMA_M5_Diff", 10,145, "MA M5 Diff: 0%");
   CreateLabel("lblInfoMA_M15",     10,165, "Status M15: UNKNOWN");
   CreateLabel("lblInfoMA_M15_Diff",10,185, "MA M15 Diff: 0%");
   CreateLabel("lblInfoStatus",     10,205, "Status: Active");
}

void CreateLabel(const string name, const int x, const int y, const string text)
{
   const string obj = "RDT_"+name;
   ObjectCreate(0,obj,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,obj,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,obj,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,obj,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,obj,OBJPROP_TEXT,text);
   ObjectSetString (0,obj,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,obj,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,obj,OBJPROP_COLOR,DashboardColor_TEXT);
   ObjectSetInteger(0,obj,OBJPROP_BACK,false);
}

void UpdateProfitDisplay()
{
   string profitText = "Target (Today): €"+DoubleToString(DailyProfit,2)+"/"+DoubleToString(TotalProfitTarget,2);
   ObjectSetString(0, "RDT_lblInfoBalance", OBJPROP_TEXT, profitText);

   int total = TotalWins+TotalLosses; int wPct=0,lPct=0; if(total>0){ wPct=(int)((double)TotalWins/total*100.0); lPct=100-wPct; }
   string wl = StringFormat("W: %d (%d%%) | L: %d (%d%%) | T: %d", TotalWins,wPct,TotalLosses,lPct,total);
   ObjectSetString(0, "RDT_lblInfoTrades", OBJPROP_TEXT, wl);

   double avgWin  = (TotalWins>0)?(TotalProfitWins/TotalWins):0.0;
   double avgLoss = (TotalLosses>0)?(TotalProfitLosses/TotalLosses):0.0;
   string rrText; color rrColor = clrDimGray;
   if(avgLoss>0)
   {
      double rr=avgWin/avgLoss; rrText=StringFormat("AvgW: %.2f | AvgL: %.2f | RR: %.2f",avgWin,avgLoss,rr);
      if(rr>=1.5) rrColor=clrLimeGreen; else if(rr>=1.0) rrColor=clrGold; else rrColor=clrOrangeRed;
   }
   else rrText=StringFormat("AvgW: %.2f | AvgL: %.2f | RR: N/A",avgWin,avgLoss);

   ObjectSetString(0, "RDT_lblInfoAvgs", OBJPROP_TEXT, rrText);
   ObjectSetInteger(0, "RDT_lblInfoAvgs", OBJPROP_COLOR, rrColor);
}

void UpdateStatisticsDisplay()
{
   ObjectSetString(0, "RDT_lblInfoStatus", OBJPROP_TEXT, (IsTradingStopped?"Status: Paused (Daily Target)":"Status: Active"));
   ObjectSetString(0, "RDT_lblInfoTime", OBJPROP_TEXT, "Time: "+FormatElapsedTime(ScriptStartTime));

   int d1 = GetMATrendDirection(FastMA_M1_Handle,SlowMA_M1_Handle);
   double f1,s1,df1; if(!GetCurrentMAValues(FastMA_M1_Handle,SlowMA_M1_Handle,f1,s1,df1)) return;
   ObjectSetString(0,"RDT_lblInfoMA_M1",OBJPROP_TEXT,(d1==-1?"Status M1: UNKNOWN":d1==0?"Status M1: Uptrend":"Status M1: Downtrend"));
   ObjectSetInteger(0,"RDT_lblInfoMA_M1",OBJPROP_COLOR,(d1==-1?clrDimGray:d1==0?clrLimeGreen:clrOrangeRed));

   int d5 = GetMATrendDirection(FastMA_M5_Handle,SlowMA_M5_Handle);
   double f5,s5,df5; if(!GetCurrentMAValues(FastMA_M5_Handle,SlowMA_M5_Handle,f5,s5,df5)) return;
   ObjectSetInteger(0, "RDT_lblInfoMA_M5_Diff", OBJPROP_COLOR, (df5>=MADifferenceMinThreshold?clrLimeGreen:clrDimGray));
   ObjectSetString (0, "RDT_lblInfoMA_M5_Diff", OBJPROP_TEXT, StringFormat("MA M5 Diff: %.2f%% [%.2f]", df5, MADifferenceMinThreshold));
   ObjectSetString (0, "RDT_lblInfoMA_M5", OBJPROP_TEXT, (d5==-1?"Status M5: UNKNOWN":d5==0?"Status M5: Uptrend":"Status M5: Downtrend"));
   ObjectSetInteger(0, "RDT_lblInfoMA_M5", OBJPROP_COLOR, (d5==-1?clrDimGray:d5==0?clrLimeGreen:clrOrangeRed));

   int d15 = GetMATrendDirection(FastMA_M15_Handle,SlowMA_M15_Handle);
   double f15,s15,df15; if(!GetCurrentMAValues(FastMA_M15_Handle,SlowMA_M15_Handle,f15,s15,df15)) return;
   ObjectSetInteger(0, "RDT_lblInfoMA_M15_Diff", OBJPROP_COLOR, (df15>=MADifferenceMinThreshold?clrLimeGreen:clrDimGray));
   ObjectSetString (0, "RDT_lblInfoMA_M15_Diff", OBJPROP_TEXT, StringFormat("MA M15 Diff: %.2f%% [%.2f]", df15, MADifferenceMinThreshold));
   ObjectSetString (0, "RDT_lblInfoMA_M15", OBJPROP_TEXT, (d15==-1?"Status M15: UNKNOWN":d15==0?"Status M15: Uptrend":"Status M15: Downtrend"));
   ObjectSetInteger(0, "RDT_lblInfoMA_M15", OBJPROP_COLOR, (d15==-1?clrDimGray:d15==0?clrLimeGreen:clrOrangeRed));
}

#endif // RDT_FEAT_DASHBOARD
#endif // RDT_DASHBOARD_MQH
