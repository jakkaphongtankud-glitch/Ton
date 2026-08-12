//+------------------------------------------------------------------+
//|                                                         Defs.mqh |
//|      Global enums, constants and timeframe index definitions      |
//|      Part of: MTF_Structure_Scalper_Runner_v2                     |
//+------------------------------------------------------------------+
//  Technical Specification v2.0 - Section 3 (ENUM DEFINITIONS)
//  All enums here are LOCKED per SPEC_v2.0. Do not renumber existing
//  members (telemetry / .set files depend on the integer values).
//+------------------------------------------------------------------+
#ifndef MTSR2_DEFS_MQH
#define MTSR2_DEFS_MQH

#define MTSR2_VERSION      "2.0.0_CORE"
#define MTSR2_BUILD        "p2-sr-liq-bias"

//--- Internal timeframe indexing (hierarchy order: HTF -> LTF) ------
#define TF_COUNT 7
enum ENUM_TF_INDEX
  {
   IDX_D1  = 0,
   IDX_H4  = 1,
   IDX_H2  = 2,
   IDX_H1  = 3,
   IDX_M15 = 4,
   IDX_M5  = 5,
   IDX_M1  = 6
  };

//====================================================================
//  3.1 Market regime
//====================================================================
enum ENUM_MARKET_REGIME
  {
   REGIME_UNKNOWN = 0,
   REGIME_STRONG_BULL,
   REGIME_BULL,
   REGIME_RANGE,
   REGIME_BEAR,
   REGIME_STRONG_BEAR,
   REGIME_TRANSITION,
   REGIME_HIGH_VOLATILITY,
   REGIME_LOW_LIQUIDITY
  };

//====================================================================
//  3.2 Structure direction
//====================================================================
enum ENUM_STRUCTURE_DIR
  {
   STRUCT_UNKNOWN = 0,
   STRUCT_BULL,
   STRUCT_BEAR,
   STRUCT_RANGE,
   STRUCT_TRANSITION
  };

//====================================================================
//  3.3 Swing type
//====================================================================
enum ENUM_SWING_TYPE
  {
   SWING_NONE = 0,
   SWING_HIGH,
   SWING_LOW
  };

//====================================================================
//  3.4 Structure event
//====================================================================
enum ENUM_STRUCTURE_EVENT
  {
   STRUCT_EVENT_NONE = 0,
   STRUCT_HH,
   STRUCT_HL,
   STRUCT_LH,
   STRUCT_LL,
   STRUCT_BOS_BULL,
   STRUCT_BOS_BEAR,
   STRUCT_CHOCH_BULL,
   STRUCT_CHOCH_BEAR,
   STRUCT_FAILED_BREAK_HIGH,
   STRUCT_FAILED_BREAK_LOW
  };

//====================================================================
//  3.5 Setup type
//====================================================================
enum ENUM_SETUP_TYPE
  {
   SETUP_NONE                 = 0,
   SETUP_TREND_PULLBACK       = 1,
   SETUP_BREAKOUT_RETEST      = 2,
   SETUP_LIQUIDITY_REVERSAL   = 3,
   SETUP_FALSE_BREAK_REVERSAL = 4,
   SETUP_CONTINUATION         = 5,
   SETUP_COUNTERTREND         = 6,
   SETUP_HEDGE                = 7
  };

//====================================================================
//  3.6 Signal side
//====================================================================
enum ENUM_SIGNAL_SIDE
  {
   SIGNAL_NONE = 0,
   SIGNAL_BUY,
   SIGNAL_SELL
  };

//====================================================================
//  3.7 Setup quality
//====================================================================
enum ENUM_SETUP_QUALITY
  {
   QUALITY_REJECT = 0,
   QUALITY_B,
   QUALITY_A,
   QUALITY_A_PLUS
  };

