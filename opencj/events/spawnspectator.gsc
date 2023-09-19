#include openCJ\util;

main()
{
    if (self.sessionState == "spectator")
    {
        return;
    }

    self openCJ\noclip::disableNoclip();

    if (!self.isFirstSpawn)
    {
        obituary(self, self, "", "MOD_SUICIDE");
    }

    self notify("spawned_spectator");

    resetTimeout();

    self.sessionState = "spectator";
    self.sessionTeam = "spectator";
    self.spectatorClient = -1;
    self.archiveTime = 0;
    self.pers["team"] = "spectator";

    specSpawnpoint = self openCJ\spawnpoints::getSpectatorSpawnpoint();
    self setOrigin(specSpawnpoint.origin);
    self setPlayerAngles(specSpawnpoint.angles);

    self openCJ\shellShock::resetShellShock();
    self openCJ\healthRegen::onSpawnSpectator();
    self openCJ\playerRuns::onSpawnSpectator();
    self openCJ\showRecords::onSpawnSpectator();
    self openCJ\checkpointPointers::onSpawnSpectator();
    self openCJ\huds\hudProgressBar::onSpawnSpectator();
    self openCJ\huds\hudOnScreenKeyboard::onSpawnSpectator();
    self openCJ\huds\hudJumpSlowdown::onSpawnSpectator();
    self openCJ\huds\hudFpsHistory::onSpawnSpectator();
    self openCJ\huds\hudStatistics::onSpawnSpectator();
    self openCJ\huds\hudPosition::onSpawnSpectator();
    self openCJ\events\eventHandler::onSpawnSpectator();
    self openCJ\huds\hudRunInfo::onSpawnSpectator();
    self openCJ\huds\hudSpeedoMeter::onSpawnSpectator();
    self openCJ\huds\hudSpectatorList::onSpawnSpectator();

    self stopFollowingMe();

    self thread openCJ\events\whileSpectating::main();
}