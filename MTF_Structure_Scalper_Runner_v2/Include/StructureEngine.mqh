//+------------------------------------------------------------------+
//|                                              StructureEngine.mqh |
//|      BOS / CHoCH / HH-HL-LH-LL / protected swings                  |
//|      SPEC v2.0 sections 10-19. Confirmed bars only, no repaint.    |
//+------------------------------------------------------------------+
#ifndef MTSR2_STRUCTUREENGINE_MQH
#define MTSR2_STRUCTUREENGINE_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "MarketData.mqh"
#include "SwingEngine.mqh"
#include "Inputs.mqh"
#include "Utils.mqh"

class CStructureEngine
  {
private:
   CMarketData      *m_data;
   CSwingEngine     *m_swing;
   CLogger          *m_log;
   string            m_symbol;
   double            m_point;

   double            SpreadPrice() const
     {
      double ask=SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      double bid=SymbolInfoDouble(m_symbol,SYMBOL_BID);
      double s=ask-bid;
      if(s<=0.0) s=(double)SymbolInfoInteger(m_symbol,SYMBOL_SPREAD)*m_point;
      return MathMax(s,0.0);
     }

   double            BreakBuffer(const int idx) const
     {
      double atr=m_data.ATR(idx);
      double b1=InpBOSMinPoints*m_point;
      double b2=atr*InpBOSMinATR;
      double b3=SpreadPrice()*InpBOSSpreadMultiplier;
      return MathMax(b1,MathMax(b2,b3));
     }
   double            CHoCHBuffer(const int idx) const
     {
      double atr=m_data.ATR(idx);
      double b2=atr*InpCHoCHMinATR;
      double b3=SpreadPrice()*InpCHoCHSpreadMultiplier;
      return MathMax(b2,b3);
     }

   double            BosQuality(const int idx,const MqlRates &r,const double dist_beyond) const
     {
      double atr=MathMax(m_data.ATR(idx),m_point);
      double f_dist=Clamp01(dist_beyond/(atr*0.50));
      double f_body=Clamp01(CandleBodyRatio(r,m_point));
      double f_disp=Clamp01(CandleRange(r)/(atr*MathMax(InpDisplacementATR,0.01)));
      double score=(0.40*f_dist + 0.35*f_body + 0.25*f_disp)*100.0;
      return Clamp(score,0.0,100.0);
     }

   // Simplified CHoCH confidence (SPEC sec 19). Liquidity/HTF-zone
   // features are neutral until those engines exist (later builds).
   double            ChochScore(const int idx,const MqlRates &r,const bool failed_ext) const
     {
      double atr=MathMax(m_data.ATR(idx),m_point);
      double f_struct = 1.0;                                   // 25%
      double f_disp   = Clamp01(CandleRange(r)/(atr*0.60));    // 20%
      double f_failed = failed_ext?1.0:0.4;                    // 15%
      double f_liq    = 0.0;                                   // 15% (pending)
      double f_htf    = 0.0;                                   // 15% (pending)
      double f_vol    = 0.5;                                   // 10% (neutral)
      double s=(0.25*f_struct + 0.20*f_disp + 0.15*f_failed +
                0.15*f_liq   + 0.15*f_htf  + 0.10*f_vol)*100.0;
      return Clamp(s,0.0,100.0);
     }

   void              Classify(const TFState &st,ENUM_STRUCTURE_DIR &dir) const
     {
      bool haveH=(st.last_high.time>0 && st.prev_high.time>0);
      bool haveL=(st.last_low.time>0  && st.prev_low.time>0);
      if(haveH && haveL)
        {
         bool hh=(st.last_high.price>st.prev_high.price);
         bool hl=(st.last_low.price >st.prev_low.price);
         bool lh=(st.last_high.price<st.prev_high.price);
         bool ll=(st.last_low.price <st.prev_low.price);
         if(hh && hl) { dir=STRUCT_BULL; return; }
         if(lh && ll) { dir=STRUCT_BEAR; return; }
         dir=STRUCT_TRANSITION; return;
        }
      dir=STRUCT_UNKNOWN;
     }

public:
                     CStructureEngine() { m_data=NULL; m_swing=NULL; m_log=NULL; m_symbol=""; m_point=0.0; }

   void              Init(CMarketData *data,CSwingEngine *swing,CLogger *log,const string sym)
     {
      m_data=data; m_swing=swing; m_log=log; m_symbol=sym;
      m_point=SymbolInfoDouble(sym,SYMBOL_POINT);
      if(m_point<=0.0) m_point=_Point;
     }

   //--- evaluate structure on the last CLOSED bar (shift 1) ---------
   void              Update(const int idx,TFState &st)
     {
      // reset per-bar event flags
      st.bos_bull=false; st.bos_bear=false;
      st.choch_bull=false; st.choch_bear=false;

      CSwingSeries *ser=m_swing.Series(idx);
      if(ser==NULL) return;

      // baseline classification if direction still unknown
      if(st.structure==STRUCT_UNKNOWN)
        {
         ENUM_STRUCTURE_DIR d; Classify(st,d); st.structure=d;
        }

      MqlRates r1;
      if(!m_data.Rate(idx,1,r1)) return;

      ENUM_STRUCTURE_DIR dir0=st.structure;   // capture pre-event direction

      double buffer_b=BreakBuffer(idx);
      double buffer_c=CHoCHBuffer(idx);

      SwingPoint refHigh,refLow;
      bool haveHigh=ser.LastUnbroken(SWING_HIGH,refHigh);
      bool haveLow =ser.LastUnbroken(SWING_LOW ,refLow);

      double breakUpPrice   = InpRequireCloseForBOS ? r1.close : r1.high;
      double breakDownPrice = InpRequireCloseForBOS ? r1.close : r1.low;

      double body_ratio = CandleBodyRatio(r1,m_point);
      bool   body_ok    = (body_ratio>=InpMinBodyRatioForBOS);
      bool   disp_ok    = (!InpRequireDisplacement) ||
                          (CandleRange(r1) >= m_data.ATR(idx)*InpDisplacementATR);

      //--- BULLISH break -------------------------------------------
      bool bull_is_choch=(dir0==STRUCT_BEAR);
      double bull_buf=(bull_is_choch? buffer_c : buffer_b);
      if(haveHigh && breakUpPrice > refHigh.price + bull_buf)
        {
         bool is_choch = bull_is_choch;
         if(is_choch)
           {
            // break of the protected LH -> change of character up
            bool failed_ext = (st.last_high.price < st.prev_high.price); // was making LH
            st.choch_bull=true;
            st.choch_score=ChochScore(idx,r1,failed_ext);
            st.structure=STRUCT_BULL;
            st.last_event=STRUCT_CHOCH_BULL;
            st.last_event_time=r1.time;
            m_swing.MarkBroken(idx,refHigh.time,r1.time);
            if(haveLow) st.protected_low=refLow.price;
            if(m_log!=NULL) m_log.Debug(StringFormat("[%s] CHoCH BULL @%.2f score=%.0f",
                              TFIndexToName(idx),r1.close,st.choch_score));
           }
         else if(body_ok && disp_ok)
           {
            double dist=breakUpPrice-(refHigh.price+bull_buf);
            st.bos_bull=true;
            st.bos_score=BosQuality(idx,r1,dist);
            st.structure=STRUCT_BULL;
            st.last_event=STRUCT_BOS_BULL;
            st.last_event_time=r1.time;
            m_swing.MarkBroken(idx,refHigh.time,r1.time);
            if(haveLow) st.protected_low=refLow.price;    // HL that led to BOS
            if(m_log!=NULL) m_log.Debug(StringFormat("[%s] BOS BULL @%.2f q=%.0f",
                              TFIndexToName(idx),r1.close,st.bos_score));
           }
        }

      bool bull_fired=(st.bos_bull || st.choch_bull);

      //--- BEARISH break -------------------------------------------
      bool bear_is_choch=(dir0==STRUCT_BULL);
      double bear_buf=(bear_is_choch? buffer_c : buffer_b);
      if(!bull_fired && haveLow && breakDownPrice < refLow.price - bear_buf)
        {
         bool is_choch = bear_is_choch;
         if(is_choch)
           {
            bool failed_ext = (st.last_low.price > st.prev_low.price); // was making HL
            st.choch_bear=true;
            st.choch_score=ChochScore(idx,r1,failed_ext);
            st.structure=STRUCT_BEAR;
            st.last_event=STRUCT_CHOCH_BEAR;
            st.last_event_time=r1.time;
            m_swing.MarkBroken(idx,refLow.time,r1.time);
            if(haveHigh) st.protected_high=refHigh.price;
            if(m_log!=NULL) m_log.Debug(StringFormat("[%s] CHoCH BEAR @%.2f score=%.0f",
                              TFIndexToName(idx),r1.close,st.choch_score));
           }
         else if(body_ok && disp_ok)
           {
            double dist=(refLow.price-bear_buf)-breakDownPrice;
            st.bos_bear=true;
            st.bos_score=BosQuality(idx,r1,dist);
            st.structure=STRUCT_BEAR;
            st.last_event=STRUCT_BOS_BEAR;
            st.last_event_time=r1.time;
            m_swing.MarkBroken(idx,refLow.time,r1.time);
            if(haveHigh) st.protected_high=refHigh.price;
            if(m_log!=NULL) m_log.Debug(StringFormat("[%s] BOS BEAR @%.2f q=%.0f",
                              TFIndexToName(idx),r1.close,st.bos_score));
           }
        }

      //--- directional confidence (0..1) used by bias/score later ---
      double conf=0.0;
      if(st.structure==STRUCT_BULL || st.structure==STRUCT_BEAR)
         conf=Clamp01(0.5 + 0.5*Clamp01((st.bos_score>0?st.bos_score:st.choch_score)/100.0));
      else if(st.structure==STRUCT_TRANSITION) conf=0.3;
      st.trend_confidence=conf;
      st.bull_confidence=(st.structure==STRUCT_BULL? conf : 0.0);
      st.bear_confidence=(st.structure==STRUCT_BEAR? conf : 0.0);
     }
  };

#endif // MTSR2_STRUCTUREENGINE_MQH
//+------------------------------------------------------------------+
