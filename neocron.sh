#!/bin/sh

#export DXVK_HUD=memory,gpuload,api,version,fps
export WINEDEBUG=-all
#export DXVK_LOG_LEVEL=info
#export DXVK_LOG_PATH=$HOME/neocron/dxvk.log

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export WINEPREFIX="$SCRIPT_DIR/prefix"
export PROTON_NO_ESYNC=1
export PULSE_LATENCY_MSEC=60

WINE=/usr/local/wine-proton/bin/wine
SYSDIR="${WINEPREFIX}/drive_c/windows/system32"
APPDIR="${WINEPREFIX}/drive_c/Games/Neocron Evolution Launcher/"
LAUNCHER_EXE="${APPDIR}/NeocronLauncher.exe"

# Initialize wine pfx
if [ ! -f "${WINEPREFIX}/.wineboot_done" ]; then
    echo "Initializing Wine prefix..."
    $WINE wineboot --init
    wineserver -w
    touch "${WINEPREFIX}/.wineboot_done"
fi

# winetricks
if [ ! -f "${WINEPREFIX}/.tricks_installed" ]; then
    echo "Installing winetricks components..."
    WINE=$WINE winetricks -q corefonts vcrun6 mfc42
    touch "${WINEPREFIX}/.tricks_installed"
fi

# DXVK
if [ ! -f "${WINEPREFIX}/.dxvk_installed" ]; then
    echo "Installing DXVK..."
    DXVK_VERSION="2.4"
    curl -L "https://github.com/doitsujin/dxvk/releases/download/v${DXVK_VERSION}/dxvk-${DXVK_VERSION}.tar.gz" \
        -o "${SCRIPT_DIR}/dxvk.tar.gz"
    tar -xf "${SCRIPT_DIR}/dxvk.tar.gz" -C "${SCRIPT_DIR}"
    cp "${SCRIPT_DIR}/dxvk-${DXVK_VERSION}/x64/"*.dll "$SYSDIR/"
    WINE=$WINE WINEPREFIX=$WINEPREFIX $WINE reg add \
        "HKEY_CURRENT_USER\Software\Wine\DllOverrides" \
        /v d3d11 /t REG_SZ /d native /f
    WINE=$WINE WINEPREFIX=$WINEPREFIX $WINE reg add \
        "HKEY_CURRENT_USER\Software\Wine\DllOverrides" \
        /v dxgi /t REG_SZ /d native /f
    rm -rf "${SCRIPT_DIR}/dxvk.tar.gz" "${SCRIPT_DIR}/dxvk-${DXVK_VERSION}"
    touch "${WINEPREFIX}/.dxvk_installed"
fi

# Download
if [ ! -f "$LAUNCHER_EXE" ]; then
    echo "Fetching Neocron Evolution..."
    mkdir -p "$APPDIR"
    curl -L "https://downloads.neocron-game.com/Neocron%20Client/Neocron-Evolution-Launcher-Web-Installer.exe" \
        -o "${SCRIPT_DIR}/Neocron-Evolution-Launcher-Web-Installer.exe"
fi

# Install
if [ ! -f "${WINEPREFIX}/.neocron_installed" ]; then
    echo "Installing Neocron Evolution..."
    cd $APPDIR
    $WINE ${SCRIPT_DIR}/Neocron-Evolution-Launcher-Web-Installer.exe
    rm ${SCRIPT_DIR}/Neocron-Evolution-Launcher-Web-Installer.exe
    touch "${WINEPREFIX}/.neocron_installed"
fi

echo "Starting Neocron Evolution Launcher..."
cd "$APPDIR"
$WINE "$LAUNCHER_EXE"
