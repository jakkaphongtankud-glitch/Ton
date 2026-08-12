//+------------------------------------------------------------------+
//|                                             LiquidityEngine.mqh |
//|      Liquidity pools + sweep detection (SPEC v2.0 sec 26-31).    |
//+------------------------------------------------------------------+
#ifndef MTSR2_LIQUIDITYENGINE_MQH
#define MTSR2_LIQUIDITYENGINE_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "MarketData.mqh"
#include "SwingEngine.mqh"
#include "Inputs.mqh"
#include "Utils.mqh"

class CLiquidityEngine
  {
private:
   CMarketData      *m_data;
   CSwingEngine     *m_swing;
   string            m_symbol;
   double            m_point;
   ulong             m_next_id;

   LiquidityPool     m_pools[];

   // most recent confirmed sweep (persists across pool rebuilds)
   ENUM_SIGNAL_SIDE  m_sweep_side;
   double            m_sweep_price;
   datetime          m_sweep_time;
   ENUM_TIMEFRAMES   m_sweep_tf;

   double            Importance(const int idx) const
     {
      switch(idx)
        { case IDX_D1: return 1.00; case IDX_H4: return 0.90; case IDX_H2: return 0.80;
          case IDX_H1: return 0.70; case IDX_M15:return 0.55; }
      return 0.40;
     }
   void              AddPool(const double price,const ENUM_TIMEFRAMES tf,
                             const ENUM_SIGNAL_SIDE expected_side,const double strength)
     {
      int n=ArraySize(m_pools);
      ArrayResize(m_pools,n+1);
      m_pools[n].Reset();
      m_pools[n].id=m_next_id++;
      m_pools[n].price=price;
      m_pools[n].tf=tf;
      m_pools[n].expected_sweep_side=expected_side;
      m_pools[n].strength=strength;
      m_pools[n].touches=1;
      m_pools[n].active=true;
     }

public:
                     CLiquidityEngine()
     { m_data=NULL; m_swing=NULL; m_symbol=""; m_point=0.0; m_next_id=1;
       m_sweep_side=SIGNAL_NONE; m_sweep_price=0.0; m_sweep_time=0; m_sweep_tf=PERIOD_CURRENT; }

   void              Init(CMarketData *data,CSwingEngine *swing,const string sym)
     {
      m_data=data; m_swing=swing; m_symbol=sym;
      m_point=SymbolInfoDouble(sym,SYMBOL_POINT); if(m_point<=0.0) m_point=_Point;
     }

   int               Count() const { return ArraySize(m_pools); }
   bool              Get(const int i,LiquidityPool &out) const
     { if(i<0||i>=ArraySize(m_pools)) return false; out=m_pools[i]; return true; }

   ENUM_SIGNAL_SIDE  LastSweepSide() const { return m_sweep_side; }
   datetime          LastSweepTime() const { return m_sweep_time; }
   double            LastSweepPrice() const { return m_sweep_price; }

   bool              RecentSweep(const ENUM_SIGNAL_SIDE side,const int max_age_sec) const
     {
      if(m_sweep_side!=side || m_sweep_time==0) return false;
      return((TimeCurrent()-m_sweep_time)<=max_age_sec);
     }

   //--- rebuild liquidity pools from HTF swings + prev day/week ------
   void              RebuildPools()
     {
      ArrayResize(m_pools,0);
      int srtf[5]={IDX_D1,IDX_H4,IDX_H2,IDX_H1,IDX_M15};
      for(int t=0;t<5;t++)
        {
         int idx=srtf[t];
         if(!m_data.Enabled(idx)) continue;
         CSwingSeries *ser=m_swing.Series(idx);
         if(ser==NULL) continue;
         double atr=MathMax(m_data.ATR(idx),m_point);
         double eq=atr*InpEqualHighLowATR;
         int cnt=ser.Count();
         int lo=MathMax(0,cnt-16);
         // collect recent highs/lows, detect equal-level clustering
         double prevHigh=-1, prevLow=-1;
         for(int i=lo;i<cnt;i++)
           {
            SwingPoint sp; if(!ser.Get(i,sp)) continue;
            double strength=Importance(idx);
            if(sp.type==SWING_HIGH)
              {
               if(prevHigh>0 && MathAbs(sp.price-prevHigh)<=eq) strength+=0.5; // equal high
               AddPool(sp.price,m_data.Period(idx),SIGNAL_SELL,strength);
               prevHigh=sp.price;
              }
            else
              {
               if(prevLow>0 && MathAbs(sp.price-prevLow)<=eq) strength+=0.5;   // equal low
               AddPool(sp.price,m_data.Period(idx),SIGNAL_BUY,strength);
               prevLow=sp.price;
              }
           }
        }
      if(InpUsePrevDayHL)
        {
         double dh=iHigh(m_symbol,PERIOD_D1,1), dl=iLow(m_symbol,PERIOD_D1,1);
         if(dh>0) AddPool(dh,PERIOD_D1,SIGNAL_SELL,1.2);
         if(dl>0) AddPool(dl,PERIOD_D1,SIGNAL_BUY ,1.2);
        }
      if(InpUsePrevWeekHL)
        {
         double wh=iHigh(m_symbol,PERIOD_W1,1), wl=iLow(m_symbol,PERIOD_W1,1);
         if(wh>0) AddPool(wh,PERIOD_W1,SIGNAL_SELL,1.3);
         if(wl>0) AddPool(wl,PERIOD_W1,SIGNAL_BUY ,1.3);
        }
     }

   //--- detect a sweep on the last CLOSED bar of a lower timeframe --
   bool              DetectSweeps(const int idx)
     {
      if(idx!=IDX_M15 && idx!=IDX_M5 && idx!=IDX_M1) return false;
      MqlRates r; if(!m_data.Rate(idx,1,r)) return false;
      double atr=MathMax(m_data.ATR(idx),m_point);
      double minPen=atr*InpSweepMinPenATR;
      double maxPen=atr*InpSweepMaxPenATR;
      double reclaim=atr*InpSweepReclaimATR;
      double denom=MathMax(CandleRange(r),m_point);
      double uwr=CandleUpperWick(r)/denom;
      double lwr=CandleLowerWick(r)/denom;
      bool found=false;

      for(int i=0;i<ArraySize(m_pools);i++)
        {
         if(!m_pools[i].active || m_pools[i].swept) continue;
         double L=m_pools[i].price;
         if(m_pools[i].expected_sweep_side==SIGNAL_SELL)   // high pool
           {
            double pen=r.high-L;
            if(pen>minPen && pen<maxPen && uwr>=InpMinSweepWickRatio &&
               (!InpRequireSweepCloseBack || r.close<L+reclaim))
              {
               m_pools[i].swept=true; m_pools[i].swept_time=r.time;
               m_sweep_side=SIGNAL_SELL; m_sweep_price=L; m_sweep_time=r.time;
               m_sweep_tf=m_data.Period(idx); found=true;
              }
           }
         else                                              // low pool
           {
            double pen=L-r.low;
            if(pen>minPen && pen<maxPen && lwr>=InpMinSweepWickRatio &&
               (!InpRequireSweepCloseBack || r.close>L-reclaim))
              {
               m_pools[i].swept=true; m_pools[i].swept_time=r.time;
               m_sweep_side=SIGNAL_BUY; m_sweep_price=L; m_sweep_time=r.time;
               m_sweep_tf=m_data.Period(idx); found=true;
              }
           }
        }
      return found;
     }
  };

#endif // MTSR2_LIQUIDITYENGINE_MQH
//+------------------------------------------------------------------+
