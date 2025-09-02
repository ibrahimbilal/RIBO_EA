//==============================================================
// RDT_FeatureFlags.mqh
// — Central feature toggles + shared inputs for RIBO EA
//==============================================================
#ifndef RDT_FEATURE_FLAGS_MQH
#define RDT_FEATURE_FLAGS_MQH

// --- Core feature toggles (enable/disable modules at compile-time)
#define RDT_FEAT_CORE                1
#define RDT_FEAT_RISK                1
#define RDT_FEAT_POSITION            1
#define RDT_FEAT_INDICATORS          1
#define RDT_FEAT_DASHBOARD           1
#define RDT_FEAT_HISTORY             1
#define RDT_FEAT_UTILS               1
#define RDT_FEAT_SMART_SR            1

// --- Sub-feature toggles
#define RDT_FEAT_TP_FROM_MONEY       1  // Compute TP from € target
#define RDT_FEAT_ATR_TRAILING        1  // ATR-based trailing
#define RDT_FEAT_BREAKEVEN           1  // Break-even logic
#define RDT_FEAT_LONG_CANDLE_FILTER  1
#define RDT_FEAT_MTF_TREND           1
#define RDT_FEAT_DAILY_TARGET_PAUSE  1
#define RDT_FEAT_CSV_LOG             1
#define RDT_FEAT_PUSH_NOTIFICATIONS  1

#endif // RDT_FEATURE_FLAGS_MQH
