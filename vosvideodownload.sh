#!/bin/sh
# TURN INTO ".SH" TO USE.
# ANY FALSE USE OF THIS PROGRAM CAN RESULT IN COPYRIGHT INFRINGEMENT TO THE RESPECTIVE AUTHORS.

VERSION="1.00.12"
VERSION_TYPE="RELEASE (IOS BUILD)"
UPDATE_URL="https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
HISTORY_FILE="$SCRIPT_DIR/history.txt"

ESC=$(printf '\033')
RED="${ESC}[91m"
DARKRED="${ESC}[31m"
ORANGE="${ESC}[38;5;208m"
YELLOW="${ESC}[93m"
GREEN="${ESC}[92m"
CYAN="${ESC}[96m"
RESET="${ESC}[0m"

banner() {
    printf '\033[2J\033[3J\033[H'
    printf "%s\n" "${DARKRED} __     __   ___    ____     __     __  ___   ____    _____    ___  ${RESET}"
    printf "%s\n" "${DARKRED} \ \   / /  / _ \  / ___|    \ \   / / |_ _| |  _ \  | ____|  / _ \ ${RESET}"
    printf "%s\n" "${RED}  \ \ / /  | | | | \___ \     \ \ / /   | |  | | | | |  _|   | | | |${RESET}"
    printf "%s\n" "${RED}   \ V /   | |_| |  ___) |     \ V /    | |  | |_| | | |___  | |_| |${RESET}"
    printf "%s\n" "${ORANGE}    \_/     \___/  |____/       \_/    |___| |____/  |_____|  \___/ ${RESET}"
    printf "%s\n" "${ORANGE}  ____     ___   __        __  _   _   _        ___      _     ____  ${RESET}"
    printf "%s\n" "${ORANGE} |  _ \   / _ \  \ \      / / | \ | | | |      / _ \    / \   |  _ \ ${RESET}"
    printf "%s\n" "${ORANGE} | | | | | | | |  \ \ /\ / /  |  \| | | |     | | | |  / _ \  | | | |${RESET}"
    printf "%s\n" "${YELLOW} | |_| | | |_| |   \ V  V /   | |\  | | |___  | |_| | / ___ \ | |_| |${RESET}"
    printf "%s\n" "${YELLOW} |____/   \___/     \_/\_/    |_| \_| |_____|  \___/ /_/   \_\|____/ ${RESET}"
    printf "\n"
}

