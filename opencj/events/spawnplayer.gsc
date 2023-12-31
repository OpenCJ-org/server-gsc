#include openCJ\util;

main(atLastSavedPosition)
{
    if(!self openCJ\login::isLoggedIn())
    {
        return;
    }

    self openCJ\noclip::disableNoclip();

    self notify("spawned");

    resetTimeout();
    self.sessionTeam = "allies";
    self.sessionState = "playing";
    if (self.spectatorClient != -1)
    {
        self openCJ\events\spectatorClientChanged::main(getEntByNum(self.spectatorClient), undefined);
        self.spectatorClient = -1;
    }
    self.archiveTime = 0;
    self.psOffsetTime = 0;
    self.pers["team"] = "allies";
    spawnpoint = self openCJ\spawnpoints::getPlayerSpawnpoint();
    self unlink(); // Player may be attached to something
    self spawn(spawnpoint.origin, spawnpoint.angles);

    self openCJ\savePosition::onSpawnPlayer();
    self openCJ\playerRuns::onSpawnPlayer();
    self openCJ\checkpoints::onSpawnPlayer();
    self openCJ\showRecords::onSpawnPlayer();
    self openCJ\huds\hudOnScreenKeyboard::onSpawnPlayer();
    self openCJ\huds\hudJumpSlowdown::onSpawnPlayer();
    self openCJ\huds\hudProgressBar::onSpawnPlayer();
    self openCJ\huds\hudSpeedometer::onSpawnPlayer();
    self openCJ\huds\hudGrenadeTimers::onSpawnPlayer();
    self openCJ\huds\hudFpsHistory::onSpawnPlayer();
    self openCJ\huds\hudFps::onSpawnPlayer();
    self openCJ\huds\hudPosition::onSpawnPlayer();
    self openCJ\huds\hudRunInfo::onSpawnPlayer();
    self openCJ\huds\hudSpectatorList::onSpawnPlayer();
    self openCJ\events\eventHandler::onSpawnPlayer();
    self openCJ\statistics::onSpawnPlayer();
    self openCJ\huds\hudStatistics::onSpawnPlayer();
    self openCJ\playTime::onSpawnPlayer();
    self openCJ\fps::onSpawnPlayer();

    self setSharedSpawnVars(false, true);
    self thread openCJ\events\whileAlive::main();
    self thread _dummy();

    // Set player at last saved position if requested
    if (isDefined(atLastSavedPosition) && atLastSavedPosition)
    {
        self openCJ\events\eventHandler::onLoadPositionRequest(0);
    }

    // Keep this as last
    self.isFirstSpawn = false;
}

setSharedSpawnVars(giveRPG, isSpawn)
{
    self openCJ\healthRegen::resetHealthRegen();
    self openCJ\weapons::giveWeapons(giveRPG, isSpawn);
    self openCJ\weapons::setWeaponSpread();
    self openCJ\shellShock::resetShellShock();
    self openCJ\huds\hudGrenadeTimers::removeNadeTimers();
    self openCJ\buttonPress::resetButtons();

    self openCJ\playerModels::setPlayerModel();

    self openCJ\checkpointPointers::showCheckpointPointers();

    if(getCodVersion() == 2)
        self setContents(256);
    else
    {
        self setperk("specialty_fastreload");
        self setPerk("specialty_longersprint");
    }
    self jumpClearStateExtended();
    self openCJ\speedMode::applySpeedMode();
    self openCJ\huds\hudFpsHistory::hideAndClearFPSHistory();
}

_dummy()
{
    waittillframeend;
    if(isDefined(self))
        self notify("spawned_player");
}

setDemoSpawnVars(giveRPG)
{
    self openCJ\weapons::giveWeapons(giveRPG);
    self openCJ\shellShock::resetShellShock();

    self openCJ\playerModels::setPlayerModel();

    if(getCodVersion() == 2)
        self setContents(256);
    else
    {
        self setperk("specialty_fastreload");
        self setPerk("specialty_longersprint");
    }
    self jumpClearStateExtended();
}