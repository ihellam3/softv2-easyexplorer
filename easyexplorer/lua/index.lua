local nixio = require "nixio"
local http = require "luci.http"
local ksutil = require "luci.ksutil"

module("luci.controller.apps.easyexplorer.index", package.seeall)

function index()
	entry({"apps", "easyexplorer"}, call("action_index"))
	entry({"apps", "easyexplorer", "status"}, call("action_status"))
end

function action_index()
    ksutil.shell_action("easyexplorer")
end

function action_easyexplorer_status()
    http.prepare_content("text/plain; charset=utf-8")
    reader = ksutil.popen("/koolshare/scripts/easyexplorer-config.sh status", nil)
    luci.ltn12.pump.all(reader, luci.http.write)
end
