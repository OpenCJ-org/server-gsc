#include openCJ\util;

main(backwardsCount)
{
    if (self.sessionState != "playing")
    {
        return;
    }

    if(!self openCJ\login::isLoggedIn())
    {
        return undefined;
    }

    save = self openCJ\savePosition::getSavedPosition(backwardsCount);
    if (!isDefined(save))
    {
        self iprintln("^1Could not load position");
        return undefined;
    }

    if(getCodVersion() == 4)
    {
        giveRPG = (self openCJ\settings::getSetting("rpgonload") && self openCJ\savePosition::hasRPG(save)) || openCJ\weapons::isRPG(self getCurrentWeapon());
    }
    else
    {
        giveRPG = false;
        self openCJ\playTime::addTimeUntil(getTime() + (int(self getJumpSlowdownTimer() / 50) * 50)); //todo: make this flag-specific since disabling jump_slowdown should not give this delay, might already work baked-in to the function though
    }

    // Cheating
    wasCheating = self openCJ\cheating::isCheating();
    if(wasCheating && !openCJ\savePosition::isCheating(save))
    {
        self openCJ\cheating::setCheating(false);
    }
    else if(!wasCheating && openCJ\savePosition::isCheating(save))
    {
        self openCJ\cheating::setCheating(true);
    }

    // Set speed mode
    self openCJ\speedMode::setSpeedModeEver(openCJ\savePosition::hasSpeedModeEver(save));
    self openCJ\speedMode::setSpeedMode(openCJ\savePosition::hasSpeedModeNow(save));

    // Set elevator
    self openCJ\elevate::setUsedEle(openCJ\savePosition::getFlagUsedEle(save));
    // Set allow halfbeat. Don't want to put it back to non-halfbeat if player didn't save but still allows halfbeat
    self openCJ\halfBeat::setAllowHalfBeat(openCJ\savePosition::getFlagAllowHalfBeat(save) || self openCJ\settings::getSetting("allowhalfbeat"));

    // Set hard TAS
    self openCJ\tas::setHardTAS(openCJ\savePosition::getUsedHardTAS(save));
    // Set any%
    self openCJ\anyPct::setAnyPct(openCJ\savePosition::getUsedAnyPct(save));

    // Set origin and angles
    self setoriginandangles(save.origin, save.angles);

    self openCJ\statistics::setExplosiveJumps(save.explosiveJumps);
    self openCJ\statistics::setDoubleExplosives(save.doubleExplosives);
    self openCJ\statistics::onLoadPosition();
    self openCJ\checkpoints::onLoadPosition();
    self openCJ\halfBeat::onLoadPosition();
    self openCJ\huds\hudSpeedometer::onLoadPosition();

    // Set FPSMode. If save had non-hax non-mix, then the FPS mode should depend on the user's current FPS instead`
    currFPS = self openCJ\fps::getCurrentFPS();
    newFPSMode = self openCJ\fps::getNewFPSModeStrByFPS(save.FPSMode, currFPS);
    // We first force the save FPS mode, and then try to set new FPS mode based on the user's current FPS
    // This is to prevent the user from loading with hax and keeping mix, for example
    // But it will still properly try to load the player back if their settings disallow hax but they had previously used hax during noclip, for example
    self openCJ\fps::forceFPSMode(save.FPSMode);
    self openCJ\fps::setFPSMode(newFPSMode);

    self openCJ\events\spawnPlayer::setSharedSpawnVars(giveRPG, false);
    self openCJ\savePosition::printLoadSuccess();
    
    self openCJ\huds\hudFpsHistory::onLoaded();
    self thread openCJ\checkpoints::updateCheckpointsForPlayer(save.checkpointID); // This may take a bit of computational time, so let it run in background
    return save.saveNum;
}