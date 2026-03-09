#!/bin/bash

fileExistenceChecker(){
    DESKTOP_DIR=$(xdg-user-dir DESKTOP)
    TREE=${HOME}/Teknoparrot
    GAME=${TREE}/GAME
    PREFIX=${TREE}/PREFIX
    RUNNER=${TREE}/RUNNER
    TMP=${TREE}/TMP
    if [[ -d "$GAME" ]]; then
        rm -rf "$GAME"
    fi
    if [[ -d "$RUNNER" ]]; then
        rm -rf "$RUNNER"
    fi
    if [[ -d "$PREFIX" ]]; then
        rm -rf "$PREFIX"
    fi
    if [[ -d "$TMP" ]]; then
        rm -rf "$TMP"
    fi
    if [[ -d "$HOME"/.cache/winetricks ]]; then
        rm -rf "$HOME"/.cache/winetricks
    fi
    if [[ -f "$TREE"/icon.png ]]; then
        rm -rf "$TREE"/icon.png
    fi
    if [[ -f "$TREE"/Teknoparrot-Linux ]]; then
        rm -rf "$TREE"/Teknoparrot-Linux
    fi
    if [[ -f "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop ]]; then
        rm -rf "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
    fi
    pkill wine
    wineserver -k
    mkdir -p "$TREE"/{GAME,PREFIX,TMP}
}

customRunner(){
    while true; do
        clear
        echo -e "There are 2 runners available for use:\n\nWineGE (Legacy).\nUMU-Proton (Experimental).\n"
        read -p "[winege/umu] > " customRunnerSelection
        clear
        case $customRunnerSelection in
            "wine" | "winege")
                source /etc/os-release
                if [[ $ID == "arch" || $ID_LIKE == "arch" ]]; then
                (
                cd "$TMP"
                if [[ ! -f "/usr/bin/yay" ]]; then
                    sudo pacman -S --needed base-devel
                    wget -c https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz &> /dev/null
                    tar -xf yay.tar.gz && cd yay
                    makepkg -si
                fi
                if [[ ! -d "/opt/wine-ge-custom-opt/" ]]; then
                    yay -S wine-ge-custom-bin-opt
                fi
                )
                else
                (
                    cd "$TMP"
                    wget -c https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-26/wine-lutris-GE-Proton8-26-x86_64.tar.xz &> /dev/null
                    tar -xf wine-lutris-GE-Proton8-26-x86_64.tar.xz
                    sudo mv lutris-GE-Proton8-26-x86_64 /opt/wine-ge-custom-opt
                )
                fi
                ln -s /opt/wine-ge-custom-opt "$TREE"/RUNNER
                RUNNER_EXEC="$RUNNER/bin/wine"
                RUNNER_TYPE="GE-Wine"
                break
            ;;
            "umu" | "umu-proton")
            source /etc/os-release
            mkdir "$TREE"/RUNNER
                if [[ ! -f "/usr/bin/umu-run" ]]; then
                    if [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
                        sudo pacman -S umu-launcher
                        ln -s /usr/bin/umu-run "$RUNNER"/umu-run
                    else
                        (
                        cd "$TMP"
                        git clone https://github.com/Open-Wine-Components/umu-launcher
                        read -p
                        cd umu-launcher/
                        ./configure.sh --user-install
                        make install
                        ln -s "$HOME"/.local/bin/umu-run "$RUNNER"/umu-run
                        )
                    fi
                elif [[ -f "/usr/bin/umu-run" ]]; then
                    if [[ -f "/usr/bin/umu-run" ]]; then
                        ln -s "/usr/bin/umu-run" "$RUNNER"/umu-run
                    else
                        ln -s "$HOME"/.local/bin/umu-run "$RUNNER"/umu-run
                    fi
                fi
                RUNNER_EXEC="$RUNNER"/umu-run
                RUNNER_TYPE="UMU-Proton"
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

dependencyInstall(){
    clear
    export WINEPREFIX=${PREFIX}
    echo -e "[RUNNER: $RUNNER_TYPE]\n"
    echo "[Wineboot] Creating the Wine Prefix" && wineboot &> /dev/null
    echo "[Downloading] .NET Runtime" && wget -c https://aka.ms/dotnet/8.0/dotnet-runtime-win-x64.exe --directory-prefix="$TMP" &> /dev/null 
    echo "[Downloading] .NET Desktop Runtime" && wget -c https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe --directory-prefix="$TMP" &> /dev/null 
    echo "[Installing] .NET Runtime" && wine "$TMP"/dotnet-runtime-win-x64.exe /install /quiet /norestart &> /dev/null
    echo "[Installing] .NET Desktop Runtime" && wine "$TMP"/windowsdesktop-runtime-win-x64.exe /install /quiet /norestart &> /dev/null
    echo "[Installing] DXVK" && winetricks dxvk &> /dev/null
    echo "[Downloading] Teknoparrot (Web-Installer)" && wget -c https://github.com/nzgamer41/TPBootstrapper/releases/latest/download/TPBootstrapper.zip --directory-prefix="$TMP" &> /dev/null
    (
        echo "[Extracting] Teknoparrot (Web-Installer)" && unzip "$TMP"/TPBootstrapper.zip -d "$GAME" &> /dev/null
        cd "$GAME"
        echo -e "[Installing] Teknoparrot (Web-Installer)\n" && wine TPBootstrapper.exe &> /dev/null
    )
    rm -rf "$GAME"/TPBootstrapper*
    rm -rf "$TMP"
}

executableCreation(){
    (
        cp -r icon.png "$TREE"
        cd "$TREE"
        HEADER="#!/bin/bash"
        DRIPRIME_FLAG="#export DRI_PRIME=0"
        echo "$HEADER" > Teknoparrot-Linux
        echo "$DRIPRIME_FLAG" >> Teknoparrot-Linux
        echo "export WINEPREFIX=$PREFIX" >> Teknoparrot-Linux
        echo "$RUNNER_EXEC" "$GAME"/TeknoParrotUi.exe >> Teknoparrot-Linux
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
                echo "Icon="$TREE"/icon.png" >> "$DESKTOP_DIR"/com.sakaki.Teknoparrot.desktop
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

clear
fileExistenceChecker
customRunner
dependencyInstall
executableCreation