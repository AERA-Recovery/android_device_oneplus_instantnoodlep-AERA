#!/system/bin/sh

module_name=qca_cld3_qca6390.ko
module=/system/lib/modules/kona/$module_name
ready=/tmp/aera-wlan-prepared

if [ "$1" = "load" ]; then
    if [ ! -r "$module" ]; then
        echo "AERA WLAN: bundled module is missing: $module" >&2
        exit 1
    fi

    while [ ! -f "$ready" ]; do
        sleep 1
    done

    if ! grep -q '^wlan ' /proc/modules; then
        # Match the stock boot order: register the host driver first, then
        # let CNSS start calibration after module initialization has settled.
        insmod "$module" &
        module_pid=$!

        # The driver delays registration internally. Starting calibration on
        # a fixed timer can race MHI initialization, so wait for initstate.
        for attempt in 1 2 3 4 5; do
            [ "$(cat /sys/module/wlan/initstate 2>/dev/null)" = "live" ] && break
            sleep 1
        done

        setprop sys.aera.cnss.data_ready 1
        wait "$module_pid"
        exit $?
    fi

    setprop sys.aera.cnss.data_ready 1
    exit 0
fi

rm -f "$ready"

# Device-encrypted vendor data becomes available before credential unlock.
# Wait outside init's main thread so WLAN preparation never delays recovery.
while [ ! -d /data/vendor/wifi ]; do
    sleep 1
done

socket_dir=/data/vendor/wifi/sockets
runtime_socket_dir=/tmp/aera-cnss-sockets

mkdir -p "$socket_dir" "$runtime_socket_dir"
rm -f "$socket_dir/cnss_user_server" "$socket_dir/cnss_user_client"
chmod 0770 "$runtime_socket_dir"

# cnss-daemon does not unlink its socket when recovery reboots abruptly. Keep
# its runtime files in tmpfs so Android never inherits a dead root-owned socket
# that prevents the stock daemon from starting.
if ! grep -q " $socket_dir " /proc/mounts; then
    mount -o bind "$runtime_socket_dir" "$socket_dir" || exit 1
fi

# The post-decrypt loader must not start CNSS before its socket bind is ready.
: > "$ready"
