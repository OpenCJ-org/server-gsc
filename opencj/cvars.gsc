#include openCJ\util;

onInit()
{
    setCvar("sv_floodProtect", 0);
    if(getCodVersion() == 2)
    {
        setCvar("bg_falldamageminheight", 479);
        setCvar("bg_falldamagemaxheight", 480);
        setCvar("jump_slowdownenable", 1);
        setCvar("g_playerCollision", 0);
        setCvar("g_playerEject", 0);
    }
    else
    {
        setCvar("bg_falldamageminheight", 100000000);
        setCvar("bg_falldamagemaxheight", 200000000);
        setCvar("jump_slowdownenable", 0);
        setCvar("g_friendlyPlayerCanBlock", 0);
        setCvar("g_enemyPlayerCanBlock", 0);
        setCvar("g_FFAPlayerCanBlock", 0);
    }
}