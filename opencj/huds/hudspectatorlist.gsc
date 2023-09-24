#include openCJ\util;

onInit()
{
    underlyingCmd = openCJ\settings::addSettingInt("speclisthud", 0, 10, 4, "Set the maximum numbers of spectators shown in your HUD. 0 = off.", ::_onSpectatorListSettingChanged);
    openCJ\commands_base::addAlias(underlyingCmd, "speclist");

    level.specListHudName = "speclist";
    openCJ\huds\infiniteHuds::initInfiniteHud(level.specListHudName);
}

_onSpectatorListSettingChanged(newVal)
{
    if (newVal > 0)
    {
        self thread doNextFrame(::_updateSpecList); // Call after setting has been applied
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
    else
    {
        self _hideSpecList(); // Not spectating anyone right now
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
    spectatorsAndSelf = self getSpectatorList(true);
    for (i = 0; i < spectatorsAndSelf.size; i++)
    {
        spectatorsAndSelf[i].hud[level.specListHudName].alpha = 0;
        spectatorsAndSelf[i].hud[level.specListHudName] openCJ\huds\infiniteHuds::setInfiniteHudText("", spectatorsAndSelf[i], false);
    }
}

_updateSpecList()
{
    specList = self getSpectatorList(false);
    if (specList.size == 0)
    {
        self _hideSpecList();
        return;
    }

    // Update the spectator list HUD for the player and the spectators
    self _updateSpecListHud(specList);
    for (i = 0; i < specList.size; i++)
    {
        specList[i] _updateSpecListHud(specList);
    }
}

_updateSpecListHud(specList)
{
    nrSpecsToShow = self openCJ\settings::getSetting("speclisthud");
    if (nrSpecsToShow == 0)
    {
        self _hideSpecList();
        return;
    }

    newSpecListText = "Spectator";
    if (specList.size > 1)
    {
        newSpecListText += "s (" + specList.size + ")";
    }
    newSpecListText += ":\n";

    for (i = 0; i < specList.size; i++)
    {
        if (i >= nrSpecsToShow)
        {
            break; // Limit is <nrSpecsToShow> spectators, and we'll fill in the last one later since we may have to write "(and x more)" instead
        }

        newSpecListText += specList[i].name + "^7\n";
    }

    if (specList.size > nrSpecsToShow)
    {
        newSpecListText += "(and " + (specList.size - nrSpecsToShow) + " more)\n";
    }

    self.hud[level.specListHudName] openCJ\huds\infiniteHuds::setInfiniteHudText(newSpecListText, self, false);
    self.hud[level.specListHudName].alpha = 1;
}
