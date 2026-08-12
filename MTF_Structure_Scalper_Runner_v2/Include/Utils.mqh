//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|      Pure helper functions: TF mapping, candle math, enum text     |
//+------------------------------------------------------------------+
#ifndef MTSR2_UTILS_MQH
#define MTSR2_UTILS_MQH

#include "Defs.mqh"

//--- Timeframe mapping ----------------------------------------------
ENUM_TIMEFRAMES TFIndexToPeriod(const int idx)
  {
   switch(idx)
     {
      case IDX_D1:  return PERIOD_D1;
      case IDX_H4:  return PERIOD_H4;
      case IDX_H2:  return PERIOD_H2;
      case IDX_H1:  return PERIOD_H1;
      case IDX_M15: return PERIOD_M15;
      case IDX_M5:  return PERIOD_M5;
      case IDX_M1:  return PERIOD_M1;
     }
   return PERIOD_CURRENT;
  }

string TFIndexToName(const int idx)
  {
   switch(idx)
     {
      case IDX_D1:  return "D1";
      case IDX_H4:  return "H4";
      case IDX_H2:  return "H2";
      case IDX_H1:  return "H1";
      case IDX_M15: return "M15";
      case IDX_M5:  return "M5";
      case IDX_M1:  return "M1";
     }
   return "??";
  }

int PeriodToTFIndex(const ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_D1:  return IDX_D1;
      case PERIOD_H4:  return IDX_H4;
      case PERIOD_H2:  return IDX_H2;
      case PERIOD_H1:  return IDX_H1;
      case PERIOD_M15: return IDX_M15;
      case PERIOD_M5:  return IDX_M5;
      case PERIOD_M1:  return IDX_M1;
     }
   return -1;
  }

//--- Clamp helpers --------------------------------------------------
double Clamp(const double v,const double lo,const double hi)
  {
   if(v<lo) return lo;
   if(v>hi) return hi;
   return v;
  }
double Clamp01(const double v) { return Clamp(v,0.0,1.0); }

//--- Candle geometry (operate on a single MqlRates) -----------------
double CandleRange(const MqlRates &r)  { return (r.high-r.low); }
double CandleBody(const MqlRates &r)   { return MathAbs(r.close-r.open); }
double CandleUpperWick(const MqlRates &r) { return r.high-MathMax(r.open,r.close); }
double CandleLowerWick(const MqlRates &r) { return MathMin(r.open,r.close)-r.low; }
bool   CandleIsBull(const MqlRates &r) { return (r.close>=r.open); }

double CandleBodyRatio(const MqlRates &r,const double min_denom)
  {
   double denom=MathMax(CandleRange(r),min_denom);
   if(denom<=0.0) return 0.0;
   return CandleBody(r)/denom;
  }
double CandleUpperWickRatio(const MqlRates &r,const double min_denom)
  {
   double denom=MathMax(CandleRange(r),min_denom);
   if(denom<=0.0) return 0.0;
   return CandleUpperWick(r)/denom;
  }
double CandleLowerWickRatio(const MqlRates &r,const double min_denom)
  {
   double denom=MathMax(CandleRange(r),min_denom);
   if(denom<=0.0) return 0.0;
   return CandleLowerWick(r)/denom;
  }

//--- Enum -> text (dashboard / logs) --------------------------------
string StructureDirStr(const ENUM_STRUCTURE_DIR d)
  {
   switch(d)
     {
      case STRUCT_BULL:       return "BULL";
      case STRUCT_BEAR:       return "BEAR";
      case STRUCT_RANGE:      return "RANGE";
      case STRUCT_TRANSITION: return "TRANS";
     }
   return "----";
  }

string RegimeStr(const ENUM_MARKET_REGIME r)
  {
   switch(r)
     {
      case REGIME_STRONG_BULL:     return "STRONG_BULL";
      case REGIME_BULL:            return "BULL";
      case REGIME_RANGE:           return "RANGE";
      case REGIME_BEAR:            return "BEAR";
      case REGIME_STRONG_BEAR:     return "STRONG_BEAR";
      case REGIME_TRANSITION:      return "TRANSITION";
      case REGIME_HIGH_VOLATILITY: return "HIGH_VOL";
      case REGIME_LOW_LIQUIDITY:   return "LOW_LIQ";
     }
   return "UNKNOWN";
  }

string StructureEventStr(const ENUM_STRUCTURE_EVENT e)
  {
   switch(e)
     {
      case STRUCT_HH:                return "HH";
      case STRUCT_HL:                return "HL";
      case STRUCT_LH:                return "LH";
      case STRUCT_LL:                return "LL";
      case STRUCT_BOS_BULL:          return "BOS_BULL";
      case STRUCT_BOS_BEAR:          return "BOS_BEAR";
      case STRUCT_CHOCH_BULL:        return "CHOCH_BULL";
      case STRUCT_CHOCH_BEAR:        return "CHOCH_BEAR";
      case STRUCT_FAILED_BREAK_HIGH: return "FAIL_HIGH";
      case STRUCT_FAILED_BREAK_LOW:  return "FAIL_LOW";
     }
   return "NONE";
  }

string SideStr(const ENUM_SIGNAL_SIDE s)
  {
   switch(s) { case SIGNAL_BUY: return "BUY"; case SIGNAL_SELL: return "SELL"; }
   return "NONE";
  }

string SysStateStr(const ENUM_SYSTEM_STATE s)
  {
   switch(s)
     {
      case SYS_IDLE:            return "IDLE";
      case SYS_SCAN_HTF:        return "SCAN_HTF";
      case SYS_BUILD_BIAS:      return "BUILD_BIAS";
      case SYS_WAIT_ZONE:       return "WAIT_ZONE";
      case SYS_WAIT_SETUP:      return "WAIT_SETUP";
      case SYS_WAIT_M5:         return "WAIT_M5";
      case SYS_WAIT_M1:         return "WAIT_M1";
      case SYS_RISK_CHECK:      return "RISK_CHECK";
      case SYS_ENTRY:           return "ENTRY";
      case SYS_MANAGE_POSITION: return "MANAGE";
      case SYS_COOLDOWN:        return "COOLDOWN";
      case SYS_DISABLED:        return "DISABLED";
     }
   return "?";
  }

#endif // MTSR2_UTILS_MQH
//+------------------------------------------------------------------+
