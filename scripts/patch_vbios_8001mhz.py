#!/usr/bin/env python3
"""
Nines Lab - Script de Patch de Offset de VBIOS para 8001 MHz (RTX 3070 16GB Mod)
Aplica factory_memory_offset_mhz = 1000 no registro P+0x98 da VBIOS original,
elevando o P0 para 8001 MHz nominais (16 Gbps) e P2 para 7801 MHz (sem tocar em timings).
"""

import sys
import subprocess
import json
import os

def main():
    if len(sys.argv) < 3:
        print("Uso: python3 patch_vbios_8001mhz.py <rom_original.rom> <payload_saida.bin> [caminho_nvbios_editor]")
        print("Exemplo: python3 patch_vbios_8001mhz.py rtx3070_stock.rom gpu0_8001mhz_payload.bin")
        sys.exit(1)

    in_rom = sys.argv[1]
    out_payload = sys.argv[2]
    nvbios_bin = sys.argv[3] if len(sys.argv) > 3 else "/home/weyland/vix-tools/editor/nvbios"

    if not os.path.exists(in_rom):
        sys.exit(f"Erro: Arquivo {in_rom} não encontrado.")
    if not os.path.exists(nvbios_bin):
        sys.exit(f"Erro: Binário {nvbios_bin} não encontrado.")

    temp_rom = in_rom + ".8001mhz_tmp.rom"

    print("==========================================================================")
    print(" NINES LAB — PATCH DE CLOCK DE VBIOS: 8001 MHz (16 Gbps / 512 GB/s)")
    print("==========================================================================")

    print("\n[1/3] Editando registro P+0x98 (factory_memory_offset_mhz = 1000)...")
    cmd_edit = [nvbios_bin, "edit", in_rom, temp_rom, "--set", "factory_memory_offset_mhz=1000"]
    res_edit = subprocess.run(cmd_edit, capture_output=True, text=True)
    if res_edit.returncode != 0:
        sys.exit(f"Erro na edição: {res_edit.stderr or res_edit.stdout}")

    data_edit = json.loads(res_edit.stdout)
    if not data_edit.get("ok"):
        sys.exit(f"Falha na edição: {data_edit}")
    print("  -> Offset de +1000 MHz gravado com sucesso no registro oficial de fábrica!")

    print("\n[2/3] Verificando integridade e checksums da ROM modificada...")
    cmd_v = [nvbios_bin, "verify", temp_rom]
    res_v = subprocess.run(cmd_v, capture_output=True, text=True)
    data_v = json.loads(res_v.stdout)
    if not data_v.get("ok") or not data_v.get("result", {}).get("integrity", {}).get("valid"):
        os.remove(temp_rom)
        sys.exit(f"Erro: Validação de integridade falhou! {data_v}")
    print("  -> Integridade APROVADA (Checksums 100% válidos em todas as imagens).")

    print("\n[3/3] Normalizando cadeia única ampere-relocated-v1 para o vix-loader...")
    cmd_norm = [nvbios_bin, "normalize", temp_rom, out_payload, "--representation", "ampere-relocated-v1"]
    res_norm = subprocess.run(cmd_norm, capture_output=True, text=True)
    data_norm = json.loads(res_norm.stdout)
    if not data_norm.get("ok"):
        os.remove(temp_rom)
        sys.exit(f"Erro na normalização: {data_norm}")

    if os.path.exists(temp_rom):
        os.remove(temp_rom)

    payload_size = os.path.getsize(out_payload)
    sha256 = data_norm.get("result", {}).get("sha256")
    print(f"\n[SUCESSO] Payload gerado com perfeição!")
    print(f"  Arquivo : {out_payload}")
    print(f"  Tamanho : {payload_size} bytes (512 KiB compatível)")
    print(f"  SHA256  : {sha256}")
    print("==========================================================================")

if __name__ == '__main__':
    main()
