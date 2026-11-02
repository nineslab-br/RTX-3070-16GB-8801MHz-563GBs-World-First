# RTX 3070 16GB Mod @ 8801 MHz (563 GB/s) — Pioneirismo Mundial e Guia de Engenharia

**🌐 Idioma:** [English](README.md) | **Português do Brasil**

[![Marco: Primeira RTX 3070 16GB @ 8801MHz](https://img.shields.io/badge/Marco-Primeira%20RTX%203070%2016GB%20%40%208801%20MHz%20(563%20GB%2Fs)-gold.svg)]()
[![Desenvolvido por Nines Lab - Brazil](https://img.shields.io/badge/Desenvolvido%20Por-Nines%20Lab%20--%20Brazil%20%F0%9F%87%A7%F0%9F%87%B7-blue.svg)]()
[![Testado em: Linux Mint 21.3](https://img.shields.io/badge/Testado%20em-Linux%20Mint%2021.3%20Virginia-brightgreen.svg)]()
[![Arquitetura: Ampere GA104](https://img.shields.io/badge/Arquitetura-Ampere%20GA104-blueviolet.svg)]()
[![VRAM: 16 GB RX 6800 Doadora](https://img.shields.io/badge/VRAM-16%20GB%20Samsung%20HC16%20(Doadora%20RX%206800)-8b5cf6.svg)]()
[![Largura de Banda: 563 GB/s](https://img.shields.io/badge/Banda-563.2%20GB%2Fs%20(8801%20MHz)-10b981.svg)]()
[![Licença: MIT](https://img.shields.io/badge/Licen%C3%A7a-MIT-yellow.svg)](LICENSE)

Documentação técnica de engenharia reversa, scripts, ferramentas de controle e benchmarks reais de inferência de LLMs para a **GeForce RTX 3070 modificada para 16 GB** operando em **8801 MHz (17.6 Gbps nominais / 563.2 GB/s)** no Linux.

Desenvolvido e validado pela **Nines Lab - Brazil 🇧🇷**.

> **Hardware Testado e Homologado pela Nines Lab - Brazil:**
> * **GPU Alvo:** Galax GeForce RTX 3070 LHR 1-Click OC (Originalmente 8 GB GDDR6)
> * **PCI Device ID:** `10DE:2488` (Revisão GA104-302 LHR)
> * **Procedência dos Módulos de VRAM:** 8x Chips Samsung K4ZAF325BM-HC16 (16 Gbit cada / 16 GB GDDR6 total), **colhidos e resgatados de uma AMD Radeon RX 6800 16GB doadora (RDNA2 Big Navi)** com o chip gráfico danificado.
> * **Configuração de Resistores:** Strap 6 (RAMCFG: High / High / Low)
> * **Velocidade Nominal dos Chips:** 16 Gbps (8000 MHz a 1.35V JEDEC)
> * **Frequência Máxima Validada:** **8801 MHz (17.6 Gbps / 563.2 GB/s de largura de banda)**
> * **Placa-Mãe & Processador:** ASUS TUF GAMING B660M-PLUS D4 | Intel Core i7-12700K
> * **Sistema Operacional:** Linux Mint 21.3 "Virginia" (Base Ubuntu 22.04 Jammy LTS)
> * **Kernel & Driver:** Linux Kernel `6.8.0-138-generic` | Módulo Aberto NVIDIA `615.71.09-open`

---

## 📸 Prova de Conceito: 15.56 GiB de VRAM @ 8801 MHz & 218W em Carga Máxima

![Verificação no nvtop a 8801MHz](assets/nvtop_8801mhz_proof.png)
*Captura em tempo real no `nvtop` durante inferência pesada de modelo LLM de 27B: **MEM 8801 MHz**, **GPU 1890 MHz**, **Consumo: 218W / 220W**, **15.559 GiB / 16.000 GiB de VRAM alocados (97.2%)**, **Uso da GPU: 98%**, **Temp: 55°C**.*

---

## ⚡ Resumo Executivo

A GeForce RTX 3070 de referência foi lançada com 8 GB de GDDR6 a 14 Gbps. Ao substituir os 8 módulos de 8Gb por chips **Samsung K4ZAF325BM-HC16 (16Gb cada)** resgatados de uma RX 6800 16GB doadora e configurar os resistores para **Strap 6 (High / High / Low)**, a placa passa a endereçar **16.384 MiB (16 GB) de VRAM**.

No entanto, a utilização desse mod em placas desktop esbarra em limitações arquiteturais:
1. **O Defeito da VBIOS Original:** VBIOSes de montadoras (como a Galax 1-Click OC) apenas copiaram tabelas de timing de 8GB para os estados baixos e intermediários (`WR_RCD=1` no P8 405 MHz, `WR_RCD=2` e turnaround de 4 ciclos no P5 810 MHz, `CL=20` no P3 5001 MHz), provocando congelamento ao abrir vídeos (NVDEC) e falhas no repouso/suspensão S3.
2. **A Raiz de Confiança por Hardware (Root of Trust):** O processador de segurança Falcon SEC2 da arquitetura Ampere checa assinaturas criptográficas RSA/ECC da NVIDIA no cold boot. Gravar VBIOS modificada no chip físico de SPI Flash inutiliza a placa (Código 43 / sem vídeo).
3. **A Descoberta da Memória Shadow:** Varreduras completas no barramento PCI BAR0/BAR1 (cobrindo todos os 8 GiB mapeados de VRAM) provaram que o hardware decodifica os timings diretamente nos canais de silício (`BAR0+0x900000` a `0x9A0000`) no boot; **não existe tabela shadow solta em VRAM para ser sobrescrita**.

### A Solução de Engenharia Implementada (Cenário B):
* Os chips Samsung **`K4ZAF325BM-HC16`** são oficialmente certificados pela Samsung para **16 Gbps (8000 MHz)** na tensão padrão de 1.35V.
* Configurando o offset oficial de clock de fábrica (`factory_memory_offset_mhz` no registro `P+0x98` da VBIOS) e aplicando um patch no driver aberto da NVIDIA (`kern_cuda_limit.c`) para desativar o limitador de computação CUDA (P2), **tanto os Jogos 3D quanto a IA em CUDA rodam equalizados com velocidade total**.
* A placa opera sólida a **8801 MHz (563.2 GB/s)** no dia a dia, validada sob 218W de carga contínua.

---

## ♻️ Procedência do Hardware: O Transplante da RX 6800 16GB Doadora

Um dos aspectos mais fascinantes deste projeto de bancada é a procedência dos módulos de memória:
* Os 8 módulos de 16 Gbit **Samsung K4ZAF325BM-HC16** não foram comprados em lotes duvidosos da internet; eles foram **resgatados de uma placa de vídeo AMD Radeon RX 6800 16GB (RDNA2 Big Navi)** com o chip gráfico danificado.
* A AMD equipou a linha Radeon RX 6800 com módulos Samsung `-HC16` de altíssimo padrão de silício, certificados de fábrica para operar a 16 Gbps na tensão padrão JEDEC de 1.35V.
* O transplante cirúrgico BGA desses módulos para o PCB da Galax RTX 3070 deu uma sobrevida nobre a memórias que estariam condenadas ao lixo eletrônico, permitindo empurrar o silício Samsung até incríveis **8801 MHz (17.6 Gbps / 563.2 GB/s)** de forma 100% estável.

---

## 📊 Comparativo de Largura de Banda: 3070 16GB Mod vs Linha Ampere

Rodando a 8801 MHz no barramento de 256 bits, a RTX 3070 modificada atinge **563.2 GB/s**:

![Comparativo de Largura de Banda de VRAM](assets/vram_bandwidth_comparison_pt.png)

| Placa de Vídeo | Largura de Barramento | Tipo de Memória | Clock da Memória | Largura de Banda | Comparativo vs 3070 16GB @ 8801 MHz |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **RTX 3070 Original** | 256-bit | 8GB GDDR6 | 7001 MHz (14 Gbps) | **448.0 GB/s** | Ponto de partida de fábrica |
| **RTX 3070 16GB Mod (Nominal)** | **256-bit** | **16GB GDDR6 (-HC16)** | **8001 MHz (16 Gbps)** | **512.0 GB/s** | +14.3% vs Stock |
| **RTX 3070 16GB Mod (Recorde Mundial)**| **256-bit** | **16GB GDDR6 (RX 6800)**| **8801 MHz (17.6 Gbps)**| **563.2 GB/s** | **+25.7% vs Stock (Recorde)** |
| **RTX 3080** | 320-bit | 10GB GDDR6X | 9502 MHz (19 Gbps) | **760.3 GB/s** | **74.1% da banda da RTX 3080** |
| **RTX 3090** | 384-bit | 24GB GDDR6X | 9752 MHz (19.5 Gbps) | **936.2 GB/s** | **60.2% da banda da RTX 3090** |

> **Destaque:** A 8801 MHz, uma placa de 220W com barramento de 256 bits entrega **74.1% de toda a largura de banda de uma RTX 3080** e **mais de 60% de uma topo de linha RTX 3090**, operando extremamente fria.

---

## 🧠 Benchmark Real de Inferência de IA (LLMs)

Avaliamos a performance real de geração de tokens utilizando o modelo **`Qwen 3.8 27B Uncensored (GSQ-RCO / IQ3_M)`** com **Janela de Contexto de 65.536 tokens (64k)** via Ollama / llama.cpp no Linux Mint 21.3 (Kernel 6.8, Driver 615.71.09-open).

* **Consumo de VRAM:** **15.56 GiB (15.559 GiB / 16.000 GiB de VRAM alocados / 97.2%)**. Esse modelo **daria erro imediato de falta de memória (OOM) em qualquer RTX 3070 original de 8 GB**.

![Aceleração no Qwen 27B](assets/qwen_27b_iq3m_speedup_pt.png)

### Escalabilidade de Velocidade de Geração em Todas as Frequências:

| Categoria do Prompt de Teste | 6801 MHz (Base Compute P2) | 7301 MHz (Offset +500 MHz) | 8801 MHz (Modo Ultra Validado) | Ganho Total vs Stock (%) |
| :--- | :---: | :---: | :---: | :---: |
| **Pequeno (Lógica Recursiva)** | 53.73 t/s | 55.51 t/s | **64.21 tokens/s** | **+19.51%** |
| **Médio (Conceitual Linux / SO)** | 41.46 t/s | 43.47 t/s | **51.85 tokens/s** | **+25.06%** |
| **Grande (Código C Árvore Rubro-Negra)** | 47.31 t/s | 47.66 t/s | **55.40 tokens/s** | **+17.10%** |
| **MÉDIA GERAL DE VELOCIDADE** | **47.50 t/s** | **48.88 t/s** | **57.15 tokens/s** | **+20.32%** |

* **Estresse de KV-Cache com 64k Ativo:** Sob saturação total do contexto de 64k (`-c 65536`), a velocidade sustentada foi de **28.10 tokens/segundo** a **218W** e temperatura controlada entre **38°C e 52°C**.

---

## 🎮 Validação 3D e Limite Elétrico (220W / 1x Conector 8 Pinos)

Validamos a estabilidade 3D contínua da placa no **Unigine Superposition** operando a **8801 MHz (563.2 GB/s)**:

| Resolução / Preset | Pontuação Oficial | FPS Médio | Validação Oficial |
| :--- | :---: | :---: | :--- |
| **1080p EXTREME** | **7.113 pontos** | 53.20 FPS | 🔗 [Submissão Certificada no HWBOT](https://hwbot.org/submission/6092224) |
| **4K OPTIMIZED** | **9.848 pontos** | 73.66 FPS | Executado com 100% de estabilidade |
| **8K OPTIMIZED** | **4.436 pontos** | 33.18 FPS | Executado com 100% de estabilidade |

> **Nota de Engenharia — O Envelope de 220W e a Verdadeira Vantagem do Mod:**  
> A pontuação bruta em benchmarks sintéticos reflete o limite elétrico da nossa placa (Galax 1-Click OC), que possui **apenas 1 conector de energia de 8 pinos e um teto rígido de 220W TDP**. No HWBOT, placas que atingem scores mais altos utilizam PCBs especiais de 2 ou 3 conectores com BIOSes de 280W a 320W (ou *shunt-mod*).  
> 
> **A maior vitória e o objetivo real deste mod não é consumir energia excessiva, mas sim:**
> 1. **Fim do Stuttering em Jogos:** Em títulos modernos pesados (*The Last of Us Part I, Hogwarts Legacy, Cyberpunk 2077 com Ray Tracing, Alan Wake 2* em 1440p/4K), uma 3070 normal de 8 GB estoura a VRAM e é forçada a trocar texturas pela PCIe, causando travamentos de frametime e texturas borradas. Com **16 GB físicos**, todas as texturas Ultra e estruturas de Ray Tracing residem 100% na VRAM, entregando **taxas de 1% Low perfeitas e jogabilidade lisa sem engasgos**.
> 2. **Inteligência Artificial Local Massiva:** Carrega modelos densos de 27B (como o Qwen 27B com contexto total de 64k alocando 15.56 GB de VRAM) que seriam impossíveis em uma 3070 original.
> 3. **Eficiência e Durabilidade:** Tudo isso dentro do projeto térmico e elétrico original da placa (220W a 1.35V), fria, silenciosa e com o controlador PHY protegido.

---

## ⚙️ Modos de Energia: Prós, Contras e Armadilhas (Pitfalls)

Disponibilizamos três perfis nativos:

### 1. `gpu-eco` — 405 MHz (Estado P8)
* **Comando:** `gpu-eco`
* **Clock de Memória:** 405 MHz | **Banda:** 25.9 GB/s | **Consumo Idle:** **~11.8 W** | **Temp:** **~24°C** (0 RPM)
* **Prós:** Consumo elétrico mínimo absoluto (~11.8W); zero estresse térmico ou elétrico no controlador PHY e nas memórias; silêncio absoluto (ventoinhas desligadas); permite entrar e retornar da suspensão S3 (Sleep) sem falhas. Como o clock fica travado estaticamente em 405 MHz via software, a GPU **não tenta realizar transições dinâmicas para P5 (810 MHz) ou P3 (5001 MHz), impedindo os travamentos/congelamentos da VBIOS original mesmo ao abrir vídeos**.
* **Contras:** Performance severamente limitada pela largura de banda reduzida de 25.9 GB/s. A reprodução de vídeos sofre perda de quadros (baixo FPS), jogos rodam com taxa de quadros injogável e a taxa de tokens em LLMs despenca.
* **Comportamento na Prática:** O sistema permanece **100% estável e não trava nem crasha a placa**, apenas opera com lentidão proposital devido à falta de largura de banda. Ideal para deixar o PC ligado fazendo downloads, lendo documentos/código, repouso noturno ou suspensão S3. Ao abrir vídeos em alta resolução, jogos ou iniciar inferência de IA, basta alternar para `gpu-perf` ou `gpu-ultra`.

### 2. `gpu-perf` — 6801 MHz (Modo de Segurança Diário)
* **Comando:** `gpu-perf`
* **Clock de Memória:** 6801 MHz | **Banda:** 435.2 GB/s | **Consumo Idle:** ~40.0 W | **Temp:** ~30°C
* **Prós:** Estabilidade de rocha de 100% sobre as tabelas originais da Galax (`Timing ID 38`); roda qualquer jogo, kernel de computação e vídeo 4K sem risco de colisão de barramento.
* **Contras:** Consumo contínuo de ~40W em repouso se deixado ligado sem uso.
* **Armadilhas (Pitfalls):** Consome ~28W a mais que o `gpu-eco`. Boa prática: volte para o `gpu-eco` ao se afastar da mesa de trabalho.

### 3. `gpu-ultra` / `gpu-max` — 8801 MHz (Performance Máxima)
* **Comando:** `gpu-ultra`
* **Clock de Memória:** 8801 MHz | **Banda:** **563.2 GB/s** | **Consumo:** ~45.0 W (Idle) / ~218W (Carga Máxima) | **Temp:** ~32°C (Idle) / ~52°C (Carga Total)
* **Prós:** Libera 17.6 Gbps; **+25.7% de aumento de largura de banda**; acelera a geração de tokens em IA em **mais de 20%**; zero risco de degradação por sobretensão, pois a placa opera na tensão padrão de 1.35V.
* **Contras:** Consumo de energia em carga máxima de computação (~218W).
* **Armadilhas (Pitfalls):** Nenhuma. A placa opera fria (abaixo de 55°C) e trabalha 100% dentro dos limites elétricos seguros do silício.

---

## 🛠️ Conteúdo do Repositório e Scripts

Todos os scripts e ferramentas estão organizados na pasta [`scripts/`](scripts/):

| Arquivo | Função |
| :--- | :--- |
| **[`scripts/gpu-eco`](scripts/gpu-eco)** | Trava a memória em 405 MHz (P8) para trabalho leve, repouso e suspensão S3. |
| **[`scripts/gpu-perf`](scripts/gpu-perf)** | Trava a memória em 6801 MHz para estabilidade total em jogos e computação. |
| **[`scripts/gpu-ultra`](scripts/gpu-ultra)** | Trava a memória em 8801 MHz (563.2 GB/s) para máxima velocidade em IA e 4K. |
| **[`scripts/setup_nines_modes.sh`](scripts/setup_nines_modes.sh)** | Instalador automatizado: copia para `/usr/local/bin/`, configura sudoers sem senha, serviço de boot e atalhos na Área de Trabalho. |
| **[`scripts/patch_kernel_cuda_p0.patch`](scripts/patch_kernel_cuda_p0.patch)** | Patch para o driver de kernel aberto (`kern_cuda_limit.c`) desativando a redução artificial para P2 em CUDA. |
| **[`scripts/patch_vbios_8001mhz.py`](scripts/patch_vbios_8001mhz.py)** | Ferramenta offline para aplicar `factory_memory_offset_mhz` via Vix-Editor e gerar o payload normalizado. |
| **[`tabelas.md`](tabelas.md)** | Documentação completa de engenharia reversa de todos os 76 bytes de timing e bandas de clock. |

---

## 🔬 Armadilhas de Engenharia Explicadas

### 1. A Armadilha do Byte `+0x0F` (Quadro ECC vs GeForce GA104)
* **NUNCA altere o byte `+0x0F` (`0xD3C0`) na Entrada 6 para `0x10` (da RTX A4000).**
* Em placas de workstation Quadro A4000, `0x10` ativa rotinas de memória ECC. No silício GeForce GA104 (que não tem ECC físico), o firmware GSP trava na função RPC 76 no boot frio, disparando `RC watchdog: GPU is probably locked!`, ventoinhas a 100% em modo de emergência e erro fatal Xid 154.
* Em VBIOSes oficiais de GeForce 16GB nativas (como a RTX 3080 Mobile 16GB), esse byte é estritamente **`0x00`**.

### 2. A Armadilha do Downclock para P2 em CUDA
* O driver proprietário da NVIDIA contém uma regra artificial chamada **CUDA Force P2 State**, que derruba a memória em 200 MHz sempre que qualquer contexto CUDA é iniciado.
* A aplicação do patch [`scripts/patch_kernel_cuda_p0.patch`](scripts/patch_kernel_cuda_p0.patch) força `bCudaLimit = NV_FALSE` no módulo do kernel, equalizando tanto jogos 3D quanto tarefas de IA diretamente na frequência máxima.

---

## 🇧🇷 Autoria e Agradecimentos

* **Desenvolvido e Documentado por Nines Lab - Brazil 🇧🇷**.
* **Aos pioneiros dos mods de VRAM:** A **Paulo Gomes** (*Canal Paulo Gomes*) e **VIK-on** (*Canal VIK-on*), por pioneiramente criarem, testarem e popularizarem as modificações de 16 GB na GeForce RTX 3070 mundialmente.
* **A Gregory (*Canal GDTech Informática*):** Pelo trabalho de referência e excelência técnica em reparo eletrônico avançado, análise de esquemas elétricos (*boardviews*) e diagnóstico de placas de vídeo no Brasil.
* **A Zagitta e Petri Krohn:** Pelo projeto [`gpu-unlock`](https://github.com/Zagitta/gpu-unlock) e pela pesquisa no processador de segurança Falcon SEC2 do GA104, liberando o potencial pleno de computação e virtualização na arquitetura Ampere.
* **A Panchovix e @pantsoftime:** Pelo [`vix-editor`](https://github.com/Panchovix/nvidia-vbios-vix-editor) e pelo [`vix-loader`](https://github.com/Panchovix/nvidia-linux-vbios-vix-loader), ferramentas fundamentais para auditar a estrutura interna de VBIOS e entender o funcionamento dos offsets de clock no driver.

---

## 📜 Conformidade e Segurança

* **Conformidade DMCA:** Este repositório **NÃO contém imagens proprietárias de VBIOS da NVIDIA (`.rom` ou `.bin`)**.
* **Segurança:** Todas as frequências operam dentro da especificação nominal de catálogo da Samsung para os módulos `K4ZAF325BM-HC16` na tensão padrão JEDEC de 1.35V.
* **Marca:** Desenvolvido, testado e documentado pela **Nines Lab - Brazil 🇧🇷**.
