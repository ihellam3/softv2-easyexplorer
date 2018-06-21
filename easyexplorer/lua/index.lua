local nixio = require "nixio"
local ksutil = require "luci.ksutil"

module("luci.controller.apps.easyexplorer.index", package.seeall)

function index()
	entry({"apps", "easyexplorer"}, call("action_index"))
end

function action_index()
    ksutil.shell_action("easyexplorer")
end
