# deploy/pi: Bob (Raspberry Pi 5) system tuning, 2026-11-03

systemd drop-ins, health-check timer, journald and NetworkManager config installed on Bob.
These files don't touch any service code. CHANGES.md lists what was applied and the exact undo commands
(the Pi keeps its copy at /home/bob/bob-net-backups/CHANGES.md).

Install (on the Pi, from a checkout of this folder):
    for d in systemd/*.d; do sudo install -d /etc/systemd/system/$(basename $d); sudo install -m644 $d/* /etc/systemd/system/$(basename $d)/; done
    sudo install -m644 systemd/bob-healthcheck.{service,timer} systemd/bob-wifi-powersave-off.service /etc/systemd/system/
    sudo install -m755 sbin/bob-healthcheck.sh /usr/local/sbin/
    sudo install -D -m644 journald/90-bob-persistent.conf /etc/systemd/journald.conf.d/90-bob-persistent.conf
    sudo install -m644 networkmanager/90-bob-wifi-powersave.conf /etc/NetworkManager/conf.d/
    sudo systemctl daemon-reload && sudo systemctl enable --now bob-healthcheck.timer bob-wifi-powersave-off.service
    sudo systemctl restart systemd-journald
