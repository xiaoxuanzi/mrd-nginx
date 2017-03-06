-- Copyright (C) 2015-2016, UPYUN Inc.

local cjson  = require "cjson.safe"
local consul = require "modules.consul"
local mload  = require "modules.load"

slardar = require "config" -- global config variable

slardar.global.version = "1.0.0"

local no_consul = slardar.global.no_consul

-- if init config failed, abort -t or reload.
local ok, init_ok = pcall(consul.init, slardar)
if no_consul ~= true then
    if not ok then --表示pcall 捕获到了 错误
        error("Init config failed, " .. init_ok .. ", aborting !!!!")
    elseif not init_ok then ----表示 consul.init 失败，虽然是正常的返回
        error("Init config failed, aborting !!!!")
    end
end

--[[
setmetatable(slardar, {
    __index = consul.load_config,
})
--]]
