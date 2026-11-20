#!/bin/sh
# VOSVideoDownload shell edition. Only download videos you are authorized to save.
VERSION="1.00.23"
VERSION_TYPE="RELEASE"
OPERATING_SYSTEM="iOS / A-Shell"
UPDATE_URL="https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || exit 1
SCRIPT_PATH="$SCRIPT_DIR/$(basename -- "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
HISTORY_FILE="$SCRIPT_DIR/history.txt"
SETTINGS_FILE="$SCRIPT_DIR/settings.txt"
if [ -r /dev/tty ] && [ -w /dev/tty ]; then exec </dev/tty >/dev/tty 2>&1; fi
ESC=$(printf '\033')
RED="${ESC}[91m"; DARKRED="${ESC}[31m"; ORANGE="${ESC}[38;5;208m"
YELLOW="${ESC}[93m"; GREEN="${ESC}[92m"; CYAN="${ESC}[96m"; RESET="${ESC}[0m"
METADATA=DISABLED; FLAME=STANDARD

prompt() { printf '%s' "$1"; IFS= read -r REPLY || return 1; }
pause() { prompt "${CYAN}PRESS ENTER TO CONTINUE: ${RESET}" || :; }
load_settings() {
    METADATA=DISABLED; FLAME=STANDARD
    [ -f "$SETTINGS_FILE" ] || return
    while IFS='=' read -r key value; do
        case "$key:$value" in
            METADATA:ENABLED) METADATA=ENABLED ;;
            FLAME:STANDARD|FLAME:PURPLE-PINK|FLAME:GREEN-WHITE|FLAME:ICE-BLUE|FLAME:OCEAN-TEAL|FLAME:SUNSET|FLAME:CYBERPUNK|FLAME:RAINBOW) FLAME=$value ;;
        esac
    done < "$SETTINGS_FILE"
}
save_settings() { printf 'METADATA=%s\nFLAME=%s\n' "$METADATA" "$FLAME" > "$SETTINGS_FILE"; }
set_flame() {
    case "$FLAME" in
        PURPLE-PINK) FLAME_DISPLAY='PURPLE-PINK FLAME'; colors='80;0;150|105;0;185|130;0;215|155;0;235|180;0;245|205;10;240|225;30;230|240;65;225|250;115;232|255;185;245' ;;
        GREEN-WHITE) FLAME_DISPLAY='GREEN-WHITE FLAME'; colors='0;65;20|0;95;30|0;125;40|0;155;50|0;180;65|25;205;90|65;225;125|110;240;165|175;250;210|245;255;250' ;;
        ICE-BLUE) FLAME_DISPLAY='ICE-BLUE FLAME'; colors='18;18;95|25;35;135|25;55;175|30;80;215|35;110;245|40;145;255|65;175;255|105;205;255|155;230;255|220;250;255' ;;
        OCEAN-TEAL) FLAME_DISPLAY='OCEAN-TEAL FLAME'; colors='0;25;55|0;45;90|0;70;120|0;100;145|0;130;155|0;160;155|25;190;155|80;215;175|145;235;205|210;255;235' ;;
        SUNSET) FLAME_DISPLAY='SUNSET FLAME'; colors='38;0;85|70;0;130|105;0;160|145;10;175|185;20;160|220;35;130|245;65;95|255;100;65|255;150;55|255;210;100' ;;
        CYBERPUNK) FLAME_DISPLAY='CYBERPUNK FLAME'; colors='20;10;75|45;20;150|80;25;220|130;35;255|190;40;255|245;35;220|255;35;160|255;65;125|170;130;255|85;235;255' ;;
        RAINBOW) FLAME_DISPLAY='RAINBOW FLAME'; colors='255;25;45|255;75;0|255;155;0|255;225;0|135;255;0|0;235;100|0;220;220|0;125;255|100;45;255|255;60;200' ;;
        *) FLAME=STANDARD; FLAME_DISPLAY='RED-YELLOW FLAME'; colors='120;0;0|155;0;0|190;5;0|225;20;0|250;45;0|255;80;0|255;120;0|255;165;0|255;205;0|255;240;75' ;;
    esac
    old_ifs=$IFS; IFS='|'; set -- $colors; IFS=$old_ifs
    FLAME1="${ESC}[38;2;$1m"; FLAME2="${ESC}[38;2;$2m"; FLAME3="${ESC}[38;2;$3m"; FLAME4="${ESC}[38;2;$4m"; FLAME5="${ESC}[38;2;$5m"
    FLAME6="${ESC}[38;2;$6m"; FLAME7="${ESC}[38;2;$7m"; FLAME8="${ESC}[38;2;$8m"; FLAME9="${ESC}[38;2;$9m"; FLAME10="${ESC}[38;2;${10}m"
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
    printf '%s\n' " ${FLAME10}|____/   \___/     \_/\_/    |_| \_| |_____|  \___/ /_/   \_\|____/ ${RESET}"
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
        prompt "${CYAN}> ${RESET}" || return
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
        url=$REPLY
        [ -z "$url" ] && continue
        mkdir -p "$VIDEOS_DIR" || { printf '%s\n' "${RED}COULD NOT CREATE VIDEOS DIRECTORY.${RESET}"; pause; continue; }
        if [ -n "$subdir" ]; then out="$subdir/%(title)s.%(ext)s"; else out='%(title)s.%(ext)s'; fi
        if [ "$METADATA" = ENABLED ]; then
            if [ -n "$subdir" ]; then out="$subdir/%(title)s/%(title)s.%(ext)s"; else out='%(title)s/%(title)s.%(ext)s'; fi
            set -- "$@" --write-description --write-thumbnail --convert-thumbnails jpg
        fi
        if yt-dlp -P "$VIDEOS_DIR" -o "$out" "$@" "$url"; then
            printf '\n%s\n' "${GREEN}DONE! SAVED TO VIDEOS FOLDER.${RESET}"
        else
            status=$?
            printf '\n%s\n' "${RED}DOWNLOAD FAILED (YT-DLP ERROR $status). CHECK URL, NETWORK, AND DEPENDENCIES.${RESET}"
        fi
        pause
    done
}
dep_check() {
    banner
    missing=0
    for tool in yt-dlp ffmpeg ffprobe ffplay; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf '%s\n' "${GREEN}[OK] $tool IS INSTALLED.${RESET}"
        elif [ "$tool" = yt-dlp ] || [ "$tool" = ffmpeg ]; then
            printf '%s\n' "${RED}[REQUIRED/MISSING] $tool IS NOT INSTALLED.${RESET}"
            missing=1
        else
            printf '%s\n' "${YELLOW}[OPTIONAL/MISSING] $tool IS NOT INSTALLED.${RESET}"
        fi
    done
    if [ "$missing" -eq 1 ]; then
        printf '%s\n' "${RED}ONE OR MORE REQUIRED DEPENDENCIES ARE MISSING.${RESET}" "${YELLOW}YT-DLP CAN BE INSTALLED HERE; FFMPEG IS PLATFORM-MANAGED.${RESET}"
        prompt "${GREEN}[Y] INSTALL/REPAIR YT-DLP | [N] NO: ${RESET}" || return
        case "$REPLY" in Y|y) dep_download ;; esac
    else
        printf '%s\n' "${GREEN}ALL REQUIRED DEPENDENCIES ARE PRESENT.${RESET}"
        pause
    fi
}
dep_download() {
    banner
    printf '%s\n' "${RED}INSTALLING YT-DLP...${RESET}"
    if pip_action install --upgrade yt-dlp; then
        printf '%s\n' "${GREEN}YT-DLP INSTALLED/UPDATED.${RESET}"
    else
        printf '%s\n' "${RED}YT-DLP INSTALL FAILED. CHECK PYTHON/PIP AND PATH.${RESET}"
    fi
    if ! command -v ffmpeg >/dev/null 2>&1; then
        printf '%s\n' "${YELLOW}FFMPEG MUST BE INSTALLED THROUGH YOUR PLATFORM PACKAGE MANAGER.${RESET}"
    fi
    pause
}
dep_update() {
    banner
    printf '%s\n' "${RED}UPDATING YT-DLP...${RESET}"
    if pip_action install --upgrade yt-dlp; then
        printf '%s\n' "${GREEN}YT-DLP UPDATE COMPLETE.${RESET}"
    else
        printf '%s\n' "${RED}YT-DLP UPDATE FAILED.${RESET}"
    fi
    pause
}
dep_delete() {
    banner
    printf '%s\n' "${RED}WHICH DEPENDENCIES WOULD YOU LIKE TO DELETE?${RESET}" "${GREEN}1: YT-DLP${RESET}" "${GREEN}2: FFMPEG (PLATFORM MANAGED)${RESET}" "${GREEN}3: ALL REMOVABLE DEPENDENCIES${RESET}" "${CYAN}ENTER: GO BACK${RESET}"
    prompt "${CYAN}> ${RESET}" || return
    case "$REPLY" in
        1|3)
            if pip_action uninstall -y yt-dlp; then
                printf '%s\n' "${GREEN}YT-DLP REMOVED.${RESET}"
            else
                printf '%s\n' "${RED}COULD NOT REMOVE YT-DLP.${RESET}"
            fi
            if [ "$REPLY" = 3 ]; then
                printf '%s\n' "${YELLOW}FFMPEG IS PLATFORM-MANAGED AND WAS NOT REMOVED.${RESET}"
            fi
            pause
            ;;
        2)
            printf '%s\n' "${YELLOW}FFMPEG IS PLATFORM-MANAGED AND IS NOT REMOVED BY THIS SCRIPT.${RESET}"
            pause
            ;;
    esac
}
dependencies_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}DEPENDENCIES${RESET}" "${GREEN}1: CHECK IF DEPENDENCIES ARE DOWNLOADED${RESET}" "${GREEN}2: DOWNLOAD DEPENDENCIES${RESET}" "${GREEN}3: UPDATE DEPENDENCIES${RESET}" "${GREEN}4: DELETE DEPENDENCIES${RESET}" "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        prompt "${CYAN}> ${RESET}" || return
        case "$REPLY" in
            '') return ;;
            1) dep_check ;;
            2) dep_download ;;
            3) dep_update ;;
            4) dep_delete ;;
        esac
    done
}
update_animation() {
    width=20
    i=0
    while [ "$i" -le "$width" ]; do
        bar=''
        spaces=''
        j=0
        while [ "$j" -lt "$i" ]; do
            bar="${bar}█"
            j=$((j + 1))
        done
        while [ "$j" -lt "$width" ]; do
            spaces="${spaces} "
            j=$((j + 1))
        done
        printf '\r%s[%s%s] %3d%%' "$CYAN" "$bar" "$spaces" "$((i * 100 / width))"
        sleep 0.04
        i=$((i + 1))
    done
    printf '\n%s' "$RESET"
}
version_compare() {
    case "$1:$2" in *[!0-9.:]*) return 2 ;; esac
    old=$(printf '%s' "$1" | tr . ' ')
    new=$(printf '%s' "$2" | tr . ' ')
    set -- $old
    a1=${1:-0}; a2=${2:-0}; a3=${3:-0}; a4=${4:-0}
    set -- $new
    b1=${1:-0}; b2=${2:-0}; b3=${3:-0}; b4=${4:-0}
    for n in "$a1" "$a2" "$a3" "$a4" "$b1" "$b2" "$b3" "$b4"; do
        case "$n" in ''|*[!0-9]*) return 2 ;; esac
    done
    if [ "$a1.$a2.$a3.$a4" = "$b1.$b2.$b3.$b4" ]; then return 0; fi
    if [ "$b1" -gt "$a1" ] ||
       { [ "$b1" -eq "$a1" ] && [ "$b2" -gt "$a2" ]; } ||
       { [ "$b1" -eq "$a1" ] && [ "$b2" -eq "$a2" ] && [ "$b3" -gt "$a3" ]; } ||
       { [ "$b1" -eq "$a1" ] && [ "$b2" -eq "$a2" ] && [ "$b3" -eq "$a3" ] && [ "$b4" -gt "$a4" ]; }; then
        return 1
    fi
    return 0
}
update_program() {
    banner
    printf '%s\n' "${RED}SELF-UPDATER${RESET}"
    prompt "${YELLOW}CHECK FOR AND INSTALL UPDATE? [Y/N]: ${RESET}" || return
    case "$REPLY" in Y|y|YES|yes) ;; *) printf '%s\n' "${YELLOW}CANCELLED; NOTHING DOWNLOADED.${RESET}"; return ;; esac
    candidate=$(mktemp "$SCRIPT_DIR/.vos-update.XXXXXX") || { printf '%s\n' "${RED}CANNOT CREATE TEMP FILE.${RESET}"; pause; return; }
    download_status=1
    cache="$(date +%s 2>/dev/null || printf 1)-$$"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --connect-timeout 10 --max-time 60 "${UPDATE_URL}?cache=$cache" -o "$candidate" && download_status=0
    elif command -v wget >/dev/null 2>&1; then
        wget -T 60 -O "$candidate" "${UPDATE_URL}?cache=$cache" && download_status=0
    fi
    if [ "$download_status" -ne 0 ]; then
        rm -f "$candidate"
        printf '%s\n' "${RED}UPDATE DOWNLOAD FAILED.${RESET}"
        pause
        return
    fi
    remote_version=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$candidate" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE="\([^"]*\)".*/\1/p' "$candidate" | head -n 1)
    [ -n "$remote_type" ] || remote_type=UNKNOWN
    if [ -z "$remote_version" ] || ! grep -q '^#!/bin/sh' "$candidate" || ! sh -n "$candidate"; then
        rm -f "$candidate"
        printf '%s\n' "${RED}INVALID UPDATE; CURRENT FILE UNCHANGED.${RESET}"
        pause
        return
    fi
    version_compare "$VERSION" "$remote_version"
    cmp=$?
    case "$cmp" in
        0)
            rm -f "$candidate"
            printf '%s\n' "${GREEN}ALREADY UP TO DATE.${RESET}"
            pause
            return
            ;;
        2)
            rm -f "$candidate"
            printf '%s\n' "${RED}INVALID REMOTE VERSION.${RESET}"
            pause
            return
            ;;
    esac
    printf '%s\n' "${CYAN}UPDATE FOUND: $VERSION -> $remote_version${RESET}"
    update_animation
    backup="$SCRIPT_PATH.backup.$$"
    if ! cp -p "$SCRIPT_PATH" "$backup"; then
        rm -f "$candidate"
        printf '%s\n' "${RED}CANNOT BACK UP SCRIPT.${RESET}"
        pause
        return
    fi
    chmod +x "$candidate" || { rm -f "$candidate" "$backup"; return; }
    if ! mv -f "$candidate" "$SCRIPT_PATH"; then
        mv -f "$backup" "$SCRIPT_PATH" 2>/dev/null || :
        rm -f "$candidate"
        printf '%s\n' "${RED}UPDATE INSTALL FAILED.${RESET}"
        pause
        return
    fi
    if [ -f "$HISTORY_FILE" ] || : > "$HISTORY_FILE" 2>/dev/null; then
        printf 'UPDATE: %s (%s) -> %s (%s) | %s\n' "$VERSION" "$VERSION_TYPE" "$remote_version" "$remote_type" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$HISTORY_FILE" 2>/dev/null
    fi
    rm -f "$backup"
    exec /bin/sh "$SCRIPT_PATH"
}
flame_menu() {
    while :; do
        banner
        [ "$FLAME" = STANDARD ] && standard_label='(ENABLED) RED-YELLOW FLAME' || standard_label='RED-YELLOW FLAME'
        [ "$FLAME" = PURPLE-PINK ] && purple_label='(ENABLED) PURPLE-PINK FLAME' || purple_label='PURPLE-PINK FLAME'
        [ "$FLAME" = GREEN-WHITE ] && green_label='(ENABLED) GREEN-WHITE FLAME' || green_label='GREEN-WHITE FLAME'
        [ "$FLAME" = ICE-BLUE ] && ice_label='(ENABLED) ICE-BLUE FLAME' || ice_label='ICE-BLUE FLAME'
        [ "$FLAME" = OCEAN-TEAL ] && ocean_label='(ENABLED) OCEAN-TEAL FLAME' || ocean_label='OCEAN-TEAL FLAME'
        [ "$FLAME" = SUNSET ] && sunset_label='(ENABLED) SUNSET FLAME' || sunset_label='SUNSET FLAME'
        [ "$FLAME" = CYBERPUNK ] && cyber_label='(ENABLED) CYBERPUNK FLAME' || cyber_label='CYBERPUNK FLAME'
        [ "$FLAME" = RAINBOW ] && rainbow_label='(ENABLED) RAINBOW FLAME' || rainbow_label='RAINBOW FLAME'
        printf '%s\n' "${RED}ASCII FLAME SETTINGS${RESET}" "${GREEN}1: $standard_label${RESET}" "${GREEN}2: $purple_label${RESET}" "${GREEN}3: $green_label${RESET}" "${GREEN}4: $ice_label${RESET}" "${GREEN}5: $ocean_label${RESET}" "${GREEN}6: $sunset_label${RESET}" "${GREEN}7: $cyber_label${RESET}" "${GREEN}8: $rainbow_label${RESET}" "${CYAN}ENTER: BACK TO SETTINGS${RESET}"
        prompt "${CYAN}> ${RESET}" || return
        case "$REPLY" in
            '') return ;;
            1) FLAME=STANDARD ;;
            2) FLAME=PURPLE-PINK ;;
            3) FLAME=GREEN-WHITE ;;
            4) FLAME=ICE-BLUE ;;
            5) FLAME=OCEAN-TEAL ;;
            6) FLAME=SUNSET ;;
            7) FLAME=CYBERPUNK ;;
            8) FLAME=RAINBOW ;;
            *) continue ;;
        esac
        set_flame
        save_settings
    done
}
settings_menu() {
    while :; do
        banner
        update_count=0
        [ ! -f "$HISTORY_FILE" ] || update_count=$(grep -c '^UPDATE:' "$HISTORY_FILE" 2>/dev/null || printf 0)

        if command -v yt-dlp >/dev/null 2>&1; then
            dep_ytdlp=INSTALLED
        else
            dep_ytdlp='NOT INSTALLED'
        fi
        if command -v ffmpeg >/dev/null 2>&1; then
            dep_ffmpeg=INSTALLED
        else
            dep_ffmpeg='NOT INSTALLED'
        fi
        if command -v ffprobe >/dev/null 2>&1; then
            dep_ffprobe=INSTALLED
        else
            dep_ffprobe='NOT INSTALLED'
        fi
        if command -v ffplay >/dev/null 2>&1; then
            dep_ffplay=INSTALLED
        else
            dep_ffplay='NOT INSTALLED'
        fi

        video_count=0
        [ ! -d "$VIDEOS_DIR" ] || video_count=$(find "$VIDEOS_DIR" -type f ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
        printf '%s\n' "${RED}VOSVIDEODOWNLOAD SETTINGS${RESET}" \
            "${GREEN}VERSION: ${YELLOW}$VERSION${RESET}" \
            "${GREEN}VERSION TYPE: ${YELLOW}$VERSION_TYPE${RESET}" \
            "${GREEN}UPDATES INSTALLED: ${YELLOW}$update_count${RESET}" \
            "${GREEN}INTENDED OPERATING SYSTEM: ${YELLOW}$OPERATING_SYSTEM${RESET}" \
            "${GREEN}DEPENDENCIES:${RESET}" \
            "${GREEN} - YT-DLP: ${YELLOW}$dep_ytdlp${RESET}" \
            "${GREEN} - FFMPEG: ${YELLOW}$dep_ffmpeg${RESET}" \
            "${GREEN} - FFPROBE: ${YELLOW}$dep_ffprobe${RESET}" \
            "${GREEN} - FFPLAY: ${YELLOW}$dep_ffplay${RESET}" \
            "${GREEN}VIDEOS DOWNLOADED: ${YELLOW}$video_count${RESET}" \
            '' \
            "${GREEN}SETTINGS${RESET}" \
            "${GREEN}1: TOGGLE METADATA/THUMBNAIL: ${YELLOW}$METADATA${RESET}" \
            "${GREEN}2: ASCII FLAME: ${YELLOW}$FLAME_DISPLAY${RESET}" \
            "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        prompt "${CYAN}> ${RESET}" || return
        case "$REPLY" in
            '')
                return
                ;;
            1)
                if [ "$METADATA" = ENABLED ]; then
                    METADATA=DISABLED
                else
                    METADATA=ENABLED
                fi
                save_settings
                ;;
            2)
                flame_menu
                ;;
        esac
    done
}
version_info() {
    banner
    if check_required; then
        dep=INSTALLED
    else
        dep='NOT INSTALLED'
    fi
    count=0
    [ ! -d "$VIDEOS_DIR" ] || count=$(find "$VIDEOS_DIR" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
    printf '%s\n' "${RED}VOSVIDEODOWNLOAD${RESET}" "${GREEN}VERSION: ${YELLOW}$VERSION | $VERSION_TYPE${RESET}" "${GREEN}DEPENDENCIES: $dep${RESET}" "${GREEN}VIDEOS DOWNLOADED: $count${RESET}"
    pause
}
load_settings
set_flame
while :; do
    banner
    printf '%s\n' "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER${RESET}" "${GREEN}1: DOWNLOAD VIDEO${RESET}" "${GREEN}2: DEPENDENCIES${RESET}" "${GREEN}3: UPDATE VOSVIDEODOWNLOAD${RESET}" "${GREEN}4: VOSVIDEODOWNLOAD SETTINGS${RESET}" "${GREEN}5: QUIT${RESET}" "${GREEN}6: RESTART${RESET}"
    prompt "${CYAN}> ${RESET}" || exit 0
    case "$REPLY" in
        1) download_menu ;;
        2) dependencies_menu ;;
        3) update_program ;;
        4) settings_menu ;;
        5) exit 0 ;;
        6) exec /bin/sh "$SCRIPT_PATH" ;;
    esac
done