//+------------------------------------------------------------------+
//|                                                      Structs.mqh |
//|      Core data structures (SPEC v2.0 sections 71-76)              |
//+------------------------------------------------------------------+
#ifndef MTSR2_STRUCTS_MQH
#define MTSR2_STRUCTS_MQH

#include "Defs.mqh"

//====================================================================
//  71. SWING POINT
//====================================================================
struct SwingPoint
  {
   ulong             id;
   ENUM_TIMEFRAMES   tf;
   ENUM_SWING_TYPE   type;
   datetime          time;
   int               shift;        // bar shift at confirmation time (informational)
   double            price;
   double            atr;          // ATR at the swing bar
   bool              confirmed;
   bool              broken;
   datetime          broken_time;

   void Reset()
     {
      id=0; tf=PERIOD_CURRENT; type=SWING_NONE; time=0; shift=0;
      price=0.0; atr=0.0; confirmed=false; broken=false; broken_time=0;
     }
  };

//====================================================================
//  72. TF STATE  (one per active timeframe)
//====================================================================
struct TFState
  {
   ENUM_TIMEFRAMES     tf;
   int                 tf_index;
   datetime            last_bar_time;
   ENUM_STRUCTURE_DIR  structure;
   ENUM_MARKET_REGIME  regime;

   SwingPoint          last_high;
   SwingPoint          prev_high;
   SwingPoint          last_low;
   SwingPoint          prev_low;

   double              protected_high;   // LH that produced last valid bearish BOS
   double              protected_low;    // HL that produced last valid bullish BOS

   bool                bos_bull;
   bool                bos_bear;
   bool                choch_bull;
   bool                choch_bear;
   double              bos_score;
   double              choch_score;

   ENUM_STRUCTURE_EVENT last_event;
   datetime            last_event_time;

   double              atr;
   double              atr_ratio;        // current ATR / median(reference window)
   double              trend_confidence; // 0..1
   double              bull_confidence;  // 0..1
   double              bear_confidence;  // 0..1
   bool                data_ready;

   void Reset()
     {
      tf=PERIOD_CURRENT; tf_index=-1; last_bar_time=0;
      structure=STRUCT_UNKNOWN; regime=REGIME_UNKNOWN;
      last_high.Reset(); prev_high.Reset(); last_low.Reset(); prev_low.Reset();
      protected_high=0.0; protected_low=0.0;
      bos_bull=false; bos_bear=false; choch_bull=false; choch_bear=false;
      bos_score=0.0; choch_score=0.0;
      last_event=STRUCT_EVENT_NONE; last_event_time=0;
      atr=0.0; atr_ratio=1.0; trend_confidence=0.0;
      bull_confidence=0.0; bear_confidence=0.0; data_ready=false;
     }
  };

//====================================================================
//  73. S/R ZONE
//====================================================================
struct SRZone
  {
   ulong             id;
   ENUM_ZONE_TYPE    type;
   ENUM_TIMEFRAMES   source_tf;
   double            lower;
   double            upper;
   double            center;
   datetime          created;
   datetime          last_touch;
   int               touches;
   int               age_bars;
   double            score;
   bool              fresh;
   bool              broken;
   bool              active;
   bool              has_liquidity;
   bool              bos_origin;

   void Reset()
     {
      id=0; type=ZONE_UNKNOWN; source_tf=PERIOD_CURRENT;
      lower=0; upper=0; center=0; created=0; last_touch=0;
      touches=0; age_bars=0; score=0; fresh=false; broken=false;
      active=false; has_liquidity=false; bos_origin=false;
     }
  };

//====================================================================
//  74. LIQUIDITY POOL
//====================================================================
struct LiquidityPool
  {
   ulong             id;
   ENUM_SIGNAL_SIDE  expected_sweep_side;
   ENUM_TIMEFRAMES   tf;
   double            price;
   int               touches;
   double            strength;
   bool              swept;
   datetime          swept_time;
   bool              active;

   void Reset()
     {
      id=0; expected_sweep_side=SIGNAL_NONE; tf=PERIOD_CURRENT;
      price=0; touches=0; strength=0; swept=false; swept_time=0; active=false;
     }
  };

//====================================================================
//  75. SIGNAL CANDIDATE
//====================================================================
struct SignalCandidate
  {
   ulong               id;
   ENUM_SIGNAL_SIDE    side;
   ENUM_SETUP_TYPE     setup;
   datetime            created;
   double              entry;
   double              stop;
   double              target1;
   double              target2;
   double              target3;
   double              runner_target;
   double              initial_rr;
   double              master_score;
   double              structure_score;
   double              sr_score;
   double              liquidity_score;
   double              breakout_score;
   double              reversal_score;
   double              execution_score;
   ENUM_SETUP_QUALITY  quality;
   double              invalidation_price;
   bool                valid;

   void Reset()
     {
      id=0; side=SIGNAL_NONE; setup=SETUP_NONE; created=0;
      entry=0; stop=0; target1=0; target2=0; target3=0; runner_target=0;
      initial_rr=0; master_score=0; structure_score=0; sr_score=0;
      liquidity_score=0; breakout_score=0; reversal_score=0; execution_score=0;
      quality=QUALITY_REJECT; invalidation_price=0; valid=false;
     }
  };

//====================================================================
//  76. POSITION CONTEXT
//====================================================================
struct PositionContext
  {
   ulong               position_identifier;
   ulong               ticket;
   ulong               magic;
   ENUM_SETUP_TYPE     setup;
   ENUM_SIGNAL_SIDE    side;
   ENUM_POSITION_STATE state;
   datetime            open_time;
   double              entry;
   double              initial_sl;
   double              current_sl;
   double              initial_risk_price;
   double              initial_risk_cash;
   double              initial_volume;
   double              current_volume;
   double              current_r;
   double              mfe_r;
   double              mae_r;
   double              entry_score;
   double              exit_score;
   int                 runner_level;
   int                 hedge_cycles;
   bool                partial1_done;
   bool                partial2_done;
   bool                hedge_active;
   ulong               cycle_id;

   void Reset()
     {
      position_identifier=0; ticket=0; magic=0; setup=SETUP_NONE;
      side=SIGNAL_NONE; state=POS_NONE; open_time=0; entry=0;
      initial_sl=0; current_sl=0; initial_risk_price=0; initial_risk_cash=0;
      initial_volume=0; current_volume=0; current_r=0; mfe_r=0; mae_r=0;
      entry_score=0; exit_score=0; runner_level=0; hedge_cycles=0;
      partial1_done=false; partial2_done=false; hedge_active=false; cycle_id=0;
     }
  };

#endif // MTSR2_STRUCTS_MQH
//+------------------------------------------------------------------+
