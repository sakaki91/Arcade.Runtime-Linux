#!/bin/bash

primaryDependencyChecker(){
    dependencies=(wine bash wget unzip tar zenity)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf "$NORMAL_LOG $cmd not found. $ERROR_LOG\n" && exit 1
        fi
    done
}

atomicTree(){
    PROGRAM=${TREE}/bin
    PREFIX=${TREE}/pfx
    TMP=${PREFIX}/drive_c/tmp
    [ -f "$TREE"/awl ] && rm -rf "$TREE"/awl
    [ -d "$PROGRAM" ] && rm -rf "$PROGRAM"
    [ -d "$PREFIX" ] && rm -rf "$PREFIX"
    mv "$TREE" "$TREE".old
    mkdir -p "$TREE"/{bin,pfx} && mkdir -p "$PREFIX/drive_c/tmp"
    #sed -i "s|^\s*AWL_LOCATION=.*|AWL_LOCATION=\"$TREE\"|" awl.sh
}

dependencyInstall(){
    clear
    export WINEPREFIX=${PREFIX}
    printf "$NORMAL_LOG Wineboot. ($WINEPREFIX)" && wineboot -u &> $AWL_LOG
    if [ -d "$PREFIX"/drive_c ]; then
        printf " $DONE_LOG\n$NORMAL_LOG Downloading dependencies."
        wget -c https://aka.ms/dotnet/8.0/dotnet-runtime-win-x64.exe --directory-prefix="$TMP" &>> $AWL_LOG
        wget -c https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe --directory-prefix="$TMP" &>> $AWL_LOG
        wget -c https://download.microsoft.com/download/8/4/a/84a35bf1-dafe-4ae8-82af-ad2ae20b6b14/directx_Jun2010_redist.exe --directory-prefix="$TMP" &>> $AWL_LOG
        wget -c https://github.com/doitsujin/dxvk/releases/download/v$DXVK_VERSION/dxvk-$DXVK_VERSION.tar.gz --directory-prefix="$TMP" &>> $AWL_LOG
        [ ! -f "$TMP"/dotnet-runtime-win-x64.exe ] && printf " $ERROR_LOG\n" && exit
        [ ! -f "$TMP"/windowsdesktop-runtime-win-x64.exe ] && printf " $ERROR_LOG\n" && exit
        [ ! -f "$TMP"/directx_Jun2010_redist.exe ] && printf " $ERROR_LOG\n" && exit
        [ ! -f "$TMP"/dxvk-$DXVK_VERSION.tar.gz ] && printf " $ERROR_LOG\n" && exit
        printf " $DONE_LOG\n$NORMAL_LOG Installing dependencies."
        wine "$TMP"/dotnet-runtime-win-x64.exe /install /quiet /norestart &>> $AWL_LOG
        wine "$TMP"/windowsdesktop-runtime-win-x64.exe /install /quiet /norestart &>> $AWL_LOG
        wine "$TMP"/directx_Jun2010_redist.exe /Q /C /T:"C:\TMP" &>> $AWL_LOG
        wine "$TMP"/DXSETUP.exe /silent &>> $AWL_LOG
        tar -xf "$TMP"/dxvk-$DXVK_VERSION.tar.gz --directory "$TMP"
        mv "$TMP"/dxvk-$DXVK_VERSION/x32/*.dll "$PREFIX"/drive_c/windows/syswow64
        mv "$TMP"/dxvk-$DXVK_VERSION/x64/*.dll "$PREFIX"/drive_c/windows/system32
        wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d10core /d native,builtin /f &>> $AWL_LOG
        wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d11 /d native,builtin /f &>> $AWL_LOG
        wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d8 /d native,builtin /f &>> $AWL_LOG
        wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v d3d9 /d native,builtin /f &>> $AWL_LOG
        wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v dxgi /d native,builtin /f &>> $AWL_LOG
        printf " $DONE_LOG\n$NORMAL_LOG Downloading TeknoParrot (Web-Installer)."
        wget -c https://github.com/nzgamer41/TPBootstrapper/releases/latest/download/TPBootstrapper.zip --directory-prefix="$TMP" &>> $AWL_LOG
        if [ -f "$TMP"/TPBootstrapper.zip ]; then
        (
            unzip "$TMP"/TPBootstrapper.zip -d "$PROGRAM" &>> $AWL_LOG
            cd "$PROGRAM"
            wine TPBootstrapper.exe &>> $AWL_LOG
            [ -f "$PROGRAM"/TeknoParrotUi.exe ] && printf " $DONE_LOG\n"
            [ ! -f "$PROGRAM"/TeknoParrotUi.exe ] && printf " $ERROR_LOG\n" && exit
        )
        else
            printf "$ERROR_LOG\n" && exit
        fi
        ls $TREE &>> $AWL_LOG && ls $TREE/* &>> $AWL_LOG
        rm -rf "$PROGRAM"/TPBootstrapper*
        rm -rf "$TMP" && printf "$NORMAL_LOG Temporary files cleared. $DONE_LOG\n"
        [ $UMU == "true" ] && printf "add export PATH="$HOME/.local/bin:$PATH" to your ~/.bashrc\n"
    else
        printf " $ERROR_LOG\n" && exit
    fi
}

executableCreation(){
    (
        cd "$TREE"
        HEADER="#!/bin/bash"
        EXEC="LC_ALL=en_US.UTF-8 LC_NUMERIC=en_US.UTF-8 LANG=en_US.UTF-8 WINEPREFIX=$PREFIX wine $PROGRAM/TeknoParrotUi.exe"
        echo $HEADER > awl
        echo $EXEC >> awl
        chmod +x awl
    )
}

AWL_NAME="Arcade Wrapper Linux" && AWL_VERSION="3.2-1" && AWL_LOG="/dev/null"
DEFAULT_COLOR="\033[0m" && GRAY_COLOR="\e[0;37m" && BLACK_BG="\e[0;40m" && DONE_LOG="\e[1;32mOK\033[0m" && NORMAL_LOG="\e[1;34m*\033[0m" && ERROR_LOG="\e[1;31mERROR\033[0m"
TREE=${HOME}/TeknoParrot
DXVK_VERSION="2.7.1"
UMU="false"

case $1 in
    "--help")
        echo -e "\n$AWL_NAME $AWL_VERSION\n\n--help\t\tShow this message.\n--version\tShow wrapper version.\n\n$BLACK_BG./install @args @subargs$DEFAULT_COLOR\n\n@args:\n--debug\t\tThis executes the script and generates a log file (AWL.LOG) in $HOME.\n--last-dir\tUses the last directory used in the script (ideal for reinstalls/maintenance).\n--custom-dir\tWith this flag you can choose a custom installation directory.\n\n$GRAY_COLOR@subargs:\n-watch\t\tShows the last directory used, without installing anything.\n-debug \t\tThe -debug option serves as an additional subargument, for debug in the default directory, simply use --debug.\n$DEFAULT_COLOR\n"
        exit
    ;;
    "--umu")
    (
        git clone https://github.com/Open-Wine-Components/umu-launcher
        cd umu-launcher
        ./configure.sh --user-install
        make install
        UMU="true"
    )
    ;;
    "--custom-dir")
        TREE=$(zenity --file-selection --directory --title "Select your desired directory:")/TeknoParrot
        [[ $2 == "-debug" ]] && AWL_LOG=$HOME/awl.log
    ;;
    "--debug")
        AWL_LOG=$HOME/AWL.LOG
    ;;
    "--version")
        echo -e "$AWL_NAME $AWL_VERSION"
        exit
    ;;
esac

primaryDependencyChecker
git pull
atomicTree
dependencyInstall
executableCreation