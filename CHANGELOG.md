# Changelog
## v1.5.0
New **Tailscale** module (optional, install from System > Modules):
- Adds a `tailscale` www2 module. It is **not** installed by default and is never auto-installed on existing devices — operators opt in from the Modules page.
- When installed, a **Tailscale** page appears in www2 to configure it: advertise **subnet routes**, toggle **Tailscale SSH**, and a **Start/Stop switch**. On first start (or until authenticated) the page shows the **setup URL** to log in to your tailnet.
- Runs in **userspace-networking** mode (this ONT has no TUN module): `tailscaled-small --statedir=/config/tailscale-state --tun=userspace-networking --socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055`.
- **Persistence lives on `/config`** (`/config/tailscale-state` for node keys, `/config/tailscale/config.env` for settings), so it survives reflashes and module uninstall — reinstalling keeps the node identity + settings.
- When the switch is **On** it auto-starts on boot via a `BEGIN_TAILSCALE` block appended to `www2/sh/startup.sh` (carried across OTA by `merge_startup_markers`); turning it Off removes that line.
- The module framework (`module_ctl.sh`) is now multi-module: hotspot keeps its auto-migrate-on-existing behavior; tailscale defaults to not-installed. Release CI builds/publishes `lmepisowifi-tailscale-<ver>.tar.gz` and adds it to `modules.txt`.
- The Tailscale binaries keep their upstream **BSD-3-Clause** license: bundled as `tailscale/LICENSE` and recorded in `LICENSES/BSD-3-Clause.txt` + the `_README.md` licensing section (same convention as BusyBox `httpd.c`).

## v1.4.0
Hotspot is now an installable / removable **module** (new "Modules" page under System):
- **System > Modules** installs or uninstalls the whole Hotspot / Piso-Wifi subsystem from GitHub. Downloads are checksum-verified against modules.txt before they are applied — same security model as the base OTA.
- **Existing devices are unaffected.** On the first boot after this update, an already-present hotspot is auto-detected and marked "installed" (nothing is removed, disabled, or re-downloaded).
- **Uninstall keeps your data.** It stops + removes the captive portal, coin acceptor and hotspot admin pages and hides the Hotspot menu + dashboard card, but KEEPS `hotspot_data/` (users, vouchers, income) and the hotspot settings in `globals.env` (uploaded portal logo/promos/audio are preserved too), so a reinstall restores everything.
- **Uninstall persists across base OTA updates.** The base release still ships the hotspot files (so `ota.sh` and every current install keep working); a new `module_ctl.sh reconcile` runs at boot and after each OTA to re-assert the saved state, removing re-laid hotspot files when the module is uninstalled.
- Release CI now also builds + publishes the module asset `lmepisowifi-hotspot-<ver>.tar.gz` and writes `modules.txt` next to `manifest.txt`.

## v1.3.0
Hotspot DHCP + NodeMCU management overhaul (behavior changes — read before updating):
- New **DHCP Settings** page (Hotspot > DHCP Settings): edit the gateway IP, DHCP range (start/end) and DNS servers. Gateway/range changes apply live via the watchdog and re-normalize NodeMCU addresses into the new pool.
- **NodeMCU IPs are now auto-assigned** from the addresses below the DHCP range start (gateway+1 .. start-1) instead of being typed in, and the number of NodeMCUs is capped to that pool (e.g. gateway .1 + start .5 => 3 units: .2 .3 .4). Each unit keeps a stable IP; deleting one frees its address without disturbing the others.
- The **NodeMCUs page now manages the primary unit too** — it can be edited and deleted just like the extras, and units can be reordered (drag / arrows) to control the order shown in the portal's coin-slot picker. Removed the IP and Port fields (port is fixed at 8080 in the firmware).
- Removed the old NodeMCU card from the **Hotspot** page (now titled "Coin Acceptor"); the primary NodeMCU is managed entirely on the NodeMCUs page.
- Removed the **Portal IP** field from the **Interfaces** page — the gateway now lives on the DHCP Settings page (Portal Port stays here).
- Captive portal: **Insert Coin** is hidden when no NodeMCU is configured; **WiFi Rates** now shows whenever rates are set, independent of the coin on/off toggle.
- defaults.env: added DHCP_START, DHCP_END, DHCP_DNS. Existing installs pick these up automatically via seed_globals() (merged into the preserved globals.env on the first boot after update).

## v1.2.14
large update (this might break things), added multiple nodemcu support, fixed the issue of the startup.sh in the www2 not carrying over properly if the startup.sh has new or deleted lines
