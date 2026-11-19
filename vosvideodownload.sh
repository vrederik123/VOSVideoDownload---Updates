#!/bin/sh
# TURN INTO ".SH" TO USE.
# ANY FALSE USE OF THIS PROGRAM CAN RESULT IN COPYRIGHT INFRINGEMENT TO THE RESPECTIVE AUTHORS.

VOS_IOS_SCRIPT=1
VERSION=1.03.30
VERSION_TYPE=APPLE
UPDATE_URL_BASE=https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh
UPDATE_URL=$UPDATE_URL_BASE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
VIDEOS_DIR="$SCRIPT_DIR/VIDEOS"
SETTINGS_FILE="$SCRIPT_DIR/settings.txt"
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
PURPLE="${ESC}[35m"
PINK="${ESC}[95m"
WHITE="${ESC}[97m"
RESET="${ESC}[0m"

METADATA=DISABLED
FLAME=STANDARD

rgb_color() {
    printf '%s[38;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"
}

set_flame_palette() {
    FLAME1=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME2=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME3=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME4=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME5=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME6=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME7=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME8=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME9=$(rgb_color "$1" "$2" "$3"); shift 3
    FLAME10=$(rgb_color "$1" "$2" "$3")
}

set_theme_color() {
    case "$FLAME" in
        PURPLE-PINK)
            FLAME_DISPLAY='PURPLE-PINK FLAME'
            set_flame_palette 80 0 150 105 0 185 130 0 215 155 0 235 180 0 245 \
                205 10 240 225 30 230 240 65 225 250 115 232 255 185 245
            ;;
        GREEN-WHITE)
            FLAME_DISPLAY='GREEN-WHITE FLAME'
            set_flame_palette 0 65 20 0 95 30 0 125 40 0 155 50 0 180 65 \
                25 205 90 65 225 125 110 240 165 175 250 210 245 255 250
            ;;
        ICE-BLUE)
            FLAME_DISPLAY='ICE-BLUE FLAME'
            set_flame_palette 18 18 95 25 35 135 25 55 175 30 80 215 35 110 245 \
                40 145 255 65 175 255 105 205 255 155 230 255 220 250 255
            ;;
        OCEAN-TEAL)
            FLAME_DISPLAY='OCEAN-TEAL FLAME'
            set_flame_palette 0 25 55 0 45 90 0 70 120 0 100 145 0 130 155 \
                0 160 155 25 190 155 80 215 175 145 235 205 210 255 235
            ;;
        SUNSET)
            FLAME_DISPLAY='SUNSET FLAME'
            set_flame_palette 38 0 85 70 0 130 105 0 160 145 10 175 185 20 160 \
                220 35 130 245 65 95 255 100 65 255 150 55 255 210 100
            ;;
        CYBERPUNK)
            FLAME_DISPLAY='CYBERPUNK FLAME'
            set_flame_palette 20 10 75 45 20 150 80 25 220 130 35 255 190 40 255 \
                245 35 220 255 35 160 255 65 125 170 130 255 85 235 255
            ;;
        RAINBOW)
            FLAME_DISPLAY='RAINBOW FLAME'
            set_flame_palette 255 25 45 255 75 0 255 155 0 255 225 0 135 255 0 \
                0 235 100 0 220 220 0 125 255 100 45 255 255 60 200
            ;;
        *)
            FLAME=STANDARD
            FLAME_DISPLAY='RED-YELLOW FLAME'
            set_flame_palette 120 0 0 155 0 0 190 5 0 225 20 0 250 45 0 \
                255 80 0 255 120 0 255 165 0 255 205 0 255 240 75
            ;;
    esac
}

color_line() {
    printf '%s%s%s\n' "$1" "$2" "$RESET"
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
    printf '%s\n' "${FLAME10} |____/   \___/     \_/\_/    |_| \_| |_____|  \___/ /_/   \_\|____/ ${RESET}"
    printf '\n'
}

