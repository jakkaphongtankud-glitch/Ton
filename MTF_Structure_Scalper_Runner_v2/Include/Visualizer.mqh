//+------------------------------------------------------------------+
//|                                                  Visualizer.mqh |
//|      Debug chart objects for the CHART timeframe only:            |
//|      swing arrows, protected-swing lines, last-event label.       |
//|      Used for Phase-1 visual validation (SPEC v2.0 sec 128).     |
//+------------------------------------------------------------------+
#ifndef MTSR2_VISUALIZER_MQH
#define MTSR2_VISUALIZER_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "SwingEngine.mqh"
#include "SRZoneEngine.mqh"
#include "Utils.mqh"

#define VIS_PREFIX "MTSR2_VIS_"

class CVisualizer
  {
private:
   long              m_chart;
   int               m_max_swings;

   void              DelPrefix(const string pfx)
     {
      int total=ObjectsTotal(m_chart,-1,-1);
      for(int i=total-1;i>=0;i--)
        {
         string nm=ObjectName(m_chart,i,-1,-1);
         if(StringFind(nm,pfx)==0) ObjectDelete(m_chart,nm);
        }
     }
   void              Arrow(const string nm,const datetime t,const double p,const int code,const color c,const bool up)
     {
      if(ObjectFind(m_chart,nm)<0) ObjectCreate(m_chart,nm,OBJ_ARROW,0,t,p);
      ObjectSetInteger(m_chart,nm,OBJPROP_TIME,0,t);
      ObjectSetDouble (m_chart,nm,OBJPROP_PRICE,0,p);
      ObjectSetInteger(m_chart,nm,OBJPROP_ARROWCODE,code);
      ObjectSetInteger(m_chart,nm,OBJPROP_COLOR,c);
      ObjectSetInteger(m_chart,nm,OBJPROP_WIDTH,1);
      ObjectSetInteger(m_chart,nm,OBJPROP_ANCHOR,(up?ANCHOR_TOP:ANCHOR_BOTTOM));
     }
   void              HLine(const string nm,const double p,const color c,const int style)
     {
      if(ObjectFind(m_chart,nm)<0) ObjectCreate(m_chart,nm,OBJ_HLINE,0,0,p);
      ObjectSetDouble (m_chart,nm,OBJPROP_PRICE,0,p);
      ObjectSetInteger(m_chart,nm,OBJPROP_COLOR,c);
      ObjectSetInteger(m_chart,nm,OBJPROP_STYLE,style);
      ObjectSetInteger(m_chart,nm,OBJPROP_WIDTH,1);
      ObjectSetString (m_chart,nm,OBJPROP_TEXT,nm);
     }

public:
                     CVisualizer() { m_chart=0; m_max_swings=40; }
   void              Init(const long chart_id,const int max_swings)
     { m_chart=chart_id; m_max_swings=MathMax(5,max_swings); }
   void              Clear() { DelPrefix(VIS_PREFIX); }

   void              DrawTF(CSwingSeries *ser,const TFState &st)
     {
      if(ser==NULL) return;
      DelPrefix(VIS_PREFIX+"SW_");
      int n=ser.Count();
      int start=MathMax(0,n-m_max_swings);
      for(int i=start;i<n;i++)
        {
         SwingPoint sp; if(!ser.Get(i,sp)) continue;
         string nm=StringFormat("%sSW_%I64u",VIS_PREFIX,sp.id);
         if(sp.type==SWING_HIGH)
            Arrow(nm,sp.time,sp.price,234,(sp.broken?clrGray:clrTomato),false);
         else
            Arrow(nm,sp.time,sp.price,233,(sp.broken?clrGray:clrDodgerBlue),true);
        }
      if(st.protected_low>0.0)  HLine(VIS_PREFIX+"PLOW", st.protected_low, clrDodgerBlue,STYLE_DOT);
      if(st.protected_high>0.0) HLine(VIS_PREFIX+"PHIGH",st.protected_high,clrTomato,   STYLE_DOT);
     }

   void              DrawZones(CSRZoneEngine *sr,const double min_score)
     {
      if(sr==NULL) return;
      DelPrefix(VIS_PREFIX+"ZN_");
      datetime t2=TimeCurrent();
      datetime t1=t2-(datetime)(150*PeriodSeconds((ENUM_TIMEFRAMES)Period()));
      int drawn=0;
      for(int i=0;i<sr.Count() && drawn<14;i++)
        {
         SRZone z; if(!sr.Get(i,z)) continue;
         if(z.score<min_score) continue;
         string nm=StringFormat("%sZN_%I64u",VIS_PREFIX,z.id);
         if(ObjectFind(m_chart,nm)<0) ObjectCreate(m_chart,nm,OBJ_RECTANGLE,0,t1,z.upper,t2,z.lower);
         ObjectSetInteger(m_chart,nm,OBJPROP_TIME,0,t1);
         ObjectSetInteger(m_chart,nm,OBJPROP_TIME,1,t2);
         ObjectSetDouble (m_chart,nm,OBJPROP_PRICE,0,z.upper);
         ObjectSetDouble (m_chart,nm,OBJPROP_PRICE,1,z.lower);
         color c=(z.type==ZONE_RESISTANCE?clrTomato:clrDodgerBlue);
         ObjectSetInteger(m_chart,nm,OBJPROP_COLOR,c);
         ObjectSetInteger(m_chart,nm,OBJPROP_FILL,true);
         ObjectSetInteger(m_chart,nm,OBJPROP_BACK,true);
         ObjectSetInteger(m_chart,nm,OBJPROP_SELECTABLE,false);
         drawn++;
        }
     }
  };

#endif // MTSR2_VISUALIZER_MQH
//+------------------------------------------------------------------+
