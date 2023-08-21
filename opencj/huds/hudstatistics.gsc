#include openCJ\util;

onInit()
{

}

onPlayerConnected()
{
    self.statisticsHudString = "";
    self _hideStatisticsHud(true);
}

onSpawnSpectator()
{
    self _hideStatisticsHud(false); // Statistics HUD will be shown when spectating a person
}

onSpawnPlayer()
{
    self _updateForSpectators();
}

onSpectatorClientChanged(newClient)
{
    if (!isDefined(newClient))
    {
        self _hideStatisticsHud(false);
    }
    else
    {
        self _updateStatisticsHud(newClient, undefined); // undefined -> let the function determine the update string
    }
}

onStartDemo()
{
    specs = self getSpectatorList(true); // true -> includes the player that is the spectator
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _hideStatisticsHud(false);
    }
}

onRunStopped()
{
    specs = self getSpectatorList(true); // true -> includes the player that is the spectator
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _hideStatisticsHud(false);
    }
}

onRunCreated()
{
    specs = self getSpectatorList(true); // true -> includes the player that is the spectator
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _hideStatisticsHud(false);
    }
}

whileAlive()
{
    // self = owner of statistics

    if (!self openCJ\playerRuns::hasRunID() || !self openCJ\playerRuns::hasRunStarted())
    {
        return;
    }

    if (!self openCJ\statistics::haveStatisticsChanged())
    {
        return;
    }

    self _updateForSpectators(); // Will mark the statistics as no longer changed
}

_updateForSpectators() // Function to avoid getting the string multiple times if it remains the same
{
    newString = self _getStatisticsString();
    specs = self getSpectatorList(true); // true -> includes the player that is the spectator
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _updateStatisticsHud(self, newString);
    }
}

_updateStatisticsHud(playerBeingWatched, newString)
{
    // Only update if the player being watched should have their statistics up
    if (!playerBeingWatched openCJ\playerRuns::hasRunID() || !playerBeingWatched openCJ\playerRuns::hasRunStarted())
    {
        self _hideStatisticsHud(false);
        return;
    }

    // It gets provided when doing an update for all spectators at once. Otherwise it is determined here
    if (!isDefined(newString))
    {
        newString = playerBeingWatched _getStatisticsString();
    }

    self setClientCvar("openCJ_statistics", newString);
    self.statisticsHudString = newString;

    // Statistics should no longer be marked changed now, because we displayed the most recent change
    self openCJ\statistics::setHasUpdatedStatistics();
}

_hideStatisticsHud(force)
{
    if(force || (self.statisticsHudString != ""))
    {
        self.statisticsHudString = "";
        self setClientCvar("openCJ_statistics", "");
    }
}

_getStatisticsString()
{
    // Time
    newstring = "Time: " + formatTimeString(self openCJ\playTime::getTimePlayed(), true) + "\n";

    // Loads
    newstring += "Loads: " + self openCJ\statistics::getLoadCount() + "\n";

    // CoD specific (nade jumps / rpg)
    if (getCodVersion() == 2)
    {
        // Also only show jumps and saves on CoD2 as this is irrelevant for CoD4
        newstring += "Saves: " + self openCJ\statistics::getSaveCount() + "\n";
        newstring += "Jumps: " + self openCJ\statistics::getJumpCount() + "\n";
        newstring += "Nadejumps: " + self openCJ\statistics::getExplosiveJumps() + "\n";
        newstring += "Nadethrows: " + self openCJ\statistics::getExplosiveLaunches() + "\n";
    }
    else
    {
        newstring += "RPG Jumps: " + self openCJ\statistics::getExplosiveJumps() + "\n";
        // TMI
        //newstring += "RPG Shots: " + self openCJ\statistics::getExplosiveLaunches() + "\n";
        //newstring += "Double RPGs: " + self openCJ\statistics::getDoubleExplosives() + "\n";
    }

    // FPS is already covered by runInfo icons

    // Routes & progress
    newstring += self openCJ\statistics::getRouteAndProgress() + "\n";

    return newstring;
}
