local cjson     = require "cjson.safe"
local http      = require "socket.http"
local checkups  = require "resty.checkups.api"

local tab_insert = table.insert
local tab_concat = table.concat
local str_format = string.format
local str_sub    = string.sub

local strutil = require "strutil"
local to_str = strutil.to_str

local _M = {}


local function parse_body(body)
    local success, data = pcall(cjson.decode, body)
    if not success then
        ngx.log(ngx.ERR, to_str('json decode body failed, ', body))
        return
    else
        return data
    end
end


local function get_servers(cluster, key)
    -- try all the consul servers
    for _, cls in pairs(cluster) do
        for _, srv in pairs(cls.servers) do
            local url = str_format("http://%s:%s/v1/kv/%s", srv.host, srv.port, key)
            local body, code = http.request(url)
            if code == 404 then
                return {}
            elseif code == 200 and body then
                return parse_body(body)
            end
        end
    end
end


function _M.get_script_blocking(cluster, key, need_raw)
    -- try all the consul servers
    for _, cls in pairs(cluster) do
        for _, srv in pairs(cls.servers) do
            local url = str_format("http://%s:%s/v1/kv/%s", srv.host, srv.port, key)
            local body, code = http.request(url)
            if code == 404 then
                return nil
            elseif code == 200 and body then
                if need_raw then
                    return body
                else
                    return parse_body(body)
                end
            else
                ngx.log(ngx.ERR, str_format("get config from %s failed", url))
            end
        end
    end
end

local function check_servers(servers)
    if not servers or type(servers) ~= "table" or not next(servers) then
        return false
    end

    for _, srv in pairs(servers) do
        if not srv.host or not srv.port then
            return false
        end

        if srv.weight and type(srv.weight) ~= "number" or
            srv.max_fails and type(srv.max_fails) ~= "number" or
            srv.fail_timeout and type(srv.fail_timeout) ~= "number" then
            return false
        end
    end

    return true
end


function _M.init(config)
    local consul = config.consul or {}
    local key_prefix = consul.config_key_prefix or ""
    local consul_cluster = consul.cluster or {}

    local upstream_keys = get_servers(consul_cluster, key_prefix .. "upstreams?keys")
    if not upstream_keys then
        ngx.log(ngx.ERR, 'get upstreams keys failed')
        return false
    end
    for _, key in ipairs(upstream_keys) do repeat
        local skey = '/'..str_sub(key, #key_prefix + 11)
        --local skey = str_sub(key, #key_prefix + 11)
        if #skey == 0 then
            break
        end
        -- upstream already exists in config.lua
        if config[skey] then
            break
        end

        local servers = get_servers(consul_cluster, key .. "?raw")
        if not servers or not next(servers) then
            return false
        end
        if not check_servers(servers["servers"]) then
            return false
        end

        local cls = {
            servers = servers["servers"],
            keepalive = tonumber(servers["keepalive"]),
            try =  tonumber(servers["try"]),
        }

        config[skey] = {
            cluster = { cls },
        }

        -- fit config.lua format
        for k, v in pairs(servers) do
            -- copy other values
            if k ~= "servers" and k ~= "keepalive" and k ~= "try" then
                config[skey][k] = v
            end
        end
    until true end

    return true
end

return _M
