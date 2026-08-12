//+------------------------------------------------------------------+
//|                                                  SwingEngine.mqh |
//|      Fractal swing detection (SPEC v2.0 sec 8,9). No repaint:      |
//|      a swing is confirmed only after 'Right' bars have CLOSED.     |
//+------------------------------------------------------------------+
#ifndef MTSR2_SWINGENGINE_MQH
#define MTSR2_SWINGENGINE_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "MarketData.mqh"
#include "Logger.mqh"

//--- Rolling swing history for one timeframe -------------------------
class CSwingSeries
  {
private:
   SwingPoint        m_pts[];      // chronological (oldest first)
   int               m_cap;

public:
                     CSwingSeries() { m_cap=100; ArrayResize(m_pts,0); }
   void              SetCap(const int c) { m_cap=MathMax(10,c); }
   void              Clear() { ArrayResize(m_pts,0); }
   int               Count() const { return ArraySize(m_pts); }
   bool              Get(const int i,SwingPoint &out) const
     {
      if(i<0 || i>=ArraySize(m_pts)) return false;
      out=m_pts[i]; return true;
     }
   datetime          NewestTime() const
     {
      int n=ArraySize(m_pts);
      return (n>0? m_pts[n-1].time : 0);
     }

   void              Append(const SwingPoint &sp)
     {
      int n=ArraySize(m_pts);
      ArrayResize(m_pts,n+1);
      m_pts[n]=sp;
      // trim from front if over capacity
      int over=ArraySize(m_pts)-m_cap;
      if(over>0)
        {
         for(int i=0;i+over<ArraySize(m_pts);i++) m_pts[i]=m_pts[i+over];
         ArrayResize(m_pts,m_cap);
        }
     }

   // most recent swing of a given type (0=last,1=prev)
   bool              LastOfType(const ENUM_SWING_TYPE t,const int back,SwingPoint &out) const
     {
      int seen=0;
      for(int i=ArraySize(m_pts)-1;i>=0;i--)
        {
         if(m_pts[i].type==t)
           {
            if(seen==back) { out=m_pts[i]; return true; }
            seen++;
           }
        }
      return false;
     }

   // most recent UNBROKEN swing of a given type (used as active S/R by structure)
   bool              LastUnbroken(const ENUM_SWING_TYPE t,SwingPoint &out) const
     {
      for(int i=ArraySize(m_pts)-1;i>=0;i--)
         if(m_pts[i].type==t && !m_pts[i].broken) { out=m_pts[i]; return true; }
      return false;
     }

   bool              MarkBrokenByTime(const datetime t,const datetime when)
     {
      for(int i=ArraySize(m_pts)-1;i>=0;i--)
         if(m_pts[i].time==t) { m_pts[i].broken=true; m_pts[i].broken_time=when; return true; }
      return false;
     }
  };

