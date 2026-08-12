//+------------------------------------------------------------------+
//|                                                       Inputs.mqh |
//|      All optimizable inputs (SPEC v2.0). Every numeric value is    |
//|      a RESEARCH BASELINE, not a proven-best value.                 |
//+------------------------------------------------------------------+
#ifndef MTSR2_INPUTS_MQH
#define MTSR2_INPUTS_MQH

#include "Defs.mqh"

//==================== GENERAL (Section 4) ==========================
input group "=== GENERAL ==="
input string InpTradeSymbol          = "";          // Symbol ("" = current chart)
input ulong  InpBaseMagic            = 52000000;    // Base magic namespace
input int    InpInstanceID           = 1;           // Instance id (1..9)
input bool   InpAllowLong            = true;
input bool   InpAllowShort           = true;
input bool   InpEnableTrading        = true;        // Master trade switch
input bool   InpDryRun               = false;       // Signals only, no orders
input string InpTradeCommentPrefix   = "MTSR2";
input bool   InpVerboseLog           = true;
input bool   InpDebugStructure       = false;       // Draw swing/BOS/CHoCH objects
input bool   InpDebugSignals         = false;
input bool   InpDebugExecution       = false;

//==================== TIMEFRAMES (Section 5) =======================
input group "=== TIMEFRAMES ==="
input bool InpUseD1    = true;
input bool InpUseH4    = true;
input bool InpUseH2    = true;
input bool InpUseH1    = true;
input bool InpUseM15   = true;
input bool InpUseM5    = true;
input bool InpUseM1    = true;

//==================== DATA CACHE (Section 6) =======================
input group "=== DATA CACHE ==="
input int InpBarsD1       = 500;
input int InpBarsH4       = 750;
input int InpBarsH2       = 1000;
input int InpBarsH1       = 1500;
input int InpBarsM15      = 2500;
input int InpBarsM5       = 3000;
input int InpBarsM1       = 5000;
input int InpMinBarsReady = 200;

//==================== VOLATILITY (Section 7) =======================
input group "=== VOLATILITY ==="
input int    InpATRPeriod          = 14;
input double InpHighVolATRRatio    = 1.80;
input double InpLowVolATRRatio     = 0.55;
input int    InpATRReferenceBars   = 50;
input double InpMaxDailyRangeATR   = 1.50;
input double InpDailyExhaustionATR = 0.90;

//==================== SWING ENGINE (Section 8) =====================
input group "=== SWING ENGINE ==="
input int InpSwingLeftD1     = 4;
input int InpSwingRightD1    = 4;
input int InpSwingLeftH4     = 4;
input int InpSwingRightH4    = 4;
input int InpSwingLeftH2     = 3;
input int InpSwingRightH2    = 3;
input int InpSwingLeftH1     = 3;
input int InpSwingRightH1    = 3;
input int InpSwingLeftM15    = 3;
input int InpSwingRightM15   = 3;
input int InpSwingLeftM5     = 2;
input int InpSwingRightM5    = 2;
input int InpSwingLeftM1     = 2;
input int InpSwingRightM1    = 2;
input int InpMaxSwingHistory = 100;

//==================== MARKET STRUCTURE (Section 10) ================
input group "=== MARKET STRUCTURE ==="
input double InpBOSMinATR           = 0.05;
input double InpBOSSpreadMultiplier = 1.50;
input int    InpBOSMinPoints        = 20;
input double InpMinBodyRatioForBOS  = 0.45;
input double InpDisplacementATR     = 0.50;
input bool   InpRequireCloseForBOS  = true;
input bool   InpRequireDisplacement = false;
input int    InpStructureConfirmBars= 1;

//==================== CHOCH (Section 16) ===========================
input group "=== CHOCH ==="
input double InpCHoCHMinATR           = 0.05;
input double InpCHoCHSpreadMultiplier = 1.50;
input bool   InpCHoCHRequireClose     = true;
input bool   InpCHoCHRequireFailedHHLL = false;
input double InpCHoCHMinScore         = 60.0;

