#!/system/bin/sh

module_name=qca_cld3_qca6390.ko
module=/system/lib/modules/kona/$module_name
socket_dir=/data/vendor/wifi/sockets
runtime_socket_dir=/tmp/aera-cnss-sockets

wifi_data_ready() {
    grep -qE '^[^ ]+ /data (ext4|f2fs) ' /proc/mounts &&
        [ -d /data/vendor/wifi ]
}

socket_mount_ready() {
    grep -q " $socket_dir " /proc/mounts || return 1
    source_id=$(stat -Lc '%d:%i' "$runtime_socket_dir") || return 1
    target_id=$(stat -Lc '%d:%i' "$socket_dir") || return 1
    [ "$source_id" = "$target_id" ]
}

remove_socket() {
    if [ -L "$1" ]; then
        echo "AERA WLAN: refusing symlink socket: $1" >&2
        return 1
    fi
    if [ -S "$1" ]; then
        rm -f "$1"
    elif [ -e "$1" ]; then
        echo "AERA WLAN: refusing non-socket file: $1" >&2
        return 1
    fi
}

prepare_sockets() {
    wifi_data_ready || return 1
    [ ! -L "$socket_dir" ] && [ ! -L "$runtime_socket_dir" ] || return 1
    mkdir -p "$socket_dir" "$runtime_socket_dir" || return 1
    chmod 0770 "$runtime_socket_dir" || return 1

    if ! socket_mount_ready; then
        # Never stack a new bind over an unexpected existing mount.
        if grep -q " $socket_dir " /proc/mounts; then
            echo "AERA WLAN: unexpected socket mount" >&2
            return 1
        fi
        remove_socket "$socket_dir/cnss_user_server" || return 1
        remove_socket "$socket_dir/cnss_user_client" || return 1
        mount -o bind "$runtime_socket_dir" "$socket_dir" || return 1
    fi

    # /data can be remounted during recovery setup. A marker in /tmp does
    # not prove that the bind survived; verify its actual directory identity.
    socket_mount_ready
}

if [ "$1" = "cnss" ]; then
    # Init also uses this entry point on daemon restarts. Do not let CNSS
    # create root-owned, unlabeled sockets on Android's persistent userdata.
    prepare_sockets || exit 1
    remove_socket "$runtime_socket_dir/cnss_user_server" || exit 1
    remove_socket "$runtime_socket_dir/cnss_user_client" || exit 1
    socket_mount_ready || exit 1
    exec /vendor/bin/cnss-daemon -n -l
fi

if [ "$1" = "load" ]; then
    if [ ! -r "$module" ]; then
        echo "AERA WLAN: bundled module is missing: $module" >&2
        exit 1
    fi

    # Only prepare sockets after recovery has finished its decryption setup,
    # not during init's early /data mount/unmount cycle.
    while ! wifi_data_ready; do
        sleep 1
    done
    prepare_sockets || exit 1

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

echo "Usage: $0 load|cnss" >&2
exit 1
