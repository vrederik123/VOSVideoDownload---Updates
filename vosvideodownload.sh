#!/bin/sh
# TURN INTO ".SH" TO USE.
# ANY FALSE USE OF THIS PROGRAM CAN RESULT IN COPYRIGHT INFRINGEMENT TO THE RESPECTIVE AUTHORS.

VERSION="1.00.14"
VERSION_TYPE="RELEASE (IOS BUILD)"
UPDATE_URL="https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)" || exit 1
SCRIPT_PATH="$SCRIPT_DIR/$(basename -- "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
HISTORY_FILE="$SCRIPT_DIR/history.txt"
SETTINGS_FILE="$SCRIPT_DIR/settings.txt"
METADATA="DISABLED"

ESC=$(printf '\033')
RED="${ESC}[91m"; DARKRED="${ESC}[31m"; ORANGE="${ESC}[38;5;208m"
YELLOW="${ESC}[93m"; GREEN="${ESC}[92m"; CYAN="${ESC}[96m"; RESET="${ESC}[0m"

banner() {
    printf '\033[2J\033[3J\033[H'
    printf '%s\n' "${DARKRED} __     __   ___    ____     __     __  ___   ____    _____    ___  ${RESET}"
    printf '%s\n' "${DARKRED} \ \   / /  / _ \  / ___|    \ \   / / |_ _| |  _ \  | ____|  / _ \ ${RESET}"
    printf '%s\n' "${RED}  \ \ / /  | | | | \___ \     \ \ / /   | |  | | | | |  _|   | | | |${RESET}"
    printf '%s\n' "${RED}   \ V /   | |_| |  ___) |     \ V /    | |  | |_| | | |___  | |_| |${RESET}"
    printf '%s\n' "${ORANGE}    \_/     \___/  |____/       \_/    |___| |____/  |_____|  \___/ ${RESET}"
    printf '%s\n' "${ORANGE}  ____     ___   __        __  _   _   _        ___      _     ____  ${RESET}"
    printf '%s\n' "${ORANGE} |  _ \   / _ \  \ \      / / | \ | | | |      / _ \    / \   |  _ \ ${RESET}"
    printf '%s\n' "${ORANGE} | | | | | | | |  \ \ /\ / /  |  \| | | |     | | | |  / _ \  | | | |${RESET}"
    printf '%s\n' "${YELLOW} | |_| | | |_| |   \ V  V /   | |\  | | |___  | |_| | / ___ \ | |_| |${RESET}"
    printf '%s\n' "${YELLOW} |____/   \___/     \_/\_/    |_| \_| |_____|  \___/ /_/   \_\|____/ ${RESET}\n"
}

pause() { printf '%s' "${CYAN}PRESS ENTER TO CONTINUE${RESET}"; IFS= read -r enter || :; }
load_settings() {
    METADATA=DISABLED
    if [ -f "$SETTINGS_FILE" ]; then
        while IFS='=' read -r key value; do
            [ "$key" = METADATA ] && [ "$value" = ENABLED ] && METADATA=ENABLED
        done < "$SETTINGS_FILE"
    fi
}
save_settings() { printf 'METADATA=%s\n' "$METADATA" > "$SETTINGS_FILE"; }
check_required_dependencies() {
    command -v yt-dlp >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1
}

# Python/pip helpers keep install, update, and removal consistent.
pip_action() {
    action=$1; shift
    if command -v pip3 >/dev/null 2>&1; then pip3 "$action" "$@"
    elif command -v pip >/dev/null 2>&1; then pip "$action" "$@"
    elif command -v python3 >/dev/null 2>&1; then python3 -m pip "$action" "$@"
    elif command -v python >/dev/null 2>&1; then python -m pip "$action" "$@"
    else return 127
    fi
}