//==================== SUPPORT RESISTANCE (Section 20) ==============
input group "=== SUPPORT RESISTANCE ==="
input int InpSRLookbackD1  = 250;
input int InpSRLookbackH4  = 400;
input int InpSRLookbackH2  = 500;
input int InpSRLookbackH1  = 750;
input int InpSRLookbackM15 = 1000;
input double InpSRClusterATRD1  = 0.12;
input double InpSRClusterATRH4  = 0.15;
input double InpSRClusterATRH2  = 0.15;
input double InpSRClusterATRH1  = 0.18;
input double InpSRClusterATRM15 = 0.20;
input int InpSRMinTouches    = 2;
input int InpSRMaxZonesPerTF = 12;
input int InpSRMaxAgeBars    = 500;
input double InpSRMergeATR   = 0.15;
input double InpSRMinZonePts = 30;
input bool InpUsePrevDayHL   = true;
input bool InpUsePrevWeekHL  = true;
input bool InpUseSessionHL   = true;

//==================== S/R SCORE (Section 24) =======================
input group "=== S/R SCORE ==="
input double InpSRWeightTF         = 25;
input double InpSRWeightTouches    = 15;
input double InpSRWeightFreshness  = 15;
input double InpSRWeightRejection  = 10;
input double InpSRWeightConfluence = 15;
input double InpSRWeightLiquidity  = 10;
input double InpSRWeightBOSOrigin  = 5;
input double InpSRWeightVolume     = 5;
input double InpSRMinTradeScore    = 60;
input double InpSRStrongScore      = 80;

//==================== LIQUIDITY (Section 26) =======================
input group "=== LIQUIDITY ==="
input double InpEqualHighLowATR    = 0.08;
input double InpLiquidityMinATR    = 0.03;
input double InpSweepMinPenATR     = 0.02;
input double InpSweepMaxPenATR     = 0.50;
input double InpSweepReclaimATR    = 0.05;
input double InpMinSweepWickRatio  = 0.40;
input bool   InpRequireSweepCloseBack = true;

//==================== REGIME (Section 32) ==========================
input group "=== REGIME ==="
input int    InpRegimeLookback      = 20;
input double InpStrongTrendScore    = 75;
input double InpTrendScore          = 55;
input double InpRangeThreshold      = 40;
input double InpCompressionATRRatio = 0.70;
input double InpExpansionATRRatio   = 1.30;

//==================== MTF BIAS (Section 34) ========================
input group "=== MTF BIAS ==="
input double InpWeightD1  = 20;
input double InpWeightH4  = 20;
input double InpWeightH2  = 15;
input double InpWeightH1  = 15;
input double InpWeightM15 = 10;
input double InpMinBiasScore    = 15;
input double InpStrongBiasScore = 35;

//==================== SETUP ENGINES (Section 37) ===================
input group "=== SETUP ENGINES ==="
input bool InpEnablePullback          = true;
input bool InpEnableBreakout          = true;
input bool InpEnableReversal          = true;
input bool InpEnableContinuation      = true;
input bool InpEnableCounterTrend      = false;
input bool InpEnableFalseBreakReverse = true;

//==================== PULLBACK (Section 38) ========================
input group "=== PULLBACK ==="
input double InpPullbackMinDepthATR    = 0.25;
input double InpPullbackMaxDepthATR    = 2.00;
input double InpPullbackMinZoneScore   = 65;
input double InpPullbackMinEntryScore  = 75;
input bool   InpPullbackRequireSweep     = true;
input bool   InpPullbackRequireM5CHoCH   = true;
input bool   InpPullbackRequireM1Trigger = true;

