#!/bin/sh
# TURN INTO ".SH" TO USE.
# ANY FALSE USE OF THIS PROGRAM CAN RESULT IN COPYRIGHT INFRINGEMENT TO THE RESPECTIVE AUTHORS.

VERSION="1.00.13"
VERSION_TYPE="RELEASE (IOS BUILD)"
UPDATE_URL="https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
HISTORY_FILE="$SCRIPT_DIR/history.txt"
SETTINGS_FILE="$SCRIPT_DIR/settings.txt"
METADATA="DISABLED"

ESC=$(printf '\033')
RED="${ESC}[91m"
DARKRED="${ESC}[31m"
ORANGE="${ESC}[38;5;208m"
YELLOW="${ESC}[93m"
GREEN="${ESC}[92m"
CYAN="${ESC}[96m"
RESET="${ESC}[0m"

load_settings() {
    METADATA="DISABLED"
    if [ -f "$SETTINGS_FILE" ]; then
        while IFS='=' read -r key value; do
            if [ "$key" = "METADATA" ]; then
                case "$value" in
                    ENABLED) METADATA="ENABLED" ;;
                    *) METADATA="DISABLED" ;;
                esac
            fi
        done < "$SETTINGS_FILE"
    fi
}

save_settings() {
    printf 'METADATA=%s\n' "$METADATA" > "$SETTINGS_FILE"
}

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

check_download_dependencies() {
    command -v yt-dlp >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1
}

download_menu() {
    while true; do
        banner
        printf "%s\n" "${RED}DOWNLOAD OPTIONS${RESET}"
        printf "%s\n" "${GREEN}1: DOWNLOAD VIDEO${RESET}"
        printf "%s\n" "${GREEN}2: DOWNLOAD AUDIO${RESET}"
        printf "%s\n" "${GREEN}3: DOWNLOAD VIDEO ONLY (NO AUDIO)${RESET}"
        printf "%s\n" "${GREEN}4: DOWNLOAD ALL VIDEOS ON CHANNEL${RESET}"
        printf "%s\n" "${GREEN}5: DOWNLOAD ALL SHORTS ON CHANNEL${RESET}"
        printf "%s\n" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        read -r download_choice
        [ -z "$download_choice" ] && return

        if ! check_download_dependencies; then
            banner
            printf "%s\n" "${RED}YT-DLP OR FFMPEG IS MISSING. INSTALL DEPENDENCIES FIRST.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            continue
        fi

        case "$download_choice" in
            1) prompt="PASTE VIDEO URL"; args="-f bv*[vcodec*=avc1]+ba[ext=m4a]/b[ext=mp4] --merge-output-format mp4"; subdir="" ;;
            2) prompt="PASTE URL FOR AUDIO"; args="-x --audio-format mp3 --audio-quality 0"; subdir="" ;;
            3) prompt="PASTE URL FOR VIDEO ONLY"; args="-f bv*[vcodec*=avc1]/bv*[ext=mp4] --merge-output-format mp4"; subdir="" ;;
            4) prompt="PASTE CHANNEL /VIDEOS URL"; args="-f bv*[vcodec*=avc1]+ba[ext=m4a]/b[ext=mp4] --merge-output-format mp4 --yes-playlist"; subdir="%(channel)s - VIDEOS" ;;
            5) prompt="PASTE CHANNEL /SHORTS URL"; args="-f bv*[vcodec*=avc1]+ba[ext=m4a]/b[ext=mp4] --merge-output-format mp4 --yes-playlist"; subdir="%(channel)s - SHORTS" ;;
            *) continue ;;
        esac

        banner
        printf "%s" "${RED}${prompt} ${CYAN}(OR PRESS ENTER TO GO BACK)${RED}: ${RESET}"
        read -r url
        [ -z "$url" ] && continue
        mkdir -p "$VIDEOS_DIR" || {
            printf "%s\n" "${RED}COULD NOT CREATE THE VIDEOS DIRECTORY.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
            read -r enter
            continue
        }

        output_template="%(title)s.%(ext)s"
        extra_args=""
        if [ -n "$subdir" ]; then
            output_template="$subdir/$output_template"
        fi

        if [ "$METADATA" = "ENABLED" ]; then
            if [ -n "$subdir" ]; then
                output_template="$subdir/%(title)s/%(title)s.%(ext)s"
            else
                output_template="%(title)s/%(title)s.%(ext)s"
            fi
            extra_args="--write-description --write-thumbnail --convert-thumbnails jpg"
        fi

        if yt-dlp -P "$VIDEOS_DIR" -o "$output_template" $args $extra_args "$url"; then
            printf "\n%s\n" "${GREEN}DONE! SAVED TO THE VIDEOS FOLDER.${RESET}"
        else
            status=$?
            printf "\n%s\n" "${RED}DOWNLOAD FAILED. YT-DLP RETURNED ERROR CODE ${status}. CHECK THE URL, NETWORK, AND DEPENDENCIES.${RESET}"
        fi
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
    done
}

