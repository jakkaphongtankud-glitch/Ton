//+------------------------------------------------------------------+
//|                            MTF_Structure_Scalper_Runner_v2_0.mq5 |
//|   Adaptive Multi-Timeframe Structure Scalper & Runner            |
//|   D1 / H4 / H2 / H1 / M15 / M5 / M1                              |
//|                                                                  |
//|   BUILD STATUS: Phase 1  (Build 01-03)                          |
//|     [x] Framework + config + multi-TF cache      (Build 01)     |
//|     [x] Swing engine (fractal, no repaint)       (Build 02)     |
//|     [x] Structure engine BOS / CHoCH             (Build 03)     |
//|     [ ] S/R + Liquidity ... Runner ... (later builds)           |
//|                                                                  |
//|   Phase 1 does NOT place orders. It detects and visualises       |
//|   market structure so detection can be validated first           |
//|   (SPEC v2.0 sections 60-62, Definition-of-Done items 1-8).      |
//+------------------------------------------------------------------+
#property copyright "MTF Structure Scalper & Runner v2"
#property version   "2.00"
#property description "Multi-timeframe structural position engine with scalping precision entry. Phase-1 build: structure detection only."

#include "Include/Defs.mqh"
#include "Include/Structs.mqh"
#include "Include/Inputs.mqh"
#include "Include/Utils.mqh"
#include "Include/Logger.mqh"
#include "Include/MarketData.mqh"
#include "Include/SwingEngine.mqh"
#include "Include/StructureEngine.mqh"
#include "Include/Visualizer.mqh"
#include "Include/Dashboard.mqh"

//--- global engine instances ----------------------------------------
CLogger          g_log;
CMarketData      g_data;
CSwingEngine     g_swing;
CStructureEngine g_struct;
CVisualizer      g_vis;
CDashboard       g_dash;

TFState          g_tf[TF_COUNT];
ENUM_SYSTEM_STATE g_sys      = SYS_IDLE;
string           g_symbol    = "";
double           g_point     = 0.0;
int              g_chart_tf_index = -1;   // which TF the debug visuals track

