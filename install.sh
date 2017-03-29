#!/bin/bash
LOG_FILE='/var/log/mrd-nginx-lua-install.log'

ok()
{
    msg="[`/bin/date +"%F %T"`] OK Install: $@"
    echo "$msg" >> ${LOG_FILE}
}

err()
{
    msg="[`/bin/date +"%F %T"`] ERROR Install: $@"
    echo "$msg" >> ${LOG_FILE}
    exit -1
}


install_common()
{
    cd dep
    cd common

    cp *.lua /opt/openresty/lualib/

    if [ $? != 0 ]
    then
        err "cp common"
    fi

    cd ..
}

install_lua_resty_balancer()
{
    cd lua-resty-balancer
    make

    if [ $? != 0 ]
    then
        err "make lua-resty-balancer"
    fi


    cp libchash.so /opt/openresty/lualib/

    if [ $? != 0 ]
    then
        err "cp libchash.so"
    fi

    cp lib/resty/chash.lua /opt/openresty/lualib/resty/

    if [ $? != 0 ]
    then
        err "cp chash.lua"
    fi

}

install_checkups()
{
    cp -r app /opt/openresty/

    if [ $? != 0 ]
    then
        err "cp app "
    fi

    cp -r checkups /opt/openresty/lualib/resty/

    if [ $? != 0 ]
    then
        err "cp checkups"
    fi

    ok "install openresty sucessfully!!!"
}

install()
{
    install_checkups
    install_common
    install_lua_resty_balancer
}

install

