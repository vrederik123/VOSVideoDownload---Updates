#!/bin/sh
# VOSVideoDownload shell edition
# Only download videos you are authorized to save.

VERSION="1.00.17"
VERSION_TYPE="RELEASE (IOS BUILD)"
UPDATE_URL="https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || exit 1
SCRIPT_PATH="$SCRIPT_DIR/$(basename -- "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
HISTORY_FILE="$SCRIPT_DIR/history.txt"
SETTINGS_FILE="$SCRIPT_DIR/settings.txt"

# Use the controlling terminal when the launcher detached standard input/output.
if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    exec </dev/tty >/dev/tty 2>&1
fi

ESC=$(printf '\033')
RED="${ESC}[91m"; DARKRED="${ESC}[31m"; ORANGE="${ESC}[38;5;208m"
YELLOW="${ESC}[93m"; GREEN="${ESC}[92m"; CYAN="${ESC}[96m"; RESET="${ESC}[0m"
METADATA=DISABLED
FLAME=STANDARD

prompt() { printf '%s' "$1"; IFS= read -r REPLY || return 1; }
pause() { prompt "${CYAN}PRESS ENTER TO CONTINUE: ${RESET}" || :; }

load_settings() {
    METADATA=DISABLED
    FLAME=STANDARD
    if [ -f "$SETTINGS_FILE" ]; then
        while IFS='=' read -r key value; do
            case "$key:$value" in
                METADATA:ENABLED) METADATA=ENABLED ;;
                FLAME:STANDARD|FLAME:PURPLE-PINK|FLAME:GREEN-WHITE|FLAME:ICE-BLUE|FLAME:OCEAN-TEAL|FLAME:SUNSET|FLAME:CYBERPUNK|FLAME:RAINBOW) FLAME=$value ;;
            esac
        done < "$SETTINGS_FILE"
    fi
}
save_settings() {
    printf 'METADATA=%s\nFLAME=%s\n' "$METADATA" "$FLAME" > "$SETTINGS_FILE"
}

set_flame() {
    case "$FLAME" in
        PURPLE-PINK)
            FLAME_DISPLAY='PURPLE-PINK FLAME'
            c1='80;0;150'; c2='105;0;185'; c3='130;0;215'; c4='155;0;235'; c5='180;0;245'
            c6='205;10;240'; c7='225;30;230'; c8='240;65;225'; c9='250;115;232'; c10='255;185;245' ;;
        GREEN-WHITE)
            FLAME_DISPLAY='GREEN-WHITE FLAME'
            c1='0;65;20'; c2='0;95;30'; c3='0;125;40'; c4='0;155;50'; c5='0;180;65'
            c6='25;205;90'; c7='65;225;125'; c8='110;240;165'; c9='175;250;210'; c10='245;255;250' ;;
        ICE-BLUE)
            FLAME_DISPLAY='ICE-BLUE FLAME'
            c1='18;18;95'; c2='25;35;135'; c3='25;55;175'; c4='30;80;215'; c5='35;110;245'
            c6='40;145;255'; c7='65;175;255'; c8='105;205;255'; c9='155;230;255'; c10='220;250;255' ;;
        OCEAN-TEAL)
            FLAME_DISPLAY='OCEAN-TEAL FLAME'
            c1='0;25;55'; c2='0;45;90'; c3='0;70;120'; c4='0;100;145'; c5='0;130;155'
            c6='0;160;155'; c7='25;190;155'; c8='80;215;175'; c9='145;235;205'; c10='210;255;235' ;;
        SUNSET)
            FLAME_DISPLAY='SUNSET FLAME'
            c1='38;0;85'; c2='70;0;130'; c3='105;0;160'; c4='145;10;175'; c5='185;20;160'
            c6='220;35;130'; c7='245;65;95'; c8='255;100;65'; c9='255;150;55'; c10='255;210;100' ;;
        CYBERPUNK)
            FLAME_DISPLAY='CYBERPUNK FLAME'
            c1='20;10;75'; c2='45;20;150'; c3='80;25;220'; c4='130;35;255'; c5='190;40;255'
            c6='245;35;220'; c7='255;35;160'; c8='255;65;125'; c9='170;130;255'; c10='85;235;255' ;;
        RAINBOW)
            FLAME_DISPLAY='RAINBOW FLAME'
            c1='255;25;45'; c2='255;75;0'; c3='255;155;0'; c4='255;225;0'; c5='135;255;0'
            c6='0;235;100'; c7='0;220;220'; c8='0;125;255'; c9='100;45;255'; c10='255;60;200' ;;
        *)
            FLAME=STANDARD
            FLAME_DISPLAY='RED-YELLOW FLAME'
            c1='120;0;0'; c2='155;0;0'; c3='190;5;0'; c4='225;20;0'; c5='250;45;0'
            c6='255;80;0'; c7='255;120;0'; c8='255;165;0'; c9='255;205;0'; c10='255;240;75' ;;
    esac
    FLAME1="${ESC}[38;2;${c1}m"; FLAME2="${ESC}[38;2;${c2}m"
    FLAME3="${ESC}[38;2;${c3}m"; FLAME4="${ESC}[38;2;${c4}m"
    FLAME5="${ESC}[38;2;${c5}m"; FLAME6="${ESC}[38;2;${c6}m"
    FLAME7="${ESC}[38;2;${c7}m"; FLAME8="${ESC}[38;2;${c8}m"
    FLAME9="${ESC}[38;2;${c9}m"; FLAME10="${ESC}[38;2;${c10}m"
}

