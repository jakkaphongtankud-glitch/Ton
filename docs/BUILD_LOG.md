# Build Log & Experiment Manifest

บันทึกทุก build และทุกการทดสอบตาม SPEC v2.0 §83, §139
ห้ามสรุปว่า engine ใด "ช่วย" เพียงเพราะ Net Profit สูงขึ้น — ต้องเทียบกับ Champion ก่อนหน้าและผ่าน OOS

## Version naming (SPEC §138)
```
v2.0.0_CORE        Core: Structure + S/R + Liquidity + Bias + Pullback/LiqReversal + Runner
v2.1.0_H2_BRIDGE   + H2 bridge classification
v2.2.0_H2_RUNNER   + H2 runner promotion
v2.3.0_BREAKOUT    + Breakout engine
v2.4.0_FALSE_BREAK + False-break filter
v2.5.0_REVERSAL    + Advanced reversal
v2.6.0_RECOVERY    + Structural recovery
v2.7.0_HEDGE       + Hedge
v2.8.0_TREND_FLIP  + Trend flip
```

## Experiment manifest template (กรอกทุก run)
```
EA Version      :
EA SHA256       :
SET SHA256      :
Broker / Server :
Account type    : (Hedging / Netting)
Symbol          : XAUUSDm
Date start/end  :
Tester model    : Every tick based on real ticks
Spread          : (variable / fixed n)
Deposit         :
Leverage        :
--- Results ---
Net Profit      :
Profit Factor   :
Expected Payoff :
Expectancy (R)  :
Trades          :
Win %           :
Avg Win R / Avg Loss R :
Max Equity DD % :
Recovery Factor :
OOS PF          :
WF consistency  :
MC survival     :
--- Decision ---
KEEP / REJECT / ITERATE :
Reason          :
```

## Acceptance gates — Core (SPEC §76, §133)
- OOS Net Profit > 0 (**required**)
- OOS PF > 1.40 ; Overall PF > 1.70 (desirable)
- Max Equity DD < 15% (เป้าหมายผู้ใช้: < 20%)
- Recovery Factor > 5 (desirable)
- Expectancy R > 0
- ไม่มีไม้เดียวครองกำไรทั้งหมด ; Long/Short review แยกกัน
- Sample ≥ 300 trades (§134) — ถ้า runner ถือยาว ใช้ช่วงข้อมูลยาวขึ้น

## Log
| Date | Version | Change | Result summary | Decision |
|------|---------|--------|----------------|----------|
| 2026-08-12 | phase1-structure | Build 01–03: framework + swing + BOS/CHoCH | Visual validation pending (user) | — |
| 2026-08-12 | p2-sr-liq-bias | Build 04–06: S/R zones + liquidity/sweep + regime + MTF bias (H2 bridge) | Visual validation pending (user) | — |
