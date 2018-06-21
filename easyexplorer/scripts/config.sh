#!/bin/bash

. /koolshare/scripts/base.sh
. /koolshare/scripts/jshn.sh
. /koolshare/scripts/uci.sh

on_get() {
    easyexplorer_status=`pidof easyexplorer|wc -w`

    INPUT_JSON=`uci export_json easyexplorer`
    json_load "$INPUT_JSON"
    json_select "easyexplorer"
    json_select "1"

    if [ "$easyexplorer_status"x = "2"x ];then
        json_add_string "status" "start"
    else
        json_add_string "status" "stop"
    fi
    json_dump
}

on_post() {
    local easyexplorer_enabled
    local easyexplorer_token

    json_load "$INPUT_JSON"
    json_select "easyexplorer"
    json_select "1"
    json_get_var easyexplorer_enabled "enabled"
    json_get_var easyexplorer_token "token"

    app_log $easyexplorer_enabled
    app_log $easyexplorer_token
    if [ "$easyexplorer_enabled"x = "1"x ]; then
        killall easyexplorer > /dev/null 2>&1
        $APP_ROOT/bin/easyexplorer -u $easyexplorer_token -d > /dev/null 2>&1
        json_add_string "status" ""
        json_dump|app_save_cfg

        # mark as start
        json_add_string "status" "start"
        json_dump
    elif [ "$easyexplorer_enabled"x = "0"x ]; then
        killall easyexplorer > /dev/null 2>&1
        json_add_string "status" ""
        json_dump|app_save_cfg

        # mark as stop
        json_add_string "status" "stop"
        json_dump
    else
        echo '{"status": "json_parse_failed"}'
    fi
}

on_start() {
    local easyexplorer_enabled
    local easyexplorer_token
    config_load easyexplorer
    config_get easyexplorer_enabled main enabled
    config_get easyexplorer_token main token
    if [ "$easyexplorer_enabled"x = "1"x ]; then
        killall easyexplorer > /dev/null 2>&1
        $APP_ROOT/bin/easyexplorer -u $easyexplorer_token -d > /dev/null 2>&1
    else
        killall easyexplorer > /dev/null 2>&1
    fi
}

on_stop() {
    killall easyexplorer > /dev/null 2>&1
}

on_status() {
    easyexplorer_status=`pidof easyexplorer|wc -w`
    easyexplorer_pid=`pidof easyexplorer`
    easyexplorer_version=`$APP_ROOT"/bin/easyexplorer" -v`
    easyexplorer_route_id=`$APP_ROOT"/bin/easyexplorer" -w | awk '{print $2}'`
    if [ "$easyexplorer_status"x = "2"x ];then
        echo 进程运行正常！版本：${easyexplorer_version} 路由器ID：${easyexplorer_route_id} （PID：$easyexplorer_pid）
    else
        echo \<em\>【警告】：进程未运行！\<\/em\> 版本：${easyexplorer_version} 路由器ID：${easyexplorer_route_id}
    fi
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
    ;;
status)
    on_status
    ;;
stop)
    on_stop
    ;;
*)
    on_start
    ;;
esac
