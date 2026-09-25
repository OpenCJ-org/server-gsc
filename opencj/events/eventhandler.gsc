#include openCJ\util;

onBounced()
{
    self.eventQueue["bounced"] = true;
}
onConnect()
{
    self.eventQueue = [];
}

onSpawnPlayer()
{
    self.eventQueue = [];
}

onPlayerKilled(inflictor, attacker, damage, meansOfDeath, weapon, vDir, hitLoc, psOffsetTime, deathAnimDuration)
{
    self.eventQueue = [];
}

onSuicideRequest()
{
    self.eventQueue["suicide"] = true;
}

onRPGFired(rpg, name)
{
    self.eventQueue["rpg"] = true;
}

onSavePositionRequest()
{
    if (self openCJ\demos::isPlayingDemo())return;
    self.eventQueue["save"] = true;
}

onLoadPositionRequest(backwardsAmount)
{
    if (self openCJ\demos::isPlayingDemo())
    {
        self.eventQueue = [];
        self.demoExitRequested = true;
        return;
    }
    if (self openCJ\checkpointCreation::isEditing())
    {
        self.eventQueue["load"] = backwardsAmount;
        return;
    }
    self.eventQueue["load"] = self openCJ\savePosition::incrementBackwardsCount(backwardsAmount);
}

whileSpectating()
{
    // Load bind while spectating spawns you at your latest save
    if (isDefined(self.eventQueue["load"]))
    {
        self thread openCJ\events\spawnPlayer::main(true);
    }

    self.eventQueue = []; // Clear event queue
}

onSpawnSpectator()
{
    self.eventQueue = [];
}

whileAlive()
{
    if(isDefined(self.eventQueue["suicide"]))
    {
        self suicide();
    }
    else
    {
        if(isDefined(self.eventQueue["save"]))
        {
            error = self openCJ\savePosition::canSaveError();
            if(error)
            {
                self openCJ\savePosition::printCanSaveError(error);
            }
            else
            {
                saveNum = self openCJ\events\savePosition::main();
            }
        }
        if(isDefined(self.eventQueue["load"]))
        {
            error = self openCJ\savePosition::canLoadError(self openCJ\savePosition::getBackwardsCount());
            if(error == 1) // No saves
            {
                // Reset current run
                // TODO: nice feature, but needs some work for no-save attempts
                self thread openCJ\playerRuns::stopRun(true);
            }
            else if(error != 0)
            {
                self openCJ\savePosition::printCanLoadError(error);
            }
            else
            {
                saveNum = self openCJ\events\loadPosition::main(self openCJ\savePosition::getBackwardsCount());
            }
        }

    }
    if(self isPlayerReady() && self openCJ\playTime::isActivelyPlaying() && !self openCJ\playerRuns::isRunFinished() && !self openCJ\cheating::isCheating() && self openCJ\playerRuns::hasRunStarted())
    {
        self openCJ\demoRecording::capture();
    }
    self.eventQueue = [];
}