//==================== BREAKOUT (Section 39) ========================
input group "=== BREAKOUT ==="
input double InpBreakoutMinScore         = 75;
input double InpBreakoutStrongScore      = 85;
input double InpBreakoutCloseATR         = 0.03;
input double InpBreakoutMinBodyRatio     = 0.50;
input double InpBreakoutATRExpansion     = 1.10;
input double InpBreakoutVolumeMultiplier = 1.20;
input bool   InpBreakoutRequireRetest    = true;
input int    InpRetestMaxBarsM15         = 8;
input double InpRetestToleranceATR       = 0.15;

//==================== REVERSAL (Section 42) ========================
input group "=== REVERSAL ==="
input double InpReversalMinScore      = 80;
input double InpCounterD1MinScore     = 90;
input double InpReversalMinZoneScore  = 70;
input bool   InpReversalRequireSweep    = true;
input bool   InpReversalRequireM15CHoCH = true;
input bool   InpReversalRequireM5BOS    = true;
input bool   InpReversalRequireM1Retest = true;

//==================== MASTER SCORE (Section 44) ====================
input group "=== MASTER SCORE ==="
input double InpScoreD1           = 12;
input double InpScoreH4           = 13;
input double InpScoreH2           = 12;
input double InpScoreH1           = 13;
input double InpScoreSR           = 10;
input double InpScoreLiquidity    = 10;
input double InpScoreM15          = 8;
input double InpScoreM5           = 7;
input double InpScoreM1           = 5;
input double InpScoreSetupQuality = 5;
input double InpScoreReward       = 3;
input double InpScoreExecution    = 2;
input double InpEntryScoreB       = 70;
input double InpEntryScoreA       = 80;
input double InpEntryScoreAPlus   = 90;
input double InpMinScoreDifference = 15;

//==================== STOP LOSS (Section 48) =======================
input group "=== STOP LOSS ==="
input ENUM_STOP_MODE InpStopMode = STOP_HYBRID;
input double InpStopATRMultiplier = 0.30;
input double InpStopSpreadMult    = 2.00;
input int    InpStopMinPoints     = 100;
input int    InpStopMaxPoints     = 3000;
input double InpStopMaxATR        = 1.50;

//==================== TARGETS (Section 50) =========================
input group "=== TARGETS ==="
input double InpMinInitialRR   = 2.20;
input bool   InpUseH1Target    = true;
input bool   InpUseH2Target    = true;
input bool   InpUseH4Target    = true;
input bool   InpUseD1Target    = true;
input double InpTargetBufferATR = 0.05;

//==================== RISK (Section 52) ============================
input group "=== RISK ==="
input double InpRiskPercent           = 0.35;
input double InpRiskAPlusMultiplier   = 1.25;
input double InpMaxRiskPerTrade       = 0.75;
input double InpMaxOpenHeatPercent    = 1.50;
input double InpMaxPendingHeatPercent = 0.75;
input int    InpMaxOpenPositions      = 2;
input int    InpMaxTradesPerDay       = 5;
input double InpDailyLossLimitPct     = 2.50;
input double InpWeeklyLossLimitPct    = 5.00;
input double InpMaxEquityDDPct        = 12.00;
input int    InpMaxConsecutiveLosses  = 3;
input int    InpCooldownMinutes       = 30;
input double InpMinMarginLevelPct     = 300;

//==================== PARTIAL PROFIT (Section 55) ==================
input group "=== PARTIAL PROFIT ==="
input bool   InpEnablePartial   = true;
input double InpPartial1R        = 1.50;
input double InpPartial1Percent  = 25;
input double InpPartial2R        = 3.00;
input double InpPartial2Percent  = 25;
input double InpProtectAtR       = 1.20;
input double InpBELockR          = 0.10;

