//+------------------------------------------------------------------+
//|                                                RegimeEngine.mqh |
//|      Per-timeframe market regime (SPEC v2.0 sec 32-33).          |
//|      Direction from STRUCTURE (not EMA cross), strength from      |
//|      persistence + displacement + ATR expansion.                 |
//+------------------------------------------------------------------+
#ifndef MTSR2_REGIMEENGINE_MQH
#define MTSR2_REGIMEENGINE_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "MarketData.mqh"
#include "Inputs.mqh"
#include "Utils.mqh"

class CRegimeEngine
  {
private:
   CMarketData      *m_data;

public:
                     CRegimeEngine() { m_data=NULL; }
   void              Init(CMarketData *data) { m_data=data; }

   void              Update(const int idx,TFState &st)
     {
      bool bull=(st.structure==STRUCT_BULL);
      bool bear=(st.structure==STRUCT_BEAR);

      //--- persistence from last two highs/lows ---------------------
      double persist=0.3;
      if(st.last_high.time>0 && st.prev_high.time>0 &&
         st.last_low.time>0  && st.prev_low.time>0)
        {
         bool hh=(st.last_high.price>st.prev_high.price);
         bool hl=(st.last_low.price >st.prev_low.price);
         bool lh=(st.last_high.price<st.prev_high.price);
         bool ll=(st.last_low.price <st.prev_low.price);
         if((bull && hh && hl) || (bear && lh && ll)) persist=1.0;
         else if((hh&&hl) || (lh&&ll))                persist=0.75;
         else                                          persist=0.4;
        }

      double disp=Clamp01(MathMax(st.bos_score,st.choch_score)/100.0);
      double atr_ratio=m_data.ATRRatio(idx);
      double atr_exp=Clamp01((atr_ratio-1.0)/MathMax(InpExpansionATRRatio-1.0,0.01));
      double bos_freq=Clamp01(st.trend_confidence);   // proxy for BOS momentum

      double strength=100.0*(0.40*persist + 0.20*bos_freq + 0.20*disp + 0.20*atr_exp);
      strength=Clamp(strength,0.0,100.0);

      ENUM_MARKET_REGIME rg;
      if(bull)
         rg=(strength>=InpStrongTrendScore? REGIME_STRONG_BULL :
            (strength>=InpTrendScore? REGIME_BULL : REGIME_RANGE));
      else if(bear)
         rg=(strength>=InpStrongTrendScore? REGIME_STRONG_BEAR :
            (strength>=InpTrendScore? REGIME_BEAR : REGIME_RANGE));
      else
        {
         if(atr_ratio>=InpHighVolATRRatio)          rg=REGIME_HIGH_VOLATILITY;
         else if(atr_ratio<=InpLowVolATRRatio)      rg=REGIME_LOW_LIQUIDITY;
         else if(st.structure==STRUCT_TRANSITION)   rg=REGIME_TRANSITION;
         else                                        rg=REGIME_RANGE;
        }

      st.regime=rg;
      st.trend_confidence=strength/100.0;
      st.bull_confidence=(bull? strength/100.0 : 0.0);
      st.bear_confidence=(bear? strength/100.0 : 0.0);
     }
  };

#endif // MTSR2_REGIMEENGINE_MQH
//+------------------------------------------------------------------+
