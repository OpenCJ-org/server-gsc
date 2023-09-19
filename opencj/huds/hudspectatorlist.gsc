#include openCJ\util;

onInit()
{
    underlyingCmd = openCJ\settings::addSettingBool("speclisthud", false, "Turn on/off spectator list hud.", ::_onSpectatorListSettingChanged);
    openCJ\commands_base::addAlias(underlyingCmd, "speclist");

    level.specListHudName = "speclist";
    openCJ\huds\infiniteHuds::initInfiniteHud(level.specListHudName);
}

_onSpectatorListSettingChanged(newVal)
{
    if (newVal)
    {
        self _updateSpecList(true);
    }
    else
    {
        self _hideSpecList();
    }
}

onPlayerConnected()
{
    //                                     name                   x        y     alignX     alignY    hAlign     vAlign
    self openCJ\huds\base::initInfiniteHUD(level.specListHudName, 5,     122,    "left",    "top",    "left",    "top",
    //    foreground    font        hideInMenu   color            glowColor                        glowAlpha  fontScale  archived alpha
        undefined,    "default",    true,        (0.9, 0.9, 1.0), ((20/255), (33/255), (125/255)), 0.1,       1.4,       false,   0);
}

onPlayerDisconnect()
{
    if (self.spectatorClient != -1)
    {
        spectatee = getEntByNum(self.spectatorClient);
        if (isDefined(spectatee))
        {
            // Player first needs to be fully disconnected before the spectator list is updated
            spectatee thread doNextFrame(::_updateSpecList);
        }
    }
}

onSpectatorClientChanged(newClient, prevClient)
{
    // It'll take until the next frame before spectatorClient is updated, so we execute next frame
    if (isDefined(prevClient))
    {
        prevClient thread doNextFrame(::_updateSpecList);
    }
    if (isDefined(newClient))
    {
        newClient thread doNextFrame(::_updateSpecList);
    }
}

onSpawnPlayer()
{
    self _updateSpecList();
}

onSpawnSpectator()
{
    self _hideSpecList();
}

_hideSpecList()
{
    self.hud[level.specListHudName].alpha = 0;
    self.hud[level.specListHudName] openCJ\huds\infiniteHuds::setInfiniteHudText("", self, false);
}

_updateSpecList(enabledSetting)
{
    // If setting was enabled, this function is called with the previous value
    if ((isDefined(enabledSetting) && !enabledSetting) && !self openCJ\settings::getSetting("speclisthud"))
    {
        self _hideSpecList();
        return;
    }

    specList = self getSpectatorList(false);
    if (specList.size == 0)
    {
        self _hideSpecList();
    }
    else
    {
        newSpecListText = "Spectator";
        maxSpecLines = 4; // Max. this number of spectator lines
        if (specList.size > 1)
        {
            newSpecListText += "s (" + specList.size + ")";
        }
        newSpecListText += ":\n";

        for (i = 0; i < specList.size; i++)
        {
            if (i >= (maxSpecLines - 1)) // Limit is n spectators, but we'll fill in the 4th one after since we may have to write "(and x more)"
            {
                break;
            }

            newSpecListText += specList[i].name + "\n";
        }

        if (specList.size > maxSpecLines)
        {
            newSpecListText += "(and " + (specList.size - maxSpecLines + 1) + " more)\n"; // + 1 because one of the lines will be "(and x more)"
        }
        else if (specList.size == maxSpecLines)
        {
            newSpecListText += specList[maxSpecLines - 1].name;
        }

        self.hud[level.specListHudName] openCJ\huds\infiniteHuds::setInfiniteHudText(newSpecListText, self, false);
        self.hud[level.specListHudName].alpha = 1;
    }
}
