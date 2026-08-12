//+------------------------------------------------------------------+
//|                                                   Dashboard.mqh |
//|      On-chart status panel (SPEC v2.0 sec 59, 101).               |
//|      Phase-1 subset: MTF structure table + system state.          |
//+------------------------------------------------------------------+
#ifndef MTSR2_DASHBOARD_MQH
#define MTSR2_DASHBOARD_MQH

#include "Defs.mqh"
#include "Structs.mqh"
#include "Utils.mqh"

#define DASH_PREFIX "MTSR2_DASH_"

class CDashboard
  {
private:
   long              m_chart;
   int               m_x;
   int               m_y;
   int               m_dy;
   int               m_row;

   void              Row(const string tag,const string text,const color c)
     {
      string nm=DASH_PREFIX+tag;
      if(ObjectFind(m_chart,nm)<0)
        {
         ObjectCreate(m_chart,nm,OBJ_LABEL,0,0,0);
         ObjectSetInteger(m_chart,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(m_chart,nm,OBJPROP_XDISTANCE,m_x);
         ObjectSetString (m_chart,nm,OBJPROP_FONT,"Consolas");
         ObjectSetInteger(m_chart,nm,OBJPROP_FONTSIZE,9);
         ObjectSetInteger(m_chart,nm,OBJPROP_BACK,false);
         ObjectSetInteger(m_chart,nm,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(m_chart,nm,OBJPROP_HIDDEN,true);
        }
      ObjectSetInteger(m_chart,nm,OBJPROP_YDISTANCE,m_y+m_row*m_dy);
      ObjectSetInteger(m_chart,nm,OBJPROP_COLOR,c);
      ObjectSetString (m_chart,nm,OBJPROP_TEXT,text);
      m_row++;
     }

   color             DirColor(const ENUM_STRUCTURE_DIR d) const
     {
      switch(d)
        {
         case STRUCT_BULL: return clrLime;
         case STRUCT_BEAR: return clrTomato;
         case STRUCT_TRANSITION: return clrGold;
        }
      return clrSilver;
     }

public:
                     CDashboard() { m_chart=0; m_x=12; m_y=22; m_dy=16; m_row=0; }
   void              Init(const long chart) { m_chart=chart; }
   void              Clear()
     {
      int total=ObjectsTotal(m_chart,-1,-1);
      for(int i=total-1;i>=0;i--)
        {
         string nm=ObjectName(m_chart,i,-1,-1);
         if(StringFind(nm,DASH_PREFIX)==0) ObjectDelete(m_chart,nm);
        }
     }

   void              Render(const TFState &st[],const int tf_count,
                            const ENUM_SYSTEM_STATE sys,const string sym,
                            const double spread_pts,const string build)
     {
      m_row=0;
      Row("H0",StringFormat("MTF STRUCTURE SCALPER v%s [%s]",MTSR2_VERSION,build),clrWhite);
      Row("H1",StringFormat("%s  state=%s  spread=%.0fpt",sym,SysStateStr(sys),spread_pts),clrSilver);
      Row("H2","--------------------------------------",clrDimGray);
      Row("H3"," TF   STRUCT   REGIME       EVENT      ATR",clrLightGray);
      for(int i=0;i<tf_count && i<TF_COUNT;i++)
        {
         if(st[i].tf_index<0) continue;
         string line=StringFormat(" %-4s %-7s  %-11s  %-9s  %.2f",
                                   TFIndexToName(i),
                                   StructureDirStr(st[i].structure),
                                   RegimeStr(st[i].regime),
                                   StructureEventStr(st[i].last_event),
                                   st[i].atr);
         Row(StringFormat("R%d",i),line,DirColor(st[i].structure));
        }
      Row("F0","--------------------------------------",clrDimGray);
      Row("F1","Phase 1: STRUCTURE ONLY (no orders)",clrGold);
     }
  };

#endif // MTSR2_DASHBOARD_MQH
//+------------------------------------------------------------------+
