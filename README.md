# MTF Structure Scalper & Runner v2.0

**Multi-Timeframe Structural Position Engine with Scalping Precision Entry**
D1 / H4 / H2 / H1 / M15 / M5 / M1 — MetaTrader 5 / MQL5 — XAUUSDm (Exness)

> สร้างตาม *Master Specification v2* + *Technical Specification v2.0* ของคุณ
> โดยยึดหลัก **พิสูจน์ edge ของ Core ก่อน แล้วค่อยเพิ่ม engine ทีละตัวแบบ A/B test**

---

## ⚠️ อ่านก่อน — สถานะปัจจุบัน

ระบบนี้ **ไม่ได้สร้างเสร็จทั้งหมดในครั้งเดียว** (และไม่ควร) สเปคของคุณเองระบุชัด (§54, §63, §87, §129)
ว่าต้องสร้าง **Champion Core** ให้พิสูจน์ว่ามี edge ก่อน แล้วจึงเพิ่ม Breakout / Reversal / Recovery / Hedge
ทีละตัว เพื่อวัดว่าแต่ละ engine เพิ่ม Expectancy จริง หรือแค่ทำให้ backtest ดูสวย

**ตอนนี้เสร็จ: Phase 1 — Market Structure Only (Build 01–03)**
EA เวอร์ชันนี้ **ยังไม่เปิดออเดอร์** — มันทำหน้าที่ตรวจจับและวาดโครงสร้างตลาดให้เรา
ตรวจสอบด้วยตาก่อนว่า detect ถูกต้อง (ตรงตาม SPEC §60–62 และ Definition-of-Done ข้อ 1–8)

| Build | โมดูล | สถานะ |
|------|--------|:------:|
| 01 | Framework + Config + Multi-TF Cache + Logger + State Machine | ✅ |
| 02 | Swing Engine (fractal L/R, no repaint) | ✅ |
| 03 | Structure Engine — BOS / CHoCH / HH-HL-LH-LL / Protected Swing | ✅ |
| 04 | S/R Zone Engine (cluster + score) | ⬜ |
| 05 | Liquidity Engine (equal H/L, sweep) | ⬜ |
| 06 | Regime + MTF Bias (weighted hierarchy, H2 bridge) | ⬜ |
| 07–09 | M15 Setup → M5 Confirm → M1 Trigger | ⬜ |
| 10 | Central Score + Conflict Resolver | ⬜ |
| 11–13 | Stop / Target / RR → Risk Sizing → Execution | ⬜ |
| 14–16 | Position State → Partial / Runner → HTF Exit | ⬜ |
| 17 | Telemetry (CSV journal) + Dashboard เต็ม | ⬜ |
| 18 | **Core Backtest (v2.0.0_CORE)** — วัด edge จริง | ⬜ |
| 19–24 | Breakout → False Break → Reversal → Recovery → Hedge → Trend Flip | ⬜ |

---

## 📁 โครงสร้างไฟล์

```
MTF_Structure_Scalper_Runner_v2/
├── MTF_Structure_Scalper_Runner_v2_0.mq5   ← ไฟล์หลัก (คอมไพล์ไฟล์นี้)
└── Include/
    ├── Defs.mqh            enums + ค่าคงที่ (LOCKED per SPEC §3)
    ├── Structs.mqh         SwingPoint / TFState / SRZone / SignalCandidate / PositionContext (§71–76)
    ├── Inputs.mqh          input ทุกตัวจากสเปค (optimizable, ค่าเป็น Research Baseline)
    ├── Utils.mqh           helper: TF mapping, candle math, enum→text
    ├── Logger.mqh          leveled logger
    ├── MarketData.mqh      multi-TF bar cache + ATR หลาย TF (§5–7, §81–82)
    ├── SwingEngine.mqh     fractal swing detection (§8–9)
    ├── StructureEngine.mqh BOS / CHoCH engine (§10–19)
    ├── Visualizer.mqh      debug objects สำหรับ visual validation (§128)
    └── Dashboard.mqh       on-chart status panel (§59, §101)
```

## 🔧 การติดตั้ง

1. เปิดโฟลเดอร์ data ของ MT5: MetaEditor/MT5 → **File → Open Data Folder**
2. ก๊อปโฟลเดอร์ `MTF_Structure_Scalper_Runner_v2/` ทั้งอัน ไปวางใน `MQL5/Experts/`
3. เปิด `MTF_Structure_Scalper_Runner_v2_0.mq5` ใน MetaEditor → กด **Compile (F7)**
   - **เป้าหมาย: 0 errors / 0 warnings** (Definition-of-Done ข้อ 1)
4. ลาก EA ลงชาร์ต **XAUUSDm** (แนะนำเปิดที่ M15 เพื่อดู visual)

