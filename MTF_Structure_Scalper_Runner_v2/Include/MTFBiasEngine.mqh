//+------------------------------------------------------------------+
//|                                               MTFBiasEngine.mqh |
//|      Weighted-hierarchy MTF bias + H2 bridge (SPEC v2.0 sec 34-36)|
//|      Not a majority vote: D1/H4/H2/H1/M15 weighted; M5/M1 excluded.|
//+------------------------------------------------------------------+
#ifndef MTSR2_MTFBIASENGINE_MQH
#define MTSR2_MTFBIASENGINE_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "MarketData.mqh"
#include "Inputs.mqh"
#include "Utils.mqh"

//--- output context shared with setup/score engines ------------------
struct BiasContext
  {
   double            bias_pct;          // -100..+100 (positive = bullish)
   ENUM_SIGNAL_SIDE  side;              // dominant directional bias
   bool              strong;            // |bias| >= strong threshold
   bool              pullback;          // HTF trend + LTF counter pullback
   bool              early_transition;  // H2 warns before H4 confirms
   string            label;
   bool              valid;

   void Reset()
     { bias_pct=0; side=SIGNAL_NONE; strong=false; pullback=false;
       early_transition=false; label=""; valid=false; }
  };

class CMTFBiasEngine
  {
private:
   CMarketData      *m_data;

   double            DirVal(const ENUM_MARKET_REGIME rg) const
     {
      switch(rg)
        {
         case REGIME_STRONG_BULL: return  1.00;
         case REGIME_BULL:        return  0.70;
         case REGIME_STRONG_BEAR: return -1.00;
         case REGIME_BEAR:        return -0.70;
        }
      return 0.0;   // range / transition / vol / unknown
     }
   bool              IsBull(const ENUM_STRUCTURE_DIR d) const { return d==STRUCT_BULL; }
   bool              IsBear(const ENUM_STRUCTURE_DIR d) const { return d==STRUCT_BEAR; }

public:
                     CMTFBiasEngine() { m_data=NULL; }
   void              Init(CMarketData *data) { m_data=data; }

   void              Build(const TFState &tf[],BiasContext &ctx)
     {
      ctx.Reset();

      int    idxs[5]={IDX_D1,IDX_H4,IDX_H2,IDX_H1,IDX_M15};
      double wts [5]={InpWeightD1,InpWeightH4,InpWeightH2,InpWeightH1,InpWeightM15};

      double raw=0.0, sumw=0.0;
      for(int i=0;i<5;i++)
        {
         int idx=idxs[i];
         if(!m_data.Enabled(idx) || !tf[idx].data_ready) continue;
         raw += wts[i]*DirVal(tf[idx].regime);
         sumw+= wts[i];
        }
      if(sumw<=0.0) { ctx.valid=false; return; }

      ctx.bias_pct = raw/sumw*100.0;
      ctx.valid=true;
      ctx.side=(ctx.bias_pct>=InpMinBiasScore? SIGNAL_BUY :
               (ctx.bias_pct<=-InpMinBiasScore? SIGNAL_SELL : SIGNAL_NONE));
      ctx.strong=(MathAbs(ctx.bias_pct)>=InpStrongBiasScore);

      //--- H2 BRIDGE RULE (SPEC sec 36) -----------------------------
      ENUM_STRUCTURE_DIR d1=tf[IDX_D1].structure;
      ENUM_STRUCTURE_DIR h4=tf[IDX_H4].structure;
      ENUM_STRUCTURE_DIR h2=tf[IDX_H2].structure;
      ENUM_STRUCTURE_DIR h1=tf[IDX_H1].structure;

      // Bullish HTF + H1 pullback -> do NOT read as bear trend
      if(IsBull(d1) && IsBull(h4) && IsBull(h2) && IsBear(h1))
        { ctx.pullback=true; ctx.side=SIGNAL_BUY; ctx.label="HTF_PULLBACK_BULL"; }
      else if(IsBear(d1) && IsBear(h4) && IsBear(h2) && IsBull(h1))
        { ctx.pullback=true; ctx.side=SIGNAL_SELL; ctx.label="HTF_PULLBACK_BEAR"; }

      // H2 transitions before H4 confirms -> early warning, reduce counter side
      if(IsBull(d1) && IsBull(h4) && IsBear(h2) && IsBear(h1))
        { ctx.early_transition=true; ctx.label="EARLY_HTF_TRANSITION_BEAR"; ctx.bias_pct*=0.6; }
      else if(IsBear(d1) && IsBear(h4) && IsBull(h2) && IsBull(h1))
        { ctx.early_transition=true; ctx.label="EARLY_HTF_TRANSITION_BULL"; ctx.bias_pct*=0.6; }

      if(StringLen(ctx.label)==0)
        {
         if(ctx.side==SIGNAL_BUY)      ctx.label=(ctx.strong?"STRONG_BULL":"BULL");
         else if(ctx.side==SIGNAL_SELL)ctx.label=(ctx.strong?"STRONG_BEAR":"BEAR");
         else                          ctx.label="NEUTRAL";
        }
     }
  };

#endif // MTSR2_MTFBIASENGINE_MQH
//+------------------------------------------------------------------+
