#!/bin/sh

cp -r /tmp/aliddns6/* /koolshare/
chmod a+x /koolshare/scripts/aliddns6_*

# add icon into softerware center
dbus set softcenter_module_aliddns6_install=1
dbus set softcenter_module_aliddns6_version=0.6
dbus set softcenter_module_aliddns6_description="阿里云解析自动更新IPv6"
