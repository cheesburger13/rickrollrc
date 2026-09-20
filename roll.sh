#!/bin/bash
# Rick Astley in your Terminal.
# By Serene Han and Justine Tunney <3
# Patched: paplay routing for Bluetooth audio, cheesburger13 GitHub mirror
version='1.3'
rick='https://raw.githubusercontent.com/cheesburger13/rickrollrc/master'
video="$rick/astley80.full.bz2"
audio_gsm="$rick/roll.gsm"
audio_raw="$rick/roll.s16.wav"
audio_mp3="$rick/roll.mp3"
audpid=0
NEVER_GONNA='curl -s -L https://raw.githubusercontent.com/cheesburger13/rickrollrc/master/roll.sh | bash'
MAKE_YOU_CRY="$HOME/.bashrc"
red='\x1b[38;5;9m'
yell='\x1b[38;5;216m'
green='\x1b[38;5;10m'
purp='\x1b[38;5;171m'
echo -en '\x1b[s'  # Save cursor.

has?() { hash $1 2>/dev/null; }
cleanup() { (( audpid > 1 )) && kill $audpid 2>/dev/null; }
quit() { echo -e "\x1b[2J \x1b[0H ${purp}<3 \x1b[?25h \x1b[u \x1b[m"; }

usage () {
  echo -en "${green}Rick Astley performs ♪ Never Gonna Give You Up ♪ on STDOUT."
  echo -e "  ${purp}[v$version]"
  echo -e "${yell}Usage: ./roll.sh [OPTIONS...]"
  echo -e "${purp}OPTIONS : ${yell}"
  echo -e " help   - Show this message."
  echo -e " inject - Append to ${purp}${USER}${yell}'s bashrc. (Recommended :D)"
}
for arg in "$@"; do
  if [[ "$arg" == "help"* || "$arg" == "-h"* || "$arg" == "--h"* ]]; then
    usage && exit
  elif [[ "$arg" == "inject" ]]; then
    echo -en "${red}[Inject] "
    echo $NEVER_GONNA >> $MAKE_YOU_CRY
    echo -e "${green}Appended to $MAKE_YOU_CRY. <3"
    echo -en "${yell}If you've astley overdosed, "
    echo -e "delete the line ${purp}\"$NEVER_GONNA\"${yell}."
    exit
  else
    echo -e "${red}Unrecognized option: \"$arg\""
    usage && exit
  fi
done
trap "cleanup" INT
trap "quit" EXIT

# Bean streamin' - agnostic to curl or wget availability.
obtainium() {
  if has? curl; then curl -sL $1
  elif has? wget; then wget -q -O - $1
  else echo "Cannot has internets. :(" && exit
  fi
}
echo -en "\x1b[?25l \x1b[2J \x1b[H"  # Hide cursor, clear screen.

# Audio: paplay first (routes to PulseAudio/PipeWire sinks, incl. Bluetooth),
# then afplay (Mac), then aplay (raw ALSA hardware only), then sox's play.
# Fully detached with nohup+disown so the video pipeline's CPU/pipe load
# downstream can never interrupt or cut off playback.
if has? afplay; then
  [ -f /tmp/roll.mp3 ] || obtainium $audio_mp3 >/tmp/roll.mp3
  nohup afplay /tmp/roll.mp3 >/dev/null 2>&1 &
  disown
elif has? paplay; then
  [ -f /tmp/roll.s16.wav ] || obtainium $audio_raw >/tmp/roll.s16.wav
  nohup paplay /tmp/roll.s16.wav >/dev/null 2>&1 &
  disown
elif has? aplay; then
  [ -f /tmp/roll.s16.wav ] || obtainium $audio_raw >/tmp/roll.s16.wav
  nohup aplay -q -r 16000 /tmp/roll.s16.wav >/dev/null 2>&1 &
  disown
elif has? play; then
  obtainium $audio_gsm >/tmp/roll.gsm.wav
  nohup play -t gsm -q /tmp/roll.gsm.wav >/dev/null 2>&1 &
  disown
fi
audpid=$!

# Sync FPS to reality as best as possible.
python3 <(cat <<EOF
import sys
import time
fps = 25; time_per_frame = 1.0 / fps
buf = ''; frame = 0; next_frame = 0
begin = time.time()
try:
  for i, line in enumerate(sys.stdin):
    if i % 32 == 0:
      frame += 1
      sys.stdout.write(buf); buf = ''
      elapsed = time.time() - begin
      repose = (frame * time_per_frame) - elapsed
      if repose > 0.0:
        time.sleep(repose)
      next_frame = elapsed / time_per_frame
    if frame >= next_frame:
      buf += line
except KeyboardInterrupt:
  pass
EOF
) < <(obtainium $video | bunzip2 -q 2> /dev/null)
