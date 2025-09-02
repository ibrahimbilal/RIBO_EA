//==============================================================
// RiboEA_v4_1.mq5 — how to wire the modules together
// (Drop-in template for your EA main file)
//==============================================================
#property strict
#property copyright "Copyright 2025, Ibrahim Bilal"
#property link      "https://www.ibrahimbilal.com"
#property version   "4.1"
#property indicator_chart_window

#include <Trade/Trade.mqh>

#include "includes/RDT_Inputs.mqh"
#include "includes/RDT_Core.mqh"
#include "includes/RDT_FeatureFlags.mqh"
#include "includes/RDT_Utils.mqh"
#include "includes/RDT_Indicators.mqh"
#include "includes/RDT_Risk.mqh"
#include "includes/RDT_Position.mqh"
#include "includes/RDT_History.mqh"
#include "includes/RDT_Dashboard.mqh"
#include "includes/RDT_Close.mqh"

// --- Define globals once here
const int      MagicNumber               = 20032023;
const double   point                     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

double      AccumulatedProfit            = 0.0;
double      DailyProfit                  = 0.0;
int         LastYMD                      = -1;
bool        TradingPausedToday           = false;
bool        IsTradingStopped             = false;
datetime    ScriptStartTime              = 0;
int         TotalWins = 0, TotalLosses   =0; 
double      TotalProfitWins = 0.0, TotalProfitLosses = 0.0;

// Indicator handles
int FastMA_M1_Handle=INVALID_HANDLE, SlowMA_M1_Handle    =  INVALID_HANDLE;
int FastMA_M5_Handle=INVALID_HANDLE, SlowMA_M5_Handle    =  INVALID_HANDLE;
int FastMA_M15_Handle=INVALID_HANDLE,SlowMA_M15_Handle   =  INVALID_HANDLE;
int ATR_M15_Handle=INVALID_HANDLE;

// Runtime state
ulong    LastClosedTicket  =  0; 
bool     tradeJustClosed   =  false; 
datetime lastCandleTimeM5  =  0; 
int      freezeCandles     =  0;

int OnInit()
{
   ScriptStartTime = TimeCurrent();
   if(!InitializeIndicators()) { Print("❌ Failed to initialize indicators. Retrying in timer..."); EventSetTimer(1); }
   if(ShowDashboardOnChart) CreateInfoPanel();
   return INIT_SUCCEEDED;
}

void OnTimer(){ OnTimerIndicatorsRetry(); }

void OnDeinit(const int reason)
{
   //ObjectsDeleteAll(0, "RDT_");
   ReleaseIndicators();
}

void OnTick()
{
   EnsureDailyTradingState();
   datetime t=iTime(NULL,PERIOD_M5,0); if(t!=lastCandleTimeM5){ lastCandleTimeM5=t; if(freezeCandles>0)--freezeCandles; else tradeJustClosed=false; }
   CheckForRecentlyClosedTrades();
   UpdateTrailingStops();
   UpdateProfitDisplay();
   UpdateStatisticsDisplay();
   if(IsTradingStopped) return;

   // 1) Enforce session rule: close winners only if session is OFF
   RDT_CloseProfitablePositions_WhenSessionOff();

   if(ShouldEnterTrade()){
      int dir = GetFramesTrendDirection();
      ExecuteMarketOrder(dir);
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res)
{
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD && HistoryDealSelect(trans.deal))
   {
      if(HistoryDealGetInteger(trans.deal,DEAL_ENTRY)==DEAL_ENTRY_OUT && HistoryDealGetInteger(trans.deal,DEAL_MAGIC)==MagicNumber && trans.deal!=LastClosedTicket)
      {
         CheckLastClosedTrade();
         tradeJustClosed = true; lastCandleTimeM5=(datetime)HistoryDealGetInteger(trans.deal,DEAL_TIME); freezeCandles=FreezeCandlesCount;
         Print("❄️ Trade closed! Freezing for ", FreezeCandlesCount, " candles.");
      }
   }
}
