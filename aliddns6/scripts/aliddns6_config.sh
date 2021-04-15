#!/bin/sh

if [ "`dbus get aliddns6_enable`" = "1" ]; then
    dbus delay aliddns6_timer `dbus get aliddns6_interval` /koolshare/scripts/aliddns6_update.sh
else
    dbus remove __delay__aliddns6_timer
fi