banner() {
    printf '\033[2J\033[3J\033[H'
    printf '%s\n' "${FLAME1} __     __   ___    ____     __     __  ___   ____    _____    ___  ${RESET}"
    printf '%s\n' "${FLAME2} \ \   / /  / _ \  / ___|    \ \   / / |_ _| |  _ \  | ____|  / _ \ ${RESET}"
    printf '%s\n' "${FLAME3}  \ \ / /  | | | | \___ \     \ \ / /   | |  | | | | |  _|   | | | |${RESET}"
    printf '%s\n' "${FLAME4}   \ V /   | |_| |  ___) |     \ V /    | |  | |_| | | |___  | |_| |${RESET}"
    printf '%s\n' "${FLAME5}    \_/     \___/  |____/       \_/    |___| |____/  |_____|  \___/ ${RESET}"
    printf '%s\n' "${FLAME6}  ____     ___   __        __  _   _   _        ___      _     ____  ${RESET}"
    printf '%s\n' "${FLAME7} |  _ \   / _ \  \ \      / / | \ | | | |      / _ \    / \   |  _ \ ${RESET}"
    printf '%s\n' "${FLAME8} | | | | | | | |  \ \ /\ / /  |  \| | | |     | | | |  / _ \  | | | |${RESET}"
    printf '%s\n' "${FLAME9} | |_| | | |_| |   \ V  V /   | |\  | | |___  | |_| | / ___ \ | |_| |${RESET}"
    printf '%s\n' "${FLAME10}|____/   \___/     \_/\_/    |_| \_| |_____|  \___/ /_/   \_\|____/ ${RESET}"
    printf '\n'
}
check_required() { command -v yt-dlp >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1; }
pip_action() {
    action=$1; shift
    if command -v pip3 >/dev/null 2>&1; then pip3 "$action" "$@"
    elif command -v pip >/dev/null 2>&1; then pip "$action" "$@"
    elif command -v python3 >/dev/null 2>&1; then python3 -m pip "$action" "$@"
    elif command -v python >/dev/null 2>&1; then python -m pip "$action" "$@"
    else return 127; fi
}

download_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}DOWNLOAD OPTIONS${RESET}" "${GREEN}1: DOWNLOAD VIDEO${RESET}" "${GREEN}2: DOWNLOAD AUDIO${RESET}" "${GREEN}3: DOWNLOAD VIDEO ONLY (NO AUDIO)${RESET}" "${GREEN}4: DOWNLOAD ALL VIDEOS ON CHANNEL${RESET}" "${GREEN}5: DOWNLOAD ALL SHORTS ON CHANNEL${RESET}" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        prompt '> ' || return
        case "$REPLY" in
            '') return ;;
            1) label='PASTE VIDEO URL'; subdir=''; set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4 ;;
            2) label='PASTE URL FOR AUDIO'; subdir=''; set -- -x --audio-format mp3 --audio-quality 0 ;;
            3) label='PASTE URL FOR VIDEO ONLY'; subdir=''; set -- -f 'bv*[vcodec^=avc1]/bv*[ext=mp4]' --merge-output-format mp4 ;;
            4) label='PASTE CHANNEL /VIDEOS URL'; subdir='%(channel)s - VIDEOS'; set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4 --yes-playlist ;;
            5) label='PASTE CHANNEL /SHORTS URL'; subdir='%(channel)s - SHORTS'; set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4 --yes-playlist ;;
            *) continue ;;
        esac
        if ! check_required; then printf '%s\n' "${RED}YT-DLP OR FFMPEG IS MISSING. INSTALL DEPENDENCIES FIRST.${RESET}"; pause; continue; fi
        prompt "${RED}${label} (ENTER TO GO BACK): ${RESET}" || return
        url=$REPLY; [ -z "$url" ] && continue
        mkdir -p "$VIDEOS_DIR" || { printf '%s\n' "${RED}COULD NOT CREATE VIDEOS DIRECTORY.${RESET}"; pause; continue; }
        if [ -n "$subdir" ]; then out="$subdir/%(title)s.%(ext)s"; else out='%(title)s.%(ext)s'; fi
        if [ "$METADATA" = ENABLED ]; then
            if [ -n "$subdir" ]; then out="$subdir/%(title)s/%(title)s.%(ext)s"; else out='%(title)s/%(title)s.%(ext)s'; fi
            set -- "$@" --write-description --write-thumbnail --convert-thumbnails jpg
        fi
        if yt-dlp -P "$VIDEOS_DIR" -o "$out" "$@" "$url"; then printf '\n%s\n' "${GREEN}DONE! SAVED TO VIDEOS FOLDER.${RESET}"
        else status=$?; printf '\n%s\n' "${RED}DOWNLOAD FAILED (YT-DLP ERROR $status). CHECK URL, NETWORK, AND DEPENDENCIES.${RESET}"; fi
        pause
    done
}

