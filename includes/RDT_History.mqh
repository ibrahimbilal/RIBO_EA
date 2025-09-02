//==============================================================
// RDT_History.mqh - closed-trade handling, stats & CSV logging
//==============================================================
#ifndef RDT_HISTORY_MQH
#define RDT_HISTORY_MQH
#include "RDT_FeatureFlags.mqh"
#include "RDT_Utils.mqh"

#ifdef RDT_FEAT_HISTORY

// impl
void CheckForRecentlyClosedTrades()
{
   if(PositionsTotal()==0 && !tradeJustClosed)
   {
      HistorySelect(0, TimeCurrent());
      for(int i=HistoryDealsTotal()-1;i>=0;--i)
      {
         ulong deal = HistoryDealGetTicket(i);
         if(!HistoryDealSelect(deal)) continue;
         if(HistoryDealGetInteger(deal,DEAL_ENTRY)==DEAL_ENTRY_OUT &&
            HistoryDealGetInteger(deal,DEAL_MAGIC)==MagicNumber &&
            HistoryDealGetInteger(deal,DEAL_TIME) > lastCandleTimeM5)
         {
            tradeJustClosed = true;
            lastCandleTimeM5 = (datetime)HistoryDealGetInteger(deal,DEAL_TIME);
            freezeCandles = FreezeCandlesCount;
            Print("❄️ Trade closed! Freezing trading for ", freezeCandles, " candles.");
            break;
         }
      }
   }
   else if(PositionsTotal()>0) tradeJustClosed=false;
}

void CheckLastClosedTrade()
{
   HistorySelect(0, TimeCurrent());
   int n=HistoryDealsTotal(); if(n<=0) return;
   for(int i=n-1;i>=0;--i)
   {
      ulong dtk = HistoryDealGetTicket(i);
      if(!HistoryDealSelect(dtk)) continue;
      if(HistoryDealGetInteger(dtk,DEAL_MAGIC)!=MagicNumber) continue;
      if(HistoryDealGetInteger(dtk,DEAL_ENTRY)!=DEAL_ENTRY_OUT) continue;
      if(dtk==LastClosedTicket) continue;

      string sym=HistoryDealGetString(dtk,DEAL_SYMBOL);
      int    dtype=(int)HistoryDealGetInteger(dtk,DEAL_TYPE);
      double vol=HistoryDealGetDouble(dtk,DEAL_VOLUME);
      double priceClose=HistoryDealGetDouble(dtk,DEAL_PRICE);
      double sl=HistoryDealGetDouble(dtk,DEAL_SL);
      double tp=HistoryDealGetDouble(dtk,DEAL_TP);
      double profit=HistoryDealGetDouble(dtk,DEAL_PROFIT);
      double comm=HistoryDealGetDouble(dtk,DEAL_COMMISSION);
      double swap=HistoryDealGetDouble(dtk,DEAL_SWAP);
      datetime dtime=(datetime)HistoryDealGetInteger(dtk,DEAL_TIME);
      string  dcmnt=HistoryDealGetString(dtk,DEAL_COMMENT);

      // find open deal
      ulong posId=(ulong)HistoryDealGetInteger(dtk,DEAL_POSITION_ID);
      double priceOpen=0.0; datetime openTime=0;
      for(int j=n-1;j>=0;--j)
      {
         ulong od=HistoryDealGetTicket(j); if(!HistoryDealSelect(od)) continue;
         if((ulong)HistoryDealGetInteger(od,DEAL_POSITION_ID)==posId && HistoryDealGetInteger(od,DEAL_ENTRY)==DEAL_ENTRY_IN)
         { priceOpen=HistoryDealGetDouble(od,DEAL_PRICE); openTime=(datetime)HistoryDealGetInteger(od,DEAL_TIME); break; }
      }

      double priceMovementProfit = profit - comm - swap;
      double profitWithCommission= profit - swap;

      if(profitWithCommission>=0)
      {
         ++TotalWins; TotalProfitWins += profitWithCommission;
#ifdef RDT_FEAT_PUSH_NOTIFICATIONS
         if(SendNotificationOnWin) SendNotification("✅ Ribo EA Trader - Win: €"+DoubleToString(profitWithCommission,2)+" | Total: €"+DoubleToString(AccumulatedProfit+profitWithCommission,2));
#endif
      }
      else
      {
         ++TotalLosses; TotalProfitLosses += MathAbs(profitWithCommission);
#ifdef RDT_FEAT_PUSH_NOTIFICATIONS
         if(SendNotificationOnLoss) SendNotification("❌ Ribo EA Trader - Loss: €"+DoubleToString(profitWithCommission,2)+" | Total: €"+DoubleToString(AccumulatedProfit+profitWithCommission,2));
#endif
      }

#ifdef RDT_FEAT_DAILY_TARGET_PAUSE
      DailyProfit += profitWithCommission;
#endif
      AccumulatedProfit += profitWithCommission;

      PrintClosedTradeInfo(sym,(dtype==DEAL_TYPE_BUY)?"BUY":"SELL",vol,priceOpen,priceClose,openTime,dtime,profit,swap,comm);

#ifdef RDT_FEAT_CSV_LOG
      LogTradeToCSV(dtk,sym,(dtype==DEAL_TYPE_BUY)?"Buy":"Sell",vol,priceOpen,priceClose,sl,tp,priceMovementProfit,profitWithCommission,comm,swap,openTime,dtime,ScriptStartTime,dcmnt);
#endif

#ifdef RDT_FEAT_DAILY_TARGET_PAUSE
      if(!TradingPausedToday && DailyProfit >= TotalProfitTarget)
      {
         TradingPausedToday = true; IsTradingStopped = true;
         Print("🎯 Daily target reached (€", DoubleToString(TotalProfitTarget,2), "). Trading paused until end of day.");
#ifdef RDT_FEAT_PUSH_NOTIFICATIONS
         if(SendNotificationOnTotalProfitTarget) SendNotification("✅ Ribo EA Trader - Target Reached! Profit: €"+DoubleToString(AccumulatedProfit,2));
#endif
      }
#endif

      LastClosedTicket = dtk;
      break;
   }
}