download_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}DOWNLOAD OPTIONS${RESET}" "${GREEN}1: DOWNLOAD VIDEO${RESET}" "${GREEN}2: DOWNLOAD AUDIO${RESET}" "${GREEN}3: DOWNLOAD VIDEO ONLY (NO AUDIO)${RESET}" "${GREEN}4: DOWNLOAD ALL VIDEOS ON CHANNEL${RESET}" "${GREEN}5: DOWNLOAD ALL SHORTS ON CHANNEL${RESET}" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        IFS= read -r choice || return
        [ -z "$choice" ] && return
        case "$choice" in
            1) prompt='PASTE VIDEO URL'; subdir=''; set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4 ;;
            2) prompt='PASTE URL FOR AUDIO'; subdir=''; set -- -x --audio-format mp3 --audio-quality 0 ;;
            3) prompt='PASTE URL FOR VIDEO ONLY'; subdir=''; set -- -f 'bv*[vcodec^=avc1]/bv*[ext=mp4]' --merge-output-format mp4 ;;
            4) prompt='PASTE CHANNEL /VIDEOS URL'; subdir='%(channel)s - VIDEOS'; set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4 --yes-playlist ;;
            5) prompt='PASTE CHANNEL /SHORTS URL'; subdir='%(channel)s - SHORTS'; set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4 --yes-playlist ;;
            *) continue ;;
        esac
        if ! check_required_dependencies; then
            banner; printf '%s\n' "${RED}YT-DLP OR FFMPEG IS MISSING. INSTALL DEPENDENCIES FIRST.${RESET}"; pause; continue
        fi
        banner; printf '%s' "${RED}${prompt} ${CYAN}(OR PRESS ENTER TO GO BACK)${RED}: ${RESET}"
        IFS= read -r url || return
        [ -z "$url" ] && continue
        if ! mkdir -p "$VIDEOS_DIR"; then printf '%s\n' "${RED}COULD NOT CREATE THE VIDEOS DIRECTORY.${RESET}"; pause; continue; fi
        if [ -n "$subdir" ]; then out="$subdir/%(title)s.%(ext)s"; else out='%(title)s.%(ext)s'; fi
        if [ "$METADATA" = ENABLED ]; then
            if [ -n "$subdir" ]; then out="$subdir/%(title)s/%(title)s.%(ext)s"; else out='%(title)s/%(title)s.%(ext)s'; fi
            set -- "$@" --write-description --write-thumbnail --convert-thumbnails jpg
        fi
        if yt-dlp -P "$VIDEOS_DIR" -o "$out" "$@" "$url"; then
            printf '\n%s\n' "${GREEN}DONE! SAVED TO THE VIDEOS FOLDER.${RESET}"
        else
            status=$?; printf '\n%s\n' "${RED}DOWNLOAD FAILED. YT-DLP RETURNED ERROR CODE $status. CHECK THE URL, NETWORK, AND DEPENDENCIES.${RESET}"
        fi
        pause
    done
}

