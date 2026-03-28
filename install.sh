#!/bin/bash

hostDependencyChecker(){
    [ ! -f /usr/bin/wine ] && echo -e "$ERROR_LOG Wine not found" && exit
    [ ! -f /usr/bin/winetricks ] && echo -e "$ERROR_LOG Winetricks not found" && exit
    [ ! -f /usr/bin/bash ] && echo -e "$ERROR_LOG Bash not found" && exit
    [ ! -f /usr/bin/wget ] && echo -e "$ERROR_LOG Wget not found" && exit
    [ ! -f /usr/bin/unzip ] && echo -e "$ERROR_LOG Unzip not found" && exit
    [ ! -f /usr/bin/tar ] && echo -e "$ERROR_LOG Tar not found" && exit
    [ ! -f /usr/bin/zenity ] && echo -e "$ERROR_LOG Zenity not found" && exit
}

atomicTree(){
    TMP=${TREE}/TMP
    PROGRAM=${TREE}/PROGRAM
    PREFIX=${TREE}/PREFIX
    [ -d "$PROGRAM" ] && rm -rf $PROGRAM
    [ -d "$PREFIX" ] && rm -rf $PREFIX
    [ -d "$TMP" ] && rm -rf $TMP
    rm -rf $TREE
    mkdir -p "$TREE"/{TMP,PROGRAM}
}

dependencyInstall(){
    clear
    export WINEPREFIX=${PREFIX}
    echo -e "$WAIT_LOG Wineboot." && wineboot -u &> $ARL_LOG
        [ -d "$PREFIX"/drive_c ] && echo -e " $DONE_LOG Structure created!"
        [ ! -d "$PREFIX"/drive_c ] && echo -e " $ERROR_LOG Structure not created." && exit
        echo -e "$WAIT_LOG Downloading dependencies [DXVK & .NET-Runtime/Desktop-Runtime]"
        wget -c https://aka.ms/dotnet/8.0/dotnet-runtime-win-x64.exe --directory-prefix="$TMP" &>> $ARL_LOG
        wget -c https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe --directory-prefix="$TMP" &>> $ARL_LOG
        [ ! -f "$TMP"/dotnet-runtime-win-x64.exe ] && echo -e " $ERROR_LOG .NET Runtime was not downloaded." && exit
        [ ! -f "$TMP"/windowsdesktop-runtime-win-x64.exe ] && echo -e " $ERROR_LOG .NET Desktop Runtime was not downloaded." && exit
        winetricks dxvk &>> $ARL_LOG && echo -e " $DONE_LOG DXVK installed!"
        wine "$TMP"/dotnet-runtime-win-x64.exe /install /quiet /norestart &>> $ARL_LOG && echo -e " $DONE_LOG .NET Runtime installed!"
        wine "$TMP"/windowsdesktop-runtime-win-x64.exe /install /quiet /norestart &>> $ARL_LOG && echo -e " $DONE_LOG .NET Desktop Runtime installed!"  
        echo -e "$WAIT_LOG Downloading TeknoParrot (Web-Installer)"
        wget -c https://github.com/nzgamer41/TPBootstrapper/releases/latest/download/TPBootstrapper.zip --directory-prefix="$TMP" &>> $ARL_LOG
        [ ! -f "$TMP"/TPBootstrapper.zip ] && echo -e " $ERROR_LOG TPBootstrapper was not downloaded." && exit
        unzip "$TMP"/TPBootstrapper.zip -d "$PROGRAM" &>> $ARL_LOG
        [ ! -f "$PROGRAM"/TPBootstrapper.exe ] && echo -e " $ERROR_LOG TPBootstrapper was not extracted." && exit
        [ ! -f "$PROGRAM"/TPBootstrapper.exe ] && echo -e " $ERROR_LOG TPBootstrapper was not found." && exit
        (
            cd "$PROGRAM"
            wine TPBootstrapper.exe &>> $ARL_LOG
            [ -f "$PROGRAM"/TeknoParrotUi.exe ] && echo -e " $DONE_LOG TeknoParrot installed!"
            [ ! -f "$PROGRAM"/TeknoParrotUi.exe ] && echo -e " $ERROR_LOG TeknoParrot not installed." && exit
        )
    ls $TREE &>> $ARL_LOG && ls $TREE/* &>> $ARL_LOG
    rm -rf "$PROGRAM"/TPBootstrapper*
    rm -rf "$TMP" && echo -e " $DONE_LOG Temporary files cleared!"
}

executableCreation(){
    (
        cd "$TREE"
        HEADER="#!/bin/bash"
        FLAGS="LC_ALL=C LC_NUMERIC=C LANG=en_US.UTF-8 WINEPREFIX=$PREFIX wine $PROGRAM/TeknoParrotUi.exe"
        echo $HEADER > TeknoParrot-Linux
        echo $FLAGS >> TeknoParrot-Linux
        chmod +x TeknoParrot-Linux
    )
}

ARL_NAME="Arcade Wrapper Linux"
ARL_VERSION="3.1-5wr (wine return)"
ARL_LOG="/dev/null"
DONE_LOG="\e[1;32m*\033[0m"
WAIT_LOG="\e[1;33m*\033[0m"
ERROR_LOG="\e[1;31m*\033[0m"
TREE=${HOME}/TeknoParrot

case $1 in
    "--help")
        echo -e "\n$ARL_NAME $ARL_VERSION\n\n--help\t\tShow this message.\n--version\tShow wrapper version.\n--custom-dir\tWith this flag you can choose a custom installation directory.\n--debug \tThis executes the script and generates a log file (ARL.LOG) in $HOME.\n"
        exit
    ;;
    "--custom-dir")
        TREE=$(zenity --file-selection --directory --title "Select your desired directory:")/TeknoParrot
    ;;
    "--debug")
        ARL_LOG=$HOME/AR.LOG
    ;;
    "--version")
        echo -e "$ARL_NAME $ARL_VERSION"
        exit
    ;;
esac

hostDependencyChecker
clear
atomicTree
dependencyInstall
executableCreation