#include openCJ\util;

onInit()
{
    level.menu["ingame"] = "openCJ_ingame";
    level.menu["clientcmd"] = "openCJ_clientcmd";
    precacheMenu(level.menu["ingame"]);
    precacheMenu(level.menu["clientcmd"]);
    if(getCodVersion() == 2)
    {
        level.menu["login"] = "opencj_fps_userinfo";
        precacheMenu(level.menu["login"]);
    }
    else
    {
        precacheMenu("opencj_client_init");
        level.menu["fpsuserinfo"] = "opencj_fps_userinfo";
        precacheMenu(level.menu["fpsuserinfo"]);
    }
}

openLoginmenu()
{
    self openMenu(level.menu["login"]);
    self closeMenu();
}

onPlayerLogin()
{
    self setClientCvar("g_scriptMainMenu", level.menu["ingame"]);
}

openFPSUserinfoMenu()
{
    // Registration/restoration is immediate; the menu closes itself.
    self openMenu(level.menu["fpsuserinfo"]);
}

onStartDemo()
{
    //placeholder, open demo menu here
}