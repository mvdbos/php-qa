#!/bin/sh

setuser() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <path>"
    return
  fi
  CURRENT_UID=`id -u`
  DEST_UID=`stat -c "%u" $1`
  if [ $CURRENT_UID = $DEST_UID ]; then
    return
  fi
  DEST_GID=`stat -c "%g" $1`
  if [ -e /home/$DEST_UID ]; then
    return
  fi
  adduser -g $DEST_GID -u $DEST_UID -D $DEST_UID
  mkdir -p /home/$DEST_UID
  chown $DEST_UID:$DEST_GID /home/$DEST_UID
}
setuser $1