dep_check() {
    banner; missing=0
    for tool in yt-dlp ffmpeg ffprobe ffplay; do
        if command -v "$tool" >/dev/null 2>&1; then printf '%s\n' "${GREEN}[OK] $tool IS INSTALLED.${RESET}"
        else
            if [ "$tool" = yt-dlp ] || [ "$tool" = ffmpeg ]; then
                printf '%s\n' "${RED}[REQUIRED/MISSING] $tool IS NOT INSTALLED.${RESET}"; missing=1
            else printf '%s\n' "${YELLOW}[OPTIONAL/MISSING] $tool IS NOT INSTALLED.${RESET}"; fi
        fi
    done
    if [ "$missing" -eq 1 ]; then
        printf '\n%s\n%s\n' "${RED}WOULD YOU LIKE TO INSTALL/UPDATE YT-DLP? FFMPEG MUST BE INSTALLED THROUGH YOUR PLATFORM PACKAGE MANAGER.${RESET}" "${GREEN}[Y] YES | [N] NO${RESET}"
        IFS= read -r answer; case "$answer" in Y|y) dep_download ;; esac
    else printf '\n%s\n' "${GREEN}ALL REQUIRED DEPENDENCIES ARE AVAILABLE.${RESET}"; pause
    fi
}
dep_download() {
    banner; printf '%s\n' "${RED}INSTALLING/UPDATING YT-DLP...${RESET}"
    if pip_action install --upgrade yt-dlp && command -v yt-dlp >/dev/null 2>&1; then
        printf '%s\n' "${GREEN}YT-DLP INSTALLATION COMPLETE.${RESET}"
    else
        printf '%s\n' "${RED}YT-DLP INSTALL FAILED. CHECK PYTHON/PIP AND YOUR PATH.${RESET}"
    fi
    if ! command -v ffmpeg >/dev/null 2>&1; then
        printf '%s\n' "${YELLOW}FFMPEG IS NOT INSTALLED. INSTALL IT USING YOUR PLATFORM'S PACKAGE MANAGER (FOR A-SHELL, USE ITS SUPPORTED PACKAGE METHOD).${RESET}"
    fi
    pause
}
dep_update() {
    banner; printf '%s\n' "${RED}UPDATING YT-DLP...${RESET}"
    if pip_action install --upgrade yt-dlp; then printf '%s\n' "${GREEN}YT-DLP UPDATE COMPLETE.${RESET}"
    else printf '%s\n' "${RED}YT-DLP UPDATE FAILED.${RESET}"; fi
    pause
}
dep_delete() {
    while :; do
        banner; printf '%s\n' "${RED}WHICH WOULD YOU LIKE TO UNINSTALL?${RESET}" "${GREEN}1: YT-DLP${RESET}" "${GREEN}2: FFMPEG${RESET}" "${GREEN}3: ALL REMOVABLE DEPENDENCIES${RESET}" "${CYAN}ENTER: GO BACK${RESET}"
        IFS= read -r choice || return
        case "$choice" in
            '') return ;;
            1|3) if pip_action uninstall -y yt-dlp; then printf '%s\n' "${GREEN}YT-DLP REMOVED.${RESET}"; else printf '%s\n' "${RED}COULD NOT REMOVE YT-DLP.${RESET}"; fi
                 [ "$choice" = 3 ] && printf '%s\n' "${YELLOW}FFMPEG IS PLATFORM-PROVIDED AND WAS NOT REMOVED.${RESET}"; pause; return ;;
            2) printf '%s\n' "${YELLOW}FFMPEG IS PLATFORM-PROVIDED AND IS NOT REMOVED BY THIS SCRIPT.${RESET}"; pause; return ;;
            *) ;;
        esac
    done
}
dependencies_menu() {
    while :; do
        banner; printf '%s\n' "${RED}DEPENDENCIES${RESET}" "${GREEN}1: CHECK DEPENDENCIES${RESET}" "${GREEN}2: INSTALL/REPAIR YT-DLP${RESET}" "${GREEN}3: UPDATE YT-DLP${RESET}" "${GREEN}4: DELETE DEPENDENCIES${RESET}" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        IFS= read -r choice || return
        case "$choice" in '' ) return ;; 1) dep_check ;; 2) dep_download ;; 3) dep_update ;; 4) dep_delete ;; esac
    done
}

