#!/bin/sh

VOS_IOS_SCRIPT=1
VERSION=1.03.23
VERSION_TYPE=APPLE
UPDATE_URL=${VOS_UPDATE_URL:-https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/iosvosvideodownload.sh}

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
else
    ESC=
    RESET=
fi

METADATA=DISABLED
FLAME=STANDARD

set_theme_color() {
    case "$FLAME" in
        PURPLE-PINK) COLOR=${ESC}'[35m' ;;
        GREEN-WHITE) COLOR=${ESC}'[32;1m' ;;
        ICE-BLUE) COLOR=${ESC}'[34;1m' ;;
        OCEAN-TEAL) COLOR=${ESC}'[36m' ;;
        SUNSET) COLOR=${ESC}'[33;1m' ;;
        CYBERPUNK) COLOR=${ESC}'[35;1m' ;;
        RAINBOW) COLOR=${ESC}'[31;1m' ;;
        *) FLAME=STANDARD; COLOR=${ESC}'[31m' ;;
    esac
    FLAME_DISPLAY=$FLAME
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
    printf '%s\n' "${COLOR}__     __   ___    ____     __     __  ___   ____    _____    ___${RESET}"
    printf '%s\n' "${COLOR}\ \   / /  / _ \  / ___|    \ \   / / |_ _| |  _ \  | ____|  / _ \${RESET}"
    printf '%s\n' "${COLOR} \ \ / /  | | | | \___ \     \ \ / /   | |  | | | | |  _|   | | | |${RESET}"
    printf '%s\n' "${COLOR}  \ V /   | |_| |  ___) |     \ V /    | |  | |_| | | |___  | |_| |${RESET}"
    printf '%s\n' "${COLOR}   \_/     \___/  |____/       \_/    |___| |____/  |_____|  \___/${RESET}"
    printf '\n'
}

pause() {
    printf '%s' "Press ENTER to continue..."
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

run_ytdlp() {
    if [ "$IOS_MODE" -eq 1 ] && command -v python3 >/dev/null 2>&1; then
        python3 -m yt_dlp "$@"
    elif command -v yt-dlp >/dev/null 2>&1; then
        command yt-dlp "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m yt_dlp "$@"
    else
        printf '%s\n' "yt-dlp is not installed. Open Dependencies to install it."
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
                printf '%s\n' "Using a single-file video format; FFmpeg merging is unavailable here."
            fi
            ;;
        audio)
            output_template='%(title)s.%(ext)s'
            if ffmpeg_available; then
                set -- -x --audio-format mp3 --audio-quality 0
            else
                set -- -f 'ba[ext=m4a]/ba'
                printf '%s\n' "Saving the source audio (usually M4A) because FFmpeg MP3 conversion is unavailable."
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
                printf '%s\n' "Using single-file channel formats; FFmpeg merging is unavailable here."
            fi
            ;;
        channel-shorts)
            output_template='%(channel)s - SHORTS/%(title)s.%(ext)s'
            if ffmpeg_available; then
                set -- -f 'bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]' --merge-output-format mp4
            else
                set -- -f 'b[vcodec^=avc1][ext=mp4]/b[ext=mp4]/b'
                printf '%s\n' "Using single-file channel formats; FFmpeg merging is unavailable here."
            fi
            ;;
    esac

    if [ "$METADATA" = ENABLED ]; then
        set -- "$@" --write-description --write-thumbnail
        if ffmpeg_available; then
            set -- "$@" --convert-thumbnails jpg
        fi
    fi

    printf '\n%s\n' "Downloading..."
    if run_ytdlp -P "$VIDEO_DIR" -o "$output_template" "$@" -- "$download_url"; then
        printf '\n%s\n' "Done. Saved under: $VIDEO_DIR"
    else
        download_status=$?
        printf '\n%s\n' "Download failed (yt-dlp exit code $download_status). Check the URL, network, and dependencies."
    fi
}

