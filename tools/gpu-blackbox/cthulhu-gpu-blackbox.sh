#!/usr/bin/env bash
# Cthulhu GPU Blackbox 1.1 — AMDGPU flight recorder for systemd Linux
# Tested on Arch Linux, AMD Radeon RX 9060 XT / Navi 44 (2026-10-21).
# License: MIT (see repository LICENSE).
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

CONFIG=/etc/cthulhu-gpu-blackbox.conf
if [[ ! -v BLACKBOX_MOUNT && -r "$CONFIG" ]]; then
    # Created root-owned by this installer; contains only BLACKBOX_MOUNT.
    source "$CONFIG"
fi
MOUNT="${BLACKBOX_MOUNT:-/mnt/Homelab}"
[[ "$MOUNT" =~ ^/[A-Za-z0-9_./-]+$ && "$MOUNT" != "/" && "$MOUNT" != *"/../"* && "$MOUNT" != *"/./"* ]] ||
    { printf '[blackbox] Invalid absolute mount path: %s\n' "$MOUNT" >&2; exit 1; }

STORE="$MOUNT/Cthulhu-GPU-Blackbox"
TARGET=/usr/local/bin/cthulhu-gpu-blackbox
SERVICE=/etc/systemd/system/cthulhu-gpu-blackbox.service
DUMP_SERVICE=/etc/systemd/system/cthulhu-gpu-blackbox-dump@.service
UDEV_RULE=/etc/udev/rules.d/90-cthulhu-gpu-blackbox.rules
RUNTIME=/run/cthulhu-gpu-blackbox