pause() {
    printf '%s' "${CYAN}PRESS ENTER TO CONTINUE${RESET}"
    read -r enter
}

load_settings() {
    if [ -f "$SETTINGS_FILE" ]; then
        while IFS='=' read -r key value; do
            case "$key" in
                METADATA)
                    case "$value" in ENABLED|DISABLED) METADATA=$value ;; esac
                    ;;
                FLAME)
                    case "$value" in
                        STANDARD|PURPLE-PINK|GREEN-WHITE|ICE-BLUE|OCEAN-TEAL|SUNSET|CYBERPUNK|RAINBOW)
                            FLAME=$value
                            ;;
                    esac
                    ;;
            esac
        done < "$SETTINGS_FILE"
    fi
    set_theme_color
}

save_settings() {
    settings_tmp="$SETTINGS_FILE.tmp.$$"
    if ! printf 'METADATA=%s\nFLAME=%s\n' "$METADATA" "$FLAME" > "$settings_tmp"; then
        color_line "$RED" "Could not write settings."
        return 1
    fi
    if ! mv "$settings_tmp" "$SETTINGS_FILE"; then
        rm -f "$settings_tmp"
        color_line "$RED" "Could not save settings."
        return 1
    fi
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
        color_line "$RED" "yt-dlp is not installed."
        return 127
    fi
}

ffmpeg_available() {
    [ "$IOS_MODE" -eq 0 ] && command -v ffmpeg >/dev/null 2>&1
}

download_video() {
    download_kind=$1
    download_url=$2
    output_template='%(title)s.%(ext)s'

    case "$download_kind" in
        video|channel-videos|channel-shorts)
            if [ "$download_kind" = channel-videos ]; then
                output_template='%(channel)s - VIDEOS/%(title)s.%(ext)s'
            elif [ "$download_kind" = channel-shorts ]; then
                output_template='%(channel)s - SHORTS/%(title)s.%(ext)s'
            fi
            if ffmpeg_available; then
                set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4
            else
                set -- -f 'b[vcodec^=avc1][ext=mp4]/b[ext=mp4]/b'
                color_line "$YELLOW" "Using a single-file video format; FFmpeg merging is unavailable here."
            fi
            ;;
        audio)
            if ffmpeg_available; then
                set -- -x --audio-format mp3 --audio-quality 0
            else
                set -- -f 'ba[ext=m4a]/ba'
                color_line "$YELLOW" "Saving source audio (usually M4A); MP3 conversion needs FFmpeg."
            fi
            ;;
        video-only)
            set -- -f 'bv*[vcodec^=avc1][ext=mp4]/bv*[ext=mp4]/bv*'
            ;;
    esac

    if [ "$METADATA" = ENABLED ]; then
        set -- "$@" --write-description --write-thumbnail
        if ffmpeg_available; then
            set -- "$@" --convert-thumbnails jpg
        fi
    fi

    color_line "$CYAN" "DOWNLOADING..."
    if run_ytdlp -P "$VIDEOS_DIR" -o "$output_template" "$@" -- "$download_url"; then
        color_line "$GREEN" "DONE! SAVED UNDER: $VIDEOS_DIR"
    else
        download_status=$?
        color_line "$RED" "DOWNLOAD FAILED (EXIT CODE $download_status). CHECK URL, NETWORK, AND DEPENDENCIES."
    fi
}

