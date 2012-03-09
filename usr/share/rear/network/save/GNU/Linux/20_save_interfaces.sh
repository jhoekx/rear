### Show all network interfaces

### records information like:
### interface eth0 mac driver
for sysfs_path in /sys/class/net/* ; do
    device=${sysfs_path#/sys/class/net/}

    ### skip some device types
    case $device in
            (bonding_masters|lo|pan*|sit*|tun*|tap*|vboxnet*|vmnet*)
                Debug "Skipping network device $device."
                continue
                ;;
            (vlan*) Error "$PRODUCT does not yet support 802.1q, please sponsor it!" ;;
    esac

    ### skip devices that are not up
    if ! ip link show dev $device | grep -q UP ; then
        Debug "Skipping $device because it is not UP."
        continue
    fi

    ### get mac address
    mac=$(cat $sysfs_path/address)
    BugIfError "Could not read a MAC address from '$sysfs_path/address'!"

    ### skip fake interfaces without MAC address
    if [[ "$mac" == "00:00:00:00:00:00" ]] ; then
        Debug "Skipping $device because of fake MAC."
        continue
    fi

    ### determine the driver to load, relevant only for non-udev environments
    if [[ -e "$sysfs_path/device/driver" ]]; then
        # this should work for virtio_net, xennet and vmxnet on recent kernels
        driver=$(basename $(readlink $sysfs_path/device/driver))
        if [[ "$driver" ]] && [[ "$driver" = vif ]] ; then
                # xennet driver announces itself as vif :-(
                driver=xennet
        fi
    elif [[ -e "$sysfs_path/driver" ]]; then
        # this should work for virtio_net, xennet and vmxnet on older kernels (2.6.18)
        driver=$(basename $(readlink $sysfs_path/driver))
    elif has_binary ethtool; then
        driver=$(ethtool -i $dev 2>&8 | grep driver: | cut -d: -f2)
    fi

    if [[ "$driver" ]]; then
        if ! grep -q $driver /proc/modules; then
            LogPrint "WARNING: Driver $driver currently not loaded ?"
        fi
        echo "$driver" >>$ROOTFS_DIR/etc/modules
    else
        LogPrint "WARNING:   Could not determine network driver for '$dev'. Please make
WARNING:   sure that it loads automatically (e.g. via udev) or add
WARNING:   it to MODULES_LOAD in $CONFIG_DIR/{local,site}.conf!"
    fi

    echo "interface $device $mac $driver" >> $NET_FILE
done