update_animation() {
    width=20; i=0
    while [ "$i" -le "$width" ]; do
        bar=''; spaces=''; j=0
        while [ "$j" -lt "$i" ]; do bar="${bar}█"; j=$((j + 1)); done
        while [ "$j" -lt "$width" ]; do spaces="${spaces} "; j=$((j + 1)); done
        printf '\r%s[%s%s] %3d%%' "$CYAN" "$bar" "$spaces" "$((i * 100 / width))"
        sleep 0.04; i=$((i + 1))
    done
    printf '\n%s' "$RESET"
}
version_compare() {
    # Compare four numeric components without relying on non-portable version tools.
    old=$1; new=$2
    case "$old:$new" in *[!0-9.:]*) printf INVALID; return ;; esac
    old=$(printf '%s' "$old" | tr . ' '); new=$(printf '%s' "$new" | tr . ' ')
    set -- $old; a1=${1:-0}; a2=${2:-0}; a3=${3:-0}; a4=${4:-0}
    set -- $new; b1=${1:-0}; b2=${2:-0}; b3=${3:-0}; b4=${4:-0}
    for n in "$a1" "$a2" "$a3" "$a4" "$b1" "$b2" "$b3" "$b4"; do case "$n" in ''|*[!0-9]*) printf INVALID; return ;; esac; done
    if [ "$a1.$a2.$a3.$a4" = "$b1.$b2.$b3.$b4" ]; then printf CURRENT
    elif [ "$b1" -gt "$a1" ] || { [ "$b1" -eq "$a1" ] && [ "$b2" -gt "$a2" ]; } || { [ "$b1" -eq "$a1" ] && [ "$b2" -eq "$a2" ] && [ "$b3" -gt "$a3" ]; } || { [ "$b1" -eq "$a1" ] && [ "$b2" -eq "$a2" ] && [ "$b3" -eq "$a3" ] && [ "$b4" -gt "$a4" ]; }; then printf UPDATE
    else printf OLDER; fi
}
update_program() {
    banner; printf '%s\n' "${RED}CHECK FOR AND INSTALL A VOSVIDEODOWNLOAD UPDATE?${RESET}" "${CYAN}NO NETWORK DOWNLOAD WILL START UNLESS YOU CONFIRM YES.${RESET}" "${GREEN}[Y] YES | [N] NO${RESET}"
    IFS= read -r answer || return
    case "$answer" in Y|y|YES|yes) ;; *) printf '%s\n' "${YELLOW}UPDATE CANCELLED; NOTHING WAS DOWNLOADED.${RESET}"; return ;; esac

    update_file=$(mktemp "$SCRIPT_DIR/.vosvideodownload-update.XXXXXX") || { printf '%s\n' "${RED}COULD NOT CREATE A TEMPORARY UPDATE FILE.${RESET}"; pause; return; }
    cache="$(date +%s 2>/dev/null || printf 1)$$"
    if command -v curl >/dev/null 2>&1; then
        curl -fLsS --connect-timeout 10 --max-time 60 "${UPDATE_URL}?cache=$cache" -o "$update_file" || download_failed=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=30 -O "$update_file" "${UPDATE_URL}?cache=$cache" || download_failed=1
    else download_failed=1; fi
    if [ "${download_failed:-0}" -ne 0 ]; then rm -f "$update_file"; printf '%s\n' "${RED}UPDATE DOWNLOAD FAILED. CHECK YOUR CONNECTION OR CURL/WGET INSTALLATION.${RESET}"; pause; return; fi

    remote_version=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$update_file" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE="\([^"]*\)".*/\1/p' "$update_file" | head -n 1)
    [ -n "$remote_type" ] || remote_type=UNKNOWN
    if [ -z "$remote_version" ] || ! grep -q '^#!/bin/sh' "$update_file" || ! sh -n "$update_file"; then
        rm -f "$update_file"; printf '%s\n' "${RED}DOWNLOADED UPDATE FAILED VALIDATION; INSTALLED SCRIPT WAS NOT CHANGED.${RESET}"; pause; return
    fi
    result=$(version_compare "$VERSION" "$remote_version")
    case "$result" in
        CURRENT) rm -f "$update_file"; printf '%s\n' "${GREEN}ALREADY UP TO DATE ($VERSION).${RESET}"; pause; return ;;
        OLDER) rm -f "$update_file"; printf '%s\n' "${YELLOW}INSTALLED VERSION IS NEWER THAN THE REMOTE VERSION.${RESET}"; pause; return ;;
        INVALID) rm -f "$update_file"; printf '%s\n' "${RED}REMOTE VERSION NUMBER IS INVALID.${RESET}"; pause; return ;;
    esac
    printf '%s\n' "${CYAN}UPDATE FOUND: $VERSION TO $remote_version${RESET}"
    # This animation runs only after the user confirmed and a valid update was downloaded.
    update_animation

    backup="$SCRIPT_PATH.backup"
    if ! cp -p "$SCRIPT_PATH" "$backup" 2>/dev/null; then
        rm -f "$update_file"; printf '%s\n' "${RED}CANNOT BACK UP THE CURRENT SCRIPT; UPDATE ABORTED.${RESET}"; pause; return
    fi
    chmod +x "$update_file" || { rm -f "$backup" "$update_file"; printf '%s\n' "${RED}CANNOT MARK UPDATE EXECUTABLE.${RESET}"; pause; return; }
    if ! mv -f "$update_file" "$SCRIPT_PATH"; then
        mv -f "$backup" "$SCRIPT_PATH" 2>/dev/null || :
        rm -f "$update_file"; printf '%s\n' "${RED}UPDATE INSTALL FAILED; RESTORED THE PREVIOUS SCRIPT WHEN POSSIBLE.${RESET}"; pause; return
    fi
    if [ -f "$HISTORY_FILE" ] || : > "$HISTORY_FILE" 2>/dev/null; then
        printf 'UPDATE: %s (%s) -> %s (%s) | %s\n' "$VERSION" "$VERSION_TYPE" "$remote_version" "$remote_type" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$HISTORY_FILE" 2>/dev/null || printf '%s\n' "${YELLOW}WARNING: COULD NOT WRITE UPDATE HISTORY.${RESET}"
    else printf '%s\n' "${YELLOW}WARNING: COULD NOT CREATE HISTORY FILE.${RESET}"; fi
    rm -f "$backup"
    printf '%s\n' "${GREEN}UPDATE INSTALLED. RESTARTING...${RESET}"
    exec /bin/sh "$SCRIPT_PATH"
}

