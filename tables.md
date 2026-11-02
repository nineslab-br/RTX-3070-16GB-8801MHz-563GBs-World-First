# Technical Timing Specification & P-States: RTX 3070 16GB Mod (GA104 + Samsung K4ZAF325BM-HC16)

**🌐 Language:** **English** | [Português do Brasil](tabelas.md)

[![Milestone: World First 8001MHz](https://img.shields.io/badge/Milestone-World's%20First%208001%20MHz%20(512%20GB%2Fs)-gold.svg)]()
[![Developed by Nines Lab](https://img.shields.io/badge/Developed%20By-Nines%20Lab-blue.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Document:** Reverse-Engineering Comparison and Timing Mapping  
**Target Hardware:** Galax GeForce RTX 3070 LHR 1-Click OC (Modded to 16 GB Samsung GDDR6, Strap 6 H/H/L)  
**Comparison Sources:**
1. **Galax RTX 3070 (Stock Dump):** Factory Original VBIOS (`94.04.46.00.CC`)
2. **NVIDIA RTX A4000 16GB:** Official Workstation GA104 VBIOS (`94.04.46.00.56` / `donor_a4000_16gb.rom`)
3. **ASUS ROG RTX 3080 Mobile 16GB:** Official GeForce GA104 VBIOS (`94.04.3E.00.56` / `Asus.RTX3080Mobile.16384.201223.rom`)

---

## 1. CRITICAL HARDWARE WARNING: Memory Descriptor Byte `+0x0F`

> ⚠️ **NEVER SET BYTE `+0x0F` TO `0x10` (A4000 WORKSTATION STANDARD)!**  
> **THIS BYTE MUST REMAIN STRICTLY AT `0x00` ON GEFORCE HARDWARE!**

### Why the A4000's `0x10` Value Bricks GeForce Cards:
* **Origin of `0x10`:** The NVIDIA RTX A4000 is a professional workstation (*Quadro*) GPU featuring dedicated circuitry and firmware routines for **out-of-band ECC memory**. The `0x10` bit in the memory descriptor instructs the on-chip GSP firmware to initialize ECC memory control structures.
* **Behavior on GeForce GA104 Silicon (3070 Desktop / 3080 Mobile):** Consumer GeForce GA104 chips **lack hardware ECC support**. When an Ampere GeForce VBIOS is configured with `0x10`:
  1. GSP firmware attempts to initialize nonexistent ECC controllers during driver bring-up;
  2. The GSP RPC command `GSP_RM_CONTROL` (function 76) suffers an unrecoverable timeout;
  3. The Linux kernel logs a hardware watchdog deadlock: `NVRM: krcWatchdog_IMPL: RC watchdog: GPU is probably locked!`;
  4. The GPU enters an unrecoverable error state (`NV_ERR_RESET_REQUIRED` / `Xid 154`), temperature sensor telemetry hangs, and the board's emergency fail-safe circuit **ramps the cooling fans to 100% full speed**.
* **Official Proof:** On the **GeForce RTX 3080 Mobile 16GB** VBIOS (native GA104 silicon with 16 GB Samsung GDDR6), the memory descriptor byte `+0x0F` is strictly **`0x00`**.

---

## 2. Memory Configuration Descriptor Table (BIT Token M / Strap 6 Samsung 16Gb)

Memory Table Header Offset: `0xD326`  
Entry 6 Offset (Strap 6 — Samsung 16Gb): `0xD3B1`

| Graphics Card | Entry Size | Hexadecimal Dump (22 bytes) | Byte `+0x0F` (`0xD3C0`) | Practical Effect |
| :--- | :---: | :--- | :---: | :--- |
| **Galax 3070 Stock (Factory)** | 22 bytes | `69 16 60 02 00 00 00 00 ff 00 ff 00 ff ff 00 00 00 00 00 00 00 00` | **`0x00`** | Stable native GeForce standard. |
| **ASUS RTX 3080 Mobile 16GB** | 14 bytes | `69 16 60 02 00 00 00 00 ff 00 ff 00 ff ff` *(+ 0x00)* | **`0x00`** | **Official Native 16GB GeForce Standard.** |
| **NVIDIA RTX A4000 16GB** | 22 bytes | `69 16 60 02 00 00 00 00 ff 00 ff 00 ff ff 00 10 00 00 00 00 00 00` | **`0x10`** | ❌ **Incompatible (Boot lockup / 100% fans).** |

---

## 3. Memory Clock Bands Mapping

In NVIDIA Ampere architecture, the clock bands table (`BIT Token P+0x04` @ `0x89CFA`) maps memory frequency ranges to a specific timing table index (**Timing ID**):

| Band | Frequency Range | Factory Clock Points | Linked Timing ID | Typical Operating State |
| :---: | :---: | :---: | :---: | :--- |
| **Band 0** | 0 – 540 MHz | **405 MHz** | **Timing ID 30** | Absolute Idle (Static Desktop) — **P8 State** |
| **Band 1** | 541 – 1249 MHz | **810 MHz** | **Timing ID 31** | 2D Decoding and Light Video Acceleration — **P5 State** |
| **Band 2** | 2005 – 4699 MHz | *(Ramp)* | **Timing ID 32** | Intermediate transition |
| **Band 3** | 4700 – 5250 MHz | **5001 MHz** | **Timing ID 32** | 4K Video Playback / NVDEC / YouTube — **P3 State** |
| **Band 4** | 5251 – 5799 MHz | *(Ramp)* | **Timing ID 33** | Mid-range workload — Initial **P2 State** |
| **Band 5** | 5800 – 6300 MHz | *(Ramp)* | **Timing ID 34** | Mid-range workload — Upper **P2 State** |
| **Band 6** | 6301 – 16383 MHz | **6801 / 7001 MHz** | **Timing ID 38** | High Performance / Gaming / AI Compute — **P0 State** |

---

## 4. Complete Timing Records Comparison (76 Bytes Per Record)

Timing Table Base Offsets:
* **Galax 3070:** `0x8B880 + 6 + (ID * 76)`
* **RTX A4000 16GB:** `0x8C29C + 6 + (ID * 76)`
* **RTX 3080 Mobile 16GB:** `0x748B8 + 6 + (ID * 76)`

---

### Timing ID 30 — P8 State (405 MHz / Desktop Idle)

* **Function:** Minimum low-power state when the desktop is completely idle.
* **Measured Power Draw:** 11.8 W to 12.5 W (24°C, 0 RPM silent fans).

| Parameter | Galax 3070 Stock | RTX A4000 16GB | RTX 3080 Mobile 16GB | Nominal 16GB Target | Engineering Diagnosis |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **tRC (Row Cycle)** | 6 | 6 | 6 | **6 cycles** | Identical across all boards. |
| **tRFC (Refresh)** | 13 | 13 | 13 | **13 cycles** | Identical across all boards. |
| **tRP (Precharge)** | 8 | 8 | 8 | **8 cycles** | Identical across all boards. |
| **tRAS (Active)** | 2 | 2 | 2 | **2 cycles** | Identical across all boards. |
| **CL (CAS Latency)** | 9 (`0x82`) | 9 (`0x82`) | 9 (`0x82`) | **9 cycles** | Identical across all boards. |
| **WR_RCD (Write Delay)** | **1** (`0x10`) | **2** (`0x20`) | **2** (`0x20`) | **2 cycles (`0x20`)** | ❌ **Stock is FLAWED.** 1 cycle causes write collisions on 16Gb density modules. Official 16GB target is **2**. |
| **Turnaround (Bytes 46..51)**| `90 90 14 44 44 A3` | `00 90 14 44 44 A3` | `00 B4 15 55 55 53` | **`00 B4 15 55 55 53`** | 5-cycle turnaround (`0x55`) prevents memory bus turnaround contention. |

#### Verbatim Hexadecimal Dumps (76 Bytes):
* **Galax 3070 Stock:**  
  `060d080289821034110304774c100022250081e20371a237110a0051010000000034020589034012a54414034a039090144444a322018000070800000a000080000000000200102616000100`
* **RTX 3080 Mobile 16GB (Target):**  
  `060d080289822034110304774c100022250081e20371a237110a0051010000000034020589034012a54414030a0400b41555555322018000070800000a000080000000000200102616800100`

---

### Timing ID 31 — P5 State (810 MHz / Light Video Playback)

* **Function:** Frequency to which the hardware NVDEC engine downclocks memory during continuous 1080p video playback.
* **Root Cause of Video Freezes:** The primary culprit of 1-to-2 second video playback freezes on stock BIOSes.

| Parameter | Galax 3070 Stock | RTX A4000 16GB | RTX 3080 Mobile 16GB | Nominal 16GB Target | Engineering Diagnosis |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **tRC (Row Cycle)** | 11 | 11 | 11 | **11 cycles** | Identical across all boards. (Forcing 14 destabilized the PLL). |
| **tRFC (Refresh)** | 25 | 25 | 25 | **25 cycles** | Identical across all boards. (Forcing 40 broke state machine parity). |
| **tRP (Precharge)** | 14 | 14 | 14 | **14 cycles** | Identical across all boards. |
| **tRAS (Active)** | 4 | 4 | 4 | **4 cycles** | Identical across all boards. |
| **CL (CAS Latency)** | 9 (`0x02`) | 9 (`0x02`) | 9 (`0x02`) | **9 cycles** | Identical across all boards. |
| **WR_RCD (Write Delay)** | **2** (`0x21`) | **3** (`0x31`) | **3** (`0x31`) | **3 cycles (`0x31`)** | ❌ **Stock is CRITICAL.** 2 cycles causes write collisions while decoding video frames. Official 16GB target is **3**. |
| **Turnaround (Bytes 46..51)**| `90 90 14 44 44 A3` | `90 90 14 44 44 A3` | `00 B4 15 55 55 53` | **`00 B4 15 55 55 53`** | ❌ **Stock is CRITICAL.** 4 cycles (`0x44`) causes read operations before write operations finish. Requires 5 cycles (`0x55`). |

#### Verbatim Hexadecimal Dumps (76 Bytes):
* **Galax 3070 Stock:**  
  `0b190e0489022134110304776c100022250081e20371a237110a0051010000000034030689034012a64414040a049090144444a3220180000d0800000a000080000000000200102616000100`
* **RTX 3080 Mobile 16GB (Target):**  
  `0b190e0489023134110304776c100022250081e20371a237110a0051010000000034030689034012a64414040a0400b415555553220180000d0c00000a000080000000000200102616000100`

---

### Timing ID 32 — P3 State (5001 MHz / 4K Video Playback / Heavy Media)

* **Function:** High-performance media decoding state, used during initial video buffer loads and 4K/60fps playback.
* **Root Cause of TLB Timeout:** Responsible for the GMMU `PDB 0x3f6192000` page directory read failure.

| Parameter | Galax 3070 Stock | RTX A4000 16GB | RTX 3080 Mobile 16GB | Nominal 16GB Target | Engineering Diagnosis |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **tRC (Row Cycle)** | **57** | **65** | **65** | **65 cycles** | ❌ **Stock is FLAWED.** Undersized 8GB value. |
| **tRFC (Refresh)** | 150 | 150 | 150 | **150 cycles** | Identical across all boards. |
| **tRP (Precharge)** | **76** | **86** | **86** | **86 cycles** | ❌ **Stock is FLAWED.** Requires longer precharge on 16Gb. |
| **tRAS (Active)** | **19** | **22** | **22** | **22 cycles** | ❌ **Stock is FLAWED.** Must maintain $t_{RC} = t_{RAS} + t_{RP}$. |
| **CL (CAS Latency)** | **20** (`0xC2`) | **22** (`0x82`) | **22** (`0x82`) | **22 cycles (`0x82`)** | ❌ **CRITICAL FLAW.** 16Gb chips cannot deliver read data in 20 cycles at 5 GHz, corrupting GMMU page table reads at 15.84 GB. |
| **WR_RCD / RD_RCD** | **12 / 4** (`0xC4`) | **14 / 5** (`0xE5`) | **14 / 5** (`0xE5`) | **14 / 5 (`0xE5`)** | ❌ **Stock is FLAWED.** Write activation too aggressive for 16Gb. |
| **Turnaround (Bytes 46..51)**| `93 91 14 44 44 A3` | `93 91 14 44 44 A3` | `93 B5 15 55 55 53` | **`93 B5 15 55 55 53`** | 5-cycle turnaround ensures continuous read/write stability. |

#### Verbatim Hexadecimal Dumps (76 Bytes):
* **Galax 3070 Stock:**  
  `39964c1394c2c46410071377ac190022258081e20571c297130a00510100000000340d1089034012a0441a900d049391144444a2230580004b28000001000080000000000300102616000100`
* **RTX 3080 Mobile 16GB (Target):**  
  `419656169682e56410071677ac190022258081e2f570c297130a00510100000000340e1189034012a1441a900d0493b515555553230580004b3c000001000080000000000300102616000100`

---

### Timing IDs 33 and 34 — P2 State (5251 to 6300 MHz / Intermediate Ramping)

* **Function:** Intermediate ramping states between P3 (5001 MHz) and maximum load (6801+ MHz).

| Parameter | Galax 3070 Stock (ID 33 / ID 34) | RTX 3080 Mobile 16GB (ID 33 / ID 34) | Nominal 16GB Target |
| :--- | :---: | :---: | :---: |
| **tRC** | 63 / 68 | 71 / 77 | **71 / 77 cycles** |
| **tRFC** | 165 / 180 | 165 / 180 | **165 / 180 cycles** |
| **tRP** | 84 / 90 | 94 / 102 | **94 / 102 cycles** |
| **tRAS** | 21 / 23 | 24 / 26 | **24 / 26 cycles** |
| **CL** | 21 / 22 | 23 / 24 | **23 / 24 cycles** |
| **WR_RCD** | 13 / 14 | 16 / 17 | **16 / 17 cycles** |
| **Turnaround** | `... 44 44 ...` | `... 55 55 ...` | **5 cycles (`0x55, 0x55`)** |

---

### Timing ID 38 — P0 State (6301 to 16383 MHz / High Performance: 6801 and 7001 MHz)

* **Function:** Extreme load state, 3D rendering, heavy gaming, and LLM training/inference.
* **Factory Status:** ✅ **100% EXCELLENT & FLAWLESS.**

| Parameter | Galax 3070 Stock | RTX A4000 16GB | RTX 3080 Mobile 16GB | Verdict |
| :--- | :---: | :---: | :---: | :--- |
| **tRC** | 90 | 85 | 90 | **Factory Perfect (90 cycles)** |
| **tRFC** | 240 | 226 | 240 | **Factory Perfect (240 cycles — maximum capacitor recharge window)** |
| **tRP** | 120 | 114 | 120 | **Factory Perfect (120 cycles)** |
| **tRAS** | 30 | 28 | 30 | **Factory Perfect (30 cycles)** |
| **CL** | 26 (`0x82`) | 25 (`0x02`) | 26 (`0x82`) | **Factory Perfect (26 cycles — fully relaxed read latency)** |
| **WR_RCD / RD_RCD**| 18 / 23 (`0x27`) | 17 / 23 (`0x17`) | 18 / 23 (`0x27`) | **Factory Perfect** |

#### Verbatim Stock Galax 3070 Hexadecimal Dump (UNTOUCHED):
`5af0781e9a822765100a1e778c280022258082e20671e2d7150a0051010000000034141789034012a744289954069391144444a3230580007840000001000080200000000500102616000100`

---

## 5. Executive Engineering Takeaways

1. **Galax Only Calibrated P0 for 16GB:** Timing ID 38 was the only table genuinely engineered by Galax for 16 Gbit density chips. This explains why the card is indestructible in heavy gaming and AI compute at 220W.
2. **All Low and Intermediate States Were Copied from 8GB BIOS:**
   * **P8:** `WR_RCD = 1` is too tight for write flushes (requires `2`);
   * **P5:** `WR_RCD = 2` and a 4-cycle turnaround cause severe bus collisions during NVDEC video playback (requires `3` and `5 cycles`);
   * **P3:** `CL = 20` causes corrupted GMMU page table reads at 5001 MHz (requires `CL = 22`);
3. **Memory Descriptor Must Be `0x00`:** The `0x10` value from the A4000 is exclusive to workstation ECC circuitry and triggers Falcon/GSP boot lockups on consumer GeForce hardware.
