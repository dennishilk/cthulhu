#!/bin/sh

LOG="/var/log/emerge.log"

# readable?
[ -r "$LOG" ] || { echo "unknown"; exit 0; }

# first timestamp from emerge.log
FIRST_TS=$(sed -n '1{s/:.*//;p}' "$LOG")

# now
NOW_TS=$(date +%s)

# diff in days
DAYS_TOTAL=$(( (NOW_TS - FIRST_TS) / 86400 ))

# years + remaining days
YEARS=$(( DAYS_TOTAL / 365 ))
DAYS=$(( DAYS_TOTAL % 365 ))

printf "%d years, %d days\n" "$YEARS" "$DAYS"

