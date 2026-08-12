//+------------------------------------------------------------------+
//|                                                   MarketData.mqh |
//|      Multi-timeframe bar cache + ATR (SPEC v2.0 sec 5,6,7,81,82)   |
//+------------------------------------------------------------------+
#ifndef MTSR2_MARKETDATA_MQH
#define MTSR2_MARKETDATA_MQH

#include "Defs.mqh"
#include "Utils.mqh"
#include "Logger.mqh"

//--- Per-timeframe rolling bar series --------------------------------
class CBarSeries
  {
public:
   MqlRates          rates[];   // series indexed: [0]=current forming bar
   int               count;
                     CBarSeries() { count=0; ArraySetAsSeries(rates,true); }

   bool              Copy(const string sym,const ENUM_TIMEFRAMES tf,const int want)
     {
      ArraySetAsSeries(rates,true);
      int got=CopyRates(sym,tf,0,want,rates);
      count=(got>0?got:0);
      return(count>0);
     }
   // shift 0 = forming bar, 1 = last closed bar
   bool              Get(const int shift,MqlRates &out) const
     {
      if(shift<0 || shift>=count) return false;
      out=rates[shift];
      return true;
     }
   double            High(const int s)  const { return (s>=0 && s<count)? rates[s].high  : 0.0; }
   double            Low (const int s)  const { return (s>=0 && s<count)? rates[s].low   : 0.0; }
   double            Open(const int s)  const { return (s>=0 && s<count)? rates[s].open  : 0.0; }
   double            Close(const int s) const { return (s>=0 && s<count)? rates[s].close : 0.0; }
   datetime          Time(const int s)  const { return (s>=0 && s<count)? rates[s].time  : 0;   }
   long              Vol (const int s)  const { return (s>=0 && s<count)? rates[s].tick_volume : 0; }
  };

