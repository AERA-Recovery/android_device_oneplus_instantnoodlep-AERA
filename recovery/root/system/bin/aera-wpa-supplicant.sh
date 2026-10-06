#!/system/bin/sh

# The QCA6390 interface appears only after AERA's post-decrypt module loader
# finishes. Keep init's service alive while that happens so the generic WLAN
# host can wait for the real control socket instead of timing out early.
attempt=0
while [ ! -e /sys/class/net/wlan0 ] && [ "$attempt" -lt 55 ]; do
    sleep 1
    attempt=$((attempt + 1))
done

[ -e /sys/class/net/wlan0 ] || exit 1

exec /system/bin/wpa_supplicant \
    -Dnl80211 \
    -iwlan0 \
    -dd \
    -O/tmp/recovery/sockets \
    -c/vendor/etc/wifi/wpa_supplicant.conf