download_menu() {
    while true; do
        banner
        printf '%s\n' "${RED}DOWNLOAD OPTIONS${RESET}"
        printf '%s\n' "${GREEN}1: DOWNLOAD VIDEO${RESET}"
        printf '%s\n' "${GREEN}2: DOWNLOAD AUDIO${RESET}"
        printf '%s\n' "${GREEN}3: DOWNLOAD VIDEO ONLY${RESET}"
        printf '%s\n' "${GREEN}4: DOWNLOAD ALL VIDEOS ON CHANNEL${RESET}"
        printf '%s\n' "${GREEN}5: DOWNLOAD ALL SHORTS ON CHANNEL${RESET}"
        printf '%s\n' "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        read -r choice

        case "$choice" in
            '') return ;;
            1) download_kind=video; prompt="PASTE YOUTUBE VIDEO URL" ;;
            2) download_kind=audio; prompt="PASTE YOUTUBE URL FOR AUDIO" ;;
            3) download_kind=video-only; prompt="PASTE YOUTUBE VIDEO URL" ;;
            4) download_kind=channel-videos; prompt="PASTE YOUTUBE CHANNEL /VIDEOS URL" ;;
            5) download_kind=channel-shorts; prompt="PASTE YOUTUBE CHANNEL /SHORTS URL" ;;
            *) continue ;;
        esac

        if ! ytdlp_available; then
            color_line "$RED" "YT-DLP IS MISSING. INSTALL IT FROM DEPENDENCIES FIRST."
            pause
            continue
        fi
        printf '%s' "${CYAN}${prompt} (OR PRESS ENTER TO GO BACK): ${RESET}"
        read -r download_url
        if [ -n "$download_url" ]; then
            mkdir -p "$VIDEOS_DIR"
            download_video "$download_kind" "$download_url"
            pause
        fi
    done
}

dep_check() {
    banner
    missing=0

    if ytdlp_available; then
        color_line "$GREEN" "[OK] YT-DLP IS INSTALLED."
    else
        color_line "$RED" "[MISSING] YT-DLP IS NOT INSTALLED."
        missing=1
    fi

    if [ "$IOS_MODE" -eq 1 ]; then
        color_line "$YELLOW" "[INFO] A-SHELL PROVIDES ITS OWN FFMPEG SUPPORT."
    elif command -v ffmpeg >/dev/null 2>&1; then
        color_line "$GREEN" "[OK] FFMPEG IS INSTALLED."
    else
        color_line "$YELLOW" "[OPTIONAL] FFMPEG IS NOT INSTALLED."
        missing=1
    fi

    printf '\n'
    if [ "$missing" -eq 1 ]; then
        printf '%s\n' "${RED}WOULD YOU LIKE TO INSTALL OR REPAIR DEPENDENCIES?${RESET}"
        printf '%s\n' "${GREEN}[Y] YES | [N] NO${RESET}"
        read -r depchoice
        case "$depchoice" in
            Y|y) dep_download ;;
        esac
    else
        color_line "$GREEN" "ALL REQUIRED DEPENDENCIES ARE WORKING."
        pause
    fi
}

pip_install_ytdlp() {
    if command -v pip >/dev/null 2>&1; then
        pip "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m pip "$@"
    else
        color_line "$RED" "PYTHON/PIP IS NOT AVAILABLE IN THIS SHELL."
        return 127
    fi
}

dep_download() {
    banner
    color_line "$RED" "INSTALLING DEPENDENCIES..."
    if [ "$IOS_MODE" -eq 1 ]; then
        pip_install_ytdlp install yt-dlp
    elif command -v brew >/dev/null 2>&1; then
        brew install yt-dlp ffmpeg
    else
        pip_install_ytdlp install yt-dlp
    fi
    install_status=$?
    printf '\n'
    if [ "$install_status" -eq 0 ]; then
        color_line "$GREEN" "INSTALLATION COMPLETE!"
    else
        color_line "$RED" "INSTALLATION FAILED (EXIT CODE $install_status)."
    fi
    pause
}

dep_update() {
    banner
    color_line "$RED" "UPDATING DEPENDENCIES..."
    if [ "$IOS_MODE" -eq 1 ]; then
        pip_install_ytdlp install --upgrade yt-dlp
    elif command -v brew >/dev/null 2>&1; then
        brew upgrade yt-dlp ffmpeg
    else
        pip_install_ytdlp install --upgrade yt-dlp
    fi
    update_status=$?
    printf '\n'
    if [ "$update_status" -eq 0 ]; then
        color_line "$GREEN" "DEPENDENCY UPDATE COMPLETE!"
    else
        color_line "$RED" "DEPENDENCY UPDATE FAILED (EXIT CODE $update_status)."
    fi
    pause
}