dep_check() {
    banner; missing=0
    for tool in yt-dlp ffmpeg ffprobe ffplay; do
        if command -v "$tool" >/dev/null 2>&1; then printf '%s\n' "${GREEN}[OK] $tool IS INSTALLED.${RESET}"
        elif [ "$tool" = yt-dlp ] || [ "$tool" = ffmpeg ]; then printf '%s\n' "${RED}[REQUIRED/MISSING] $tool${RESET}"; missing=1
        else printf '%s\n' "${YELLOW}[OPTIONAL/MISSING] $tool${RESET}"; fi
    done
    if [ "$missing" -eq 1 ]; then
        printf '%s\n' "${YELLOW}YT-DLP CAN BE INSTALLED HERE. FFMPEG MUST BE INSTALLED WITH YOUR PLATFORM PACKAGE MANAGER.${RESET}"
        prompt "${GREEN}INSTALL/UPDATE YT-DLP? [Y/N]: ${RESET}" || return
        case "$REPLY" in Y|y) dep_install ;; esac
    else printf '%s\n' "${GREEN}REQUIRED DEPENDENCIES ARE AVAILABLE.${RESET}"; pause; fi
}
dep_install() {
    banner; printf '%s\n' "${RED}INSTALLING/UPDATING YT-DLP...${RESET}"
    if pip_action install --upgrade yt-dlp; then printf '%s\n' "${GREEN}YT-DLP INSTALLATION COMPLETE.${RESET}"
    else printf '%s\n' "${RED}INSTALL FAILED. CHECK PYTHON/PIP AND PATH.${RESET}"; fi
    if ! command -v ffmpeg >/dev/null 2>&1; then printf '%s\n' "${YELLOW}FFMPEG MUST BE INSTALLED THROUGH YOUR PLATFORM PACKAGE MANAGER.${RESET}"; fi
    pause
}
dep_update() {
    banner; printf '%s\n' "${RED}UPDATING YT-DLP...${RESET}"
    if pip_action install --upgrade yt-dlp; then printf '%s\n' "${GREEN}YT-DLP UPDATE COMPLETE.${RESET}"; else printf '%s\n' "${RED}YT-DLP UPDATE FAILED.${RESET}"; fi
    pause
}
dep_delete() {
    banner; printf '%s\n' "${GREEN}1: REMOVE YT-DLP${RESET}" "${GREEN}2: FFMPEG (PLATFORM MANAGED)${RESET}" "${GREEN}3: REMOVE YT-DLP${RESET}" "${CYAN}ENTER: BACK${RESET}"
    prompt '> ' || return
    case "$REPLY" in
        1|3) if pip_action uninstall -y yt-dlp; then printf '%s\n' "${GREEN}YT-DLP REMOVED.${RESET}"; else printf '%s\n' "${RED}COULD NOT REMOVE YT-DLP.${RESET}"; fi; pause ;;
        2) printf '%s\n' "${YELLOW}FFMPEG IS PLATFORM-MANAGED AND IS NOT REMOVED HERE.${RESET}"; pause ;;
    esac
}
dependencies_menu() {
    while :; do
        banner; printf '%s\n' "${RED}DEPENDENCIES${RESET}" "${GREEN}1: CHECK${RESET}" "${GREEN}2: INSTALL/REPAIR YT-DLP${RESET}" "${GREEN}3: UPDATE YT-DLP${RESET}" "${GREEN}4: REMOVE${RESET}" "${CYAN}ENTER: BACK${RESET}"
        prompt '> ' || return
        case "$REPLY" in '' ) return ;; 1) dep_check ;; 2) dep_install ;; 3) dep_update ;; 4) dep_delete ;; esac
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
    case "$1:$2" in *[!0-9.:]*) return 2 ;; esac
    old=$(printf '%s' "$1" | tr . ' '); new=$(printf '%s' "$2" | tr . ' ')
    set -- $old; a1=${1:-0}; a2=${2:-0}; a3=${3:-0}; a4=${4:-0}
    set -- $new; b1=${1:-0}; b2=${2:-0}; b3=${3:-0}; b4=${4:-0}
    for n in "$a1" "$a2" "$a3" "$a4" "$b1" "$b2" "$b3" "$b4"; do case "$n" in ''|*[!0-9]*) return 2 ;; esac; done
    if [ "$a1.$a2.$a3.$a4" = "$b1.$b2.$b3.$b4" ]; then return 0; fi
    if [ "$b1" -gt "$a1" ] || { [ "$b1" -eq "$a1" ] && [ "$b2" -gt "$a2" ]; } || { [ "$b1" -eq "$a1" ] && [ "$b2" -eq "$a2" ] && [ "$b3" -gt "$a3" ]; } || { [ "$b1" -eq "$a1" ] && [ "$b2" -eq "$a2" ] && [ "$b3" -eq "$a3" ] && [ "$b4" -gt "$a4" ]; }; then return 1; fi
    return 0
}
update_program() {
    banner; printf '%s\n' "${RED}SELF-UPDATER${RESET}" "${YELLOW}No network request is made until you confirm.${RESET}"
    prompt "${GREEN}CHECK FOR AND INSTALL AN UPDATE? [Y/N]: ${RESET}" || return
    case "$REPLY" in Y|y|YES|yes) ;; *) printf '%s\n' "${YELLOW}CANCELLED; NOTHING DOWNLOADED.${RESET}"; return ;; esac
    candidate=$(mktemp "$SCRIPT_DIR/.vos-update.XXXXXX") || { printf '%s\n' "${RED}CANNOT CREATE A TEMPORARY FILE.${RESET}"; pause; return; }
    cache="$(date +%s 2>/dev/null || printf 1)-$$"; download_status=1
    if command -v curl >/dev/null 2>&1; then curl -fL --connect-timeout 10 --max-time 60 "${UPDATE_URL}?cache=$cache" -o "$candidate" && download_status=0
    elif command -v wget >/dev/null 2>&1; then wget -T 60 -O "$candidate" "${UPDATE_URL}?cache=$cache" && download_status=0; fi
    if [ "$download_status" -ne 0 ]; then rm -f "$candidate"; printf '%s\n' "${RED}UPDATE DOWNLOAD FAILED. CURL/WGET AND NETWORK ACCESS ARE REQUIRED.${RESET}"; pause; return; fi
    remote_version=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$candidate" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE="\([^"]*\)".*/\1/p' "$candidate" | head -n 1); [ -n "$remote_type" ] || remote_type=UNKNOWN
    if [ -z "$remote_version" ] || ! grep -q '^#!/bin/sh' "$candidate" || ! sh -n "$candidate"; then rm -f "$candidate"; printf '%s\n' "${RED}INVALID UPDATE; CURRENT FILE LEFT UNCHANGED.${RESET}"; pause; return; fi
    version_compare "$VERSION" "$remote_version"; cmp=$?
    case "$cmp" in 0) rm -f "$candidate"; printf '%s\n' "${GREEN}ALREADY UP TO DATE ($VERSION).${RESET}"; pause; return ;; 2) rm -f "$candidate"; printf '%s\n' "${RED}INVALID REMOTE VERSION.${RESET}"; pause; return ;; esac
    printf '%s\n' "${CYAN}VALID UPDATE FOUND: $VERSION -> $remote_version${RESET}"
    update_animation
    backup="$SCRIPT_PATH.update-backup.$$"
    if ! cp -p "$SCRIPT_PATH" "$backup"; then rm -f "$candidate"; printf '%s\n' "${RED}CANNOT BACK UP SCRIPT; ABORTING.${RESET}"; pause; return; fi
    chmod +x "$candidate" || { rm -f "$candidate" "$backup"; printf '%s\n' "${RED}CANNOT SET UPDATE PERMISSIONS.${RESET}"; pause; return; }
    if ! mv -f "$candidate" "$SCRIPT_PATH"; then mv -f "$backup" "$SCRIPT_PATH" 2>/dev/null || :; rm -f "$candidate"; printf '%s\n' "${RED}UPDATE INSTALL FAILED.${RESET}"; pause; return; fi
    if [ -f "$HISTORY_FILE" ] || : > "$HISTORY_FILE" 2>/dev/null; then
        printf 'UPDATE: %s (%s) -> %s (%s) | %s\n' "$VERSION" "$VERSION_TYPE" "$remote_version" "$remote_type" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$HISTORY_FILE" 2>/dev/null || printf '%s\n' "${YELLOW}HISTORY WRITE FAILED.${RESET}"
    fi
    rm -f "$backup"; printf '%s\n' "${GREEN}UPDATE INSTALLED. RESTARTING...${RESET}"
    exec /bin/sh "$SCRIPT_PATH"
}

