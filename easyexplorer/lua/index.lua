local nixio = require "nixio"
local ksutil = require "luci.ksutil"

module("luci.controller.apps.easyexplorer.index", package.seeall)

function index()
	entry({"apps", "easyexplorer"}, call("action_index"))
    entry({"apps", "easyexplorer", "mounts"}, call("action_mounts"))
end

function action_index()
    ksutil.shell_action("easyexplorer")
end

local function mounts()
    local data = {}
    local k = {"fs", "blocks", "used", "available", "percent", "mountpoint"}
    local ps = luci.util.execi("df")

    if not ps then
        return
    else
        ps()
    end

    for line in ps do
        local row = {}

        local j = 1
        for value in line:gmatch("[^%s]+") do
            row[k[j]] = value
            j = j + 1
        end

        if row[k[1]] then

            -- this is a rather ugly workaround to cope with wrapped lines in
            -- the df output:
            --
            --  /dev/scsi/host0/bus0/target0/lun0/part3
            --                   114382024  93566472  15005244  86% /mnt/usb
            --

            if not row[k[2]] then
                j = 2
                line = ps()
                for value in line:gmatch("[^%s]+") do
                    row[k[j]] = value
                    j = j + 1
                end
            end

            table.insert(data, row)
        end
    end

    return data
end

function action_mounts()
    http.prepare_content("application/json; charset=UTF-8")
    local mount_points = mounts()
    local js = ksutil.stringify(mount_points)
    http.write(js)
end
