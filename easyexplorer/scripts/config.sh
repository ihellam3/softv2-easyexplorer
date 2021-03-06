#!/bin/sh

. /koolshare/scripts/base.sh
. /koolshare/scripts/jshn.sh
. /koolshare/scripts/uci.sh

on_get() {
    local easyexplorer_enabled
    local easyexplorer_token
    local easyexplorer_path
    config_load easyexplorer
    config_get easyexplorer_enabled main enabled
    config_get easyexplorer_token main token
    config_get easyexplorer_path main path

    if [ "$easyexplorer_token" == "none" -o "$easyexplorer_token"x == x ]; then
        easyexplorer_token=`uci get luci.main.token`
    fi

    status=`pidof easyexplorer`
    router_id=`$APP_ROOT/bin/easyexplorer -vv`

    echo '{"status":"'$status'","router_id":"'$router_id'","token":"'$easyexplorer_token'","path":"'$easyexplorer_path'","enabled":"'$easyexplorer_enabled'"}'
}

on_post() {
    local easyexplorer_enabled
    local easyexplorer_token
    local easyexplorer_path

    json_load "$INPUT_JSON"
    json_get_var easyexplorer_enabled "enabled"
    json_get_var easyexplorer_token "token"
    json_get_var easyexplorer_path "path"
    uci -q batch <<-EOF
set easyexplorer.main.enabled=${easyexplorer_enabled}
set easyexplorer.main.token=${easyexplorer_token}
set easyexplorer.main.path=${easyexplorer_path}
EOF

    if [ "$easyexplorer_enabled" = "1" ]; then
        killall easyexplorer > /dev/null 2>&1
        start-stop-daemon -S -b -q -x $APP_ROOT/bin/easyexplorer -- -u $easyexplorer_token -share $easyexplorer_path -c /tmp/ee >/dev/null

        uci commit
        on_get
    elif [ "$easyexplorer_enabled" = "0" ]; then
        killall easyexplorer > /dev/null 2>&1

        uci commit
        on_get
    else
        echo '{"status": "json_parse_failed"}'
    fi
}

on_start() {
    local easyexplorer_enabled
    local easyexplorer_token
    local easyexplorer_path
    config_load easyexplorer
    config_get easyexplorer_enabled main enabled
    config_get easyexplorer_token main token
    config_get easyexplorer_path main path
    if [ "$easyexplorer_enabled"x = "1"x ]; then
        killall easyexplorer > /dev/null 2>&1
        start-stop-daemon -S -b -q -x $APP_ROOT/bin/easyexplorer -- -u $easyexplorer_token -share $easyexplorer_path -c /tmp/ee >/dev/null
    else
        killall easyexplorer > /dev/null 2>&1
    fi
}

on_stop() {
    killall easyexplorer > /dev/null 2>&1
}

case $ACTION in
start)
    on_start
    ;;
post)
    on_post
    ;;
get)
    on_get
    ;;
installed)
    app_init_cfg '{"easyexplorer":[{"_id":"main","enabled":"0","token":"none","path":"/tmp/ee"}]}'
    ;;
status)
    on_get
    ;;
stop)
    on_stop
    ;;
*)
    on_start
    ;;
esac