## ✅ วิธีวัดผล Phase 1 (สำคัญ — ต้องผ่านก่อนไป Build 04)

Phase 1 พิสูจน์ว่า **detect โครงสร้างถูกต้อง ไม่ repaint** เปิด **Strategy Tester → Visual Mode**
(หรือรันสด demo) ตั้งค่า input:

- `InpDebugStructure = true` → วาดลูกศร swing + เส้น protected high/low บน TF ของชาร์ต
- `InpVerboseLog = true` → log ทุก BOS/CHoCH ใน Experts tab

**เช็คลิสต์ (อ้างอิง Test Matrix §108–110):**

| # | ตรวจสอบ | ผลที่คาดหวัง |
|---|---------|--------------|
| S01/S02 | ลูกศร swing high/low ตรงกับ fractal จริง | ตรง |
| S04/S06 | swing ที่ยืนยันแล้ว **ไม่ขยับ/ไม่หาย** เมื่อมีแท่งใหม่ | no repaint |
| B01 | wick ทะลุ swing แต่ราคาปิดไม่พ้น buffer | **ไม่เกิด** BOS |
| B02 | ปิดพ้น swing high + buffer + body พอ | BOS Bull |
| B06 | swing เดิมถูกทะลุซ้ำ | ไม่เกิด BOS ซ้ำ (duplicate protection) |
| CH01 | Bull อยู่ แล้วปิดหลุด protected HL | CHoCH Bear + flip เป็น Bear |
| Dashboard | ตาราง MTF โชว์ทิศแต่ละ TF ตรงกับตาที่เห็น | ตรง |

ถ้าผ่านหมด → **lock เป็น baseline** แล้วผมต่อ Build 04 (S/R) ได้

---

## 🎯 เรื่องเป้าหมาย $1,200 / เดือน, DD < 20% (ต้องเข้าใจให้ตรงกัน)

ไม่มีใคร — รวมถึงผม — รับประกันตัวเลขนี้ได้ก่อนที่ระบบจะผ่าน **OOS + Walk-Forward + Monte Carlo**
(นี่คือเหตุผลที่สเปคของคุณเน้น §69–82) $1,200/เดือน **ขึ้นกับขนาดทุน** เป็นหลัก:

| ผลตอบแทน/เดือน (proven) | ทุนที่ต้องใช้เพื่อได้ ~$1,200 | ความสมจริง (DD<20%) |
|:---:|:---:|:---|
| 4% | ~$30,000 | ทำได้จริงถ้า edge นิ่ง |
| 8% | ~$15,000 | ท้าทาย ต้องผ่าน OOS แน่น |
| 12% | ~$10,000 | เสี่ยงสูง มักมาพร้อม DD เกิน |
| 20%+ | ~$6,000 | มัก overfit / ระเบิดใน forward |

**แนวทางที่ถูกต้อง:** สร้าง Core → หา Expectancy (R เฉลี่ยต่อไม้) + จำนวนไม้/เดือนจาก backtest จริง
→ คำนวณย้อนกลับว่าต้องใช้ทุนเท่าไรที่ risk 0.35%/ไม้ เพื่อได้ $1,200 โดย DD ไม่เกิน 20%
ถ้า Core ยังไม่มี edge เราจะ **แก้ที่ edge ไม่ใช่เร่ง lot** (สเปค §50, §145)

---

## 🧭 หลักการที่ฝังในโค้ด (จะไม่ถูกละเมิด)

- ❌ ไม่มี Martingale / Grid / Averaging down / เพิ่ม lot หลังแพ้ (บังคับด้วย `ValidateInputs`, §140)
- ❌ ไม่ขยาย SL หลังเข้า — SL ขยับทางเดียวเท่านั้น (จะ implement ใน Build 15)
- ✅ ทุก signal ต้องผ่าน Central Decision Engine — ไม่มี engine ไหนส่ง order เอง
- ✅ Recovery = ผ่านข้อมูลตลาดที่ดีขึ้น ไม่ใช่ผ่าน lot (`RecoveryRiskMultiplier ≤ 1.0` บังคับ)
- ✅ Winner เปลี่ยนจาก Scalper → Runner ด้วย **structure trailing** ไม่ใช่ tight trailing

## 📌 ขั้นต่อไป

ผมจะทำ **Build 04 (S/R Zone Engine)** และ **Build 05 (Liquidity)** เป็นชุดถัดไป — ทั้งคู่ยังเป็น
เฟส "validation มากกว่า profit" (§62) แล้วจึงเข้า Build 06 (Regime + MTF Bias + H2 Bridge)
ซึ่งเป็นหัวใจที่ต้องพิสูจน์ว่า **H2 เพิ่ม edge จริงไหม**

การวัดผลแต่ละ build บันทึกใน `docs/BUILD_LOG.md` (Experiment Manifest ตาม §139)