say()  { printf '[blackbox] %s\n' "$*"; }
warn() { printf '[blackbox] WARNING: %s\n' "$*" >&2; }
die()  { printf '[blackbox] ERROR: %s\n' "$*" >&2; exit 1; }
root_only() { (( EUID == 0 )) || die 'Run this command with sudo.'; }
mounted_separately() {
    mountpoint -q -- "$MOUNT" &&
        [[ "$(stat -c '%d' "$MOUNT")" != "$(stat -c '%d' /)" ]]
}
require_mount() { mounted_separately || die "$MOUNT is not a separate mount. Refusing writes to the root filesystem."; }
check_tools() {
    local tool
    for tool in bash findmnt mountpoint stat flock timeout journalctl systemctl udevadm \
       install cmp date sync df grep sort tail readlink cat mktemp find wc tr sleep mv rm uname; do
        command -v "$tool" >/dev/null 2>&1 || die "Missing required program: $tool"
    done
}
gpu_devices() {
    local card dev driver
    for card in /sys/class/drm/card[0-9]*; do
        [[ -d "$card" ]] || continue
        dev="$card/device"
        driver=$(readlink -f "$dev/driver" 2>/dev/null || true)
        [[ "$driver" == */amdgpu ]] || continue
        readlink -f "$dev" 2>/dev/null || true
    done
}
preflight() {
    check_tools
    say 'Preflight (read only)'
    printf 'Host: %s | Kernel: %s\n' "$(cat /proc/sys/kernel/hostname)" "$(uname -r)"
    printf 'Mount setting: %s\n' "$MOUNT"
    findmnt --mountpoint "$MOUNT" -o SOURCE,FSTYPE,OPTIONS,TARGET || true
    if mounted_separately; then
        df -h -- "$MOUNT"
    else
        die 'The storage volume must be mounted separately before installation.'
    fi
    local dev seen=0
    while IFS= read -r dev; do
        [[ -n "$dev" ]] || continue
        printf 'AMDGPU: %s\n' "$dev"
        ((seen+=1))
    done < <(gpu_devices)
    ((seen > 0)) || warn 'No AMDGPU DRM card detected.'
    [[ -d /sys/class/devcoredump ]] || warn 'No devcoredump class currently visible.'
    say 'Preflight passed.'
}
install_safe() {
    local src="$1" dst="$2" mode="$3"
    if [[ -e "$dst" ]] && ! cmp -s -- "$src" "$dst"; then
        die "Different file already exists: $dst (will not overwrite)."
    fi
    install -m "$mode" -- "$src" "$dst"
}
install_blackbox() (
    root_only
    check_tools
    require_mount
    [[ -n "$(gpu_devices)" ]] || die 'AMDGPU not detected.'
    local source tmp f
    source=$(readlink -f -- "${BASH_SOURCE[0]}")
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' EXIT
    {
        printf '# Cthulhu GPU Blackbox configuration (root managed)\n'
        printf 'BLACKBOX_MOUNT=%q\n' "$MOUNT"
    } > "$tmp/config"
    cat > "$tmp/service" <<UNIT
[Unit]
Description=Cthulhu GPU Blackbox - AMDGPU kernel and telemetry recorder
After=local-fs.target systemd-journald.service
RequiresMountsFor=$MOUNT
ConditionPathIsMountPoint=$MOUNT

[Service]
Type=simple
EnvironmentFile=$CONFIG
ExecStart=$TARGET daemon
Restart=on-failure
RestartSec=5s
User=root
UMask=0077
Nice=10
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$STORE $RUNTIME
RuntimeDirectory=cthulhu-gpu-blackbox
RuntimeDirectoryMode=0700
RuntimeDirectoryPreserve=yes
TimeoutStopSec=15s

[Install]
WantedBy=multi-user.target
UNIT
    cat > "$tmp/dump-service" <<UNIT
[Unit]
Description=Cthulhu GPU Blackbox - capture devcoredump %I
After=local-fs.target
RequiresMountsFor=$MOUNT
ConditionPathIsMountPoint=$MOUNT

[Service]
Type=oneshot
EnvironmentFile=$CONFIG
ExecStart=$TARGET capture %I
User=root
UMask=0077
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$STORE $RUNTIME
RuntimeDirectory=cthulhu-gpu-blackbox
RuntimeDirectoryMode=0700
RuntimeDirectoryPreserve=yes
TimeoutStartSec=120s
UNIT
    cat > "$tmp/udev" <<'RULE'
# All Linux devcoredumps: systemd starts a short-lived root-owned capture service.
ACTION=="add", SUBSYSTEM=="devcoredump", KERNEL=="devcd*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="cthulhu-gpu-blackbox-dump@%k.service"
RULE
    # Pre-check every destination to avoid partially overwriting existing installs.
    local -a srcs=("$source" "$tmp/config" "$tmp/service" "$tmp/dump-service" "$tmp/udev")
    local -a dsts=("$TARGET" "$CONFIG" "$SERVICE" "$DUMP_SERVICE" "$UDEV_RULE")
    local i
    for i in "${!srcs[@]}"; do
        if [[ -e "${dsts[i]}" ]] && ! cmp -s -- "${srcs[i]}" "${dsts[i]}"; then
            die "Conflict: ${dsts[i]} already exists with different content. No changes made."
        fi
    done
    install -d -m 0700 -- "$STORE" "$STORE/sessions" "$STORE/dumps" "$STORE/reports" "$RUNTIME"
    install_safe "$source" "$TARGET" 0755
    install_safe "$tmp/config" "$CONFIG" 0644
    install_safe "$tmp/service" "$SERVICE" 0644
    install_safe "$tmp/dump-service" "$DUMP_SERVICE" 0644
    install_safe "$tmp/udev" "$UDEV_RULE" 0644
    systemctl daemon-reload
    udevadm control --reload
    say 'Installed. Logger remains stopped; udev dump capture rule is armed.'
    say "Storage: $STORE"
)
read_num() {
    local value=''
    if [[ -r "$1" ]] && IFS= read -r -t 0.25 value < "$1" 2>/dev/null && [[ "$value" =~ ^[0-9]+$ ]]; then
        printf '%s' "$value"
    else
        printf NA
    fi
}
read_text() {
    local value=''
    if [[ -r "$1" ]] && IFS= read -r -t 0.25 value < "$1" 2>/dev/null; then
        value=${value//$'\t'/ }
        printf '%s' "${value:-NA}"
    else
        printf NA
    fi
}
sample_gpu() {
    local stamp dev hwmon h bdf busy membusy vram gtt t1 t2 t3 power cap fan gfx mem speed width
    local found=0
    stamp=$(date -u +'%Y-%m-%dT%H:%M:%S.%3NZ')
    while IFS= read -r dev; do
        [[ -n "$dev" ]] || continue
        found=1
        bdf=${dev##*/}
        hwmon=/sys/no-hwmon
        for h in "$dev"/hwmon/hwmon*; do [[ -d "$h" ]] && { hwmon="$h"; break; }; done
        busy=$(read_num "$dev/gpu_busy_percent")
        membusy=$(read_num "$dev/mem_busy_percent")
        vram=$(read_num "$dev/mem_info_vram_used")
        gtt=$(read_num "$dev/mem_info_gtt_used")
        t1=$(read_num "$hwmon/temp1_input")
        t2=$(read_num "$hwmon/temp2_input")
        t3=$(read_num "$hwmon/temp3_input")
        power=$(read_num "$hwmon/power1_average")
        [[ "$power" == NA ]] && power=$(read_num "$hwmon/power1_input")
        cap=$(read_num "$hwmon/power1_cap")
        fan=$(read_num "$hwmon/fan1_input")
        gfx=$(read_num "$hwmon/freq1_input")
        mem=$(read_num "$hwmon/freq2_input")
        speed=$(read_text "$dev/current_link_speed")
        width=$(read_text "$dev/current_link_width")
        printf '%s' "$stamp"
        printf '\t%s' "$bdf" "$busy" "$membusy" "$vram" "$gtt" \
           "$t1" "$t2" "$t3" "$power" "$cap" "$fan" "$gfx" "$mem" "$speed" "$width"
        printf '\n'
    done < <(gpu_devices)
    if ((found == 0)); then
        printf '%s\tGPU_MISSING' "$stamp"
        printf '\tNA%.0s' {1..14}
        printf '\n'
    fi
}
snapshot() {
    {
        printf 'CTHULHU GPU BLACKBOX SNAPSHOT\n'
        date --iso-8601=seconds
        uname -a
        printf '\nBOOT_ID\n'; cat /proc/sys/kernel/random/boot_id
        printf '\nKERNEL_CMDLINE\n'; cat /proc/cmdline
        printf '\nSTORAGE\n'; findmnt --mountpoint "$MOUNT" -o SOURCE,FSTYPE,OPTIONS,TARGET
        printf '\nGPU_PCI\n'
        if command -v lspci >/dev/null 2>&1; then lspci -nnk -d 1002:; fi
        printf '\nPACKAGES (Arch if available)\n'
        if command -v pacman >/dev/null 2>&1; then
            pacman -Q linux linux-firmware mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon 2>&1 || true
        fi
        printf '\nHWMON LABELS\n'
        local d f
        while IFS= read -r d; do
            for f in "$d"/hwmon/hwmon*/temp*_label; do
                [[ -r "$f" ]] && printf '%s: %s\n' "$f" "$(cat "$f")"
            done
        done < <(gpu_devices)
    } > "$1"
}
capture_one() {
    local node="$1" name id stamp out tmp info failing=unknown fd rc
    [[ -r "$node/data" ]] || return 0
    require_mount
    install -d -m 0700 -- "$STORE/dumps" "$RUNTIME"
    exec {fd}>"$RUNTIME/dump.lock"
    if ! flock -w 5 "$fd"; then
        warn "Another capture is in progress: $node"
        exec {fd}>&-
        return 0
    fi
    [[ -r "$node/data" ]] || { exec {fd}>&-; return 0; }
    name=${node##*/}
    id=$(stat -Lc '%D_%i_%Y' -- "$node/data" 2>/dev/null || true)
    [[ -n "$id" ]] || id="unknown_$name"
    id=${id//[^A-Za-z0-9_]/_}
    if [[ -e "$RUNTIME/$id.seen" ]]; then exec {fd}>&-; return 0; fi
    stamp=$(date -u +'%Y%m%dT%H%M%SZ')
    out="$STORE/dumps/${stamp}_${name}_${id}.dump"
    tmp="$out.partial"
    info="$out.info"
    if [[ -e "$node/failing_device" ]]; then
        failing=$(readlink -f "$node/failing_device" 2>/dev/null || printf unavailable)
    fi
    {
        printf 'captured_utc=%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        printf 'source=%s/data\n' "$node"
        printf 'failing_device=%s\n' "$failing"
        printf 'kernel=%s\n' "$(uname -r)"
        printf 'host=%s\n' "$(cat /proc/sys/kernel/hostname)"
    } > "$info"
    if timeout --signal=TERM --kill-after=5s 90s cat -- "$node/data" > "$tmp"; then
        mv -- "$tmp" "$out"
        printf 'complete=yes\nbytes=%s\n' "$(stat -c '%s' "$out")" >> "$info"
        say "Saved devcoredump: $out"
    else
        rc=$?
        if [[ -s "$tmp" ]]; then
            printf 'complete=no\nexit_code=%s\n' "$rc" >> "$info"
            warn "Only partial dump saved: $tmp"
        else
            rm -f -- "$tmp"
            printf 'complete=no\nexit_code=%s\nbytes=0\n' "$rc" >> "$info"
            warn "Could not read dump: $node/data"
        fi
    fi
    [[ -e "$out" ]] && printf '%s\n' "$out" > "$RUNTIME/$id.seen"
    sync -d "$info" 2>/dev/null || true
    [[ ! -e "$out" ]] || sync -d "$out" 2>/dev/null || true
    exec {fd}>&-
}
capture_scan() {
    local d
    for d in /sys/class/devcoredump/devcd* /sys/class/drm/card[0-9]*/device/devcoredump; do
        [[ -r "$d/data" ]] && capture_one "$d" || true
    done
}
capture_cmd() {
    root_only
    if [[ -n "${1:-}" ]]; then
        [[ "$1" =~ ^devcd[0-9]+$ ]] || die 'Invalid devcoredump name.'
        capture_one "/sys/class/devcoredump/$1"
    else
        capture_scan
    fi
}
daemon() {
    root_only
    require_mount
    local bootid stamp session telemetry kernel follower n=0 free_kb
    bootid=$(cat /proc/sys/kernel/random/boot_id)
    stamp=$(date -u +'%Y%m%dT%H%M%SZ')
    session="$STORE/sessions/${stamp}_${bootid}"
    install -d -m 0700 -- "$session" "$RUNTIME"
    telemetry="$session/telemetry.tsv"
    kernel="$session/kernel.log"
    printf 'utc_timestamp\tpci_bdf\tgpu_busy_pct\tmem_busy_pct\tvram_used_bytes\tgtt_used_bytes\ttemp1_mC\ttemp2_mC\ttemp3_mC\tpower_uW\tpower_cap_uW\tfan_rpm\tgfx_clock_hz\tmem_clock_hz\tpcie_link_speed\tpcie_link_width\n' > "$telemetry"
    snapshot "$session/snapshot.txt"
    printf '%s\n' "$session" > "$STORE/current-session"
    journalctl -k --boot --no-pager --output=short-iso-precise --lines=500 > "$kernel" 2>&1 || true
    journalctl -k --boot --follow --no-pager --output=short-iso-precise --lines=0 >> "$kernel" 2>&1 &
    follower=$!
    trap 'kill "$follower" 2>/dev/null || true; wait "$follower" 2>/dev/null || true' EXIT
    trap 'exit 0' INT TERM
    say "Recording: $session"
    while :; do
        require_mount
        sample_gpu >> "$telemetry"
        if ((n % 3 == 0)); then capture_scan; fi
        if ((n % 5 == 0)); then sync -d "$telemetry" "$kernel" 2>/dev/null || true; fi
        if ((n % 30 == 0)); then
            free_kb=$(df -k --output=avail "$MOUNT" | tail -n 1 | tr -d '[:space:]')
            if [[ "$free_kb" =~ ^[0-9]+$ ]] && ((free_kb < 5242880)); then
                die 'Less than 5 GiB left on storage; stopping logger.'
            fi
        fi
        if ! kill -0 "$follower" 2>/dev/null; then
            warn 'Kernel journal follower exited; restarting.'
            wait "$follower" 2>/dev/null || true
            journalctl -k --boot --follow --no-pager --output=short-iso-precise --lines=0 >> "$kernel" 2>&1 &
            follower=$!
        fi
        ((n+=1))
        sleep 1
    done
}
start_cmd() {
    root_only
    require_mount
    [[ -x "$TARGET" ]] || die 'Install first.'
    systemctl enable --now cthulhu-gpu-blackbox.service
    say 'Logger enabled and started. udev dump collector remains active independently.'
}
stop_cmd() {
    root_only
    systemctl disable --now cthulhu-gpu-blackbox.service
    say 'Logger stopped and disabled. udev dump rule is still active.'
}
status_cmd() {
    systemctl --no-pager --full status cthulhu-gpu-blackbox.service || true
    findmnt --mountpoint "$MOUNT" -o SOURCE,FSTYPE,TARGET || true
    if [[ -r "$STORE/current-session" ]]; then
        printf 'Last session: '; cat "$STORE/current-session"
    fi
    if [[ -d "$STORE/dumps" && -r "$STORE/dumps" ]]; then
        printf 'Complete dumps: '
        find "$STORE/dumps" -maxdepth 1 -type f -name '*.dump' | wc -l
    fi
}
report_cmd() {
    root_only
    require_mount
    local session out
    session=$(find "$STORE/sessions" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)
    [[ -d "$session" ]] || die 'No session yet.'
    install -d -m 0700 -- "$STORE/reports"
    out="$STORE/reports/$(date -u +'%Y%m%dT%H%M%SZ')_report.txt"
    {
        printf 'CTHULHU GPU BLACKBOX REPORT\n'
        printf 'Created: %s\nSession: %s\n\n' "$(date --iso-8601=seconds)" "$session"
        printf '=== START SNAPSHOT ===\n'
        cat "$session/snapshot.txt" 2>/dev/null || true
        printf '\n=== RELEVANT KERNEL MESSAGES ===\n'
        grep -iE 'amdgpu|drm|gpu fault|page fault|ring.*timeout|device lost|pcie|aer|iommu|nvme|ata[0-9]|reset|SQC|PERMISSION_FAULTS|GPUVM|GCVM' \
            "$session/kernel.log" 2>/dev/null | tail -n 150 || true
        printf '\n=== LAST TELEMETRY SAMPLES ===\n'
        tail -n 120 "$session/telemetry.tsv" 2>/dev/null || true
        printf '\n=== CAPTURED DUMPS ===\n'
        find "$STORE/dumps" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.partial' -o -name '*.info' \) \
            -printf '%TY-%Tm-%Td %TH:%TM:%TS %s bytes %p\n' 2>/dev/null | sort || true
        printf '\nA full hardlock can prevent the final samples from reaching disk.\n'
    } > "$out"
    sync -d "$out" 2>/dev/null || true
    say "Report: $out"
}
uninstall_cmd() {
    root_only
    [[ -e "$TARGET" ]] || die 'No installed program.'
    grep -Fq '# Cthulhu GPU Blackbox' "$TARGET" || die 'Unrecognized executable; refusing removal.'
    local f
    for f in "$SERVICE" "$DUMP_SERVICE"; do
        if [[ -e "$f" ]] && ! grep -Fq 'Description=Cthulhu GPU Blackbox' "$f"; then
            die "Unrecognized service: $f"
        fi
    done
    if [[ -e "$UDEV_RULE" ]] && ! grep -Fq 'cthulhu-gpu-blackbox-dump@%k.service' "$UDEV_RULE"; then
        die 'Unrecognized udev rule.'
    fi
    if [[ -e "$CONFIG" ]] && ! grep -Fq '# Cthulhu GPU Blackbox configuration' "$CONFIG"; then
        die 'Unrecognized configuration file.'
    fi
    systemctl disable --now cthulhu-gpu-blackbox.service 2>/dev/null || true
    rm -f -- "$TARGET" "$SERVICE" "$DUMP_SERVICE" "$UDEV_RULE" "$CONFIG"
    systemctl daemon-reload
    udevadm control --reload
    say "Uninstalled. Captured data remains untouched at $STORE"
}
usage() {
    cat <<HELP
Cthulhu GPU Blackbox v1.1 — AMDGPU / systemd (Arch tested)
Mount: $MOUNT
Storage: $STORE

preflight     Read-only checks of tools, GPU and separate mount
install       Install executable, root config, services and udev rule (logger stays off)
start         Start logger now; enable on subsequent boots
stop          Stop logger; disable it at boot (udev capture remains active)
status        Service and mount status
report        Summarize the latest recorded session
uninstall     Remove installed components; never delete recordings

Root-required internal commands: daemon, capture [devcdN]
To choose a different disk BEFORE installing:
  sudo env BLACKBOX_MOUNT=/mnt/YourDisk bash ./cthulhu-gpu-blackbox.sh preflight
  sudo env BLACKBOX_MOUNT=/mnt/YourDisk bash ./cthulhu-gpu-blackbox.sh install
HELP
}
case "${1:-help}" in
    preflight) preflight ;;
    install) install_blackbox ;;
    start) start_cmd ;;
    stop) stop_cmd ;;
    status) status_cmd ;;
    report) report_cmd ;;
    uninstall) uninstall_cmd ;;
    daemon) daemon ;;
    capture) capture_cmd "${2:-}" ;;
    help|-h|--help) usage ;;
    *) usage; exit 2 ;;
esac
