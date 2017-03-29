local _M = {}


_M.global = {
    -- checkups send heartbeats to backend servers every 5s.
    checkup_timer_interval = 10,

    -- checkups timer key will expire in every 60s.
    -- In most cases, you don't need to change this value.
    checkup_timer_overtime = 60,

    -- checkups will sent heartbeat to servers by default.
    default_heartbeat_enable = true,

    -- create upstream syncer for each worker.
    -- If set to false, dynamic upstream will not work properly.
    -- This switch is used for compatibility purpose only in checkups,
    -- don't change this in slardar.
    checkup_shd_sync_enable = true,

    -- sync upstream list from shared memory every 1s
    shd_config_timer_interval = 1,

    -- If no_consul is set to true, Slardar will continue start or reload
    -- even if getting data from consul failed.
    -- Remember to set this value to false when you need to read persisted
    -- upstreams or lua codes from consul.
    no_consul = true,
}


_M.consul = {
    -- connect to consul will timeout in 5s.
    timeout = 5,

    -- disable checkups heartbeat to consul.
    enable = false,

    -- consul k/v prefix.
    -- Slardar will read upstream list from config/slardar/upstreams.
    config_key_prefix = "config/service1/",

    -- positive cache ttl(in seconds) for dynamic configurations from consul.
    config_positive_ttl = 10,

    -- negative cache ttl(in seconds) for dynamic configurations from consul.
    config_negative_ttl = 5,

    -- enable or disable dynamic configurations cache from consul.
    config_cache_enable = true,

    cluster = {
        {
            servers = {
                -- change these to your own consul http addresses
                --{ host = "127.0.0.1", port = 8500 },
                { host = "10.10.1.71", port = 8500 },
                { host = "10.10.1.72", port = 8500 },
                { host = "10.10.1.73", port = 8500 },
            },
        },
    },
}

return _M
