#!/bin/sh

VOS_IOS_SCRIPT=1
VERSION=1.03.25
VERSION_TYPE=APPLE
UPDATE_URL_BASE=https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.sh
UPDATE_URL=${VOS_UPDATE_URL:-$UPDATE_URL_BASE}

case "$0" in
    */*) SCRIPT_NAME=${0##*/}; SCRIPT_DIR=${0%/*}; [ -n "$SCRIPT_DIR" ] || SCRIPT_DIR=/ ;;
    *) SCRIPT_NAME=$0; SCRIPT_DIR=. ;;
esac
SCRIPT_DIR=$(CDPATH= cd "$SCRIPT_DIR" && pwd) || {
    printf '%s\n' "Cannot resolve the script directory."
    exit 1
}
SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_NAME
VIDEO_DIR=$SCRIPT_DIR/VIDEOS
SETTINGS_FILE=$SCRIPT_DIR/settings.txt
HISTORY_FILE=$SCRIPT_DIR/history.txt

if command -v pkg >/dev/null 2>&1; then
    IOS_MODE=1
else
    IOS_MODE=0
fi

if [ -t 1 ]; then
    ESC=$(printf '\033')
    RESET=${ESC}'[0m'
    RED=${ESC}'[91m'
    DARKRED=${ESC}'[31m'
    ORANGE=${ESC}'[38;5;208m'
    YELLOW=${ESC}'[93m'
    GREEN=${ESC}'[92m'
    CYAN=${ESC}'[96m'
    PURPLE=${ESC}'[35m'
    PINK=${ESC}'[95m'
    WHITE=${ESC}'[97m'
else
    ESC=
    RESET=
    RED=
    DARKRED=
    ORANGE=
    YELLOW=
    GREEN=
    CYAN=
    PURPLE=
    PINK=
    WHITE=
fi

METADATA=DISABLED
FLAME=STANDARD

rgb_color() {
    if [ -n "$ESC" ]; then
        printf '%s[38;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"
    fi
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

color_line() {
    printf '%s%s%s\n' "$1" "$2" "$RESET"
}

color_prompt() {
    printf '%s%s%s' "$1" "$2" "$RESET"
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
        STANDARD)
            FLAME_DISPLAY='RED-YELLOW FLAME'
            set_flame_palette 120 0 0 155 0 0 190 5 0 225 20 0 250 45 0 \
                255 80 0 255 120 0 255 165 0 255 205 0 255 240 75
            ;;
        *)
            FLAME=STANDARD
            FLAME_DISPLAY='RED-YELLOW FLAME'
            set_flame_palette 120 0 0 155 0 0 190 5 0 225 20 0 250 45 0 \
                255 80 0 255 120 0 255 165 0 255 205 0 255 240 75
            ;;
    esac
}

load_settings() {
    [ -f "$SETTINGS_FILE" ] || return 0
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
    set_theme_color
}

save_settings() {
    settings_tmp=$SETTINGS_FILE.tmp.$$
    if ! printf 'METADATA=%s\nFLAME=%s\n' "$METADATA" "$FLAME" > "$settings_tmp"; then
        printf '%s\n' "Could not write settings to $SETTINGS_FILE."
        return 1
    fi
    if ! mv "$settings_tmp" "$SETTINGS_FILE"; then
        rm -f "$settings_tmp"
        printf '%s\n' "Could not install settings file at $SETTINGS_FILE."
        return 1
    fi
}

clear_screen() {
    if [ -t 1 ]; then
        printf '\033[2J\033[H'
    fi
}

banner() {
    clear_screen
    printf '%s\n' "${FLAME1} __     __   ___    ____     __     __  ___   ____    _____    ___${RESET}"
    printf '%s\n' "${FLAME2} \ \   / /  / _ \  / ___|    \ \   / / |_ _| |  _ \  | ____|  / _ \${RESET}"
    printf '%s\n' "${FLAME3}  \ \ / /  | | | | \___ \     \ \ / /   | |  | | | | |  _|   | | | |${RESET}"
    printf '%s\n' "${FLAME4}   \ V /   | |_| |  ___) |     \ V /    | |  | |_| | | |___  | |_| |${RESET}"
    printf '%s\n' "${FLAME5}    \_/     \___/  |____/       \_/    |___| |____/  |_____|  \___/${RESET}"
    printf '%s\n' "${FLAME6}  ____     ___   __        __  _   _   _        ___      _     ____${RESET}"
    printf '%s\n' "${FLAME7} |  _ \   / _ \  \ \      / / | \ | | | |      / _ \    / \   |  _ \${RESET}"
    printf '%s\n' "${FLAME8} | | | | | | | |  \ \ /\ / /  |  \| | | |     | | | |  / _ \  | | | |${RESET}"
    printf '%s\n' "${FLAME9} | |_| | | |_| |   \ V  V /   | |\  | | |___  | |_| | / ___ \ | |_| |${RESET}"
    printf '%s\n' "${FLAME10} |____/   \___/     \_/\_/    |_| \_| |_____|  \___/ /_/   \_\|____/${RESET}"
    printf '\n'
}

pause() {
    color_prompt "$CYAN" "Press ENTER to continue..."
    IFS= read -r _ || :
}

read_input() {
    IFS= read -r REPLY
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
        /^UPDATE_URL=/ {
            print "UPDATE_URL=${VOS_UPDATE_URL:-" url "}"
            matches++
            next
        }
        { print }
        END { if (matches != 1) exit 1 }
    ' "$1" > "$2"
}

validate_update_syntax() {
    if [ "$IOS_MODE" -eq 1 ]; then
        color_line "$YELLOW" "Skipping nested sh -n validation in a-Shell; product and version checks passed."
        return 0
    fi
    sh -n "$1"
}

run_ytdlp() {
    if [ "$IOS_MODE" -eq 1 ] && command -v python3 >/dev/null 2>&1; then
        python3 -m yt_dlp "$@"
    elif command -v yt-dlp >/dev/null 2>&1; then
        command yt-dlp "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m yt_dlp "$@"
    else
        color_line "$RED" "yt-dlp is not installed. Open Dependencies to install it."
        return 127
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

ffmpeg_available() {
    [ "$IOS_MODE" -eq 0 ] && command -v ffmpeg >/dev/null 2>&1
}

download_video() {
    download_kind=$1
    download_url=$2

    case "$download_kind" in
        video)
            output_template='%(title)s.%(ext)s'
            if ffmpeg_available; then
                set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4
            else
                set -- -f 'b[vcodec^=avc1][ext=mp4]/b[ext=mp4]/b'
                color_line "$YELLOW" "Using a single-file video format; FFmpeg merging is unavailable here."
            fi
            ;;
        audio)
            output_template='%(title)s.%(ext)s'
            if ffmpeg_available; then
                set -- -x --audio-format mp3 --audio-quality 0
            else
                set -- -f 'ba[ext=m4a]/ba'
                color_line "$YELLOW" "Saving the source audio (usually M4A) because FFmpeg MP3 conversion is unavailable."
            fi
            ;;
        video-only)
            output_template='%(title)s.%(ext)s'
            set -- -f 'bv*[vcodec^=avc1][ext=mp4]/bv*[ext=mp4]/bv*'
            ;;
        channel-videos)
            output_template='%(channel)s - VIDEOS/%(title)s.%(ext)s'
            if ffmpeg_available; then
                set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4
            else
                set -- -f 'b[vcodec^=avc1][ext=mp4]/b[ext=mp4]/b'
                color_line "$YELLOW" "Using single-file channel formats; FFmpeg merging is unavailable here."
            fi
            ;;
        channel-shorts)
            output_template='%(channel)s - SHORTS/%(title)s.%(ext)s'
            if ffmpeg_available; then
                set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4
            else
                set -- -f 'b[vcodec^=avc1][ext=mp4]/b[ext=mp4]/b'
                color_line "$YELLOW" "Using single-file channel formats; FFmpeg merging is unavailable here."
            fi
            ;;
    esac

    if [ "$METADATA" = ENABLED ]; then
        set -- "$@" --write-description --write-thumbnail
        if ffmpeg_available; then
            set -- "$@" --convert-thumbnails jpg
        fi
    fi

    color_line "$CYAN" "Downloading..."
    if run_ytdlp -P "$VIDEO_DIR" -o "$output_template" "$@" -- "$download_url"; then
        color_line "$GREEN" "Done. Saved under: $VIDEO_DIR"
    else
        download_status=$?
        color_line "$RED" "Download failed (yt-dlp exit code $download_status). Check the URL, network, and dependencies."
    fi
}

download_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}DOWNLOAD OPTIONS${RESET}" \
            "${GREEN}1: Download video${RESET}" \
            "${GREEN}2: Download audio${RESET}" \
            "${GREEN}3: Download video only (no audio)${RESET}" \
            "${GREEN}4: Download all videos on channel${RESET}" \
            "${GREEN}5: Download all shorts on channel${RESET}" \
            "${CYAN}ENTER: Back to main menu${RESET}"
        color_prompt "$CYAN" "Select: "
        read_input || return
        case "$REPLY" in
            '') return ;;
            1) download_kind=video; prompt="Paste video URL" ;;
            2) download_kind=audio; prompt="Paste URL for audio" ;;
            3) download_kind=video-only; prompt="Paste URL for video only" ;;
            4) download_kind=channel-videos; prompt="Paste channel /videos URL" ;;
            5) download_kind=channel-shorts; prompt="Paste channel /shorts URL" ;;
            *) continue ;;
        esac
        if ! ytdlp_available; then
            color_line "$RED" "yt-dlp is missing. Install it from Dependencies first."
            pause
            continue
        fi
        color_prompt "$CYAN" "$prompt (ENTER to go back): "
        read_input || return
        [ -n "$REPLY" ] || continue
        download_video "$download_kind" "$REPLY"
        pause
    done
}

dependency_status() {
    if ytdlp_available; then
        if ytdlp_version=$(run_ytdlp --version); then
            color_line "$GREEN" "yt-dlp: installed ($ytdlp_version)"
        else
            color_line "$YELLOW" "yt-dlp was found but could not be run."
        fi
    else
        color_line "$RED" "yt-dlp: not installed"
    fi
    if [ "$IOS_MODE" -eq 1 ]; then
        color_line "$YELLOW" "FFmpeg: not used for iOS downloads (a-Shell cannot run yt-dlp's FFmpeg subprocess)"
    elif command -v ffmpeg >/dev/null 2>&1; then
        color_line "$GREEN" "FFmpeg: installed"
    else
        color_line "$YELLOW" "FFmpeg: not installed (optional; required for MP3 conversion and stream merging)"
    fi
}

pip_install_ytdlp() {
    if command -v pip >/dev/null 2>&1; then
        pip "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m pip "$@"
    else
        printf '%s\n' "Python/pip is unavailable. Install Python in your terminal app first."
        return 127
    fi
}

dependency_install_or_update() {
    dependency_action=$1
    if [ "$IOS_MODE" -eq 1 ]; then
        if [ "$dependency_action" = update ]; then
            pip_install_ytdlp install --upgrade yt-dlp
        else
            pip_install_ytdlp install yt-dlp
        fi
    elif command -v brew >/dev/null 2>&1; then
        if [ "$dependency_action" = update ]; then
            brew upgrade yt-dlp ffmpeg
        else
            brew install yt-dlp ffmpeg
        fi
    else
        color_line "$YELLOW" "Homebrew was not found. Installing yt-dlp with pip; install FFmpeg separately if needed."
        if [ "$dependency_action" = update ]; then
            pip_install_ytdlp install --upgrade yt-dlp
        else
            pip_install_ytdlp install yt-dlp
        fi
    fi
}

dependency_delete() {
    color_line "$YELLOW" "This removes yt-dlp and, on macOS with Homebrew, FFmpeg from the shared environment."
    color_prompt "$CYAN" "Continue? [y/N]: "
    read_input || return
    case "$REPLY" in
        y|Y)
            if [ "$IOS_MODE" -eq 1 ] || ! command -v brew >/dev/null 2>&1; then
                pip_install_ytdlp uninstall -y yt-dlp
            else
                brew uninstall yt-dlp ffmpeg
            fi
            ;;
        *) color_line "$YELLOW" "Cancelled." ;;
    esac
}

dependencies_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}DEPENDENCIES${RESET}" \
            "${GREEN}1: Check dependencies${RESET}" \
            "${GREEN}2: Install / repair dependencies${RESET}" \
            "${GREEN}3: Update dependencies${RESET}" \
            "${GREEN}4: Delete dependencies${RESET}" \
            "${CYAN}ENTER: Back to main menu${RESET}"
        color_prompt "$CYAN" "Select: "
        read_input || return
        case "$REPLY" in
            '') return ;;
            1) dependency_status; pause ;;
            2|3)
                if [ "$REPLY" = 2 ]; then
                    dependency_install_or_update install
                else
                    dependency_install_or_update update
                fi
                dependency_result=$?
                if [ "$dependency_result" -eq 0 ]; then
                    color_line "$GREEN" "Dependency operation completed."
                else
                    color_line "$RED" "Dependency operation failed (exit code $dependency_result)."
                fi
                pause
                ;;
            4)
                dependency_delete
                dependency_result=$?
                if [ "$dependency_result" -ne 0 ]; then
                    color_line "$RED" "Dependency removal failed (exit code $dependency_result)."
                fi
                pause
                ;;
            *) ;;
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
    video_files=$(find "$VIDEO_DIR" -type f) || return 1
    printf '%s\n' "$video_files" |
        awk 'tolower($0) ~ /\.(mp4|mp3|mkv|webm|m4a|wav|mov|avi|flv|ogg|opus|aac|wmv)$/ { count++ }
             END { print count + 0 }'
}

settings_menu() {
    while :; do
        banner
        color_line "$RED" "VOSVIDEODOWNLOAD SETTINGS"
        color_line "$GREEN" "Version: $YELLOW$VERSION$GREEN | $VERSION_TYPE"
        color_line "$GREEN" "Updates installed: $YELLOW$(update_count)"
        color_line "$GREEN" "Intended platform: $YELLOW$([ "$IOS_MODE" -eq 1 ] && printf 'iOS (a-Shell)' || printf 'macOS / POSIX shell')"
        if videos_total=$(video_count); then
            color_line "$GREEN" "Videos downloaded: $YELLOW$videos_total"
        else
            color_line "$RED" "Videos downloaded: unavailable (could not read the Videos folder)"
        fi
        printf '\n'
        printf '%s\n' \
            "${GREEN}1: Toggle metadata/thumbnails ($YELLOW$METADATA$GREEN)${RESET}" \
            "${GREEN}2: ASCII flame ($YELLOW$FLAME_DISPLAY$GREEN)${RESET}" \
            "${CYAN}ENTER: Back${RESET}"
        color_prompt "$CYAN" "Select: "
        read_input || return
        case "$REPLY" in
            '')
                return
                ;;
            1)
                if [ "$METADATA" = ENABLED ]; then METADATA=DISABLED; else METADATA=ENABLED; fi
                save_settings || pause
                ;;
            2)
                flame_menu
                ;;
            *)
                ;;
        esac
    done
}

flame_option() {
    if [ "$FLAME" = "$1" ]; then
        color_line "$GREEN" "$2: (ENABLED) $3"
    else
        color_line "$GREEN" "$2: $3"
    fi
}

flame_menu() {
    while :; do
        banner
        color_line "$RED" "ASCII FLAME SETTINGS"
        flame_option STANDARD 1 "RED-YELLOW FLAME"
        flame_option PURPLE-PINK 2 "PURPLE-PINK FLAME"
        flame_option GREEN-WHITE 3 "GREEN-WHITE FLAME"
        flame_option ICE-BLUE 4 "ICE-BLUE FLAME"
        flame_option OCEAN-TEAL 5 "OCEAN-TEAL FLAME"
        flame_option SUNSET 6 "SUNSET FLAME"
        flame_option CYBERPUNK 7 "CYBERPUNK FLAME"
        flame_option RAINBOW 8 "RAINBOW FLAME"
        color_line "$CYAN" "ENTER: Back to settings"
        color_prompt "$CYAN" "Select: "
        read_input || return
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
        set_theme_color
        save_settings || pause
    done
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
    color_line "$RED" "Checking for VOSVideoDownload updates..."
    if ! command -v curl >/dev/null 2>&1; then
        color_line "$RED" "curl is unavailable in this shell."
        pause
        return
    fi
    update_tmp=$SCRIPT_PATH.update.$$
    update_prepared=$update_tmp.prepared
    if ! curl --location --fail --silent --show-error --connect-timeout 15 --max-time 60 \
        "$UPDATE_URL" --output "$update_tmp"; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$RED" "Update download failed. Check the connection and the iOS update URL."
        color_line "$YELLOW" "The update script must be published at: $UPDATE_URL"
        pause
        return
    fi
    if [ ! -s "$update_tmp" ] || ! grep -Fxq 'VOS_IOS_SCRIPT=1' "$update_tmp"; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$RED" "The downloaded file is not a valid VOSVideoDownload Apple script."
        pause
        return
    fi
    remote_version=$(sed -n 's/^VERSION=//p' "$update_tmp" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE=//p' "$update_tmp" | head -n 1)
    if ! valid_version "$remote_version" || [ -z "$remote_type" ] ||
        printf '%s\n' "$remote_type" | grep -Eq '[^A-Za-z0-9_-]'; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$RED" "The downloaded update has invalid version metadata."
        pause
        return
    fi
    if ! rewrite_update_url "$update_tmp" "$update_prepared"; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$RED" "Could not set the update script's URL."
        pause
        return
    fi
    if ! validate_update_syntax "$update_prepared"; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$RED" "The downloaded update has invalid shell syntax."
        pause
        return
    fi
    version_order=$(compare_versions "$VERSION" "$remote_version")
    if [ "$version_order" -lt 0 ] ||
        { [ "$version_order" -eq 0 ] && [ "$VERSION_TYPE" = "$remote_type" ]; }; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$GREEN" "VOSVIDEODOWNLOAD $VERSION is already up to date."
        pause
        return
    fi

    color_line "$CYAN" "Update found: $VERSION to $remote_version ($remote_type)"
    color_line "$YELLOW" "This replaces only the script; settings, history, and downloaded videos stay in place."
    color_prompt "$CYAN" "Install this update? [y/N]: "
    read_input || {
        rm -f "$update_tmp" "$update_prepared"
        return
    }
    case "$REPLY" in
        y|Y) ;;
        *)
            rm -f "$update_tmp" "$update_prepared"
            color_line "$YELLOW" "Update cancelled."
            pause
            return
            ;;
    esac
    if [ -x "$SCRIPT_PATH" ] && ! chmod +x "$update_prepared"; then
        rm -f "$update_tmp" "$update_prepared"
        color_line "$RED" "Could not preserve the script's executable permission."
        pause
        return
    fi
    if ! mv "$update_prepared" "$SCRIPT_PATH"; then
        rm -f "$update_tmp"
        color_line "$RED" "Could not replace the script. Keep it in a writable local folder and try again."
        color_line "$YELLOW" "Prepared update remains at: $update_prepared"
        pause
        return
    fi
    rm -f "$update_tmp"
    if record_update "$remote_version" "$remote_type"; then
        color_line "$GREEN" "Update installed and recorded in history.txt."
    else
        color_line "$YELLOW" "Update installed, but history.txt could not be written."
    fi
    color_line "$CYAN" "Quit this terminal session and run the script again to use the new version."
    pause
}

main_menu() {
    while :; do
        banner
        printf '%s\n' "${RED}WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER${RESET}" \
            "${GREEN}1: Download video${RESET}" \
            "${GREEN}2: Dependencies${RESET}" \
            "${GREEN}3: Update VOSVideoDownload${RESET}" \
            "${GREEN}4: VOSVideoDownload settings${RESET}" \
            "${GREEN}5: Quit${RESET}" \
            "${GREEN}6: Restart${RESET}"
        color_prompt "$CYAN" "Select: "
        read_input || return
        case "$REPLY" in
            1) download_menu ;;
            2) dependencies_menu ;;
            3) update_app ;;
            4) settings_menu ;;
            5) return ;;
            6) load_settings ;;
            *) ;;
        esac
    done
}

if ! mkdir -p "$VIDEO_DIR"; then
    color_line "$RED" "Cannot create download folder: $VIDEO_DIR"
    exit 1
fi
set_theme_color
load_settings
main_menu
