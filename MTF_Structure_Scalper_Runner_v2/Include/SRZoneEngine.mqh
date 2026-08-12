//+------------------------------------------------------------------+
//|                                                 SRZoneEngine.mqh |
//|      Dynamic support/resistance zones (SPEC v2.0 sec 20-25).      |
//|      Sources: HTF swings + prev day/week H/L, clustered, scored.  |
//+------------------------------------------------------------------+
#ifndef MTSR2_SRZONEENGINE_MQH
#define MTSR2_SRZONEENGINE_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "MarketData.mqh"
#include "SwingEngine.mqh"
#include "Inputs.mqh"
#include "Utils.mqh"

class CSRZoneEngine
  {
private:
   CMarketData      *m_data;
   CSwingEngine     *m_swing;
   string            m_symbol;
   double            m_point;
   ulong             m_next_id;

   SRZone            m_zones[];
   // parallel accumulators used during a rebuild
   double            m_imp[];       // importance per zone
   double            m_wsum[];      // sum of weights
   double            m_wprice[];    // sum weight*price

   double            SpreadPrice() const
     {
      double a=SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      double b=SymbolInfoDouble(m_symbol,SYMBOL_BID);
      double s=a-b; if(s<=0.0) s=(double)SymbolInfoInteger(m_symbol,SYMBOL_SPREAD)*m_point;
      return MathMax(s,0.0);
     }
   double            Importance(const int idx) const
     {
      switch(idx)
        { case IDX_D1: return 1.00; case IDX_H4: return 0.90; case IDX_H2: return 0.80;
          case IDX_H1: return 0.70; case IDX_M15:return 0.55; }
      return 0.40;
     }
   double            ClusterMult(const int idx) const
     {
      switch(idx)
        { case IDX_D1: return InpSRClusterATRD1; case IDX_H4: return InpSRClusterATRH4;
          case IDX_H2: return InpSRClusterATRH2; case IDX_H1: return InpSRClusterATRH1;
          case IDX_M15:return InpSRClusterATRM15; }
      return 0.15;
     }
   double            RefATR() const
     {
      int order[5]={IDX_H1,IDX_M15,IDX_H4,IDX_H2,IDX_D1};
      for(int i=0;i<5;i++) if(m_data.Enabled(order[i]) && m_data.ATR(order[i])>0.0) return m_data.ATR(order[i]);
      return m_point*100.0;
     }

   void              AddCandidate(SRZone &cand[],double &imp[],int &n,
                                  const double price,const ENUM_TIMEFRAMES tf,
                                  const double halfw,const double importance,const bool bos_origin)
     {
      ArrayResize(cand,n+1); ArrayResize(imp,n+1);
      cand[n].Reset();
      cand[n].id=m_next_id++;
      cand[n].source_tf=tf;
      cand[n].center=price;
      cand[n].lower=price-halfw;
      cand[n].upper=price+halfw;
      cand[n].touches=1;
      cand[n].bos_origin=bos_origin;
      cand[n].active=true;
      imp[n]=importance;
      n++;
     }

   void              SortByCenter(SRZone &cand[],double &imp[],const int n)
     {
      for(int i=0;i<n-1;i++)
        {
         int mi=i;
         for(int j=i+1;j<n;j++) if(cand[j].center<cand[mi].center) mi=j;
         if(mi!=i)
           { SRZone tz=cand[i]; cand[i]=cand[mi]; cand[mi]=tz;
             double ti=imp[i]; imp[i]=imp[mi]; imp[mi]=ti; }
        }
     }

   double            ScoreZone(const SRZone &z,const double imp,const int confluence) const
     {
      double f_tf     = Clamp01(imp);
      double f_touch  = Clamp01((double)z.touches/4.0);
      double age_max  = MathMax(1.0,(double)InpSRMaxAgeBars);
      double f_fresh  = Clamp01(1.0-(double)z.age_bars/age_max);
      double f_reject = Clamp01((double)z.touches/3.0);       // proxy until reaction tracking
      double f_conf   = Clamp01((double)confluence/3.0);
      double f_liq    = z.has_liquidity?1.0:0.0;
      double f_bos    = z.bos_origin?1.0:0.0;
      double f_vol    = 0.5;                                   // neutral placeholder
      double num = InpSRWeightTF*f_tf + InpSRWeightTouches*f_touch +
                   InpSRWeightFreshness*f_fresh + InpSRWeightRejection*f_reject +
                   InpSRWeightConfluence*f_conf + InpSRWeightLiquidity*f_liq +
                   InpSRWeightBOSOrigin*f_bos + InpSRWeightVolume*f_vol;
      double den = InpSRWeightTF+InpSRWeightTouches+InpSRWeightFreshness+InpSRWeightRejection+
                   InpSRWeightConfluence+InpSRWeightLiquidity+InpSRWeightBOSOrigin+InpSRWeightVolume;
      if(den<=0.0) return 0.0;
      return Clamp(num/den*100.0,0.0,100.0);
     }

public:
                     CSRZoneEngine() { m_data=NULL; m_swing=NULL; m_symbol=""; m_point=0.0; m_next_id=1; }
   void              Init(CMarketData *data,CSwingEngine *swing,const string sym)
     {
      m_data=data; m_swing=swing; m_symbol=sym;
      m_point=SymbolInfoDouble(sym,SYMBOL_POINT); if(m_point<=0.0) m_point=_Point;
     }

   int               Count() const { return ArraySize(m_zones); }
   bool              Get(const int i,SRZone &out) const
     { if(i<0||i>=ArraySize(m_zones)) return false; out=m_zones[i]; return true; }

   //--- full rebuild from current swings + prev day/week levels -----
   void              Rebuild()
     {
      SRZone cand[]; double imp[]; int n=0;
      double spr=SpreadPrice();
      int srtf[5]={IDX_D1,IDX_H4,IDX_H2,IDX_H1,IDX_M15};

      for(int t=0;t<5;t++)
        {
         int idx=srtf[t];
         if(!m_data.Enabled(idx)) continue;
         CSwingSeries *ser=m_swing.Series(idx);
         if(ser==NULL) continue;
         double atr=m_data.ATR(idx);
         double halfw=MathMax(atr*ClusterMult(idx),
                      MathMax(InpSRMinZonePts*m_point/2.0, spr*1.5));
         int cnt=ser.Count();
         int lo=MathMax(0,cnt-12);          // last 12 swings per TF
         for(int i=lo;i<cnt;i++)
           {
            SwingPoint sp; if(!ser.Get(i,sp)) continue;
            AddCandidate(cand,imp,n,sp.price,m_data.Period(idx),halfw,Importance(idx),sp.broken);
            if(n>=300) break;
           }
        }

      //--- previous day / week high & low ---------------------------
      if(InpUsePrevDayHL)
        {
         double dh=iHigh(m_symbol,PERIOD_D1,1), dl=iLow(m_symbol,PERIOD_D1,1);
         double atr=MathMax(m_data.ATR(IDX_D1),m_point*50);
         double hw=MathMax(atr*InpSRClusterATRD1,InpSRMinZonePts*m_point/2.0);
         if(dh>0){ AddCandidate(cand,imp,n,dh,PERIOD_D1,hw,1.0,false); cand[n-1].has_liquidity=true; }
         if(dl>0){ AddCandidate(cand,imp,n,dl,PERIOD_D1,hw,1.0,false); cand[n-1].has_liquidity=true; }
        }
      if(InpUsePrevWeekHL)
        {
         double wh=iHigh(m_symbol,PERIOD_W1,1), wl=iLow(m_symbol,PERIOD_W1,1);
         double atr=MathMax(m_data.ATR(IDX_D1),m_point*50);
         double hw=MathMax(atr*InpSRClusterATRD1,InpSRMinZonePts*m_point/2.0);
         if(wh>0){ AddCandidate(cand,imp,n,wh,PERIOD_W1,hw,1.0,false); cand[n-1].has_liquidity=true; }
         if(wl>0){ AddCandidate(cand,imp,n,wl,PERIOD_W1,hw,1.0,false); cand[n-1].has_liquidity=true; }
        }

      if(n==0) { ArrayResize(m_zones,0); return; }

      SortByCenter(cand,imp,n);
      double thr=InpSRMergeATR*RefATR();

      //--- merge adjacent candidates into zones ---------------------
      ArrayResize(m_zones,0);
      ArrayResize(m_wsum,0); ArrayResize(m_wprice,0); ArrayResize(m_imp,0);
      for(int i=0;i<n;i++)
        {
         int zc=ArraySize(m_zones);
         bool merge=false;
         if(zc>0)
           {
            double dc=MathAbs(cand[i].center-m_zones[zc-1].center);
            bool overlap=(cand[i].lower<=m_zones[zc-1].upper && cand[i].upper>=m_zones[zc-1].lower);
            if(dc<=thr || overlap) merge=true;
           }
         if(merge)
           {
            int z=zc-1;
            double w=imp[i];
            m_wsum[z]+=w; m_wprice[z]+=w*cand[i].center;
            m_zones[z].touches+=1;
            m_zones[z].lower=MathMin(m_zones[z].lower,cand[i].lower);
            m_zones[z].upper=MathMax(m_zones[z].upper,cand[i].upper);
            if(imp[i]>m_imp[z]) m_imp[z]=imp[i];
            m_zones[z].bos_origin=(m_zones[z].bos_origin||cand[i].bos_origin);
            m_zones[z].has_liquidity=(m_zones[z].has_liquidity||cand[i].has_liquidity);
           }
         else
           {
            ArrayResize(m_zones,zc+1);
            ArrayResize(m_wsum,zc+1); ArrayResize(m_wprice,zc+1); ArrayResize(m_imp,zc+1);
            m_zones[zc]=cand[i];
            m_wsum[zc]=imp[i]; m_wprice[zc]=imp[i]*cand[i].center; m_imp[zc]=imp[i];
           }
        }

      //--- finalize: center, type, age, score -----------------------
      double bid=SymbolInfoDouble(m_symbol,SYMBOL_BID);
      datetime now=TimeCurrent();
      int zn=ArraySize(m_zones);
      for(int z=0;z<zn;z++)
        {
         if(m_wsum[z]>0.0) m_zones[z].center=m_wprice[z]/m_wsum[z];
         double halfw=0.5*(m_zones[z].upper-m_zones[z].lower);
         m_zones[z].lower=m_zones[z].center-halfw;
         m_zones[z].upper=m_zones[z].center+halfw;
         m_zones[z].created=now;
         m_zones[z].age_bars=0;      // freshness tracking refined in a later build
         m_zones[z].fresh=(m_zones[z].touches<=2);
         m_zones[z].type=(m_zones[z].center>=bid?ZONE_RESISTANCE:ZONE_SUPPORT);
         int confluence=m_zones[z].touches;
         m_zones[z].score=ScoreZone(m_zones[z],m_imp[z],confluence);
        }
     }

   //--- nearest zones relative to a price --------------------------
   bool              NearestResistance(const double price,const double min_score,SRZone &out) const
     {
      double best=DBL_MAX; bool found=false;
      for(int i=0;i<ArraySize(m_zones);i++)
        {
         if(m_zones[i].score<min_score) continue;
         if(m_zones[i].center>price && m_zones[i].center-price<best)
           { best=m_zones[i].center-price; out=m_zones[i]; found=true; }
        }
      return found;
     }
   bool              NearestSupport(const double price,const double min_score,SRZone &out) const
     {
      double best=DBL_MAX; bool found=false;
      for(int i=0;i<ArraySize(m_zones);i++)
        {
         if(m_zones[i].score<min_score) continue;
         if(m_zones[i].center<price && price-m_zones[i].center<best)
           { best=price-m_zones[i].center; out=m_zones[i]; found=true; }
        }
      return found;
     }
  };

#endif // MTSR2_SRZONEENGINE_MQH
//+------------------------------------------------------------------+
