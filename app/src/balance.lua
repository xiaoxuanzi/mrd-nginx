-- Copyright (C) 2015-2016, UPYUN Inc.

local checkups  = require "resty.checkups.api"
local balancer  = require "ngx.balancer"

local get_last_failure = balancer.get_last_failure
local set_current_peer = balancer.set_current_peer
local set_more_tries = balancer.set_more_tries
local set_timeouts = balancer.set_timeouts

--local skey = ngx.var.host
local skey = ngx.var.uri
skey = string.gsub(skey, '/', '-')
skey = string.sub(skey, 2)
--local skey = ngx.ctx.upstream_name
if not skey then
    return
end

local status, code = get_last_failure()
if status == "failed" then
    local last_peer = ngx.ctx.last_peer
    -- mark last_peer failed
    checkups.feedback_status(skey, last_peer.host, last_peer.port, true)
end

local peer, ok, err
peer, err = checkups.select_peer(skey)
if not peer then
    ngx.log(ngx.ERR, "select peer failed, ", err)
    return
end
ngx.ctx.last_peer = peer

ok, err = set_current_peer(peer.host, peer.port)
if not ok then
    ngx.log(ngx.ERR, "set_current_peer failed, ", err)
    return
end

local connect_timeout, send_timeout, read_timeout
connect_timeout, send_timeout, read_timeout = checkups.get_ups_timeout(skey)
ok, err = set_timeouts(connect_timeout, send_timeout, read_timeout)
if not ok then
    ngx.log(ngx.ERR, "set_timeouts failed, ", err)
    return
end

ok, err = set_more_tries(1)
if not ok then
    ngx.log(ngx.ERR, "set_more_tries failed, ", err)
    return
end