void PrintClosedTradeInfo(const string symbol, const string type, const double volume,
                          const double openPrice, const double closePrice,
                          const datetime openTime, const datetime closeTime,
                          const double profit, const double swap, const double commission)
{
   int mins=(int)((closeTime-openTime)/60); int hrs=mins/60; mins%=60;
   double netProfit = profit + swap + commission;
   string msg = StringFormat(
      "\n=== CLOSED TRADE ===\nSymbol: %s | Type: %s | Vol: %.2f\nOpen: %.5f | Close: %.5f\nDuration: %dh %dm | Closed: %s\nProfit: %.2f %s | Swap: %.2f | Commission: %.2f\nNet: %.2f %s\n====================",
      symbol,type,volume,openPrice,closePrice,hrs,mins,TimeToString(closeTime,TIME_DATE|TIME_MINUTES|TIME_SECONDS),
      profit,AccountInfoString(ACCOUNT_CURRENCY),swap,commission,netProfit,AccountInfoString(ACCOUNT_CURRENCY));
   Print(msg);
}

string GenerateUniqueCSVFilename()
{
   MqlDateTime ts; TimeCurrent(ts);
   return StringFormat("RIBO_EA_Log_%s_%04d-%02d-%02d_%02d-%02d-%02d.csv", _Symbol, ts.year, ts.mon, ts.day, ts.hour, ts.min, ts.sec);
}

void LogTradeToCSV(const ulong ticket, const string symbol, const string direction, const double volume,
                   const double openPrice, const double closePrice, const double sl, const double tp,
                   const double priceMovementProfit, const double profitWithCommission,
                   const double commission, const double swap, const datetime openTime,
                   const datetime closeTime, const datetime startTime, const string comment)
{
   static string csvFile = GenerateUniqueCSVFilename();
   int fh = FileOpen(csvFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(fh==INVALID_HANDLE) { Print("❌ CSV open failed: ", csvFile, " Err=", GetLastError()); return; }
   if(FileSize(fh)==0)
   {
      FileWrite(fh, "Ticket","Symbol","Direction","Volume","Open Price","Close Price","SL","TP",
                   "Price Movement Profit","Profit With Commission","Commission","Swap","Open Time","Close Time","Script Start Time","Comment");
   }
   FileSeek(fh,0,SEEK_END);
   FileWrite(fh,(long)ticket,symbol,direction,DoubleToString(volume,2),
      DoubleToString(openPrice,_Digits),DoubleToString(closePrice,_Digits),
      DoubleToString(sl,_Digits),DoubleToString(tp,_Digits),
      DoubleToString(priceMovementProfit,2),DoubleToString(profitWithCommission,2),
      DoubleToString(commission,2),DoubleToString(swap,2),
      TimeToString(openTime,TIME_DATE|TIME_MINUTES),TimeToString(closeTime,TIME_DATE|TIME_MINUTES),
      TimeToString(startTime,TIME_DATE|TIME_MINUTES),comment);
   FileClose(fh);
   Print("✅ Trade logged to: ", csvFile);
}

#endif // RDT_FEAT_HISTORY
#endif // RDT_HISTORY_MQH
