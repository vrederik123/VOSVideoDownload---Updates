#!/bin/sh
# TURN INTO ".SH" TO USE.
# ANY FALSE USE OF THIS PROGRAM CAN RESULT IN COPYRIGHT INFRINGEMENT TO THE RESPECTIVE AUTHORS.

VOS_IOS_SCRIPT=1
VERSION=1.03.31
VERSION_TYPE=APPLE
UPDATE_URL_BASE=https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh
UPDATE_URL=$UPDATE_URL_BASE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
HISTORY_FILE="$SCRIPT_DIR/history.txt"

if command -v pkg >/dev/null 2>&1; then
    IOS_MODE=1
else
    IOS_MODE=0
fi

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

ytdlp_available() {
    if [ "$IOS_MODE" -eq 1 ]; then
        command -v python3 >/dev/null 2>&1 && python3 -m yt_dlp --version >/dev/null 2>&1
        return $?
    fi
    if command -v yt-dlp >/dev/null 2>&1; then
        return 0
    fi
    command -v python3 >/dev/null 2>&1 && python3 -m yt_dlp --version >/dev/null 2>&1
}

run_ytdlp() {
    if [ "$IOS_MODE" -eq 1 ] && command -v python3 >/dev/null 2>&1; then
        python3 -m yt_dlp "$@"
    elif command -v yt-dlp >/dev/null 2>&1; then
        yt-dlp "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m yt_dlp "$@"
    else
        printf '%s\n' "${RED}[ERROR] YT-DLP IS NOT INSTALLED.${RESET}"
        return 127
    fi
}

ffmpeg_available() {
    [ "$IOS_MODE" -eq 0 ] && command -v ffmpeg >/dev/null 2>&1
}

