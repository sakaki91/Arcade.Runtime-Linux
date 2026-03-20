#!/bin/bash

creationTree(){
    while true; do
        echo -e "Do you want to use a custom directory? (default: $HOME)\n"
        read -p "[Y/n] " customDirectoryInput
        case $customDirectoryInput in
            [Yy])
                TREE=$(zenity --file-selection --directory --title "Select your desired directory:")/Teknoparrot
                break
            ;;
            [Nn])
                TREE=${HOME}/Teknoparrot
                break
            ;;
            *)
                echo -e "\nInvalid value\n"
                sleep 1.5
                clear
            ;;
        esac
    done
}

variableTree(){
    DESKTOP_DIR=$(xdg-user-dir DESKTOP)
    PROGRAM=${TREE}/PROGRAM
    PREFIX=${TREE}/PREFIX
    RUNNER=${TREE}/RUNNER
    TMP=${TREE}/TMP
    RUNNER_EXEC="$RUNNER"/umu-run
}

fileExistenceChecker(){      
    if [[ -d "$TREE" || -f "$HOME"/.icons/icon.png || -f "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop ]]; then
        rm -rf "$TREE"
        rm -rf "$HOME"/.icons/icon.png
        rm -rf "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
    fi
}

runner(){
    mkdir -p "$TREE"/{PROGRAM,PREFIX,RUNNER,TMP}
    if [[ ! -f "$HOME"/.local/bin/umu-run ]]; then
        (
        cd "$TMP"
        git clone https://github.com/Open-Wine-Components/umu-launcher
        cd umu-launcher/
        ./configure.sh --user-install
        make install
        )
    fi
    ln -s "$HOME"/.local/bin/umu-run "$RUNNER"/umu-run
}

dependencyInstall(){
    clear
    export WINEPREFIX=${PREFIX}
    echo "[Proton] Wineboot" && $RUNNER_EXEC wineboot -u &> /dev/null
    echo "[Downloading] .NET Runtime" && wget -c https://aka.ms/dotnet/8.0/dotnet-runtime-win-x64.exe --directory-prefix="$TMP" &> /dev/null 
    echo "[Downloading] .NET Desktop Runtime" && wget -c https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe --directory-prefix="$TMP" &> /dev/null 
    echo "[Installing] .NET Runtime" && "$RUNNER_EXEC" "$TMP"/dotnet-runtime-win-x64.exe /install /quiet /norestart &> /dev/null
    echo "[Installing] .NET Desktop Runtime" && "$RUNNER_EXEC" "$TMP"/windowsdesktop-runtime-win-x64.exe /install /quiet /norestart &> /dev/null
    echo "[Downloading] Teknoparrot (Web-Installer)" && wget -c https://github.com/nzgamer41/TPBootstrapper/releases/latest/download/TPBootstrapper.zip --directory-prefix="$TMP" &> /dev/null
    (
        echo "[Extracting] Teknoparrot (Web-Installer)" && unzip "$TMP"/TPBootstrapper.zip -d "$PROGRAM" &> /dev/null
        cd "$PROGRAM"
        echo -e "[Installing] Teknoparrot (Web-Installer)\n" && "$RUNNER_EXEC" TPBootstrapper.exe &> /dev/null
    )
    rm -rf "$PROGRAM"/TPBootstrapper*
    rm -rf "$TMP"
    
}

executableCreation(){
    (
        mkdir -p "$HOME/.icons"
        cp -r icon.png "$HOME/.icons"
        cd "$TREE"
        HEADER="#!/bin/bash"
        DEBUG_FLAG="#PROTON_LOG=1"
        DRIPRIME_FLAG="#export DRI_PRIME=1"
        MANGOHUD_FLAG="#export MANGOHUD=1"
        echo "$HEADER" > Teknoparrot-Linux
        echo "$DEBUG_FLAG" >> Teknoparrot-Linux
        echo "$DRIPRIME_FLAG" >> Teknoparrot-Linux
        echo "$MANGOHUD_FLAG" >> Teknoparrot-Linux
        echo "export LC_ALL=C" >> Teknoparrot-Linux
        echo "export LC_NUMERIC=C" >> Teknoparrot-Linux
        echo "export LANG=en_US.UTF-8" >> Teknoparrot-Linux
        echo "export WINEPREFIX=$PREFIX" >> Teknoparrot-Linux
        echo "$RUNNER_EXEC" "$PROGRAM"/TeknoParrotUi.exe >> Teknoparrot-Linux
        chmod +x Teknoparrot-Linux
    )
    while true; do
        echo -e "Do you want to create a shortcut on your Desktop?\n"
        read -p "[Y/n] " shortcutInput
        if [[ -z "$shortcutInput" ]]; then
            shortcutInput="y"
        fi
        case $shortcutInput in
            [Yy])
                echo "[Desktop Entry]" > "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                echo "Exec="$TREE"/Teknoparrot-Linux" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                echo "Name=Teknoparrot" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                echo "Icon="$HOME"/.icons/icon.png" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                echo "Terminal=false" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                echo "Type=Application" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                echo "Categories=Game;" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                chmod +x "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
                cp "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop "$HOME"/.local/share/applications/
                break
            ;;
            [Nn])
                exit
            ;;
            *)
                if [[ -f "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop ]]; then
                    break
                fi
                echo -e "\nInvalid value\n"
                sleep 1.5
                clear
            ;;
        esac
    done
}

if [[ $1 == "--remove" ]]; then
    clear
    creationTree
    variableTree
    fileExistenceChecker
    exit
elif [[ $1 == "--help" ]]; then
    echo -e "\nTeknoparrot.Core-Linux: Version 2.0\n\n--help\t\tShow this message.\n--remove\tClears all files created by the script.\n"
    exit
fi

clear
creationTree
variableTree
fileExistenceChecker
runner
dependencyInstall
executableCreation