dep_check() {
    banner
    missing=0
    for tool in yt-dlp ffmpeg ffprobe ffplay; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf "%s\n" "${GREEN}[OK] $tool IS INSTALLED.${RESET}"
        else
            printf "%s\n" "${YELLOW}[OPTIONAL/MISSING] $tool IS NOT INSTALLED.${RESET}"
            [ "$tool" = "yt-dlp" ] || [ "$tool" = "ffmpeg" ] && missing=1
        fi
    done

    printf "\n"
    if [ "$missing" -eq 1 ]; then
        printf "%s\n" "${RED}WOULD YOU LIKE TO INSTALL/REPAIR YT-DLP AND FFMPEG?${RESET}"
        printf "%s\n" "${GREEN}[Y] YES | [N] NO${RESET}"
        read -r dlchoice
        case "$dlchoice" in Y|y) dep_download ;; esac
    else
        printf "%s\n" "${GREEN}ALL REQUIRED DEPENDENCIES ARE WORKING PROPERLY!${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
    fi
}

python_command() {
    if command -v python3 >/dev/null 2>&1; then
        python3 "$@"
    elif command -v python >/dev/null 2>&1; then
        python "$@"
    else
        return 127
    fi
}

dep_download() {
    banner
    printf "%s\n" "${RED}INSTALLING YT-DLP AND FFMPEG...${RESET}"

    failed=0
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --upgrade yt-dlp || failed=1
    elif command -v pip >/dev/null 2>&1; then
        pip install --upgrade yt-dlp || failed=1
    elif python_command -m pip --version >/dev/null 2>&1; then
        python_command -m pip install --upgrade yt-dlp || failed=1
    else
        printf "%s\n" "${RED}NO PYTHON/PIP INSTALLER WAS FOUND.${RESET}"
        failed=1
    fi

    if ! command -v ffmpeg >/dev/null 2>&1; then
        printf "%s\n" "${YELLOW}FFMPEG IS NOT AVAILABLE AUTOMATICALLY ON THIS PLATFORM.${RESET}"
        printf "%s\n" "${YELLOW}PLEASE INSTALL FFMPEG THROUGH A-SHELL/APK OR THE IOS PACKAGE MANAGER.${RESET}"
        failed=1
    fi

    if [ "$failed" -eq 0 ] && check_download_dependencies; then
        printf "%s\n" "${GREEN}DEPENDENCY INSTALLATION COMPLETE!${RESET}"
    else
        printf "%s\n" "${RED}ONE OR MORE DEPENDENCIES COULD NOT BE INSTALLED.${RESET}"
    fi
    printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

dep_update() {
    banner
    printf "%s\n" "${RED}UPDATING YT-DLP...${RESET}"
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --upgrade yt-dlp
    elif command -v pip >/dev/null 2>&1; then
        pip install --upgrade yt-dlp
    elif python_command -m pip --version >/dev/null 2>&1; then
        python_command -m pip install --upgrade yt-dlp
    else
        printf "%s\n" "${RED}NO PYTHON/PIP INSTALLER WAS FOUND.${RESET}"
    fi
    printf "\n%s\n" "${GREEN}UPDATE CHECK COMPLETE!${RESET}"
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

        case "$delchoice" in
            "") return ;;
            1)
                banner
                if command -v pip3 >/dev/null 2>&1; then pip3 uninstall -y yt-dlp
                elif command -v pip >/dev/null 2>&1; then pip uninstall -y yt-dlp
                elif python_command -m pip --version >/dev/null 2>&1; then python_command -m pip uninstall -y yt-dlp
                else printf "%s\n" "${RED}NO PYTHON/PIP INSTALLER WAS FOUND.${RESET}"; fi
                printf "%s\n" "${GREEN}YT-DLP REMOVED.${RESET}" ;;
            2)
                banner
                printf "%s\n" "${YELLOW}FFMPEG IS PLATFORM-PROVIDED AND IS NOT REMOVED BY THIS SCRIPT.${RESET}" ;;
            3)
                banner
                if command -v pip3 >/dev/null 2>&1; then pip3 uninstall -y yt-dlp
                elif command -v pip >/dev/null 2>&1; then pip uninstall -y yt-dlp
                elif python_command -m pip --version >/dev/null 2>&1; then python_command -m pip uninstall -y yt-dlp
                else printf "%s\n" "${RED}NO PYTHON/PIP INSTALLER WAS FOUND.${RESET}"; fi
                printf "%s\n" "${YELLOW}FFMPEG WAS NOT REMOVED BECAUSE IT IS PLATFORM-PROVIDED.${RESET}" ;;
            *) continue ;;
        esac
        printf "\n%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
        read -r enter
        return
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

        case "$depchoice" in
            "") return ;;
            1) dep_check ;;
            2) dep_download ;;
            3) dep_update ;;
            4) dep_delete ;;
        esac
    done
}