download_video() {
    banner
    if ! ytdlp_available; then
        printf "%s\n" "${RED}[ERROR] YT-DLP IS MISSING! INSTALL IT FROM MENU OPTION 2 FIRST.${RESET}"
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
    if ffmpeg_available; then
        if run_ytdlp -P "$VIDEOS_DIR" -f "bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]" \
            --merge-output-format mp4 "$url"; then
            printf "\n"
            printf "%s\n" "${GREEN}DONE! SAVED TO THE VIDEOS FOLDER.${RESET}"
        else
            printf "%s\n" "${RED}DOWNLOAD FAILED. CHECK THE URL, NETWORK, AND DEPENDENCIES.${RESET}"
        fi
    else
        printf "%s\n" "${YELLOW}USING A SINGLE-FILE VIDEO FORMAT; FFMPEG MERGING IS UNAVAILABLE.${RESET}"
        if run_ytdlp -P "$VIDEOS_DIR" -f "b[vcodec^=avc1][ext=mp4]/b[ext=mp4]/b" "$url"; then
            printf "\n"
            printf "%s\n" "${GREEN}DONE! SAVED TO THE VIDEOS FOLDER.${RESET}"
        else
            printf "%s\n" "${RED}DOWNLOAD FAILED. CHECK THE URL, NETWORK, AND DEPENDENCIES.${RESET}"
        fi
    fi
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

dep_check() {
    banner
    missing=0

    if ytdlp_available; then
        printf "%s\n" "${GREEN}[OK] YT-DLP IS INSTALLED.${RESET}"
    else
        printf "%s\n" "${RED}[MISSING] YT-DLP IS NOT INSTALLED.${RESET}"
        missing=1
    fi

    if [ "$IOS_MODE" -eq 1 ]; then
        printf "%s\n" "${YELLOW}[OK] FFMPEG IS BUILT INTO A-SHELL; THIS SCRIPT USES SINGLE-FILE FORMATS.${RESET}"
    elif command -v ffmpeg >/dev/null 2>&1; then
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

pip_install_ytdlp() {
    if command -v pip >/dev/null 2>&1; then
        pip "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m pip "$@"
    else
        printf "%s\n" "${RED}[ERROR] PYTHON/PIP IS NOT AVAILABLE IN THIS SHELL.${RESET}"
        return 127
    fi
}

dep_download() {
    banner
    printf "%s\n" "${RED}INSTALLING DEPENDENCIES...${RESET}"
    if [ "$IOS_MODE" -eq 1 ]; then
        pip_install_ytdlp install yt-dlp
    elif command -v brew >/dev/null 2>&1; then
        brew install yt-dlp ffmpeg
    else
        pip_install_ytdlp install yt-dlp
    fi
    install_status=$?
    printf "\n"
    if [ "$install_status" -eq 0 ]; then
        printf "%s\n" "${GREEN}INSTALLATION COMPLETE!${RESET}"
    else
        printf "%s\n" "${RED}INSTALLATION FAILED (EXIT CODE $install_status).${RESET}"
    fi
    printf "\n"
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

dep_update() {
    banner
    printf "%s\n" "${RED}UPDATING DEPENDENCIES...${RESET}"
    if [ "$IOS_MODE" -eq 1 ]; then
        pip_install_ytdlp install --upgrade yt-dlp
    elif command -v brew >/dev/null 2>&1; then
        brew upgrade yt-dlp ffmpeg
    else
        pip_install_ytdlp install --upgrade yt-dlp
    fi
    update_status=$?
    printf "\n"
    if [ "$update_status" -eq 0 ]; then
        printf "%s\n" "${GREEN}UPDATE CHECK COMPLETE!${RESET}"
    else
        printf "%s\n" "${RED}DEPENDENCY UPDATE FAILED (EXIT CODE $update_status).${RESET}"
    fi
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
            if [ "$IOS_MODE" -eq 1 ] || ! command -v brew >/dev/null 2>&1; then
                pip_install_ytdlp uninstall -y yt-dlp
            else
                brew uninstall yt-dlp
            fi
            delete_status=$?
            if [ "$delete_status" -eq 0 ]; then
                printf "%s\n" "${GREEN}YT-DLP REMOVED.${RESET}"
            else
                printf "%s\n" "${RED}YT-DLP UNINSTALL FAILED (EXIT CODE $delete_status).${RESET}"
            fi
            printf "\n"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        elif [ "$delchoice" = "2" ]; then
            banner
            if [ "$IOS_MODE" -eq 1 ]; then
                printf "%s\n" "${YELLOW}FFMPEG IS BUILT INTO A-SHELL AND CANNOT BE UNINSTALLED.${RESET}"
            elif command -v brew >/dev/null 2>&1; then
                brew uninstall ffmpeg
            else
                printf "%s\n" "${YELLOW}FFMPEG IS NOT MANAGED BY HOMEBREW.${RESET}"
            fi
            printf "\n"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
        elif [ "$delchoice" = "3" ]; then
            banner
            printf "%s\n" "${RED}UNINSTALLING ALL REMOVABLE DEPENDENCIES...${RESET}"
            if [ "$IOS_MODE" -eq 1 ] || ! command -v brew >/dev/null 2>&1; then
                pip_install_ytdlp uninstall -y yt-dlp
            else
                brew uninstall yt-dlp ffmpeg
            fi
            delete_status=$?
            if [ "$delete_status" -eq 0 ]; then
                printf "%s\n" "${GREEN}ALL REMOVABLE DEPENDENCIES REMOVED.${RESET}"
            else
                printf "%s\n" "${RED}DEPENDENCY UNINSTALL FAILED (EXIT CODE $delete_status).${RESET}"
            fi
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

version_info() {
    banner
    dep_status="INSTALLED"
    if ! ytdlp_available; then
        dep_status="YT-DLP NOT INSTALLED"
    elif [ "$IOS_MODE" -eq 0 ] && ! command -v ffmpeg >/dev/null 2>&1; then
        dep_status="FFMPEG NOT INSTALLED"
    elif [ "$IOS_MODE" -eq 1 ]; then
        dep_status="INSTALLED (A-SHELL)"
    fi

    vid_count=0
    if [ -d "$VIDEOS_DIR" ]; then
        vid_count=$(find "$VIDEOS_DIR" -type f ! -name ".*" | wc -l | tr -d ' ')
    fi

    printf "%s\n" "${RED} VOSVIDEODOWNLOAD${RESET}"
    printf "%s\n" "${GREEN}VERSION: ${YELLOW}${VERSION} | RELEASE (APPLE BUILD)${RESET}"
    printf "%s\n" "${GREEN}DEPENDENCIES: ${YELLOW}${dep_status}${RESET}"
    printf "%s\n" "${GREEN}VIDEOS DOWNLOADED: ${YELLOW}${vid_count}${RESET}"
    printf "\n"
    printf "%s" "${CYAN}PRESS ENTER TO BACK${RESET}"
    read -r enter
}

valid_version() {
    awk -v version="$1" 'BEGIN {
        count = split(version, part, ".")
        if (count < 2 || count > 4) exit 1
        for (i = 1; i <= count; i++) {
            if (part[i] !~ /^[0-9]+$/) exit 1
        }
    }'
}

compare_versions() {
    awk -v old="$1" -v new="$2" 'BEGIN {
        old_count = split(old, old_part, ".")
        new_count = split(new, new_part, ".")
        count = old_count > new_count ? old_count : new_count
        for (i = 1; i <= count; i++) {
            old_value = old_part[i] + 0
            new_value = new_part[i] + 0
            if (new_value > old_value) { print 1; exit }
            if (new_value < old_value) { print -1; exit }
        }
        print 0
    }'
}

rewrite_update_url() {
    awk -v url="$UPDATE_URL_BASE" '
        BEGIN { matches = 0 }
        /^UPDATE_URL_BASE=/ {
            print "UPDATE_URL_BASE=" url
            matches++
            next
        }
        { print }
        END { if (matches != 1) exit 1 }
    ' "$1" > "$2"
}

update_app() {
    banner
    printf "%s\n" "${RED}CHECKING FOR VOSVIDEODOWNLOAD UPDATES...${RESET}"
    if ! command -v curl >/dev/null 2>&1; then
        printf "%s\n" "${RED}CURL IS NOT AVAILABLE IN THIS SHELL.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    update_tmp="$SCRIPT_PATH.update.$$"
    update_ready="$update_tmp.ready"
    if ! curl --location --fail --silent --show-error --connect-timeout 15 --max-time 60 \
        "$UPDATE_URL" --output "$update_tmp"; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}UPDATE DOWNLOAD FAILED. CHECK YOUR CONNECTION.${RESET}"
        printf "%s\n" "${YELLOW}UPDATE URL: $UPDATE_URL${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    if [ ! -s "$update_tmp" ] || ! grep -Fxq 'VOS_IOS_SCRIPT=1' "$update_tmp"; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}THE DOWNLOADED FILE IS NOT A VALID APPLE VERSION.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    remote_version=$(sed -n 's/^VERSION=//p' "$update_tmp" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE=//p' "$update_tmp" | head -n 1)
    if ! valid_version "$remote_version" || [ -z "$remote_type" ]; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}THE UPDATE HAS INVALID VERSION INFORMATION.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi
    case "$remote_type" in
        *[!A-Za-z0-9_-]*)
            rm -f "$update_tmp" "$update_ready"
            printf "%s\n" "${RED}THE UPDATE HAS INVALID VERSION INFORMATION.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            return
            ;;
    esac

    if ! rewrite_update_url "$update_tmp" "$update_ready"; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}COULD NOT SET THE UPDATE URL.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi
    if [ "$IOS_MODE" -eq 0 ] && ! sh -n "$update_ready"; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}THE DOWNLOADED UPDATE HAS INVALID SHELL SYNTAX.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    version_order=$(compare_versions "$VERSION" "$remote_version")
    if [ "$version_order" -ge 0 ]; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${GREEN}VOSVIDEODOWNLOAD $VERSION IS ALREADY UP TO DATE.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    printf "%s\n" "${GREEN}UPDATE FOUND: $VERSION TO $remote_version ($remote_type)${RESET}"
    printf "%s" "${CYAN}INSTALL THIS UPDATE? [Y/N]: ${RESET}"
    read -r update_choice
    if [ "$update_choice" != "Y" ] && [ "$update_choice" != "y" ]; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${YELLOW}UPDATE CANCELLED.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi

    if [ -x "$SCRIPT_PATH" ] && ! chmod +x "$update_ready"; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}COULD NOT PRESERVE THE SCRIPT'S EXECUTABLE PERMISSION.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi
    if ! mv "$update_ready" "$SCRIPT_PATH"; then
        rm -f "$update_tmp" "$update_ready"
        printf "%s\n" "${RED}COULD NOT REPLACE THE SCRIPT IN THIS FOLDER.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
    fi
    rm -f "$update_tmp"

    if [ ! -f "$HISTORY_FILE" ]; then
        printf '%s\n' "VOSVIDEODOWNLOAD UPDATE HISTORY LOG" > "$HISTORY_FILE"
    fi
    update_date=$(date '+%m/%d/%Y at %I:%M %p')
    printf 'UPDATE: %s (%s) > %s (%s) AT %s\n' \
        "$VERSION" "$VERSION_TYPE" "$remote_version" "$remote_type" "$update_date" >> "$HISTORY_FILE"
    printf "%s\n" "${GREEN}UPDATE INSTALLED.${RESET}"
    printf "%s\n" "${CYAN}QUIT AND RUN THE SCRIPT AGAIN TO USE THE NEW VERSION.${RESET}"
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

while true; do
    banner
    printf "%s\n" "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO YOUTUBE DOWNLOADER${RESET}"
    printf "%s\n" "${GREEN}1: DOWNLOAD VIDEO${RESET}"
    printf "%s\n" "${GREEN}2: DEPENDENCIES${RESET}"
    printf "%s\n" "${GREEN}3: CHECK VOSVIDEODOWNLOAD VERSION${RESET}"
    printf "%s\n" "${GREEN}4: QUIT${RESET}"
    printf "%s\n" "${GREEN}5: RESTART${RESET}"
    printf "%s\n" "${GREEN}6: CHECK FOR VOSVIDEODOWNLOAD UPDATES${RESET}"
    read -r choice

    case "$choice" in
        1) download_video ;;
        2) dependencies_menu ;;
        3) version_info ;;
        4) exit 0 ;;
        5) exec "$0" "$@" ;;
        6) update_app ;;
    esac
done