download_video() {
    banner
    if ! command -v yt-dlp >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
        printf "%s\n" "${RED}[ERROR] MISSING DEPENDENCIES! PLEASE INSTALL THEM FROM MENU OPTION 2 FIRST.${RESET}"
        printf "\n"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    printf "%s" "${RED}PASTE YOUTUBE URL ${CYAN}(OR PRESS ENTER TO GO BACK)${RED}: ${RESET}"
    read -r url
    if [ -z "$url" ]; then
        return
    fi

    mkdir -p "$VIDEOS_DIR"
    yt-dlp -P "$VIDEOS_DIR" -f "bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]" --merge-output-format mp4 "$url"

    printf "\n"
    printf "%s\n" "${GREEN}DONE! SAVED TO THE VIDEOS FOLDER.${RESET}"
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

dep_check() {
    banner
    missing=0

    if command -v yt-dlp >/dev/null 2>&1; then
        printf "%s\n" "${GREEN}[OK] YT-DLP IS INSTALLED.${RESET}"
    else
        printf "%s\n" "${RED}[MISSING] YT-DLP IS NOT INSTALLED.${RESET}"
        missing=1
    fi

    if command -v ffmpeg >/dev/null 2>&1; then
        printf "%s\n" "${GREEN}[OK] FFMPEG IS INSTALLED.${RESET}"
    else
        printf "%s\n" "${RED}[MISSING] FFMPEG IS NOT INSTALLED.${RESET}"
        missing=1
    fi

    printf "\n"
    if [ "$missing" -eq 1 ]; then
        printf "%s\n" "${RED}WOULD YOU LIKE TO INSTALL THE REQUIRED DEPENDENCIES?${RESET}"
        printf "%s\n" "${GREEN}[Y] YES | [N] NO${RESET}"
        read -r dlchoice
        if [ "$dlchoice" = "Y" ] || [ "$dlchoice" = "y" ]; then
            dep_download
        fi
    else
        printf "%s\n" "${GREEN}ALL DEPENDENCIES ARE WORKING PROPERLY!${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
    fi
}

dep_download() {
    banner
    printf "%s\n" "${RED}INSTALLING DEPENDENCIES...${RESET}"
    pip install yt-dlp
    printf "\n"
    printf "%s\n" "${GREEN}INSTALLATION COMPLETE!${RESET}"
    printf "\n"
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

dep_update() {
    banner
    printf "%s\n" "${RED}UPDATING DEPENDENCIES...${RESET}"
    pip install --upgrade yt-dlp
    printf "\n"
    printf "%s\n" "${GREEN}UPDATE CHECK COMPLETE!${RESET}"
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

dep_delete() {
    while true; do
        banner
        printf "%s\n" "${RED}WHICH WOULD YOU LIKE TO UNINSTALL?${RESET}"
        printf "%s\n" "${GREEN}1: YT-DLP${RESET}"
        printf "%s\n" "${GREEN}2: FFMPEG${RESET}"
        printf "%s\n" "${GREEN}3: ALL${RESET}"
        printf "%s\n" "${CYAN}ENTER: GO BACK${RESET}"
        read -r delchoice

        if [ -z "$delchoice" ]; then
            return
        elif [ "$delchoice" = "1" ]; then
            banner
            printf "%s\n" "${RED}UNINSTALLING YT-DLP...${RESET}"
            pip uninstall -y yt-dlp
            printf "%s\n" "${GREEN}YT-DLP REMOVED.${RESET}"
            printf "\n"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        elif [ "$delchoice" = "2" ]; then
            banner
            printf "%s\n" "${YELLOW}FFMPEG IS BUILT INTO A-SHELL AND CANNOT BE UNINSTALLED.${RESET}"
            printf "\n"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        elif [ "$delchoice" = "3" ]; then
            banner
            printf "%s\n" "${RED}UNINSTALLING ALL DEPENDENCIES...${RESET}"
            pip uninstall -y yt-dlp
            printf "%s\n" "${GREEN}ALL REMOVABLE DEPENDENCIES REMOVED.${RESET}"
            printf "\n"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        fi
    done
}

dependencies_menu() {
    while true; do
        banner
        printf "%s\n" "${RED}DEPENDENCIES${RESET}"
        printf "%s\n" "${GREEN}1: CHECK IF DEPENDENCIES ARE DOWNLOADED${RESET}"
        printf "%s\n" "${GREEN}2: DOWNLOAD DEPENDENCIES${RESET}"
        printf "%s\n" "${GREEN}3: UPDATE DEPENDENCIES${RESET}"
        printf "%s\n" "${GREEN}4: DELETE DEPENDENCIES${RESET}"
        printf "%s\n" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        read -r depchoice

        if [ -z "$depchoice" ]; then
            return
        elif [ "$depchoice" = "1" ]; then
            dep_check
        elif [ "$depchoice" = "2" ]; then
            dep_download
        elif [ "$depchoice" = "3" ]; then
            dep_update
        elif [ "$depchoice" = "4" ]; then
            dep_delete
        fi
    done
}

update_animation() {
    bar_width=24
    i=0
    while [ "$i" -le "$bar_width" ]; do
        filled=""
        empty=""
        j=0
        while [ "$j" -lt "$i" ]; do
            filled="${filled}█"
            j=$((j + 1))
        done
        while [ "$j" -lt "$bar_width" ]; do
            empty="${empty} "
            j=$((j + 1))
        done
        percent=$((i * 100 / bar_width))
        printf '\r%s[%s%s] %3d%%' "$CYAN" "$filled" "$empty" "$percent"
        sleep 0.04
        i=$((i + 1))
    done
    printf '\n%s\n' "$RESET"
}

update_program() {
    banner
    printf "%s\n" "${RED}CHECKING FOR VOSVIDEODOWNLOAD UPDATES...${RESET}"

    update_file=$(mktemp "$SCRIPT_DIR/.vosvideodownload-update.XXXXXX") || {
        printf "%s\n" "${RED}COULD NOT CREATE A TEMPORARY UPDATE FILE IN THE PROGRAM FOLDER.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    }

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL --connect-timeout 10 --max-time 60 "$UPDATE_URL" -o "$update_file"; then
            rm -f "$update_file"
            printf "%s\n" "${RED}UPDATE DOWNLOAD FAILED. CHECK YOUR CONNECTION AND TRY AGAIN.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q --timeout=30 -O "$update_file" "$UPDATE_URL"; then
            rm -f "$update_file"
            printf "%s\n" "${RED}UPDATE DOWNLOAD FAILED. CHECK YOUR CONNECTION AND TRY AGAIN.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        fi
    else
        rm -f "$update_file"
        printf "%s\n" "${RED}CURL OR WGET IS REQUIRED TO DOWNLOAD UPDATES.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    remote_version=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$update_file" | head -n 1)
    if [ -z "$remote_version" ] || ! grep -q '^#!/bin/sh' "$update_file" || ! sh -n "$update_file"; then
        rm -f "$update_file"
        printf "%s\n" "${RED}THE DOWNLOADED UPDATE IS INVALID; YOUR INSTALLED SCRIPT WAS NOT CHANGED.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    if [ "$remote_version" = "$VERSION" ]; then
        rm -f "$update_file"
        printf "%s\n" "${GREEN}VOSVIDEODOWNLOAD $VERSION IS ALREADY UP TO DATE.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    printf "%s\n" "${CYAN}UPDATE FOUND: $VERSION TO $remote_version${RESET}"
    update_animation
    printf "%s" "${CYAN}INSTALL UPDATE AND RESTART? [Y/N]: ${RESET}"
    read -r update_choice
    case "$update_choice" in
        Y|y|YES|yes) ;;
        *) rm -f "$update_file"; return ;;
    esac

    if ! chmod +x "$update_file" || ! mv -f "$update_file" "$SCRIPT_PATH"; then
        rm -f "$update_file"
        printf "%s\n" "${RED}COULD NOT INSTALL THE UPDATE. CHECK WRITE PERMISSIONS.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    if [ ! -f "$HISTORY_FILE" ]; then
        printf '%s\n' 'VOSVIDEODOWNLOAD UPDATE HISTORY LOG' > "$HISTORY_FILE"
    fi
    if printf 'UPDATE: %s (%s) -> %s (%s) | %s\n' "$VERSION" "$VERSION_TYPE" "$remote_version" "$(sed -n 's/^VERSION_TYPE="\([^"]*\)".*/\1/p' "$SCRIPT_PATH" | head -n 1)" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$HISTORY_FILE"; then
        printf "%s\n" "${GREEN}UPDATE HISTORY SAVED TO: $HISTORY_FILE${RESET}"
    else
        printf "%s\n" "${YELLOW}WARNING: UPDATE INSTALLED, BUT HISTORY COULD NOT BE WRITTEN.${RESET}"
    fi

    printf "%s\n" "${GREEN}UPDATE INSTALLED. RESTARTING...${RESET}"
    exec "$SCRIPT_PATH" "$@"
}

version_info() {
    banner
    dep_status="INSTALLED"
    if ! command -v yt-dlp >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
        dep_status="NOT INSTALLED"
    fi

    vid_count=0
    if [ -d "$VIDEOS_DIR" ]; then
        vid_count=$(find "$VIDEOS_DIR" -maxdepth 1 -type f ! -name ".*" | wc -l | tr -d ' ')
    fi

    printf "%s\n" "${RED} VOSVIDEODOWNLOAD${RESET}"
    printf "%s\n" "${GREEN}VERSION: ${YELLOW}${VERSION} | ${VERSION_TYPE}${RESET}"
    printf "%s\n" "${GREEN}DEPENDENCIES: ${YELLOW}${dep_status}${RESET}"
    printf "%s\n" "${GREEN}VIDEOS DOWNLOADED: ${YELLOW}${vid_count}${RESET}"
    printf "\n"
    printf "%s" "${CYAN}PRESS ENTER TO BACK${RESET}"
    read -r enter
}

while true; do
    banner
    printf "%s\n" "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO YOUTUBE DOWNLOADER${RESET}"
    printf "%s\n" "${GREEN}1: DOWNLOAD VIDEO${RESET}"
    printf "%s\n" "${GREEN}2: DEPENDENCIES${RESET}"
    printf "%s\n" "${GREEN}3: UPDATE VOSVIDEODOWNLOAD${RESET}"
    printf "%s\n" "${GREEN}4: CHECK VOSVIDEODOWNLOAD VERSION${RESET}"
    printf "%s\n" "${GREEN}5: QUIT${RESET}"
    printf "%s\n" "${GREEN}6: RESTART${RESET}"
    read -r choice

    case "$choice" in
        1) download_video ;;
        2) dependencies_menu ;;
        3) update_program ;;
        4) version_info ;;
        5) exit 0 ;;
        6) exec "$SCRIPT_PATH" "$@" ;;
    esac
done