update_animation() {
    bar_width=24
    i=0
    while [ "$i" -le "$bar_width" ]; do
        filled=""; empty=""; j=0
        while [ "$j" -lt "$i" ]; do filled="${filled}█"; j=$((j + 1)); done
        while [ "$j" -lt "$bar_width" ]; do empty="${empty} "; j=$((j + 1)); done
        percent=$((i * 100 / bar_width))
        printf '\r%s[%s%s] %3d%%' "$CYAN" "$filled" "$empty" "$percent"
        sleep 0.04
        i=$((i + 1))
    done
    printf '\n%s\n' "$RESET"
}

version_compare() {
    old=$1; new=$2
    if [ "$old" = "$new" ]; then printf 'CURRENT'; return; fi
    old_a=$(printf '%s' "$old" | sed 's/[^0-9.]//g')
    new_a=$(printf '%s' "$new" | sed 's/[^0-9.]//g')
    if [ -z "$old_a" ] || [ -z "$new_a" ]; then printf 'INVALID'; return; fi
    old_i=$(printf '%s' "$old_a" | tr . ' ')
    new_i=$(printf '%s' "$new_a" | tr . ' ')
    set -- $old_i
    old1=${1:-0}; old2=${2:-0}; old3=${3:-0}; old4=${4:-0}
    set -- $new_i
    new1=${1:-0}; new2=${2:-0}; new3=${3:-0}; new4=${4:-0}
    if [ "$new1" -gt "$old1" ] || { [ "$new1" -eq "$old1" ] && [ "$new2" -gt "$old2" ]; } || { [ "$new1" -eq "$old1" ] && [ "$new2" -eq "$old2" ] && [ "$new3" -gt "$old3" ]; } || { [ "$new1" -eq "$old1" ] && [ "$new2" -eq "$old2" ] && [ "$new3" -eq "$old3" ] && [ "$new4" -gt "$old4" ]; }; then
        printf 'UPDATE'
    elif [ "$new1" -lt "$old1" ] || { [ "$new1" -eq "$old1" ] && [ "$new2" -lt "$old2" ]; } || { [ "$new1" -eq "$old1" ] && [ "$new2" -eq "$old2" ] && [ "$new3" -lt "$old3" ]; } || { [ "$new1" -eq "$old1" ] && [ "$new2" -eq "$old2" ] && [ "$new3" -eq "$old3" ] && [ "$new4" -lt "$old4" ]; }; then
        printf 'OLDER'
    else
        printf 'CURRENT'
    fi
}

update_program() {
    banner
    printf "%s\n" "${RED}CHECKING FOR VOSVIDEODOWNLOAD UPDATES...${RESET}"

    update_file=$(mktemp "$SCRIPT_DIR/.vosvideodownload-update.XXXXXX") || {
        printf "%s\n" "${RED}COULD NOT CREATE A TEMPORARY UPDATE FILE.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
        return
    }

    cache_buster="$(date +%s 2>/dev/null || printf 1)$$"
    if command -v curl >/dev/null 2>&1; then
        curl -fLsS --connect-timeout 10 --max-time 60 "${UPDATE_URL}?cache=${cache_buster}" -o "$update_file" || download_failed=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=30 -O "$update_file" "${UPDATE_URL}?cache=${cache_buster}" || download_failed=1
    else
        download_failed=1
    fi

    if [ "${download_failed:-0}" -ne 0 ]; then
        rm -f "$update_file"
        printf "%s\n" "${RED}UPDATE DOWNLOAD FAILED. CHECK YOUR CONNECTION.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
        return
    fi

    remote_version=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$update_file" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE="\([^"]*\)".*/\1/p' "$update_file" | head -n 1)
    [ -n "$remote_type" ] || remote_type="UNKNOWN"

    if [ -z "$remote_version" ] || ! grep -q '^#!/bin/sh' "$update_file" || ! sh -n "$update_file"; then
        rm -f "$update_file"
        printf "%s\n" "${RED}THE DOWNLOADED UPDATE IS INVALID; YOUR SCRIPT WAS NOT CHANGED.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
        return
    fi

    compare_result=$(version_compare "$VERSION" "$remote_version")
    case "$compare_result" in
        CURRENT)
            rm -f "$update_file"
            printf "%s\n" "${GREEN}VOSVIDEODOWNLOAD $VERSION IS ALREADY UP TO DATE.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
            return ;;
        OLDER)
            rm -f "$update_file"
            printf "%s\n" "${YELLOW}THIS COPY IS NEWER THAN THE REMOTE RELEASE.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
            return ;;
        INVALID)
            rm -f "$update_file"
            printf "%s\n" "${RED}THE UPDATE VERSION IS INVALID.${RESET}"
            printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
            return ;;
    esac

    printf "%s\n" "${CYAN}UPDATE FOUND: $VERSION TO $remote_version${RESET}"
    update_animation
    printf "%s" "${CYAN}INSTALL UPDATE AND RESTART? [Y/N]: ${RESET}"
    read -r update_choice
    case "$update_choice" in Y|y|YES|yes) ;; *) rm -f "$update_file"; return ;; esac

    backup_file="$SCRIPT_PATH.backup"
    cp -f "$SCRIPT_PATH" "$backup_file" 2>/dev/null || true
    chmod +x "$update_file"
    if mv -f "$update_file" "$SCRIPT_PATH" 2>/dev/null; then
        :
    else
        rm -f "$backup_file" "$update_file"
        printf "%s\n" "${RED}COULD NOT INSTALL THE UPDATE. CHECK WRITE PERMISSIONS.${RESET}"
        printf "%s" "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; read -r enter
        return
    fi

    if [ -f "$HISTORY_FILE" ] || : > "$HISTORY_FILE" 2>/dev/null; then
        printf 'UPDATE: %s (%s) -> %s (%s) | %s\n' "$VERSION" "$VERSION_TYPE" "$remote_version" "$remote_type" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$HISTORY_FILE" 2>/dev/null || true
    fi

    rm -f "$backup_file"
    printf "%s\n" "${GREEN}UPDATE INSTALLED. RESTARTING...${RESET}"
    exec "$SCRIPT_PATH" "$@"
}

