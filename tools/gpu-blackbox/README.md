# 🐙 Cthulhu GPU Blackbox v1.1

**A small local flight recorder for AMDGPU hangs on Linux.** It records kernel messages and GPU sensors every second and attempts to preserve kernel `devcoredump` data on a *separately mounted* filesystem, even if X11/the game session stops responding.

**Status:** field-tested on **Arch Linux / systemd / Radeon RX 9060 XT (Navi 44)** on 21 October 2026. During a S.T.A.L.K.E.R. 2 reload freeze, the kernel logged a GFXHUB permission fault and `gfx_0.0.0` ring timeout, and the collector automatically saved a **423,438-byte** AMDGPU coredump (`complete=yes`). **Other GPUs/distros are not yet proven. This does not fix GPU bugs.**

[German case study](https://www.dennishilk.com/de/blog/rx-9060-xt-linux-abstuerze/#blackbox-20261021) · [English case study](https://www.dennishilk.com/blog/rx-9060-xt-linux-crashes/#blackbox-20261021)

## What it does

- Independently follows the kernel journal via `journalctl -k --follow` (plus up to 500 earlier boot lines).
- Reads AMDGPU sensor files from sysfs every second: utilization, VRAM and GTT, temperature, power, clock rates, PCIe link speed and width when available.
- Uses a udev-triggered systemd service to copy kernel `/sys/class/devcoredump/devcd*/data` immediately; the normal daemon scans for remaining dumps every three seconds as a fallback.
- Uses restricted root-owned storage (permissions `0700`), `flock` to serialize collectors, and a sidecar `.info` file describing whether the copy finished.
- Produces a text `report` that can be inspected after a reboot.
- Never modifies kernel arguments, Mesa, firmware, GPU settings, game files, X11 or Wayland configuration.

**Limits:** total hardlocks can interrupt file writes. A devcoredump exists only when the kernel actually creates one; `complete=yes` indicates a completed read, not an expert interpretation of the dump. This version's udev trigger covers **all Linux devcoredump events**, not solely AMDGPU, and the output may include sensitive system details. **Review/sanitize before sharing any report or coredump.** Nothing is transmitted automatically. Recordings are not auto-deleted; at under 5 GiB remaining, the logger stops. Storage should be chosen with sufficient free space.

## Requirements

Linux with systemd, udev, a supported amdgpu-bound DRM device, Bash, `journalctl`, `flock`, standard coreutils/util-linux and a **separately mounted writable volume** (ext4 works). `lspci` and `pacman` are optional: they only enrich the snapshot. No Python and no extra daemon are required.

## Setup (review every step)

Download or clone the repository, **read the script**, and run these actions **one at a time**, inspecting output before proceeding.

1. Choose a mounted disk. Default: `/mnt/Homelab`. This path is *only the author's default*, not a device to be formatted or created by this tool.
2. Run `bash cthulhu-gpu-blackbox.sh preflight`. If using a different mount, run `sudo env BLACKBOX_MOUNT=/mnt/YourDisk bash cthulhu-gpu-blackbox.sh preflight` instead.
3. On successful preflight, install with `sudo bash cthulhu-gpu-blackbox.sh install`; for a nondefault mount, use `sudo env BLACKBOX_MOUNT=/mnt/YourDisk bash cthulhu-gpu-blackbox.sh install`. This writes a root-owned mount configuration at `/etc/cthulhu-gpu-blackbox.conf` for subsequent commands and services. It **does not start the continuous logger**; the udev dump collector is armed.
4. Inspect the installed systemd units; then run `sudo cthulhu-gpu-blackbox start`. This enables and starts the logger across boots.
5. Use `sudo cthulhu-gpu-blackbox status` and `sudo cthulhu-gpu-blackbox report` to check and summarize stored evidence.
6. `sudo cthulhu-gpu-blackbox stop` stops the permanent logger but **leaves the udev collector armed**. `sudo cthulhu-gpu-blackbox uninstall` removes our executable, config, units and udev rule but **never removes log files**.

**Existing installations:** `install` refuses to overwrite different copies. Do not blindly replace a running installation: back up the existing file, inspect any local modifications, stop the service, and perform a deliberate migration. If upgrading from the original Cthulhu-only v1.0, note the new external config file and unit paths.

**Important:** Do not run the above commands as a batch. A normal user should not need to change anything under `/etc/portage`, `/etc/default`, or the GPU driver stack. Avoid triggering a crash merely to test this tool.

## Storage layout

`/mnt/YourDisk/Cthulhu-GPU-Blackbox/` (or the default mounted disk):

- `sessions/<UTC start>_<boot ID>/snapshot.txt` — host, boot ID, kernel, PCI and available package versions
- `sessions/<...>/kernel.log` — kernel journal before and during the session
- `sessions/<...>/telemetry.tsv` — tab-separated samples (16 fields)
- `dumps/*.dump` — preserved device dumps; `*.dump.info` — capture result; `*.partial` — incomplete copies
- `reports/*_report.txt` — recent findings compiled into one file

The logger will record a `GPU_MISSING` row when the GPU device is no longer visible. Timestamps in the TSV and dump filenames are **UTC**, while `journalctl` lines include local offsets.

## Example: observed RX 9060 XT crash (21 Oct 2026)

**Arch 7.2.11 / Mesa RADV 26.2.5 / Proton 11.0.2 / S.T.A.L.K.E.R. 2**

| Local time (CEST) | Observation |
| --- | --- |
| 20:11:46 | GPU utilization fell from 65% to 1% |
| 20:11:47 | `[gfxhub] page fault`; `SQC (data)`; `PERMISSION_FAULTS: 0x3`; `0x00701431` |
| 20:11:49 | Kernel created coredump; `gfx_0.0.0` ring timeout; ring reset succeeded |
| 20:11:49 | Collector saved 423,438 bytes to separate NVMe (`complete=yes`) |
| Afterward | TTY2 remained accessible; game still frozen |

The matched dump names `GameThread` / `vkd3d_queue`, PASID 79, VMID 7 and the same fault address `0x000080000e000000`. GPU temperature stayed about 56–57 °C and VRAM use was about 5.6–6.0 GiB across this short interval. No clear thermal or VRAM-capacity failure. **Root cause is still unknown.**

A separately reported RX 9070 XT problem in [VKD3D-Proton issue #3221](https://github.com/HansKristian-Work/vkd3d-proton/issues/3221) has a remarkably similar kernel signature, but no common root cause has been established. A recoverable ring timeout must not be equated with Cthulhu's earlier black-screen/full-fan hardlocks.

## Technical and privacy notes

- The service is independent of the desktop and runs as root only to read protected kernel/sysfs paths. It uses `ProtectSystem=strict` and limits write access to the configured log directory and its private runtime directory.
- The collector can read the kernel-owned coredump even when the original PCIe device has vanished, **provided the devcoredump sysfs node remains accessible**.
- Capture time is limited to 90 seconds; truncated copies are retained with a `.partial` suffix for inspection. Log persistence does **not** guarantee the final seconds survive a power loss/hardlock.
- Uploaded logs, dumps, and snapshots can reveal hostnames, directory names, process identifiers and other potentially sensitive information. **Do not publish raw dumps without reviewing them.**
- The tool is a debugging aid, not evidence that a particular GPU, driver, vendor or application is defective.

## License

MIT — see the repository's [LICENSE](../../LICENSE).

Contributions and carefully documented failure reports are welcome.
