//==============================================================
// RDT_Inputs.mqh — central EA inputs
//==============================================================
#ifndef RDT_INPUTS_MQH
#define RDT_INPUTS_MQH

//--- [Risk & Volume]
input group   "Risk & Volume"
input bool    UseAutoIncrimentLots      = true;             // Enable auto increment lots
input double  MinLotSize                = 0.05;             // Min lot used or base for auto lots
input double  MaxLotSize                = 1.00;             // Max lot cap
input int     InitialSLPoints           = 800;              // Initial Stop Loss distance (PT)
input int     MaxAllowedSlippage        = 10;               // Max slippage for market orders (PT)

//--- [Profit Targets]
input group   "Profit Targets"
input double  TotalProfitTarget         = 90.0;             // Total accumulated target ($)
input double  ProfitTargetPerTrade      = 5.0;              // Per-trade target ($)
input int     MinTP                     = 100;              // Minimum TP in points (PT)
input bool    UseATRTakeProfit          = true;             // Enable ATR-based Take Profit
input double  ATR_TP_Multiplier         = 1.75;             // Multiplier for ATR-based TP

//--- [BreakEven Settings]
input group   "BreakEven Settings"
input bool   UseBreakEven          = false;    // Enable BreakEven
input double BreakEvenTriggerPoints= 100.0;    // Points in profit before moving SL to BE
input double BreakEvenOffsetPoints = 10.0;     // Offset from entry price (to secure small profit)

//--- [ATR-based Trailing Settings]
input group   "ATR-based Trailing Settings"
input bool   UseATRTrailing        = true;     // Enable ATR-based trailing
input int    ATR_Period            = 14;       // ATR period
input double ATR_Multiplier        = 2.0;      // Multiplier for trailing stop

//--- [Moving Averages]
input group   "Moving Averages"
input ENUM_MA_METHOD MAMethod           = MODE_EMA;         // MA calculation method
input int     FastMAPeriod              = 20;               // Fast MA period
input int     SlowMAPeriod              = 50;               // Slow MA period
input int     MAShift                   = 0;                // MAs shift
input double  MADifferenceMinThreshold  = 0.04;             // Min MA diff (%) to confirm trend

//--- [Entries & Filters]
input group   "Entries & Filters"
input int     PreviousCandlesToCheck    = 2;                // Previous candles to confirm direction
input int     MaxAllowedTradesInTrend   = 1;                // Max simultaneous trades per trend
input int     FreezeCandlesCount        = 0;                // Freeze on close (candles)
input int     LongCandlePoints          = 1000;             // Long candle detection (PT)
input int     TrailingStopPoints        = 300;              // Trailing on long-candle trigger (PT)

//--- [Session Control]
input group   "Session Control"
input bool    Allowed_Monday            = true;             // Monday
input bool    Allowed_Tuesday           = true;             // Tuesday
input bool    Allowed_Wednesday         = false;            // Wednesday
input bool    Allowed_Thursday          = true;             // Thursday
input bool    Allowed_Friday            = true;             // Friday
input int     StartHour                 = 11;               // Start hour (server time)
input int     EndHour                   = 20;               // End hour (server time)

//--- [Notifications]
input group   "Notifications"
input bool    SendNotificationOnWin             = true;     // Notify on win
input bool    SendNotificationOnLoss            = true;     // Notify on loss
input bool    SendNotificationOnTotalProfitTarget = true;   // Notify on reaching total target

//--- [Dashboard]
input group   "Dashboard"
input bool    ShowDashboardOnChart      = true;             // Show dashboard
input int     DashboardSize_X           = 230;              // Width
input int     DashboardSize_Y           = 210;              // Height
input color   DashboardColor_BG         = clrDarkSlateGray; // Background
input color   DashboardColor_TEXT       = clrWhite;         // Text

input double MinPointsToClose = 600; // close only if points > this threshold

#endif // RDT_INPUTS_MQH