dep_delete() {
    while true; do
        banner
        printf '%s\n' "${RED}WHICH WOULD YOU LIKE TO UNINSTALL?${RESET}"
        printf '%s\n' "${GREEN}1: YT-DLP${RESET}"
        printf '%s\n' "${GREEN}2: FFMPEG (MACOS/HOMEBREW ONLY)${RESET}"
        printf '%s\n' "${GREEN}3: ALL REMOVABLE DEPENDENCIES${RESET}"
        printf '%s\n' "${CYAN}ENTER: GO BACK${RESET}"
        read -r delchoice

        case "$delchoice" in
            '')
                return
                ;;
            1|3)
                banner
                color_line "$RED" "UNINSTALLING YT-DLP..."
                if [ "$IOS_MODE" -eq 1 ] || ! command -v brew >/dev/null 2>&1; then
                    pip_install_ytdlp uninstall -y yt-dlp
                elif [ "$delchoice" = 3 ]; then
                    brew uninstall yt-dlp ffmpeg
                else
                    brew uninstall yt-dlp
                fi
                delete_status=$?
                if [ "$delete_status" -eq 0 ]; then
                    color_line "$GREEN" "DEPENDENCY REMOVED."
                else
                    color_line "$RED" "UNINSTALL FAILED (EXIT CODE $delete_status)."
                fi
                pause
                return
                ;;
            2)
                if [ "$IOS_MODE" -eq 1 ] || ! command -v brew >/dev/null 2>&1; then
                    color_line "$YELLOW" "FFMPEG IS BUILT INTO A-SHELL OR IS NOT MANAGED BY HOMEBREW."
                else
                    brew uninstall ffmpeg
                fi
                pause
                return
                ;;
        esac
    done
}

dependencies_menu() {
    while true; do
        banner
        printf '%s\n' "${RED}DEPENDENCIES${RESET}"
        printf '%s\n' "${GREEN}1: CHECK IF DEPENDENCIES ARE INSTALLED${RESET}"
        printf '%s\n' "${GREEN}2: INSTALL DEPENDENCIES${RESET}"
        printf '%s\n' "${GREEN}3: UPDATE DEPENDENCIES${RESET}"
        printf '%s\n' "${GREEN}4: DELETE DEPENDENCIES${RESET}"
        printf '%s\n' "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        read -r depchoice

        case "$depchoice" in
            '') return ;;
            1) dep_check ;;
            2) dep_download ;;
            3) dep_update ;;
            4) dep_delete ;;
        esac
    done
}

update_count() {
    if [ -f "$HISTORY_FILE" ]; then
        awk 'NR > 1 && /^UPDATE:/ { count++ } END { print count + 0 }' "$HISTORY_FILE"
    else
        printf '0\n'
    fi
}

video_count() {
    if [ ! -d "$VIDEOS_DIR" ]; then
        printf '0\n'
        return
    fi
    find "$VIDEOS_DIR" -type f | awk '
        tolower($0) ~ /\.(mp4|mp3|mkv|webm|m4a|wav|mov|avi|flv|ogg|opus|aac|wmv)$/ { count++ }
        END { print count + 0 }
    '
}

