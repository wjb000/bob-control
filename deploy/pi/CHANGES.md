# bob-net changes, 2026-11-03 (performance/reliability pass). Undo commands are exact.
Backups in this dir: etc-systemd-system-20261103.tgz (all of /etc/systemd/system + /etc/NetworkManager/conf.d before changes),
40-rpi-volatile-storage.conf (Pi OS journald default, untouched), unit-enable-state-before-20261103.txt.
Source of truth for the new files: bob-control repo, deploy/pi/.

## 1. Wi-Fi power save off
Added /etc/NetworkManager/conf.d/90-bob-wifi-powersave.conf and bob-wifi-powersave-off.service (enabled); ran `iw dev wlan0 set power_save off`.
UNDO: sudo systemctl disable --now bob-wifi-powersave-off.service; sudo rm /etc/systemd/system/bob-wifi-powersave-off.service /etc/NetworkManager/conf.d/90-bob-wifi-powersave.conf; sudo systemctl daemon-reload; sudo nmcli general reload; sudo iw dev wlan0 set power_save on

## 2. Persistent journal
Added /etc/systemd/journald.conf.d/90-bob-persistent.conf (Storage=persistent, SystemMaxUse=200M, SystemKeepFree=2G, MaxRetentionSec=1month). /var/log/journal already existed.
UNDO: sudo rm /etc/systemd/journald.conf.d/90-bob-persistent.conf; sudo systemctl restart systemd-journald   (optional: sudo rm -rf /var/log/journal/*/)

## 3. Boot: units disabled / delayed
sudo systemctl disable NetworkManager-wait-online.service   (HMI now waits for NM itself, see 4)
sudo systemctl disable --now ModemManager.service           (no modems; it also probes serial ports)
sudo systemctl disable --now cups.service cups.socket cups.path cups-browsed.service
sudo systemctl disable --now nfs-blkmap.service rpcbind.service rpcbind.socket   (no NFS in fstab; closes :111)
sudo touch /etc/cloud/cloud-init.disabled                   (first-boot provisioning long done)
apt-daily(.upgrade).timer.d/50-bob-no-boot-catchup.conf: Persistent=false (no apt run right at boot)
UNDO: sudo systemctl enable NetworkManager-wait-online.service ModemManager.service cups.service cups.socket cups.path cups-browsed.service nfs-blkmap.service rpcbind.service rpcbind.socket
      sudo rm /etc/cloud/cloud-init.disabled
      sudo rm -r /etc/systemd/system/apt-daily.timer.d/50-bob-no-boot-catchup.conf /etc/systemd/system/apt-daily-upgrade.timer.d/50-bob-no-boot-catchup.conf; sudo systemctl daemon-reload
      (then start the ones you want now: sudo systemctl start ModemManager cups cups-browsed rpcbind)

## 4. Restart/reliability drop-ins (50-bob-reliability.conf)
bob-hmi: ExecStartPre=-nm-online -s -q -t 30, Restart=always, RestartSec=2, StartLimit 10/120s, Nice=-5, CPUWeight=400, IOWeight=400 (applies at next HMI start; CPUWeight/IOWeight also set live with --runtime; nice -5 applied live via renice)
bob-brain, bob-lights, bob-detect-lite, bob-search: Restart=always, RestartSec=3, StartLimit 10/300s
bob-funnel, bob-tunnel-boot: Restart=always, RestartSec=10, StartLimitIntervalSec=0 (never give up)
ollama: Restart=always, RestartSec=3, StartLimit 10/300s, Nice=5, CPUWeight=50 (live: --runtime CPUWeight=50 + renice 5)
UNDO: sudo rm /etc/systemd/system/{bob-hmi,bob-brain,bob-lights,bob-detect-lite,bob-search,bob-funnel,bob-tunnel-boot,ollama}.service.d/50-bob-reliability.conf; sudo rm -rf /run/systemd/system.control/bob-hmi.service.d /run/systemd/system.control/ollama.service.d; sudo systemctl daemon-reload
      (live nice values reset on the next restart of each service)

## 5. Health-check timer
/usr/local/sbin/bob-healthcheck.sh + bob-healthcheck.service + bob-healthcheck.timer (every 30 s, enabled). Probes GET-only endpoints
(:8080/login, :8095/health, :8096/state, :8097/health, :8098/health, :8090/health (user unit bob-voice), :11434/api/version, :20241/ready);
starts failed/inactive units (reset-failed), restarts a unit after 3 (HMI/tunnel: 4) consecutive failed probes if up > 120 s. Log: journalctl -t bob-healthcheck
UNDO: sudo systemctl disable --now bob-healthcheck.timer; sudo rm /etc/systemd/system/bob-healthcheck.{service,timer} /usr/local/sbin/bob-healthcheck.sh; sudo systemctl daemon-reload

## FULL ROLLBACK (everything above)
sudo tar xzf /home/bob/bob-net-backups/etc-systemd-system-20261103.tgz -C /   # restores old unit files/symlinks (does not delete new files)
then run every UNDO line above.
