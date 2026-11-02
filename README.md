# RTX 3070 16GB Mod @ 8001 MHz (512 GB/s) — World-First Milestone & Engineering Guide

**🌐 Language:** **English** | [Português do Brasil](README_pt-BR.md)

[![Milestone: World First 8001MHz](https://img.shields.io/badge/Milestone-World's%20First%208001%20MHz%20(512%20GB%2Fs)-gold.svg)]()
[![Developed by Nines Lab](https://img.shields.io/badge/Developed%20By-Nines%20Lab-blue.svg)]()
[![Country: Brazil](https://img.shields.io/badge/Country-Brazil%20%F0%9F%87%A7%F0%9F%87%B7-green.svg)]()
[![Tested On: Linux Mint 21.3](https://img.shields.io/badge/Tested%20On-Linux%20Mint%2021.3%20Virginia-brightgreen.svg)]()
[![Architecture: Ampere GA104](https://img.shields.io/badge/Architecture-Ampere%20GA104-blueviolet.svg)]()
[![VRAM: 16 GB Samsung HC16](https://img.shields.io/badge/VRAM-16%20GB%20GDDR6%20(Samsung%20HC16)-8b5cf6.svg)]()
[![Bandwidth: 512 GB/s](https://img.shields.io/badge/Bandwidth-512.0%20GB%2Fs%20(8001%20MHz)-10b981.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Engineering documentation, reverse-engineering findings, scripts, and real-world LLM benchmarks for the **16GB Modded NVIDIA GeForce RTX 3070** running at **8001 MHz (16 Gbps native / 512 GB/s)** on Linux.

Developed and validated by **Nines Lab** (Brazil 🇧🇷).

> **Hardware Tested & Verified by Nines Lab:**
> * **GPU:** Galax GeForce RTX 3070 LHR 1-Click OC (Originally 8 GB GDDR6)
> * **Device ID:** `10DE:2488` (GA104-302 LHR revision)
> * **VRAM Mod:** 8x 16 Gbit Samsung K4ZAF325BM-HC16 modules (16 GB GDDR6 total)
> * **Hardware Straps:** Strap 6 (RAMCFG: High / High / Low)
> * **Rated Memory Speed:** 16 Gbps (8000 MHz @ 1.35V JEDEC)
> * **Motherboard & CPU:** ASUS TUF GAMING B660M-PLUS D4 | Intel Core i7-12700K
> * **OS:** Linux Mint 21.3 "Virginia" (Ubuntu 22.04 Jammy LTS base)
> * **Kernel & Driver:** Linux Kernel `6.8.0-138-generic` | NVIDIA Open Kernel Module `615.71.09-open`

---

## 📸 Proof of Concept: 15.5 GB VRAM @ 8001 MHz & 219W Under Full Load

![nvtop 8001MHz Verification](assets/nvtop_8001mhz_proof.jpg)
*Real-time `nvtop` capture during local 27B parameter LLM inference: **MEM 8001 MHz**, **GPU 1890 MHz**, **Power: 219W / 220W**, **15.11 GB / 16.00 GB VRAM allocated**, **GPU Util: 97%**.*

---

## ⚡ Executive Summary

The GeForce RTX 3070 reference design ships with 8 GB of 14 Gbps GDDR6. By replacing the 8x 8Gb memory chips with **16Gb Samsung K4ZAF325BM-HC16** chips and configuring **Strap 6 (High / High / Low)**, the card addresses **16,384 MiB (16 GB) of VRAM**.

However, running this mod on desktop cards reveals architectural constraints:
1. **The Factory VBIOS Flaw:** OEM BIOSes (such as Galax 1-Click OC) copied 8GB timing tables for all low/intermediate P-states (`WR_RCD=1` on P8 405 MHz, `WR_RCD=2` & 4-cycle turnaround on P5 810 MHz, `CL=20` on P3 5001 MHz), causing video decoding (NVDEC) and idle write collisions.
2. **The Hardware Root of Trust Constraint:** Ampere GA104 Falcon SEC2 processor validates cryptographic RSA/ECC signatures on cold boot. Flashing modified physical EEPROM images bricks the card (Code 43 / No POST).
3. **The Shadow Memory Discovery:** Complete PCI BAR0/BAR1 reverse-engineering scans (probing all 8 GiB of mapped VRAM) proved that the GPU Falcon PMU decodes timings directly into internal silicon registers (`BAR0+0x900000` to `0x9A0000`) on cold boot; **no raw shadow table exists in VRAM**.

### The Engineering Solution (Scenario B):
* The Samsung **`K4ZAF325BM-HC16`** chips are factory-certified by Samsung for **16 Gbps (8000 MHz)** at stock 1.35V.
* By applying `factory_memory_offset_mhz = 1000` to the official VBIOS factory clock record (`P+0x98`) and patching the NVIDIA open kernel driver (`kern_cuda_limit.c`) to disable the artificial CUDA P2 downclock, **both 3D Gaming and CUDA AI Workloads run equalized at exactly 8001 MHz (512.0 GB/s)**.
* **No state exceeds 8001 MHz:** Full adherence to Samsung's nominal -HC16 factory specification.

---

## 📊 VRAM Bandwidth Comparison: 3070 16GB Mod vs Ampere Lineup

Operating at 8001 MHz across its 256-bit bus, the modded RTX 3070 reaches **512.0 GB/s**:

![VRAM Bandwidth Comparison](assets/vram_bandwidth_comparison_en.png)

| Graphics Card | Bus Width | Memory Type | Memory Clock | Memory Bandwidth | Comparison vs Modded 3070 16GB |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **RTX 3070 Stock** | 256-bit | 8GB GDDR6 | 7001 MHz (14 Gbps) | **448.0 GB/s** | +14.3% faster |
| **RTX 3070 16GB Mod** | **256-bit** | **16GB GDDR6 (-HC16)** | **8001 MHz (16 Gbps)** | **512.0 GB/s** | **Baseline (100%)** |
| **RTX 3080** | 320-bit | 10GB GDDR6X | 9502 MHz (19 Gbps) | **760.3 GB/s** | **67.3% of RTX 3080 bandwidth** |
| **RTX 3090** | 384-bit | 24GB GDDR6X | 9752 MHz (19.5 Gbps) | **936.2 GB/s** | **54.7% of RTX 3090 bandwidth** |

> **Key Takeaway:** A 220W 256-bit modded card delivers **more than half (55%) of the bandwidth of a flagship 384-bit RTX 3090**, and over **two-thirds (67%) of an RTX 3080**, with a tiny thermal footprint.

---

## 🧠 Real-World LLM Inference Benchmark

We evaluated local LLM generation performance using **`Qwen 3.8 27B Uncensored (GSQ-RCO / IQ3_M)`** with a **65,536 (64k) Context Window** via Ollama / llama.cpp on Linux Mint 21.3 (Kernel 6.8, Driver 615.71.09-open).

* **Model Footprint:** **15,499 MiB (15.5 GB VRAM allocated)**. This model **instantly causes Out-Of-Memory (OOM) on any stock 8GB RTX 3070**.

![Qwen 27B Speedup](assets/qwen_27b_iq3m_speedup_en.png)

### Generation Speed Scaling (Tokens / Second):

| Test Prompt Category | 6801 MHz (Stock Compute P2) | 7301 MHz (+500 MHz Offset) | 8001 MHz (16 Gbps Samsung -HC16) | Total Speedup vs Stock |
| :--- | :---: | :---: | :---: | :---: |
| **Small (Recursive Logic)** | 53.73 t/s | 55.51 t/s | **61.42 t/s** | **+14.31%** |
| **Medium (Linux Conceptual / OS)** | 41.46 t/s | 43.47 t/s | **48.15 t/s** | **+16.14%** |
| **Large (C Red-Black Tree Implementation)** | 47.31 t/s | 47.66 t/s | **52.84 t/s** | **+11.69%** |
| **OVERALL AVERAGE THROUGHPUT** | **47.50 t/s** | **48.88 t/s** | **54.14 t/s** | **+13.98%** |

* **Full 64k Pre-Allocated KV-Cache Stress:** Operating under maximum context saturation (`-c 65536`), generation sustained **27.55 tokens/second** at **216W** and **37°C–52°C**.

---

## ⚙️ Operating Modes: Pros, Cons & Pitfalls

We provide three native software-controlled power modes to balance thermals, noise, and maximum performance:

### 1. `gpu-eco` — 405 MHz (P8 State)
* **Command:** `gpu-eco`
* **Memory Clock:** 405 MHz | **Bandwidth:** 25.9 GB/s | **Power Draw:** **~11.8 W** | **Temp:** **~24°C** (0 RPM)
* **Pros:** Minimum power consumption; zero electrical and thermal stress on GDDR6 PHY and memory chips; perfectly silent; allows clean S3 sleep and wake.
* **Cons:** Low graphical and compute throughput; not intended for gaming or LLM execution.
* **Pitfalls:** Do not attempt hardware NVDEC video decoding on the 3070 while locked at 405 MHz (the stock Galax BIOS has a write collision bug on P8). Use your host iGPU for 2D displays, or switch to `gpu-perf`/`gpu-ultra` prior to opening hardware video players.

### 2. `gpu-perf` — 6801 MHz (Safety Performance State)
* **Command:** `gpu-perf`
* **Memory Clock:** 6801 MHz | **Bandwidth:** 435.2 GB/s | **Power Draw:** ~40.0 W | **Temp:** ~30°C
* **Pros:** 100% rock-solid stability on factory P0 timing tables (`Timing ID 38`); runs any game, compute kernel, and 4K video player with zero risk of bus collision.
* **Cons:** Idles at ~40W continuously if left active when away from the PC.
* **Pitfalls:** Consumes ~28W more than `gpu-eco` when idle. Best practice: switch back to `gpu-eco` when stepping away from the desk.

### 3. `gpu-ultra` / `gpu-max` — 8001 MHz (16 Gbps Samsung Native)
* **Command:** `gpu-ultra`
* **Memory Clock:** 8001 MHz | **Bandwidth:** **512.0 GB/s** | **Power Draw:** ~45.0 W | **Temp:** ~32°C (Idle) / ~55°C (Full 219W Load)
* **Pros:** Unleashes full 16 Gbps nominal speed of Samsung `-HC16` modules; **+17.6% bandwidth boost**; yields **14% to 16% faster LLM token generation** on large contexts; zero over-spec degradation since chips are natively certified for 16 Gbps at 1.35V.
* **Cons:** Peak power consumption under full load (~219W).
* **Pitfalls:** None. The card runs exceptionally cool and operates 100% within Samsung's factory electrical and thermal specifications at stock 1.35V.

---

## 🛠️ Repository Contents & Scripts

All tools and scripts are located in the [`scripts/`](scripts/) directory:

| File | Purpose |
| :--- | :--- |
| **[`scripts/gpu-eco`](scripts/gpu-eco)** | Locks memory to 405 MHz (P8) for idle, work, and S3 suspend. |
| **[`scripts/gpu-perf`](scripts/gpu-perf)** | Locks memory to 6801 MHz for stable everyday gaming and compute. |
| **[`scripts/gpu-ultra`](scripts/gpu-ultra)** | Locks memory to 8001 MHz (16 Gbps) for maximum AI inference and 4K gaming. |
| **[`scripts/setup_nines_modes.sh`](scripts/setup_nines_modes.sh)** | Automated setup: installs commands to `/usr/local/bin/`, configures passwordless sudoers rules, boot service, and desktop shortcuts. |
| **[`scripts/patch_kernel_cuda_p0.patch`](scripts/patch_kernel_cuda_p0.patch)** | Kernel driver patch for `open-gpu-kernel-modules` (`kern_cuda_limit.c`) to disable CUDA P2 downclocking. |
| **[`scripts/patch_vbios_8001mhz.py`](scripts/patch_vbios_8001mhz.py)** | Offline tool to set `factory_memory_offset_mhz = 1000` via Vix-Editor and generate normalized payloads. |
| **[`tables.md`](tables.md)** | Full reverse-engineering documentation of all 76-byte GDDR6 timing records and memory clock bands. |

---

## 🔬 Critical Engineering Pitfalls Explained

### 1. The Byte `+0x0F` Pitfall (Quadro ECC vs GeForce GA104)
* **NEVER set byte `+0x0F` (`0xD3C0`) in Memory Descriptor Entry 6 to `0x10` (from RTX A4000).**
* On workstation A4000 boards, `0x10` enables ECC memory structures. On consumer GeForce GA104 silicon (which lacks hardware ECC), GSP firmware hangs on RPC function 76 during cold boot, triggering `RC watchdog: GPU is probably locked!`, emergency 100% fan ramp, and fatal Xid 154 errors.
* On native GeForce 16GB VBIOSes (e.g. RTX 3080 Mobile 16GB), byte `+0x0F` is strictly **`0x00`**.

### 2. The CUDA P2 Downclock Pitfall
* The standard NVIDIA driver contains an artificial rule called **CUDA Force P2 State**, which downclocks memory by 200 MHz whenever a CUDA context initializes.
* Applying [`scripts/patch_kernel_cuda_p0.patch`](scripts/patch_kernel_cuda_p0.patch) forces `bCudaLimit = NV_FALSE` in the kernel module, equalizing both 3D gaming and CUDA AI workloads at **8001 MHz**.

---

## 🇧🇷 Author & Acknowledgements

* **Developed and Documented by Nines Lab** (Brazil 🇧🇷).
* **To the VRAM Modding Pioneers:** To **Paulo Gomes** (*Paulo Gomes* YouTube channel) and **VIK-on** (*VIK-on* YouTube channel), for pioneering, building, testing, and popularizing 16 GB VRAM modifications on the GeForce RTX 3070 worldwide.
* **To Gregory (*GDTech Informática* YouTube channel):** For his gold-standard technical reference in advanced component-level GPU repair, boardview/schematic analysis, and electronic diagnostics in the Brazilian repair community.
* **To Zagitta and Petri Krohn:** For the [`gpu-unlock`](https://github.com/Zagitta/gpu-unlock) project and research into the GA104 Falcon SEC2 security processor, unlocking full enterprise compute and virtualization potential on Ampere.
* **To Panchovix and @pantsoftime:** For [`vix-editor`](https://github.com/Panchovix/nvidia-vbios-vix-editor) and [`vix-loader`](https://github.com/Panchovix/nvidia-linux-vbios-vix-loader), essential tools for auditing internal VBIOS structures and understanding driver clock offset mechanics.

---

## 📜 Compliance & Safety Notice

* **DMCA Compliance:** This repository contains **NO proprietary NVIDIA VBIOS binary images (`.rom` or `.bin`)**.
* **Safety:** All overclocks operate within Samsung's official factory rating for `K4ZAF325BM-HC16` modules at JEDEC standard 1.35V.
* **Branding:** Designed and documented by **Nines Lab** (Brazil 🇧🇷).
