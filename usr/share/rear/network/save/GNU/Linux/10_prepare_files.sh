### Networking code
### stores information in $VAR_DIR/network/

LogPrint "Saving network information."

mkdir -p $VAR_DIR/network >&2

NET_FILE=$VAR_DIR/network/network.conf
: > $NET_FILE