version_info() {
    banner
    dep_status=INSTALLED
    if ! ytdlp_available; then
        dep_status="YT-DLP NOT INSTALLED"
    fi
    color_line "$RED" "VOSVIDEODOWNLOAD"
    color_line "$GREEN" "VERSION: $YELLOW$VERSION | $VERSION_TYPE"
    color_line "$GREEN" "YT-DLP: $YELLOW$dep_status"
    if [ "$IOS_MODE" -eq 1 ]; then
        color_line "$GREEN" "FFMPEG: $YELLOW A-SHELL BUILT-IN"
    elif command -v ffmpeg >/dev/null 2>&1; then
        color_line "$GREEN" "FFMPEG: $YELLOW INSTALLED"
    else
        color_line "$GREEN" "FFMPEG: $YELLOW NOT INSTALLED (OPTIONAL)"
    fi
    color_line "$GREEN" "VIDEOS DOWNLOADED: $YELLOW$(video_count)"
    color_line "$GREEN" "APP UPDATES INSTALLED: $YELLOW$(update_count)"
    printf '\n'
    pause
}

settings_menu() {
    while true; do
        banner
        color_line "$RED" "VOSVIDEODOWNLOAD SETTINGS"
        color_line "$GREEN" "METADATA / THUMBNAILS: $YELLOW$METADATA"
        color_line "$GREEN" "ASCII FLAME: $YELLOW$FLAME_DISPLAY"
        printf '%s\n' "${GREEN}1: TOGGLE METADATA / THUMBNAILS${RESET}"
        printf '%s\n' "${GREEN}2: CHANGE ASCII FLAME${RESET}"
        printf '%s\n' "${GREEN}3: VERSION INFORMATION${RESET}"
        printf '%s\n' "${CYAN}ENTER: BACK TO MAIN MENU${RESET}"
        read -r setting_choice
        case "$setting_choice" in
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
            3)
                version_info
                ;;
        esac
    done
}

