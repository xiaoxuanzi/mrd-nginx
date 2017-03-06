-- Copyright (C) 2014-2016, UPYUN Inc.

local floor      = math.floor
local str_byte   = string.byte
local tab_sort   = table.sort
local tab_insert = table.insert

local _M = { _VERSION = "0.11" }

local MOD       = 2 ^ 32
local REPLICAS  = 20
local LUCKY_NUM = 13
local strutil = require "strutil"
local to_str = strutil.to_str

local function hash_string(str)
    local key = 0
    for i = 1, #str do
        key = (key * 31 + str_byte(str, i)) % MOD
    end
    return key
end


local function init_consistent_hash_state(servers)
    local weight_sum = 0
    for _, srv in ipairs(servers) do
        weight_sum = weight_sum + (srv.weight or 1)
    end

    local circle, members = {}, 0
    for index, srv in ipairs(servers) do
        local key = ("%s:%s"):format(srv.host, srv.port)
        local base_hash = hash_string(key)
        for c = 1, REPLICAS * weight_sum do
            -- TODO: more balance hash
            local hash = (base_hash * c * LUCKY_NUM) % MOD
            tab_insert(circle, { hash, index })
        end
        members = members + 1
    end

    tab_sort(circle, function(a, b) return a[1] < b[1] end)

    return { circle = circle, members = members }
end


local function binary_search(circle, key)
    local size = #circle
    local st, ed, mid = 1, size
    while st <= ed do
        mid = floor((st + ed) / 2)
        if circle[mid][1] < key then
            st = mid + 1
        else
            ed = mid - 1
        end
    end

    return st == size + 1 and 1 or st
end


function _M.next_consistent_hash_server(servers, peer_cb, hash_key)

    local resty_chash = require"resty.chash"

    local server_list = {}
    for k, v in pairs(servers) do
        local srv = v['host'] .. ':' .. v['port']
        local weight = v['weight'] or 1
        server_list[srv]= weight
    end

    local get_servers_nodes = function( server_list )

        local srvs, nodes = {}, {}
        local str_null = string.char(0)
        for serv, weight in pairs(server_list) do
            local id = string.gsub(serv, ":", str_null)
            srvs[id] = serv
            nodes[id] = weight
        end

        return srvs, nodes
    end

    local get_server = function( servers, id )

        local server_str = servers[id]
        local idx = string.find(server_str,':')
        local host = string.sub(server_str, 1, idx-1)
        local port = string.sub(server_str, idx+1, -1)
        local server = {}
        server['host'] = host
        server['port'] = tonumber(port)
        return server

    end

    local up_servers, up_nodes = get_servers_nodes( server_list )
    local chash_up = resty_chash:new(up_nodes)
    local id, index = chash_up:find(hash_key)
    local dest_server = get_server(up_servers, id)
    local down_index
    local down_servers = {}
    local new_server_list = {}

    for i = 1, #servers do
        if peer_cb( i, dest_server ) then
            return dest_server
       end

        down_index = dest_server['host'] .. ':'  .. dest_server['port']
        down_servers[ down_index ] = true

        new_server_list = {}
        for srv in pairs( server_list ) do
            if down_servers[ srv ] == nil then
                new_server_list[ srv ] = server_list[ srv ]
            end
        end

        up_servers, up_nodes = get_servers_nodes( new_server_list )
        chash_up = resty_chash:new(up_nodes)

        id, index = chash_up:find(hash_key)
        dest_server = get_server(up_servers, id)

    end

    return nil, "consistent hash: no servers available"

end

function _M.free_consitent_hash_server(srv, failed)
    return
end


return _M