download_menu() {
    while :; do
        banner
        printf '%s\n' "DOWNLOAD OPTIONS" \
            "1: Download video" \
            "2: Download audio" \
            "3: Download video only (no audio)" \
            "4: Download all videos on channel" \
            "5: Download all shorts on channel" \
            "ENTER: Back to main menu"
        printf '%s' "Select: "
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
            printf '\n%s\n' "yt-dlp is missing. Install it from Dependencies first."
            pause
            continue
        fi
        printf '%s' "$prompt (ENTER to go back): "
        read_input || return
        [ -n "$REPLY" ] || continue
        download_video "$download_kind" "$REPLY"
        pause
    done
}

dependency_status() {
    if ytdlp_available; then
        if ytdlp_version=$(run_ytdlp --version); then
            printf 'yt-dlp: installed (%s)\n' "$ytdlp_version"
        else
            printf '%s\n' "yt-dlp was found but could not be run."
        fi
    else
        printf '%s\n' "yt-dlp: not installed"
    fi
    if [ "$IOS_MODE" -eq 1 ]; then
        printf '%s\n' "FFmpeg: not used for iOS downloads (a-Shell cannot run yt-dlp's FFmpeg subprocess)"
    elif command -v ffmpeg >/dev/null 2>&1; then
        printf '%s\n' "FFmpeg: installed"
    else
        printf '%s\n' "FFmpeg: not installed (optional; required for MP3 conversion and stream merging)"
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
        printf '%s\n' "Homebrew was not found. Installing yt-dlp with pip; install FFmpeg separately if needed."
        if [ "$dependency_action" = update ]; then
            pip_install_ytdlp install --upgrade yt-dlp
        else
            pip_install_ytdlp install yt-dlp
        fi
    fi
}

dependency_delete() {
    printf '%s\n' "This removes yt-dlp and, on macOS with Homebrew, FFmpeg from the shared environment."
    printf '%s' "Continue? [y/N]: "
    read_input || return
    case "$REPLY" in
        y|Y)
            if [ "$IOS_MODE" -eq 1 ] || ! command -v brew >/dev/null 2>&1; then
                pip_install_ytdlp uninstall -y yt-dlp
            else
                brew uninstall yt-dlp ffmpeg
            fi
            ;;
        *) printf '%s\n' "Cancelled." ;;
    esac
}

dependencies_menu() {
    while :; do
        banner
        printf '%s\n' "DEPENDENCIES" \
            "1: Check dependencies" \
            "2: Install / repair dependencies" \
            "3: Update dependencies" \
            "4: Delete dependencies" \
            "ENTER: Back to main menu"
        printf '%s' "Select: "
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
                    printf '%s\n' "Dependency operation completed."
                else
                    printf 'Dependency operation failed (exit code %s).\n' "$dependency_result"
                fi
                pause
                ;;
            4)
                dependency_delete
                dependency_result=$?
                if [ "$dependency_result" -ne 0 ]; then
                    printf 'Dependency removal failed (exit code %s).\n' "$dependency_result"
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
        printf '%s\n' "VOSVIDEODOWNLOAD SETTINGS"
        printf 'Version: %s | %s\n' "$VERSION" "$VERSION_TYPE"
        printf 'Updates installed: %s\n' "$(update_count)"
        printf 'Intended platform: %s\n' "$([ "$IOS_MODE" -eq 1 ] && printf 'iOS (a-Shell)' || printf 'macOS / POSIX shell')"
        if videos_total=$(video_count); then
            printf 'Videos downloaded: %s\n' "$videos_total"
        else
            printf '%s\n' "Videos downloaded: unavailable (could not read the Videos folder)"
        fi
        printf '\n%s\n' "1: Toggle metadata/thumbnails ($METADATA)" "2: ASCII flame ($FLAME_DISPLAY)" "ENTER: Back"
        printf '%s' "Select: "
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