//+------------------------------------------------------------------+
//| Config validation - HARD SAFETY INVARIANTS (SPEC sec 140)        |
//+------------------------------------------------------------------+
bool ValidateInputs()
  {
   string e="";
   if(InpRiskPercent<=0.0)                       e+="RiskPercent must be > 0; ";
   if(InpRiskPercent>InpMaxRiskPerTrade)         e+="RiskPercent > MaxRiskPerTrade; ";
   if(InpHedgeRatio>InpHedgeMaxRatio)            e+="HedgeRatio > HedgeMaxRatio; ";
   if(InpRecoveryRiskMultiplier>1.0)             e+="RecoveryRiskMultiplier > 1.0 (no martingale!); ";
   if(InpPartial1Percent+InpPartial2Percent>=100.0) e+="Partial1+Partial2 >= 100%; ";
   if(InpMinInitialRR<=0.0)                      e+="MinInitialRR <= 0; ";
   if(InpDailyLossLimitPct<=0.0)                 e+="DailyLossLimit <= 0; ";
   if(InpMaxEquityDDPct<=InpDailyLossLimitPct)   e+="MaxEquityDD must be > DailyLoss; ";
   if(!(InpEntryScoreAPlus>=InpEntryScoreA && InpEntryScoreA>=InpEntryScoreB)) e+="Entry A+ >= A >= B violated; ";
   if(!(InpExitFullScore>=InpExitPartialScore && InpExitPartialScore>=InpExitProtectScore)) e+="Exit Full>=Partial>=Protect violated; ";
   if(InpInstanceID<1 || InpInstanceID>9)        e+="InstanceID must be 1..9; ";
   // master-score weights must be >= 0
   if(InpScoreD1<0||InpScoreH4<0||InpScoreH2<0||InpScoreH1<0||InpScoreSR<0||
      InpScoreLiquidity<0||InpScoreM15<0||InpScoreM5<0||InpScoreM1<0||
      InpScoreSetupQuality<0||InpScoreReward<0||InpScoreExecution<0)
      e+="Negative master-score weight; ";

   if(StringLen(e)>0)
     {
      g_log.Error("Input validation FAILED: "+e);
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Resolve + prepare trading symbol                                 |
//+------------------------------------------------------------------+
bool ResolveSymbol()
  {
   g_symbol=(StringLen(InpTradeSymbol)>0? InpTradeSymbol : _Symbol);
   if(!SymbolSelect(g_symbol,true))
     {
      g_log.Error("Cannot select symbol: "+g_symbol);
      return false;
     }
   g_point=SymbolInfoDouble(g_symbol,SYMBOL_POINT);
   if(g_point<=0.0) g_point=_Point;
   return true;
  }

//+------------------------------------------------------------------+
//| Configure which timeframes are active + their parameters         |
//+------------------------------------------------------------------+
void ConfigureTimeframes()
  {
   g_data.Enable(IDX_D1 ,InpUseD1 ,InpBarsD1);
   g_data.Enable(IDX_H4 ,InpUseH4 ,InpBarsH4);
   g_data.Enable(IDX_H2 ,InpUseH2 ,InpBarsH2);
   g_data.Enable(IDX_H1 ,InpUseH1 ,InpBarsH1);
   g_data.Enable(IDX_M15,InpUseM15,InpBarsM15);
   g_data.Enable(IDX_M5 ,InpUseM5 ,InpBarsM5);
   g_data.Enable(IDX_M1 ,InpUseM1 ,InpBarsM1);

   g_swing.SetLR(IDX_D1 ,InpSwingLeftD1 ,InpSwingRightD1);
   g_swing.SetLR(IDX_H4 ,InpSwingLeftH4 ,InpSwingRightH4);
   g_swing.SetLR(IDX_H2 ,InpSwingLeftH2 ,InpSwingRightH2);
   g_swing.SetLR(IDX_H1 ,InpSwingLeftH1 ,InpSwingRightH1);
   g_swing.SetLR(IDX_M15,InpSwingLeftM15,InpSwingRightM15);
   g_swing.SetLR(IDX_M5 ,InpSwingLeftM5 ,InpSwingRightM5);
   g_swing.SetLR(IDX_M1 ,InpSwingLeftM1 ,InpSwingRightM1);

   for(int i=0;i<TF_COUNT;i++)
     {
      g_tf[i].Reset();
      if(g_data.Enabled(i)) { g_tf[i].tf_index=i; g_tf[i].tf=g_data.Period(i); }
     }
  }

//+------------------------------------------------------------------+
//| Pick which TF to draw debug objects for                          |
//+------------------------------------------------------------------+
void ResolveChartTF()
  {
   int idx=PeriodToTFIndex((ENUM_TIMEFRAMES)Period());
   if(idx>=0 && g_data.Enabled(idx)) { g_chart_tf_index=idx; return; }
   if(g_data.Enabled(IDX_M15)) { g_chart_tf_index=IDX_M15; return; }
   for(int i=0;i<TF_COUNT;i++) if(g_data.Enabled(i)) { g_chart_tf_index=i; return; }
   g_chart_tf_index=-1;
  }

//+------------------------------------------------------------------+
//| Process one timeframe on a new bar                               |
//+------------------------------------------------------------------+
void ProcessTF(const int idx)
  {
   if(!g_data.Refresh(idx)) return;
   if(g_data.Bars(idx)<InpMinBarsReady) return;
   if(g_data.ATR(idx)<=0.0) return;

   g_swing.Update(idx);
   g_swing.FillState(idx,g_tf[idx]);
   g_struct.Update(idx,g_tf[idx]);
   g_tf[idx].atr=g_data.ATR(idx);
   g_tf[idx].atr_ratio=g_data.ATRRatio(idx);
   g_tf[idx].last_bar_time=g_data.Time(idx,0);
   g_tf[idx].data_ready=true;
  }

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_log.Init(InpVerboseLog?LOG_DEBUG:LOG_INFO,false,InpTradeCommentPrefix);
   g_log.Info("=== MTF Structure Scalper v"+MTSR2_VERSION+" init ("+MTSR2_BUILD+") ===");

   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   if(!ResolveSymbol())
      return INIT_FAILED;

   g_data.SetLogger(GetPointer(g_log));
   ConfigureTimeframes();

   if(!g_data.Init(g_symbol,InpATRPeriod,InpATRReferenceBars))
     {
      g_log.Error("MarketData init failed (ATR handles).");
      return INIT_FAILED;
     }

   g_swing.Init(GetPointer(g_data),GetPointer(g_log),InpMaxSwingHistory);
   g_struct.Init(GetPointer(g_data),GetPointer(g_swing),GetPointer(g_log),g_symbol);

   ResolveChartTF();
   g_vis.Init(ChartID(),40);
   if(!InpDebugStructure) g_vis.Clear();
   g_dash.Init(ChartID());
   g_dash.Clear();

   g_sys=SYS_SCAN_HTF;
   EventSetTimer(MathMax(1,InpDashboardRefreshSec));

   g_log.Info(StringFormat("Symbol=%s point=%.5f chartTF=%s trading=%s",
              g_symbol,g_point,
              (g_chart_tf_index>=0?TFIndexToName(g_chart_tf_index):"none"),
              (InpEnableTrading?"ON(deferred)":"OFF")));
   g_log.Warn("Phase-1 build: structure detection only, NO orders are placed.");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_data.ReleaseHandles();
   g_vis.Clear();
   g_dash.Clear();
   Comment("");
   g_log.Info(StringFormat("Deinit (reason=%d)",reason));
   g_log.CloseFile();
  }

//+------------------------------------------------------------------+
//| Tick handler                                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   bool chart_tf_updated=false;

   for(int i=0;i<TF_COUNT;i++)
     {
      if(!g_data.Enabled(i)) continue;
      if(g_data.IsNewBar(i))
        {
         ProcessTF(i);
         if(i==g_chart_tf_index) chart_tf_updated=true;
        }
     }

   g_data.EvaluateReady(InpMinBarsReady);

   if(g_data.AllReady() && g_sys==SYS_SCAN_HTF)
      g_sys=SYS_BUILD_BIAS;   // structure ready; higher pipeline plugs in here (later builds)

   //--- Phase 1: no trading pipeline yet. Just visualise. -----------
   if(InpDebugStructure && chart_tf_updated && g_chart_tf_index>=0)
     {
      CSwingSeries *ser=g_swing.Series(g_chart_tf_index);
      g_vis.DrawTF(ser,g_tf[g_chart_tf_index]);
     }
  }

//+------------------------------------------------------------------+
//| Timer handler - dashboard refresh                                |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!InpEnableDashboard) return;
   double spread_pts=(double)SymbolInfoInteger(g_symbol,SYMBOL_SPREAD);
   g_dash.Render(g_tf,TF_COUNT,g_sys,g_symbol,spread_pts,MTSR2_BUILD);
  }

//+------------------------------------------------------------------+
//| Trade transaction handler (reconciliation - wired in later)      |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(!InpDebugExecution) return;
   if(trans.symbol!=g_symbol) return;
   g_log.Debug(StringFormat("TradeTxn type=%d order=%I64u deal=%I64u",
               (int)trans.type,trans.order,trans.deal));
  }
//+------------------------------------------------------------------+