settings_menu() {
    while true; do
        banner
        printf "%s\n" "${RED}VOSVIDEODOWNLOAD SETTINGS${RESET}"
        printf "%s\n" "${GREEN}VERSION: ${YELLOW}${VERSION} | ${VERSION_TYPE}${RESET}"
        printf "%s\n" "${GREEN}DEPENDENCY STATUS: ${YELLOW}"$(check_download_dependencies >/dev/null 2>&1 && printf INSTALLED || printf 'NOT INSTALLED')"${RESET}"
        printf "%s\n" "${GREEN}1: TOGGLE METADATA/THUMBNAIL: ${YELLOW}${METADATA}${RESET}"
        printf "%s\n" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        read -r settings_choice
        case "$settings_choice" in
            "") return ;; 
            1)
                if [ "$METADATA" = "DISABLED" ]; then METADATA="ENABLED"; else METADATA="DISABLED"; fi
                save_settings ;;
        esac
    done
}

version_info() {
    banner
    if check_download_dependencies; then dep_status="INSTALLED"; else dep_status="NOT INSTALLED"; fi

    vid_count=0
    if [ -d "$VIDEOS_DIR" ]; then
        vid_count=$(find "$VIDEOS_DIR" -maxdepth 1 -type f ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
    fi

    printf "%s\n" "${RED} VOSVIDEODOWNLOAD${RESET}"
    printf "%s\n" "${GREEN}VERSION: ${YELLOW}${VERSION} | ${VERSION_TYPE}${RESET}"
    printf "%s\n" "${GREEN}DEPENDENCIES: ${YELLOW}${dep_status}${RESET}"
    printf "%s\n" "${GREEN}METADATA/THUMBNAIL: ${YELLOW}${METADATA}${RESET}"
    printf "%s\n" "${GREEN}VIDEOS DOWNLOADED: ${YELLOW}${vid_count}${RESET}"
    printf "\n%s" "${CYAN}PRESS ENTER TO BACK${RESET}"
    read -r enter
}

load_settings
while true; do
    banner
    printf "%s\n" "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER${RESET}"
    printf "%s\n" "${GREEN}1: DOWNLOAD VIDEO${RESET}"
    printf "%s\n" "${GREEN}2: DEPENDENCIES${RESET}"
    printf "%s\n" "${GREEN}3: UPDATE VOSVIDEODOWNLOAD${RESET}"
    printf "%s\n" "${GREEN}4: VOSVIDEODOWNLOAD SETTINGS${RESET}"
    printf "%s\n" "${GREEN}5: QUIT${RESET}"
    printf "%s\n" "${GREEN}6: RESTART${RESET}"
    read -r choice

    case "$choice" in
        1) download_menu ;;
        2) dependencies_menu ;;
        3) update_program ;;
        4) settings_menu ;;
        5) exit 0 ;;
        6) exec "$SCRIPT_PATH" "$@" ;;
    esac
done