flame_menu() {
    while :; do
        banner
        printf '%s\n' "ASCII FLAME SETTINGS" \
            "1: STANDARD" \
            "2: PURPLE-PINK" \
            "3: GREEN-WHITE" \
            "4: ICE-BLUE" \
            "5: OCEAN-TEAL" \
            "6: SUNSET" \
            "7: CYBERPUNK" \
            "8: RAINBOW" \
            "ENTER: Back to settings"
        printf '%s' "Select: "
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
    printf '%s\n' "Checking for VOSVideoDownload updates..."
    if ! command -v curl >/dev/null 2>&1; then
        printf '%s\n' "curl is unavailable in this shell."
        pause
        return
    fi
    update_tmp=$SCRIPT_PATH.update.$$
    if ! curl --location --fail --silent --show-error --connect-timeout 15 --max-time 60 \
        "$UPDATE_URL" --output "$update_tmp"; then
        rm -f "$update_tmp"
        printf '%s\n' "Update download failed. Check the connection and the iOS update URL."
        printf '%s\n' "The update script must be published at: $UPDATE_URL"
        pause
        return
    fi
    if [ ! -s "$update_tmp" ] || ! grep -Fxq 'VOS_IOS_SCRIPT=1' "$update_tmp"; then
        rm -f "$update_tmp"
        printf '%s\n' "The downloaded file is not a valid VOSVideoDownload Apple script."
        pause
        return
    fi
    remote_version=$(sed -n 's/^VERSION=//p' "$update_tmp" | head -n 1)
    remote_type=$(sed -n 's/^VERSION_TYPE=//p' "$update_tmp" | head -n 1)
    if ! valid_version "$remote_version" || [ -z "$remote_type" ] ||
        printf '%s\n' "$remote_type" | grep -Eq '[^A-Za-z0-9_-]'; then
        rm -f "$update_tmp"
        printf '%s\n' "The downloaded update has invalid version metadata."
        pause
        return
    fi
    if ! sh -n "$update_tmp"; then
        rm -f "$update_tmp"
        printf '%s\n' "The downloaded update has invalid shell syntax."
        pause
        return
    fi
    version_order=$(compare_versions "$VERSION" "$remote_version")
    if [ "$version_order" -lt 0 ] ||
        { [ "$version_order" -eq 0 ] && [ "$VERSION_TYPE" = "$remote_type" ]; }; then
        rm -f "$update_tmp"
        printf 'VOSVIDEODOWNLOAD %s is already up to date.\n' "$VERSION"
        pause
        return
    fi

    printf 'Update found: %s to %s (%s)\n' "$VERSION" "$remote_version" "$remote_type"
    printf '%s\n' "This replaces only the script; settings, history, and downloaded videos stay in place."
    printf '%s' "Install this update? [y/N]: "
    read_input || {
        rm -f "$update_tmp"
        return
    }
    case "$REPLY" in
        y|Y) ;;
        *)
            rm -f "$update_tmp"
            printf '%s\n' "Update cancelled."
            pause
            return
            ;;
    esac
    if [ -x "$SCRIPT_PATH" ] && ! chmod +x "$update_tmp"; then
        rm -f "$update_tmp"
        printf '%s\n' "Could not preserve the script's executable permission."
        pause
        return
    fi
    if ! mv "$update_tmp" "$SCRIPT_PATH"; then
        printf '%s\n' "Could not replace the script. Keep it in a writable local folder and try again."
        printf 'Downloaded update remains at: %s\n' "$update_tmp"
        pause
        return
    fi
    if record_update "$remote_version" "$remote_type"; then
        printf '%s\n' "Update installed and recorded in history.txt."
    else
        printf '%s\n' "Update installed, but history.txt could not be written."
    fi
    printf '%s\n' "Quit this terminal session and run the script again to use the new version."
    pause
}

main_menu() {
    while :; do
        banner
        printf '%s\n' "WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER" \
            "1: Download video" \
            "2: Dependencies" \
            "3: Update VOSVideoDownload" \
            "4: VOSVideoDownload settings" \
            "5: Quit" \
            "6: Restart"
        printf '%s' "Select: "
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
    printf 'Cannot create download folder: %s\n' "$VIDEO_DIR"
    exit 1
fi
set_theme_color
load_settings
main_menu
