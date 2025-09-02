//==============================================================
// RDT_Utils.mqh — shared helpers
//==============================================================
#ifndef RDT_UTILS_MQH
#define RDT_UTILS_MQH
#include <Trade/Trade.mqh>
#include "RDT_FeatureFlags.mqh"

#ifdef RDT_FEAT_UTILS

// --- Implementation
bool SelectPositionByIndex(const int index)
{
   ulong ticket = PositionGetTicket(index);
   if(ticket == 0) return false;
   return PositionSelectByTicket(ticket);
}

string FormatElapsedTime(datetime startTime)
{
   int elapsedSec = (int)(TimeCurrent() - startTime);
   int days = elapsedSec/86400; int hours=(elapsedSec%86400)/3600; int mins=(elapsedSec%3600)/60;
   if(days==0 && hours==0) return IntegerToString(mins)+"m";
   if(days==0) return IntegerToString(hours)+"h "+IntegerToString(mins)+"m";
   return IntegerToString(days)+"d "+IntegerToString(hours)+"h "+IntegerToString(mins)+"m";
}

int TodayYMD()
{
   MqlDateTime tm; TimeToStruct(TimeCurrent(), tm);
   return tm.year*10000 + tm.mon*100 + tm.day;
}

void ResetDailyTradingState()
{
#ifdef RDT_FEAT_DAILY_TARGET_PAUSE
   DailyProfit        = 0.0;
   TradingPausedToday = false;
   IsTradingStopped   = false;
   LastYMD            = TodayYMD();
   Print("\xF0\x9F\x94\x84 New trading day: daily counters reset.");
#endif
}

void EnsureDailyTradingState()
{
#ifdef RDT_FEAT_DAILY_TARGET_PAUSE
   int ymd = TodayYMD();
   if(LastYMD == -1) LastYMD = ymd;
   if(ymd != LastYMD) ResetDailyTradingState();
#endif
}

string GetRetcodeDescription(const uint retcode)
{
   switch(retcode)
   {
      case 10004: return "TRADE_RETCODE_DONE";
      case 10006: return "TRADE_RETCODE_REJECT";
      case 10007: return "TRADE_RETCODE_CANCEL";
      case 10008: return "TRADE_RETCODE_PLACED";
      case 10009: return "TRADE_RETCODE_DONE_PARTIAL";
      case 10010: return "TRADE_RETCODE_ERROR";
      case 10011: return "TRADE_RETCODE_TIMEOUT";
      case 10012: return "TRADE_RETCODE_INVALID";
      case 10013: return "TRADE_RETCODE_INVALID_VOLUME";
      case 10014: return "TRADE_RETCODE_INVALID_PRICE";
      case 10015: return "TRADE_RETCODE_INVALID_STOPS";
      case 10016: return "TRADE_RETCODE_TRADE_DISABLED";
      case 10017: return "TRADE_RETCODE_MARKET_CLOSED";
      case 10018: return "TRADE_RETCODE_NO_MONEY";
      case 10019: return "TRADE_RETCODE_PRICE_CHANGED";
      case 10020: return "TRADE_RETCODE_PRICE_OFF";
      case 10021: return "TRADE_RETCODE_INVALID_EXPIRATION";
      case 10022: return "TRADE_RETCODE_ORDER_CHANGED";
      case 10023: return "TRADE_RETCODE_TOO_MANY_REQUESTS";
      case 10024: return "TRADE_RETCODE_NO_CHANGES";
      case 10025: return "TRADE_RETCODE_SERVER_DISABLES_AT";
      case 10026: return "TRADE_RETCODE_CLIENT_DISABLES_AT";
      case 10027: return "TRADE_RETCODE_LOCKED";
      case 10028: return "TRADE_RETCODE_FROZEN";
      case 10029: return "TRADE_RETCODE_INVALID_FILL";
      case 10030: return "TRADE_RETCODE_CONNECTION";
      case 10031: return "TRADE_RETCODE_ONLY_REAL";
      case 10032: return "TRADE_RETCODE_LIMIT_ORDERS";
      case 10033: return "TRADE_RETCODE_LIMIT_VOLUME";
      case 10034: return "TRADE_RETCODE_INVALID_ORDER";
      case 10035: return "TRADE_RETCODE_POSITION_CLOSED";
      default:    return "UNKNOWN_CODE";
   }
}

#endif // RDT_FEAT_UTILS
#endif // RDT_UTILS_MQH
