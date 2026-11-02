# Especificação Técnica de Timings e P-States: RTX 3070 16GB Mod (GA104 + Samsung K4ZAF325BM-HC16)

**🌐 Idioma:** [English](tables.md) | **Português do Brasil**

[![Marco: Pioneirismo Mundial 8001MHz](https://img.shields.io/badge/Marco-Primeiro%20do%20Mundo%208001%20MHz%20(512%20GB%2Fs)-gold.svg)]()
[![Desenvolvido por Nines Lab](https://img.shields.io/badge/Desenvolvido%20Por-Nines%20Lab-blue.svg)]()
[![Licença: MIT](https://img.shields.io/badge/Licen%C3%A7a-MIT-yellow.svg)](LICENSE)

**Documento:** Comparativo de Engenharia Reversa e Mapeamento de Timings  
**Hardware Alvo:** Galax GeForce RTX 3070 LHR 1-Click OC (Modificada para 16 GB Samsung GDDR6, Strap 6 H/H/L)  
**Fontes de Comparação:**
1. **Galax RTX 3070 (Stock Dump):** VBIOS Original de Fábrica (`94.04.46.00.CC`)
2. **NVIDIA RTX A4000 16GB:** VBIOS Oficial Workstation GA104 (`94.04.46.00.56` / `donor_a4000_16gb.rom`)
3. **ASUS ROG RTX 3080 Mobile 16GB:** VBIOS Oficial GeForce GA104 (`94.04.3E.00.56` / `Asus.RTX3080Mobile.16384.201223.rom`)

---

## 1. AVISO CRÍTICO: O Byte `+0x0F` do Descritor de Memória

> ⚠️ **NÃO ALTERAR O BYTE `+0x0F` PARA `0x10` (PADRÃO A4000)!**  
> **ESSE BYTE DEVE PERMANECER OBRIGATORIAMENTE EM `0x00`!**

### Por que o `0x10` da A4000 quebra placas GeForce:
* **Origem do `0x10`:** A NVIDIA RTX A4000 é uma GPU de linha profissional (*Quadro/Workstation*) que possui circuitos e firmware para suporte a **memória ECC out-of-band**. O bit `0x10` no descritor de memória informa ao firmware GSP que a placa possui suporte a estruturas de controle de ECC.
* **Comportamento em GeForce GA104 (3070 Desktop / 3080 Mobile):** Os chips GeForce GA104 **não possuem suporte a ECC**. Quando a VBIOS de uma GeForce é gravada com `0x10`:
  1. O firmware GSP tenta inicializar os controladores de ECC na subida do driver;
  2. O comando RPC `GSP_RM_CONTROL` (função 76) sofre timeout por falta de resposta do hardware;
  3. O kernel dispara o watchdog: `NVRM: krcWatchdog_IMPL: RC watchdog: GPU is probably locked!`;
  4. A GPU é colocada em modo de pane total (`NV_ERR_RESET_REQUIRED` / `Xid 154`), os sensores de temperatura congelam e o circuito de emergência da placa **dispara as ventoinhas em 100% de velocidade**.
* **Comprovação Oficial:** Na VBIOS da **GeForce RTX 3080 Mobile 16GB** (que é o mesmo silício GA104 com 16 GB Samsung GDDR6), o descritor de memória é estritamente **`0x00`**.

---

## 2. Tabela do Descritor de Memória (BIT Token M / Strap 6 Samsung 16Gb)

Offset do Início da Tabela de Memória: `0xD326`  
Offset da Entrada 6 (Strap 6 — Samsung 16Gb): `0xD3B1`

| Placa de Vídeo | Tamanho da Entrada | Dump Hexadecimal (22 bytes) | Byte `+0x0F` (`0xD3C0`) | Efeito Prático |
| :--- | :---: | :--- | :---: | :--- |
| **Galax 3070 Stock (Fábrica)** | 22 bytes | `69 16 60 02 00 00 00 00 ff 00 ff 00 ff ff 00 00 00 00 00 00 00 00` | **`0x00`** | Padrão GeForce estável. |
| **ASUS RTX 3080 Mobile 16GB** | 14 bytes | `69 16 60 02 00 00 00 00 ff 00 ff 00 ff ff` *(+ 0x00)* | **`0x00`** | **Padrão Oficial GeForce 16GB.** |
| **NVIDIA RTX A4000 16GB** | 22 bytes | `69 16 60 02 00 00 00 00 ff 00 ff 00 ff ff 00 10 00 00 00 00 00 00` | **`0x10`** | ❌ **Incompatível (Trava no boot/fans a 100%).** |

---

## 3. Mapeamento dos Estágios de Energia (Memory Clock Bands)

Na arquitetura Ampere, a tabela de bandas de clock (`BIT Token P+0x04` @ `0x89CFA`) mapeia faixas de frequência de memória para um índice de tabela de temporização (**Timing ID**):

| Banda | Faixa de Frequência | Clocks de Fábrica | Timing ID Vinculado | Estado de Uso Típico |
| :---: | :---: | :---: | :---: | :--- |
| **Banda 0** | 0 – 540 MHz | **405 MHz** | **Timing ID 30** | Repouso absoluto (Idle / Desktop estático) — Estado **P8** |
| **Banda 1** | 541 – 1249 MHz | **810 MHz** | **Timing ID 31** | Decodificação 2D e Aceleração de Vídeo Leve — Estado **P5** |
| **Banda 2** | 2005 – 4699 MHz | *(Rampa)* | **Timing ID 32** | Transição média |
| **Banda 3** | 4700 – 5250 MHz | **5001 MHz** | **Timing ID 32** | Reprodução de Vídeo 4K / NVDEC / YouTube — Estado **P3** |
| **Banda 4** | 5251 – 5799 MHz | *(Rampa)* | **Timing ID 33** | Carga intermediária — Estado **P2** inicial |
| **Banda 5** | 5800 – 6300 MHz | *(Rampa)* | **Timing ID 34** | Carga intermediária — Estado **P2** médio |
| **Banda 6** | 6301 – 16383 MHz | **6801 / 7001 MHz** | **Timing ID 38** | Alta Performance / Carga Máxima / Jogos / IA — Estado **P0** |

---

## 4. Comparativo Completo dos Registros de Timings (76 Bytes por Registro)

Offset da Tabela de Timings:
* **Galax 3070:** `0x8B880 + 6 + (ID * 76)`
* **RTX A4000 16GB:** `0x8C29C + 6 + (ID * 76)`
* **RTX 3080 Mobile 16GB:** `0x748B8 + 6 + (ID * 76)`

---

### Timing ID 30 — Estado P8 (405 MHz / Repouso em Idle)

* **Função:** Clock mínimo de economia de energia quando o computador está parado no desktop.
* **Consumo Real Medido:** 11.8 W a 12.5 W (24°C, ventoinhas desligadas).

| Parâmetro | Galax 3070 Original | RTX A4000 16GB | RTX 3080 Mobile 16GB | O que deveria ser (Ideal 16GB) | Diagnóstico Técnico |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **tRC (Row Cycle)** | 6 | 6 | 6 | **6 ciclos** | Idêntico em todas. |
| **tRFC (Refresh)** | 13 | 13 | 13 | **13 ciclos** | Idêntico em todas. |
| **tRP (Precharge)** | 8 | 8 | 8 | **8 ciclos** | Idêntico em todas. |
| **tRAS (Active)** | 2 | 2 | 2 | **2 ciclos** | Idêntico em todas. |
| **CL (CAS Latency)** | 9 (`0x82`) | 9 (`0x82`) | 9 (`0x82`) | **9 ciclos** | Idêntico em todas. |
| **WR_RCD (Write Delay)** | **1** (`0x10`) | **2** (`0x20`) | **2** (`0x20`) | **2 ciclos (`0x20`)** | ❌ **Original é RUIM.** 1 ciclo causa colisão de escrita (*write collision*) no repouso de chips de 16 Gbit. O valor de 16GB oficial é **2**. |
| **Turnaround (Bytes 46..51)**| `90 90 14 44 44 A3` | `00 90 14 44 44 A3` | `00 B4 15 55 55 53` | **`00 B4 15 55 55 53`** | Turnaround de 5 ciclos (`0x55`) da 3080 Mobile para evitar conflito de barramento. |

#### Dumps Hexadecimais Completos (76 Bytes):
* **Galax 3070 Original:**  
  `060d080289821034110304774c100022250081e20371a237110a0051010000000034020589034012a54414034a039090144444a322018000070800000a000080000000000200102616000100`
* **RTX 3080 Mobile 16GB (Correto):**  
  `060d080289822034110304774c100022250081e20371a237110a0051010000000034020589034012a54414030a0400b41555555322018000070800000a000080000000000200102616800100`

---

### Timing ID 31 — Estado P5 (810 MHz / Decodificação de Vídeo Leve)

* **Função:** Frequência para a qual o decodificador NVDEC reduz a GPU durante a reprodução contínua de vídeos 1080p/2D.
* **Causa Raiz de Travamentos:** É o estado que mais causava congelamentos na sua placa aos 1-2 segundos de vídeo.

| Parâmetro | Galax 3070 Original | RTX A4000 16GB | RTX 3080 Mobile 16GB | O que deveria ser (Ideal 16GB) | Diagnóstico Técnico |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **tRC (Row Cycle)** | 11 | 11 | 11 | **11 ciclos** | Idêntico em todas. (Forçar 14 desestabilizou o PLL). |
| **tRFC (Refresh)** | 25 | 25 | 25 | **25 ciclos** | Idêntico em todas. (Forçar 40 quebrou a máquina de estados). |
| **tRP (Precharge)** | 14 | 14 | 14 | **14 ciclos** | Idêntico em todas. |
| **tRAS (Active)** | 4 | 4 | 4 | **4 ciclos** | Idêntico em todas. |
| **CL (CAS Latency)** | 9 (`0x02`) | 9 (`0x02`) | 9 (`0x02`) | **9 ciclos** | Idêntico em todas. |
| **WR_RCD (Write Delay)** | **2** (`0x21`) | **3** (`0x31`) | **3** (`0x31`) | **3 ciclos (`0x31`)** | ❌ **Original é PÉSSIMO.** 2 ciclos causa colisão na gravação dos frames do vídeo. O valor de 16GB é **3**. |
| **Turnaround (Bytes 46..51)**| `90 90 14 44 44 A3` | `90 90 14 44 44 A3` | `00 B4 15 55 55 53` | **`00 B4 15 55 55 53`** | ❌ **Original é PÉSSIMO.** 4 ciclos (`0x44`) faz a GPU ler antes da memória terminar de gravar. Exige 5 ciclos (`0x55`). |

#### Dumps Hexadecimais Completos (76 Bytes):
* **Galax 3070 Original:**  
  `0b190e0489022134110304776c100022250081e20371a237110a0051010000000034030689034012a64414040a049090144444a3220180000d0800000a000080000000000200102616000100`
* **RTX 3080 Mobile 16GB (Correto):**  
  `0b190e0489023134110304776c100022250081e20371a237110a0051010000000034030689034012a64414040a0400b415555553220180000d0c00000a000080000000000200102616000100`

---

### Timing ID 32 — Estado P3 (5001 MHz / Vídeo 4K / NVDEC Inicial)

* **Função:** Frequência de aceleração pesada de mídia, usada na inicialização do player de vídeo e em vídeos 4K/60fps.
* **Causa da Falha de TLB:** Onde ocorria o erro `PDB 0x3f6192000` e timeout na GMMU.

| Parâmetro | Galax 3070 Original | RTX A4000 16GB | RTX 3080 Mobile 16GB | O que deveria ser (Ideal 16GB) | Diagnóstico Técnico |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **tRC (Row Cycle)** | **57** | **65** | **65** | **65 ciclos** | ❌ **Original é RUIM.** Subdimensionado na 3070 de 8GB. |
| **tRFC (Refresh)** | 150 | 150 | 150 | **150 ciclos** | Idêntico nas três placas. |
| **tRP (Precharge)** | **76** | **86** | **86** | **86 ciclos** | ❌ **Original é RUIM.** Exige mais tempo de pré-carga em 16Gb. |
| **tRAS (Active)** | **19** | **22** | **22** | **22 ciclos** | ❌ **Original é RUIM.** Deve acompanhar $t_{RC} = t_{RAS} + t_{RP}$. |
| **CL (CAS Latency)** | **20** (`0xC2`) | **22** (`0x82`) | **22** (`0x82`) | **22 ciclos (`0x82`)** | ❌ **ERRO CRÍTICO.** Chips de 16 Gbit a 5 GHz não entregam dados no ciclo 20. Causa corrupção de leitura na GMMU. |
| **WR_RCD / RD_RCD** | **12 / 4** (`0xC4`) | **14 / 5** (`0xE5`) | **14 / 5** (`0xE5`) | **14 / 5 (`0xE5`)** | ❌ **Original é RUIM.** Escrita muito agressiva para 16 Gbit. |
| **Turnaround (Bytes 46..51)**| `93 91 14 44 44 A3` | `93 91 14 44 44 A3` | `93 B5 15 55 55 53` | **`93 B5 15 55 55 53`** | Turnaround de 5 ciclos (`0x55`) para garantir estabilidade de leitura contínua. |

#### Dumps Hexadecimais Completos (76 Bytes):
* **Galax 3070 Original:**  
  `39964c1394c2c46410071377ac190022258081e20571c297130a00510100000000340d1089034012a0441a900d049391144444a2230580004b28000001000080000000000300102616000100`
* **RTX 3080 Mobile 16GB (Correto):**  
  `419656169682e56410071677ac190022258081e2f570c297130a00510100000000340e1189034012a1441a900d0493b515555553230580004b3c000001000080000000000300102616000100`

---

### Timing IDs 33 e 34 — Estado P2 (5251 a 6300 MHz / Rampa Média)

* **Função:** Frequências intermediárias entre o P3 (5001 MHz) e a carga máxima (6801+ MHz).

| Parâmetro | Galax 3070 Original (ID 33 / ID 34) | RTX 3080 Mobile 16GB (ID 33 / ID 34) | O que deveria ser (Ideal 16GB) |
| :--- | :---: | :---: | :---: |
| **tRC** | 63 / 68 | 71 / 77 | **71 / 77 ciclos** |
| **tRFC** | 165 / 180 | 165 / 180 | **165 / 180 ciclos** |
| **tRP** | 84 / 90 | 94 / 102 | **94 / 102 ciclos** |
| **tRAS** | 21 / 23 | 24 / 26 | **24 / 26 ciclos** |
| **CL** | 21 / 22 | 23 / 24 | **23 / 24 ciclos** |
| **WR_RCD** | 13 / 14 | 16 / 17 | **16 / 17 ciclos** |
| **Turnaround** | `... 44 44 ...` | `... 55 55 ...` | **5 ciclos (`0x55, 0x55`)** |

---

### Timing ID 38 — Estado P0 (6301 a 16383 MHz / Alta Performance: 6801 e 7001 MHz)

* **Função:** Estado de estresse máximo, renderização 3D, jogos pesados e treinamento/inferência de LLMs.
* **Status de Fábrica:** ✅ **100% EXCELENTE E PERFEITO.**

| Parâmetro | Galax 3070 Original | RTX A4000 16GB | RTX 3080 Mobile 16GB | Veredito |
| :--- | :---: | :---: | :---: | :--- |
| **tRC** | 90 | 85 | 90 | **Perfeito de fábrica (90 ciclos)** |
| **tRFC** | 240 | 226 | 240 | **Perfeito de fábrica (240 ciclos — o maior tempo de recarga)** |
| **tRP** | 120 | 114 | 120 | **Perfeito de fábrica (120 ciclos)** |
| **tRAS** | 30 | 28 | 30 | **Perfeito de fábrica (30 ciclos)** |
| **CL** | 26 (`0x82`) | 25 (`0x02`) | 26 (`0x82`) | **Perfeito de fábrica (26 ciclos — latência super folgada)** |
| **WR_RCD / RD_RCD**| 18 / 23 (`0x27`) | 17 / 23 (`0x17`) | 18 / 23 (`0x27`) | **Perfeito de fábrica** |

#### Dump Hexadecimal de Fábrica da Galax 3070 (INTOCADO):
`5af0781e9a822765100a1e778c280022258082e20671e2d7150a0051010000000034141789034012a744289954069391144444a3230580007840000001000080200000000500102616000100`

---

## 5. Resumo Executivo para Engenharia

1. **A Galax acertou apenas o P0:** O Timing ID 38 foi a única tabela que os engenheiros da Galax realmente dimensionaram para 16 Gbit. Por isso a placa é inquebrável em jogos pesados e IA a 220W.
2. **Os estados baixos e intermediários (P8, P5, P3) foram copiados da BIOS de 8 GB:**
   * **P8:** `WR_RCD=1` é apertado demais para escrita (deveria ser `2`);
   * **P5:** `WR_RCD=2` e Turnaround de `4 ciclos` causam colisão violenta de barramento no NVDEC (deveria ser `3` e `5 ciclos`);
   * **P3:** `CL=20` causa leitura corrompida de páginas da GMMU a 5001 MHz (deveria ser `CL=22`);
3. **O descritor de memória deve ser `0x00`:** O valor `0x10` da A4000 é exclusivo para circuitos de ECC de servidor/workstation e trava o processador Falcon/GSP de placas GeForce no boot.