settings_menu() {
    while :; do
        banner
        if check_required_dependencies; then dep_status=INSTALLED; else dep_status='NOT INSTALLED'; fi
        printf '%s\n' "${RED}VOSVIDEODOWNLOAD SETTINGS${RESET}" "${GREEN}VERSION: ${YELLOW}$VERSION | $VERSION_TYPE${RESET}" "${GREEN}DEPENDENCIES: ${YELLOW}$dep_status${RESET}" "${GREEN}1: TOGGLE METADATA/THUMBNAIL: ${YELLOW}$METADATA${RESET}" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        IFS= read -r choice || return
        case "$choice" in '' ) return ;; 1) if [ "$METADATA" = ENABLED ]; then METADATA=DISABLED; else METADATA=ENABLED; fi; save_settings ;; esac
    done
}
version_info() {
    banner
    if check_required_dependencies; then dep_status=INSTALLED; else dep_status='NOT INSTALLED'; fi
    count=0; [ ! -d "$VIDEOS_DIR" ] || count=$(find "$VIDEOS_DIR" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
    printf '%s\n' "${RED}VOSVIDEODOWNLOAD${RESET}" "${GREEN}VERSION: ${YELLOW}$VERSION | $VERSION_TYPE${RESET}" "${GREEN}DEPENDENCIES: ${YELLOW}$dep_status${RESET}" "${GREEN}METADATA/THUMBNAIL: ${YELLOW}$METADATA${RESET}" "${GREEN}VIDEOS DOWNLOADED: ${YELLOW}$count${RESET}"
    pause
}

load_settings
while :; do
    banner
    printf '%s\n' "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER${RESET}" "${GREEN}1: DOWNLOAD VIDEO${RESET}" "${GREEN}2: DEPENDENCIES${RESET}" "${GREEN}3: UPDATE VOSVIDEODOWNLOAD${RESET}" "${GREEN}4: VOSVIDEODOWNLOAD SETTINGS${RESET}" "${GREEN}5: QUIT${RESET}" "${GREEN}6: RESTART${RESET}"
    IFS= read -r choice || exit 0
    case "$choice" in
        1) download_menu ;;
        2) dependencies_menu ;;
        3) update_program ;;
        4) settings_menu ;;
        5) exit 0 ;;
        6) exec /bin/sh "$SCRIPT_PATH" ;;
    esac
done
