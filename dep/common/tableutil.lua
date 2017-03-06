local _M = {}

math.randomseed(ngx.now()*1000)

function _M.in_table(value, tbl)

    for _, v in pairs(tbl) do

        if v == value then
            return true
        end

    end

    return false

end

function _M.get_sub_table(tbl, keys)

    local sub = {}

    for _, k in ipairs(keys) do
        table.insert( sub, tbl[k] )
    end

    return sub

end

function _M.get_len(tbl)
    local len = 0
    for _, _ in pairs(tbl) do
        len = len + 1
    end
    return len
end


function _M.get_random_elements( tbl, n )
    local idx
    local rnd
    local tlen
    local elmts = {}

    if type(tbl) ~= 'table' then
        return tbl
    end

    tlen = #tbl
    if tlen == 0 then
        return {}
    end

    n = math.min( n or tlen, tlen )

    rnd = math.random( 1, tlen )

    for i=1, n, 1 do

        idx = (rnd+i) % tlen + 1

        table.insert( elmts, tbl[idx] )
    end

    return elmts
end

function _M.dupdict( tbl, deep, ctbl )

    local t = {}

    if type(tbl) ~= 'table' then
        return tbl
    end

    ctbl = ctbl or {}

    ctbl[tbl] = t

    for k, v in pairs( tbl ) do
        if deep then
            if ctbl[v] ~= nil then
                v = ctbl[v]
            elseif type( v ) == 'table' then
                v = _M.dupdict(v, deep, ctbl)
            end
        end
        t[ k ] = v
    end

    return setmetatable( t, getmetatable(tbl) )
end

function _M.keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do
        table.insert( ks, k )
    end
    return ks
end

function _M.repr(t, opt)

    opt = opt or {}
    opt.indent = opt.indent or ''

    local lst = _M.repr_lines(t, opt)
    local sep = ' '
    if opt.indent ~= "" then
        sep = "\n"
    end
    return table.concat( lst, sep )
end

local function normkey( k )
    local key
    if type(k) == 'string' and string.match( k, '^[%a_][%w_]*$' ) ~= nil then
        key = k
    else
        key = '['.._M.repr(k)..']'
    end
    return key
end

local function extend(lst, sublines, opt)
    for _, sl in ipairs(sublines) do
        table.insert( lst, opt.indent .. sl )
    end
    lst[ #lst ] = lst[ #lst ] .. ','
end

function _M.repr_lines(t, opt)

    local tp = type( t )

    if tp == 'string' then
        return { string.format('%q', t) }
    elseif tp ~= 'table' then
        return { tostring(t) }
    end

    -- table

    local lst = {'{'}

    local i = 1
    while t[i] ~= nil do
        local sublines = _M.repr_lines(t[i], opt)
        extend(lst, sublines, opt)
        i = i+1
    end

    local keys = _M.keys(t)
    table.sort( keys, function( a, b ) return tostring(a)<tostring(b) end )

    for _, k in ipairs(keys) do

        if type(k) ~= 'number' or k > i then

            local sublines = _M.repr_lines(t[k], opt)
            sublines[ 1 ] = normkey(k) ..'='.. sublines[ 1 ]
            extend(lst, sublines, opt)
        end
    end
    table.insert( lst, '}' )
    return lst
end

function _M.iter(tbl)

    local ks = _M.keys(tbl)
    local i = 0

    table.sort( ks, function( a, b ) return tostring(a)<tostring(b) end )

    return function()
        i = i + 1
        local k = ks[i]
        if k == nil then
            return
        end
        return ks[i], tbl[ks[i]]
    end
end

-- for ks, v in tableutil.deep_iter({a={x=3, y=4}}) do
--      print( tableutil.repr(ks), v)
-- end
-- > {"a", "x"}     3
-- > {"a", "y"}     4
function _M.deep_iter(tbl)

    local ks = {}
    local iters = {_M.iter( tbl )}
    local tabletype = type({})

    return function()

        while #iters > 0 do

            local k, v = iters[#iters]()

            if k == nil then
                ks[#iters], iters[#iters] = nil, nil
            else
                ks[#iters] = k

                if type(v) == tabletype then
                    table.insert(iters, _M.iter(v))
                else
                    return ks, v
                end
            end
        end
    end
end

return _M
