#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="audiosettings"
rp_module_desc="Configure audio settings"
rp_module_section="config"
rp_module_flags="!all rpi"

function depends_audiosettings() {
    if [[ "$md_mode" == "install" ]]; then
        getDepends alsa-utils
    fi
}

function gui_audiosettings() {

    # The list of ALSA cards/devices depends on the 'snd-bcm2385' module parameter 'enable_compat_alsa'
    # * enable_compat_alsa: true  - single soundcard, output is routed based on the `numid` control
    # * enable_compat_alsa: false - one soundcard per output type (HDMI/Headphones)
    if aplay -l; then
        _alsa_internal_audiosettings
    fi
}

function _alsa_internal_audiosettings() {
    local cmd=(dialog --backtitle "$__backtitle" --menu "Set audio output." 22 86 16)
    local options=()

    options+=(
        M "Mixer - adjust output volume"
        R "Reset to default"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [[ -n "$choice" ]]; then
        case "$choice" in
            [0-9])
                _asoundrc_save_audiosettings $choice
                printMsgs "dialog" "Set audio output to ${options[$((choice*2+1))]}"
                ;;
            M)
                alsamixer >/dev/tty </dev/tty
                alsactl store
                ;;
            R)
                /etc/init.d/alsa-utils reset
                alsactl store
                rm -f "$home/.asoundrc"
                printMsgs "dialog" "Audio settings reset to defaults"
                ;;
        esac
    fi
}

# configure the default ALSA soundcard based on chosen card #
function _asoundrc_save_audiosettings() {
    [[ -z "$1" ]] && return

    local card_index=$1
    local tmpfile=$(mktemp)

    cat << EOF > "$tmpfile"
pcm.!default {
  type asym
  playback.pcm {
    type plug
    slave.pcm "output"
  }
  capture.pcm {
    type plug
    slave.pcm "input"
  }
}
pcm.output {
  type hw
  card $card_index
}
ctl.!default {
  type hw
  card $card_index
}
EOF

    mv "$tmpfile" "$home/.asoundrc"
    chown "$user:$user" "$home/.asoundrc"
}
