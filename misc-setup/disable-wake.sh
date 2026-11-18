#!/bin/sh
# Disable wakeup on all input devices except power/sleep buttons.
# PNP0C0C = Power Button, PNP0C0E = Sleep Button
for ev in /sys/class/input/event*; do
  d=$(readlink -f "$ev/device")
  case "$d" in *PNP0C0C*|*PNP0C0E*) continue;; esac
  while [ "$d" != "/" ]; do
    if [ -f "$d/power/wakeup" ]; then
      echo disabled > "$d/power/wakeup" 2>/dev/null
      break
    fi
    d=$(dirname "$d")
  done
done