//==================== RUNNER (Section 56) ==========================
input group "=== RUNNER ==="
input bool   InpEnableRunner        = true;
input double InpRunnerActivateR     = 2.50;
input double InpPromoteH1R          = 3.00;
input double InpPromoteH2R          = 4.50;
input double InpPromoteH4R          = 6.00;
input double InpPromoteD1R          = 8.00;
input double InpRunnerSLBufferATR   = 0.10;
input bool   InpAllowRunnerDowngrade = false;

//==================== HTF EXIT (Section 59) ========================
input group "=== HTF EXIT ==="
input double InpExitWeightM15CHoCH = 10;
input double InpExitWeightH1CHoCH  = 15;
input double InpExitWeightH1BOS    = 15;
input double InpExitWeightH2CHoCH  = 20;
input double InpExitWeightH4Reject = 10;
input double InpExitWeightH4CHoCH  = 15;
input double InpExitWeightSweep    = 10;
input double InpExitWeightDisp     = 5;
input double InpExitProtectScore   = 50;
input double InpExitPartialScore   = 70;
input double InpExitFullScore      = 85;

//==================== RECOVERY (Section 61) ========================
input group "=== RECOVERY ==="
input bool   InpEnableRecovery        = true;
input double InpRecoveryWeakScore     = 55;
input double InpRecoveryInvalidScore  = 75;
input bool   InpAllowRecoveryReentry  = true;
input double InpRecoveryRiskMultiplier = 1.00;   // HARD INVARIANT <= 1.0
input int    InpRecoveryMaxReentries  = 1;

//==================== HEDGE (Section 63) ===========================
input group "=== HEDGE ==="
input bool   InpEnableHedge       = false;        // Default OFF until core proven
input double InpHedgeRatio        = 0.40;
input double InpHedgeMaxRatio     = 0.60;
input int    InpMaxHedgeCycles    = 1;
input int    InpMaxHedgeMinutes   = 180;
input double InpHedgeMinProfitR   = 2.00;
input double InpHedgeTriggerScore = 70;
input double InpHedgeReleaseScore = 55;

//==================== SESSION (Section 66) =========================
input group "=== SESSION ==="
input bool   InpUseSessionFilter = true;
input string InpAsiaStart      = "00:00";
input string InpAsiaEnd        = "08:00";
input string InpLondonStart    = "07:00";
input string InpLondonEnd      = "16:00";
input string InpNewYorkStart   = "12:00";
input string InpNewYorkEnd     = "21:00";
input bool   InpTradeAsia      = true;
input bool   InpTradeLondon    = true;
input bool   InpTradeNewYork   = true;
input bool   InpBlockRollover  = true;
input string InpRolloverStart  = "23:50";
input string InpRolloverEnd    = "00:15";

//==================== EXECUTION (Section 67) =======================
input group "=== EXECUTION ==="
input int    InpMaxSpreadPoints     = 500;
input double InpMaxSpreadATRRatio   = 0.12;
input int    InpDeviationPoints     = 50;
input int    InpMaxExecutionRetries = 2;
input int    InpRetryDelayMs        = 250;
input bool   InpUseOrderCheck       = true;
input bool   InpRejectStaleTick     = true;
input int    InpMaxTickAgeSeconds   = 5;

//==================== NEWS (Section 68) ============================
input group "=== NEWS ==="
input ENUM_NEWS_MODE InpNewsMode = NEWS_MT5_CALENDAR;
input bool InpBlockHighImpactUSD    = true;
input int  InpNewsMinutesBefore     = 30;
input int  InpNewsMinutesAfter      = 20;
input bool InpClosePendingBeforeNews = true;
input bool InpAllowRunnerDuringNews  = true;

//==================== TELEMETRY (Section 98) =======================
input group "=== TELEMETRY ==="
input bool InpEnableCSVJournal    = true;
input bool InpLogRejectedSignals  = true;
input bool InpLogTFStateSnapshots = true;
input bool InpEnableDashboard     = true;
input int  InpDashboardRefreshSec = 1;

#endif // MTSR2_INPUTS_MQH
//+------------------------------------------------------------------+
