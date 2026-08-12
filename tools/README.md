# tools/ — compile & backtest helpers (รันบนเครื่องคุณเอง)

Claude รันอยู่บนคลาวด์ **แตะเครื่องคุณไม่ได้** สคริปต์พวกนี้ให้คุณดับเบิลคลิกรันเองบน PC ที่ติดตั้ง MT5 (Exness)

## ⚠️ สำคัญที่สุด — build ตอนนี้ (01–06) ยังไม่เข้าออเดอร์
รัน backtest ตอนนี้ **จะได้ 0 trades = ถูกต้องแล้ว** เป้าหมายของการรันตอนนี้คือ 2 อย่าง:
1. **Compile ผ่าน 0/0** (compile.bat)
2. EA **โหลด+รันได้ไม่มี runtime error** และ (ถ้าเปิด Visual) เห็น swing/zone/bias ถูกต้อง

Backtest เพื่อ "กำไร/DD" จะมีความหมายจริงตอน **Build 18 (v2.0.0_CORE)** เท่านั้น

## ขั้นตอน
1. เอาโฟลเดอร์ `MTF_Structure_Scalper_Runner_v2` ไปวางใน `...\MQL5\Experts\`
   (MT5 → File → Open Data Folder → `MQL5\Experts`)
2. เปิด `tools\compile.bat` ด้วย Notepad → แก้ 2 ค่าบนสุด:
   - `MT5DIR` = ที่อยู่ของ `metaeditor64.exe` (โฟลเดอร์ที่ติดตั้ง Exness MT5)
   - `MQL5DIR` = path ของ data folder `...\MQL5` (แทน `<YOUR_TERMINAL_HASH>`)
3. ดับเบิลคลิก `compile.bat` → ดู `compile.log` (ต้อง 0 errors / 0 warnings)
4. แก้ `run_backtest.bat` ให้ `MT5DIR` ตรงกับเครื่อง → ดับเบิลคลิก
   - อยากดูภาพ: เปิด `backtest.ini` แก้ `Visual=0` เป็น `Visual=1`
   - อยากลองช่วงอื่น: แก้ `FromDate` / `ToDate`

## หา TERMINAL_HASH ยังไง
`...\AppData\Roaming\MetaQuotes\Terminal\` จะมีโฟลเดอร์ชื่อยาว ๆ (เช่น `D0E8209F77C8CF37AD8BF550E51FF075`) — อันที่ข้างในมี `MQL5\Experts` ของ Exness คืออันที่ใช้

## ถ้าติดปัญหา
ส่ง `compile.log` หรือข้อความใน Journal/Experts tab ของ MT5 มาให้ Claude ใน chat นี้ เดี๋ยวแก้ให้