//====================================================================
//  CMarketData - owns all seven timeframe caches
//====================================================================
class CMarketData
  {
private:
   string            m_symbol;
   CLogger          *m_log;
   int               m_atr_period;
   int               m_atr_ref;

   ENUM_TIMEFRAMES   m_period[TF_COUNT];
   bool              m_enabled[TF_COUNT];
   int               m_bars_want[TF_COUNT];
   int               m_atr_handle[TF_COUNT];
   datetime          m_last_bar[TF_COUNT];

   CBarSeries        m_series[TF_COUNT];
   double            m_atr[TF_COUNT];
   double            m_atr_ratio[TF_COUNT];
   bool              m_ready[TF_COUNT];

   double            Median(double &arr[],const int n) const
     {
      if(n<=0) return 0.0;
      double tmp[]; ArrayResize(tmp,n);
      for(int i=0;i<n;i++) tmp[i]=arr[i];
      ArraySort(tmp);
      if(n%2==1) return tmp[n/2];
      return 0.5*(tmp[n/2-1]+tmp[n/2]);
     }

public:
                     CMarketData()
     {
      m_symbol=""; m_log=NULL; m_atr_period=14; m_atr_ref=50;
      for(int i=0;i<TF_COUNT;i++)
        {
         m_period[i]=TFIndexToPeriod(i);
         m_enabled[i]=false; m_bars_want[i]=500; m_atr_handle[i]=INVALID_HANDLE;
         m_last_bar[i]=0; m_atr[i]=0.0; m_atr_ratio[i]=1.0; m_ready[i]=false;
        }
     }
                    ~CMarketData() { ReleaseHandles(); }

   //--- configuration ----------------------------------------------
   void              SetLogger(CLogger *log) { m_log=log; }
   void              Enable(const int idx,const bool on,const int bars)
     {
      if(idx<0 || idx>=TF_COUNT) return;
      m_enabled[idx]=on; m_bars_want[idx]=bars;
     }

   bool              Init(const string sym,const int atr_period,const int atr_ref)
     {
      m_symbol=sym; m_atr_period=atr_period; m_atr_ref=atr_ref;
      for(int i=0;i<TF_COUNT;i++)
        {
         if(!m_enabled[i]) continue;
         m_atr_handle[i]=iATR(m_symbol,m_period[i],m_atr_period);
         if(m_atr_handle[i]==INVALID_HANDLE)
           {
            if(m_log!=NULL) m_log.Error(StringFormat("iATR handle failed for %s",TFIndexToName(i)));
            return false;
           }
        }
      return true;
     }

   void              ReleaseHandles()
     {
      for(int i=0;i<TF_COUNT;i++)
         if(m_atr_handle[i]!=INVALID_HANDLE)
           { IndicatorRelease(m_atr_handle[i]); m_atr_handle[i]=INVALID_HANDLE; }
     }

   //--- accessors ---------------------------------------------------
   string            Symbol()          const { return m_symbol; }
   bool              Enabled(const int idx) const { return (idx>=0 && idx<TF_COUNT)? m_enabled[idx]:false; }
   ENUM_TIMEFRAMES   Period(const int idx)  const { return (idx>=0 && idx<TF_COUNT)? m_period[idx]:PERIOD_CURRENT; }
   bool              Ready(const int idx)   const { return (idx>=0 && idx<TF_COUNT)? m_ready[idx]:false; }
   int               Bars(const int idx)    const { return (idx>=0 && idx<TF_COUNT)? m_series[idx].count:0; }
   double            ATR(const int idx)     const { return (idx>=0 && idx<TF_COUNT)? m_atr[idx]:0.0; }
   double            ATRRatio(const int idx)const { return (idx>=0 && idx<TF_COUNT)? m_atr_ratio[idx]:1.0; }

   double            High (const int idx,const int s) const { return m_series[idx].High(s);  }
   double            Low  (const int idx,const int s) const { return m_series[idx].Low(s);   }
   double            Open (const int idx,const int s) const { return m_series[idx].Open(s);  }
   double            Close(const int idx,const int s) const { return m_series[idx].Close(s); }
   datetime          Time (const int idx,const int s) const { return m_series[idx].Time(s);  }
   long              Vol  (const int idx,const int s) const { return m_series[idx].Vol(s);   }
   bool              Rate (const int idx,const int s,MqlRates &r) const { return m_series[idx].Get(s,r); }

   //--- new bar detection (consumes the transition) -----------------
   bool              IsNewBar(const int idx)
     {
      if(idx<0 || idx>=TF_COUNT || !m_enabled[idx]) return false;
      datetime t=iTime(m_symbol,m_period[idx],0);
      if(t==0) return false;
      if(t!=m_last_bar[idx]) { m_last_bar[idx]=t; return true; }
      return false;
     }

   //--- refresh one timeframe: rates + ATR --------------------------
   bool              Refresh(const int idx)
     {
      if(idx<0 || idx>=TF_COUNT || !m_enabled[idx]) return false;

      if(!m_series[idx].Copy(m_symbol,m_period[idx],m_bars_want[idx]))
        { m_ready[idx]=false; return false; }

      int need=MathMax(m_atr_ref+2,m_atr_period+2);
      double buf[]; ArraySetAsSeries(buf,true);
      int got=CopyBuffer(m_atr_handle[idx],0,0,need,buf);
      if(got>2)
        {
         m_atr[idx]=buf[1];                       // last closed bar ATR
         int refn=MathMin(m_atr_ref,got-1);
         double window[]; ArrayResize(window,refn);
         for(int k=0;k<refn;k++) window[k]=buf[k+1];
         double med=Median(window,refn);
         m_atr_ratio[idx]=(med>0.0? m_atr[idx]/med : 1.0);
        }
      return true;
     }

   //--- evaluate readiness against minimum bar requirement ----------
   void              EvaluateReady(const int min_bars)
     {
      for(int i=0;i<TF_COUNT;i++)
        {
         if(!m_enabled[i]) { m_ready[i]=false; continue; }
         m_ready[i]=(m_series[i].count>=min_bars && m_atr[i]>0.0);
        }
     }

   bool              AllReady() const
     {
      for(int i=0;i<TF_COUNT;i++)
         if(m_enabled[i] && !m_ready[i]) return false;
      return true;
     }
  };

#endif // MTSR2_MARKETDATA_MQH
//+------------------------------------------------------------------+