//====================================================================
//  CSwingEngine
//====================================================================
class CSwingEngine
  {
private:
   CMarketData      *m_data;
   CLogger          *m_log;
   CSwingSeries      m_series[TF_COUNT];
   int               m_left[TF_COUNT];
   int               m_right[TF_COUNT];
   bool              m_built[TF_COUNT];
   ulong             m_next_id;

   bool              IsSwingHigh(const int idx,const int s,const int left,const int right) const
     {
      double h=m_data.High(idx,s);
      for(int k=1;k<=left;k++)  if(!(h> m_data.High(idx,s+k))) return false;
      for(int k=1;k<=right;k++) if(!(h>=m_data.High(idx,s-k))) return false;
      return true;
     }
   bool              IsSwingLow(const int idx,const int s,const int left,const int right) const
     {
      double l=m_data.Low(idx,s);
      for(int k=1;k<=left;k++)  if(!(l< m_data.Low(idx,s+k))) return false;
      for(int k=1;k<=right;k++) if(!(l<=m_data.Low(idx,s-k))) return false;
      return true;
     }

   void              MakeSwing(const int idx,const int s,const ENUM_SWING_TYPE t,SwingPoint &sp)
     {
      sp.Reset();
      sp.id=m_next_id++;
      sp.tf=m_data.Period(idx);
      sp.type=t;
      sp.time=m_data.Time(idx,s);
      sp.shift=s;
      sp.price=(t==SWING_HIGH? m_data.High(idx,s): m_data.Low(idx,s));
      sp.atr=m_data.ATR(idx);
      sp.confirmed=true;
     }

public:
                     CSwingEngine() { m_data=NULL; m_log=NULL; m_next_id=1;
                        for(int i=0;i<TF_COUNT;i++){ m_left[i]=3; m_right[i]=3; m_built[i]=false; } }

   void              Init(CMarketData *data,CLogger *log,const int max_hist)
     {
      m_data=data; m_log=log;
      for(int i=0;i<TF_COUNT;i++) m_series[i].SetCap(max_hist);
     }
   void              SetLR(const int idx,const int left,const int right)
     {
      if(idx<0 || idx>=TF_COUNT) return;
      m_left[idx]=MathMax(1,left); m_right[idx]=MathMax(1,right);
     }

   CSwingSeries     *Series(const int idx) { return (idx>=0 && idx<TF_COUNT)? GetPointer(m_series[idx]) : NULL; }

   //--- full scan (first time a TF becomes ready) -------------------
   void              BuildInitial(const int idx)
     {
      if(idx<0 || idx>=TF_COUNT) return;
      m_series[idx].Clear();
      int left=m_left[idx], right=m_right[idx];
      int cnt=m_data.Bars(idx);
      int oldest=cnt-1-left;         // largest confirmable center shift
      int newest=right+1;            // smallest confirmable center shift (no repaint)
      for(int s=oldest;s>=newest;s--)
        {
         if(s<0) break;
         if(IsSwingHigh(idx,s,left,right)) { SwingPoint sp; MakeSwing(idx,s,SWING_HIGH,sp); m_series[idx].Append(sp); }
         else if(IsSwingLow(idx,s,left,right)) { SwingPoint sp; MakeSwing(idx,s,SWING_LOW,sp); m_series[idx].Append(sp); }
        }
      m_built[idx]=true;
     }

   //--- incremental scan on a new bar -------------------------------
   void              Update(const int idx)
     {
      if(idx<0 || idx>=TF_COUNT) return;
      if(!m_built[idx]) { BuildInitial(idx); return; }
      int left=m_left[idx], right=m_right[idx];
      datetime newest_time=m_series[idx].NewestTime();
      int scan_lo=right+1;
      int scan_hi=right+1+8;         // small robustness window against gaps
      for(int s=scan_hi;s>=scan_lo;s--)
        {
         if(s+left>=m_data.Bars(idx)) continue;
         datetime ct=m_data.Time(idx,s);
         if(ct<=newest_time) continue;      // already recorded / older
         if(IsSwingHigh(idx,s,left,right)) { SwingPoint sp; MakeSwing(idx,s,SWING_HIGH,sp); m_series[idx].Append(sp); }
         else if(IsSwingLow(idx,s,left,right)) { SwingPoint sp; MakeSwing(idx,s,SWING_LOW,sp); m_series[idx].Append(sp); }
        }
     }

   //--- push latest swings into the TFState -------------------------
   void              FillState(const int idx,TFState &st)
     {
      SwingPoint tmp;
      tmp.Reset(); if(m_series[idx].LastOfType(SWING_HIGH,0,tmp)) st.last_high=tmp; else st.last_high.Reset();
      tmp.Reset(); if(m_series[idx].LastOfType(SWING_HIGH,1,tmp)) st.prev_high=tmp; else st.prev_high.Reset();
      tmp.Reset(); if(m_series[idx].LastOfType(SWING_LOW,0,tmp))  st.last_low =tmp; else st.last_low.Reset();
      tmp.Reset(); if(m_series[idx].LastOfType(SWING_LOW,1,tmp))  st.prev_low =tmp; else st.prev_low.Reset();
     }

   void              MarkBroken(const int idx,const datetime swing_time,const datetime when)
     {
      if(idx<0 || idx>=TF_COUNT) return;
      m_series[idx].MarkBrokenByTime(swing_time,when);
     }
  };

#endif // MTSR2_SWINGENGINE_MQH
//+------------------------------------------------------------------+
