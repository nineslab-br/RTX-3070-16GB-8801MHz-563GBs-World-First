#!/usr/bin/env bash
# ==============================================================================
# Nines Lab - Setup dos Modos de Energia e Atalhos (RTX 3070 16GB Mod)
# Instala gpu-eco, gpu-perf, gpu-ultra, regras de sudoers e serviço de boot.
# ==============================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Execute este script com sudo:"
  echo "sudo $0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

echo "[1/5] Instalando comandos em /usr/local/bin..."
cp -f "$SCRIPT_DIR/gpu-eco" /usr/local/bin/gpu-eco
cp -f "$SCRIPT_DIR/gpu-perf" /usr/local/bin/gpu-perf
cp -f "$SCRIPT_DIR/gpu-ultra" /usr/local/bin/gpu-ultra
chmod +x /usr/local/bin/gpu-eco /usr/local/bin/gpu-perf /usr/local/bin/gpu-ultra

echo "[2/5] Configurando sudoers para alternância sem senha..."
cat << 'EOF' > /etc/sudoers.d/99-nvidia-clocks
ALL ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi -pm *, /usr/bin/nvidia-smi -lmc *, /usr/bin/nvidia-smi -rmc
EOF
chmod 0440 /etc/sudoers.d/99-nvidia-clocks

echo "[3/5] Configurando serviço de inicialização (Boot no Modo ECO)..."
cat << 'EOF' > /usr/local/bin/lock_3070_16gb.sh
#!/usr/bin/env bash
/usr/local/bin/gpu-eco
EOF
chmod +x /usr/local/bin/lock_3070_16gb.sh

cat << 'EOF' > /etc/systemd/system/nvidia-power-mode.service
[Unit]
Description=Nines Lab Power Mode Manager for RTX 3070 16GB
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lock_3070_16gb.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nvidia-power-mode.service

echo "[4/5] Configurando hook de retorno da suspensão (S3 Sleep Resume)..."
mkdir -p /lib/systemd/system-sleep/
cat << 'EOF' > /lib/systemd/system-sleep/99-nvidia-lock-resume.sh
#!/bin/sh
case "$1" in
    post)
        /usr/local/bin/gpu-eco
        ;;
esac
EOF
chmod +x /lib/systemd/system-sleep/99-nvidia-lock-resume.sh

echo "[5/5] Criando atalhos na Área de Trabalho para $TARGET_USER..."
DESKTOP_DIR="$USER_HOME/Desktop"
if [ -d "$DESKTOP_DIR" ]; then
    cat << 'EOF' > "$DESKTOP_DIR/GPU-Modo-Eco.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=GPU Modo Eco (405 MHz)
Comment=Trava a RTX 3070 em 405 MHz (11.8W fria em repouso)
Exec=/usr/local/bin/gpu-eco
Icon=power-profile-power-saver
Terminal=true
Categories=System;Settings;
EOF
    chmod +x "$DESKTOP_DIR/GPU-Modo-Eco.desktop"
    chown "$TARGET_USER:$TARGET_USER" "$DESKTOP_DIR/GPU-Modo-Eco.desktop" 2>/dev/null || true

    cat << 'EOF' > "$DESKTOP_DIR/GPU-Modo-Performance.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=GPU Modo Performance (6801 MHz)
Comment=Sobe a RTX 3070 para 6801 MHz (435 GB/s)
Exec=/usr/local/bin/gpu-perf
Icon=power-profile-balanced
Terminal=true
Categories=System;Settings;
EOF
    chmod +x "$DESKTOP_DIR/GPU-Modo-Performance.desktop"
    chown "$TARGET_USER:$TARGET_USER" "$DESKTOP_DIR/GPU-Modo-Performance.desktop" 2>/dev/null || true

    cat << 'EOF' > "$DESKTOP_DIR/GPU-Modo-Ultra.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=GPU Modo Ultra (8001 MHz)
Comment=Sobe a RTX 3070 para 8001 MHz (16 Gbps / 512 GB/s)
Exec=/usr/local/bin/gpu-ultra
Icon=applications-games
Terminal=true
Categories=System;Settings;
EOF
    chmod +x "$DESKTOP_DIR/GPU-Modo-Ultra.desktop"
    chown "$TARGET_USER:$TARGET_USER" "$DESKTOP_DIR/GPU-Modo-Ultra.desktop" 2>/dev/null || true
fi

echo "========================================================================"
echo " [Nines Lab] Configuração Concluída com Sucesso!"
echo " Comandos disponíveis: gpu-eco, gpu-perf, gpu-ultra"
echo "========================================================================"