flame_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}ASCII FLAME SETTINGS${RESET}" "${GREEN}1: ${FLAME_STANDARD_LABEL:-RED-YELLOW}FLAME${RESET}" "${GREEN}2: PURPLE-PINK FLAME${RESET}" "${GREEN}3: GREEN-WHITE FLAME${RESET}" "${GREEN}4: ICE-BLUE FLAME${RESET}" "${GREEN}5: OCEAN-TEAL FLAME${RESET}" "${GREEN}6: SUNSET FLAME${RESET}" "${GREEN}7: CYBERPUNK FLAME${RESET}" "${GREEN}8: RAINBOW FLAME${RESET}" "${CYAN}ENTER: BACK TO SETTINGS${RESET}"
        prompt '> ' || return
        case "$REPLY" in
            '') return ;;
            1) FLAME=STANDARD ;; 2) FLAME=PURPLE-PINK ;; 3) FLAME=GREEN-WHITE ;; 4) FLAME=ICE-BLUE ;;
            5) FLAME=OCEAN-TEAL ;; 6) FLAME=SUNSET ;; 7) FLAME=CYBERPUNK ;; 8) FLAME=RAINBOW ;;
            *) continue ;;
        esac
        set_flame; save_settings
    done
}
settings_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}SETTINGS${RESET}" "${GREEN}VERSION: $VERSION | $VERSION_TYPE${RESET}" "${GREEN}METADATA/THUMBNAIL: $METADATA${RESET}" "${GREEN}ASCII FLAME: $FLAME_DISPLAY${RESET}" "${GREEN}1: TOGGLE METADATA/THUMBNAIL${RESET}" "${GREEN}2: CHANGE ASCII FLAME${RESET}" "${CYAN}ENTER: BACK${RESET}"
        prompt '> ' || return
        case "$REPLY" in
            '') return ;;
            1) if [ "$METADATA" = ENABLED ]; then METADATA=DISABLED; else METADATA=ENABLED; fi; save_settings ;;
            2) flame_menu ;;
        esac
    done
}
version_info() {
    banner; if check_required; then dep=INSTALLED; else dep='NOT INSTALLED'; fi
    count=0; [ ! -d "$VIDEOS_DIR" ] || count=$(find "$VIDEOS_DIR" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
    printf '%s\n' "${RED}VOSVIDEODOWNLOAD${RESET}" "${GREEN}VERSION: $VERSION | $VERSION_TYPE${RESET}" "${GREEN}DEPENDENCIES: $dep${RESET}" "${GREEN}METADATA: $METADATA${RESET}" "${GREEN}ASCII FLAME: $FLAME_DISPLAY${RESET}" "${GREEN}VIDEOS DOWNLOADED: $count${RESET}"
    pause
}

load_settings
set_flame
while :; do
    banner; printf '%s\n' "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER${RESET}" "${GREEN}1: DOWNLOAD VIDEO${RESET}" "${GREEN}2: DEPENDENCIES${RESET}" "${GREEN}3: UPDATE VOSVIDEODOWNLOAD${RESET}" "${GREEN}4: VOSVIDEODOWNLOAD SETTINGS${RESET}" "${GREEN}5: QUIT${RESET}" "${GREEN}6: RESTART${RESET}"
    prompt '> ' || exit 0
    case "$REPLY" in
        1) download_menu ;; 2) dependencies_menu ;; 3) update_program ;; 4) settings_menu ;; 5) exit 0 ;; 6) exec /bin/sh "$SCRIPT_PATH" ;;
    esac
done