//====================================================================
//  3.8 Position state
//====================================================================
enum ENUM_POSITION_STATE
  {
   POS_NONE = 0,
   POS_ENTRY_PENDING,
   POS_ACTIVE,
   POS_PROTECTED,
   POS_PARTIAL_1,
   POS_PARTIAL_2,
   POS_RUNNER_M15,
   POS_RUNNER_H1,
   POS_RUNNER_H2,
   POS_RUNNER_H4,
   POS_RUNNER_D1,
   POS_HEDGE_WARNING,
   POS_HEDGED,
   POS_RECOVERY_MONITOR,
   POS_EXIT_PENDING,
   POS_CLOSED
  };

//====================================================================
//  3.9 System state
//====================================================================
enum ENUM_SYSTEM_STATE
  {
   SYS_IDLE = 0,
   SYS_SCAN_HTF,
   SYS_BUILD_BIAS,
   SYS_WAIT_ZONE,
   SYS_WAIT_SETUP,
   SYS_WAIT_M5,
   SYS_WAIT_M1,
   SYS_RISK_CHECK,
   SYS_ENTRY,
   SYS_MANAGE_POSITION,
   SYS_COOLDOWN,
   SYS_DISABLED
  };

//====================================================================
//  3.10 Recovery state
//====================================================================
enum ENUM_RECOVERY_STATE
  {
   RECOVERY_NONE = 0,
   RECOVERY_THESIS_VALID,
   RECOVERY_THESIS_WEAK,
   RECOVERY_THESIS_INVALID,
   RECOVERY_REENTRY_WAIT
  };

//====================================================================
//  3.11 Hedge state
//====================================================================
enum ENUM_HEDGE_STATE
  {
   HEDGE_NONE = 0,
   HEDGE_WARNING,
   HEDGE_PARTIAL,
   HEDGE_CONFIRMED_REVERSAL,
   HEDGE_RELEASE
  };

//====================================================================
//  3.12 Stop mode
//====================================================================
enum ENUM_STOP_MODE
  {
   STOP_STRUCTURE = 0,
   STOP_ATR,
   STOP_HYBRID
  };

//====================================================================
//  3.13 Entry execution mode
//====================================================================
enum ENUM_ENTRY_MODE
  {
   ENTRY_MARKET_CONFIRM = 0,
   ENTRY_LIMIT_RETEST,
   ENTRY_STOP_CONFIRM
  };

//====================================================================
//  3.14 News mode
//====================================================================
enum ENUM_NEWS_MODE
  {
   NEWS_OFF = 0,
   NEWS_MT5_CALENDAR,
   NEWS_MANUAL_WINDOWS
  };

//====================================================================
//  2.3 (extra) Zone type - Section 23
//====================================================================
enum ENUM_ZONE_TYPE
  {
   ZONE_UNKNOWN = 0,
   ZONE_SUPPORT,
   ZONE_RESISTANCE,
   ZONE_FLIP,
   ZONE_SUPPLY,
   ZONE_DEMAND
  };

//====================================================================
//  Rejected-signal reasons (Section 100) - used by telemetry
//====================================================================
enum ENUM_REJECT_REASON
  {
   REJ_NONE = 0,
   REJ_LOW_SCORE,
   REJ_CONFLICT,
   REJ_LOW_RR,
   REJ_SPREAD,
   REJ_NEWS,
   REJ_SESSION,
   REJ_RISK,
   REJ_NO_M5_CONFIRM,
   REJ_NO_M1_TRIGGER,
   REJ_BAD_STOP,
   REJ_DAILY_LIMIT,
   REJ_DATA_NOT_READY,
   REJ_ENV_INVALID
  };

//--- Log levels -----------------------------------------------------
enum ENUM_LOG_LEVEL
  {
   LOG_ERROR = 0,
   LOG_WARN  = 1,
   LOG_INFO  = 2,
   LOG_DEBUG = 3
  };

#endif // MTSR2_DEFS_MQH
//+------------------------------------------------------------------+