flame_menu() {
    while true; do
        banner
        printf '%s\n' "${RED}ASCII FLAME SETTINGS${RESET}"
        printf '%s\n' "${GREEN}1: RED-YELLOW FLAME${RESET}"
        printf '%s\n' "${GREEN}2: PURPLE-PINK FLAME${RESET}"
        printf '%s\n' "${GREEN}3: GREEN-WHITE FLAME${RESET}"
        printf '%s\n' "${GREEN}4: ICE-BLUE FLAME${RESET}"
        printf '%s\n' "${GREEN}5: OCEAN-TEAL FLAME${RESET}"
        printf '%s\n' "${GREEN}6: SUNSET FLAME${RESET}"
        printf '%s\n' "${GREEN}7: CYBERPUNK FLAME${RESET}"
        printf '%s\n' "${GREEN}8: RAINBOW FLAME${RESET}"
        printf '%s\n' "${CYAN}ENTER: BACK TO SETTINGS${RESET}"
        read -r flame_choice
        case "$flame_choice" in
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
        set_theme_color
        save_settings
    done
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

record_update() {
    update_date=$(date '+%m/%d/%Y at %I:%M %p') || return 1
    if [ ! -f "$HISTORY_FILE" ]; then
        printf '%s\n' "VOSVIDEODOWNLOAD UPDATE HISTORY LOG" > "$HISTORY_FILE" || return 1
    fi
    printf 'UPDATE: %s (%s) > %s (%s) AT %s\n' \
        "$VERSION" "$VERSION_TYPE" "$1" "$2" "$update_date" >> "$HISTORY_FILE"
}

update_app() {
    banner
    color_line "$RED" "CHECKING FOR VOSVIDEODOWNLOAD UPDATES..."
    if ! command -v curl >/dev/null 2>&1; then
        color_line "$RED" "CURL IS UNAVAILABLE IN THIS SHELL."
        pause
        return
    fi

    update_tmp="$SCRIPT_PATH.update.$$"
    update_ready="$update_tmp.ready"
    if ! curl --location --fail --silent --show-error --connect-timeout 15 --max-time 60 \
        "$UPDATE_URL" --output "$update_tmp"; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "UPDATE DOWNLOAD FAILED. CHECK YOUR CONNECTION."
        color_line "$YELLOW" "UPDATE URL: $UPDATE_URL"
        pause
        return
    fi
    if [ ! -s "$update_tmp" ] || ! grep -Fxq 'VOS_IOS_SCRIPT=1' "$update_tmp"; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "THE DOWNLOADED FILE IS NOT A VALID APPLE VERSION."
        pause
        return
    fi

    remote_version=$(sed -n 's/^VERSION=//p' "$update_tmp" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE=//p' "$update_tmp" | head -n 1)
    if ! valid_version "$remote_version" || [ -z "$remote_type" ]; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "THE UPDATE HAS INVALID VERSION INFORMATION."
        pause
        return
    fi
    case "$remote_type" in
        *[!A-Za-z0-9_-]*)
            rm -f "$update_tmp" "$update_ready"
            color_line "$RED" "THE UPDATE HAS INVALID VERSION INFORMATION."
            pause
            return
            ;;
    esac

    if ! rewrite_update_url "$update_tmp" "$update_ready"; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "COULD NOT SET THE UPDATE URL."
        pause
        return
    fi
    if [ "$IOS_MODE" -eq 0 ] && ! sh -n "$update_ready"; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "THE DOWNLOADED UPDATE HAS INVALID SHELL SYNTAX."
        pause
        return
    fi

    version_order=$(compare_versions "$VERSION" "$remote_version")
    if [ "$version_order" -ge 0 ]; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$GREEN" "VOSVIDEODOWNLOAD $VERSION IS ALREADY UP TO DATE."
        pause
        return
    fi

    color_line "$CYAN" "UPDATE FOUND: $VERSION TO $remote_version ($remote_type)"
    color_line "$YELLOW" "SETTINGS, HISTORY, AND DOWNLOADED VIDEOS WILL BE KEPT."
    printf '%s' "${CYAN}INSTALL THIS UPDATE? [Y/N]: ${RESET}"
    read -r update_choice
    case "$update_choice" in
        Y|y) ;;
        *)
            rm -f "$update_tmp" "$update_ready"
            color_line "$YELLOW" "UPDATE CANCELLED."
            pause
            return
            ;;
    esac

    if [ -x "$SCRIPT_PATH" ] && ! chmod +x "$update_ready"; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "COULD NOT PRESERVE THE SCRIPT'S EXECUTABLE PERMISSION."
        pause
        return
    fi
    if ! mv "$update_ready" "$SCRIPT_PATH"; then
        rm -f "$update_tmp" "$update_ready"
        color_line "$RED" "COULD NOT REPLACE THE SCRIPT IN THIS FOLDER."
        pause
        return
    fi
    rm -f "$update_tmp"

    if record_update "$remote_version" "$remote_type"; then
        color_line "$GREEN" "UPDATE INSTALLED AND RECORDED."
    else
        color_line "$YELLOW" "UPDATE INSTALLED, BUT HISTORY COULD NOT BE UPDATED."
    fi
    color_line "$CYAN" "QUIT THIS SESSION AND RUN THE SCRIPT AGAIN."
    pause
}

if ! mkdir -p "$VIDEOS_DIR"; then
    color_line "$RED" "CANNOT CREATE THE VIDEOS FOLDER: $VIDEOS_DIR"
    exit 1
fi

load_settings

while true; do
    banner
    printf '%s\n' "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER${RESET}"
    printf '%s\n' "${GREEN}1: DOWNLOAD VIDEO${RESET}"
    printf '%s\n' "${GREEN}2: DEPENDENCIES${RESET}"
    printf '%s\n' "${GREEN}3: CHECK FOR APP UPDATES${RESET}"
    printf '%s\n' "${GREEN}4: SETTINGS / VERSION INFO${RESET}"
    printf '%s\n' "${GREEN}5: QUIT${RESET}"
    printf '%s\n' "${GREEN}6: RESTART${RESET}"
    read -r choice

    case "$choice" in
        1) download_menu ;;
        2) dependencies_menu ;;
        3) update_app ;;
        4) settings_menu ;;
        5) exit 0 ;;
        6) exec "$SCRIPT_PATH" "$@" ;;
    esac
done
