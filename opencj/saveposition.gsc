#include openCJ\util;

onInit()
{
    level.saveFlagName_cheating = "cheating";
    level.saveFlagName_speedModeNow = "speedModeNow";
    level.saveFlagName_speedModeEver = "speedModeEver";
    level.saveFlagName_hasRPG = "rpg";
    level.saveFlagName_usedEle = "usedEle";
    level.saveFlagName_anyPct = "anyPct";
    level.saveFlagName_allowHalfBeat = "halfBeat";
    level.saveFlagName_hardTAS = "hardTAS";

    level.saveFlags = [];

    // Flags are present in database as well as hardcoded in database function(s) right now, so do NOT modify existing ones.
    level.saveFlags[level.saveFlagName_cheating] = 1;
    level.saveFlags[level.saveFlagName_speedModeNow] = 2;
    level.saveFlags[level.saveFlagName_speedModeEver] = 4;
    level.saveFlags[level.saveFlagName_hasRPG] = 8;
    // 16 can be re-used, but it was eleNow
    level.saveFlags[level.saveFlagName_usedEle] = 32;
    level.saveFlags[level.saveFlagName_anyPct] = 64;
    level.saveFlags[level.saveFlagName_allowHalfBeat] = 128;
    level.saveFlags[level.saveFlagName_hardTAS] = 256;
}

getFlagUsedEle(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_usedEle]) != 0;
}

getFlagAllowHalfBeat(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_allowHalfBeat]) != 0;
}

getUsedAnyPct(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_anyPct]) != 0;
}

getUsedHardTAS(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_hardTAS]) != 0;
}

isCheating(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_cheating]) != 0;
}

hasSpeedModeNow(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_speedModeNow]) != 0;
}

hasSpeedModeEver(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_speedModeEver]) != 0;
}

hasRPG(save)
{
    return (save.flags & level.saveFlags[level.saveFlagName_hasRPG]) != 0;
}

createFlags()
{
    flags = 0;
    if(self openCJ\cheating::isCheating())
    {
        flags |= level.saveFlags[level.saveFlagName_cheating];
    }
    if(self openCJ\speedMode::hasSpeedMode())
    {
        flags |= level.saveFlags[level.saveFlagName_speedModeNow];
    }
    if(self openCJ\speedMode::hasSpeedModeEver())
    {
        flags |= level.saveFlags[level.saveFlagName_speedModeEver];
    }
    if(openCJ\weapons::isRPG(self getCurrentWeapon()))
    {
        flags |= level.saveFlags[level.saveFlagName_hasRPG];
    }
    if(self openCJ\elevate::hasUsedEle())
    {
        flags |= level.saveFlags[level.saveFlagName_usedEle];
    }
    if(self openCJ\anyPct::hasAnyPct())
    {
        flags |= level.saveFlags[level.saveFlagName_anyPct];
    }
    if(self openCJ\halfBeat::isHalfBeatAllowed())
    {
        flags |= level.saveFlags[level.saveFlagName_allowHalfBeat];
    }
    if(self openCJ\tas::hasHardTAS())
    {
        flags |= level.saveFlags[level.saveFlagName_hardTAS];
    }

    return flags;
}

onRunCreated()
{
    self savePosition_initClient();
    self resetBackwardsCount();
}

canSaveError()
{
    if(self.sessionState != "playing")
    {
        return 1;
    }

    if(!self isOnGround())
    {
        return 2;
    }

    groundEntity = self getGroundEntity();

    if(isDefined(groundEntity) && !isDefined(groundEntity.canSaveOn) && false)
    {
        return 3;
    }

    return 0;
}

printCanSaveError(error)
{
    switch(error)
    {
        case 2:
        {
            self iprintln("^1Cannot save in air");
            break;
        }
        case 3:
        {
            self iprintln("^1Cannot save on this object");
            break;
        }
    }
}

printSaveSuccess()
{
    self iprintln("^2Saved");
}

printLoadSuccess()
{
    self iprintln("^2Loaded");
}

onSpawnPlayer()
{
    self resetBackwardsCount();
}

canLoadError(backwardsCount)
{
    error = 0; // No error by default
    if((self.sessionState != "playing") && (self.sessionState != "spectator"))
    {
        error = 999;
    }
    else if(self openCJ\demos::isPlayingDemo())
    {
        error = 998;
    }
    else if (isDefined(backwardsCount)) // Sometimes we don't want to select any save
    {
        error = self savePosition_selectSave(backwardsCount);
    }

    if (error != 0) // Useful for debugging
    {
        //self iprintln("canLoadError: " + error);
    }
    return error;
}

printCanLoadError(error)
{
    switch(error)
    {
        case 1:
        {
            self iprintln("^1No save available");
            break;
        }
        case 2:
        {
            self iprintln("^1Failed loading secondary position");
            break;
        }
    }
}

setSavedPosition()
{
    groundEntity = self getGroundEntity();
    origin = self getOrigin();
    angles = self getPlayerAngles();
    if(isDefined(groundEntity) && isDefined(groundEntity.targetName))
    {
        diff = origin - groundEntity.origin;
        x = vectorDot(anglesToForward(groundEntity.angles), diff);
        y = vectorDot(anglesToRight(groundEntity.angles), diff);
        z = vectorDot(anglesToUp(groundEntity.angles), diff);
        origin = (x, y, z);
        angles = angles - (0, groundEntity.angles[1], 0);
        entNum = groundEntity getEntityNumber();
        entTargetName = groundEntity.targetName;
        numOfEnt = findNumOfEnt(groundEntity);
    }
    else
    {
        entNum = undefined;
        entTargetName = undefined;
        numOfEnt = undefined;
    }
    flags = self createFlags();
    FPSModeStr = self openCJ\fps::getCurrentFPSMode();
    FPSModeNum = self openCJ\fps::FPSModeToInt(FPSModeStr);
    saveNum = self openCJ\statistics::increaseAndGetSaveCount();

    self thread openCJ\historySave::saveToDatabase(origin, angles, entTargetName, numOfEnt, self openCJ\statistics::getExplosiveJumps(), self openCJ\statistics::getDoubleExplosives(), self openCJ\checkpoints::getCurrentCheckpointID(), FPSModeStr, flags);
    self savePosition_save(origin, angles, entNum, self openCJ\statistics::getExplosiveJumps(), self openCJ\statistics::getDoubleExplosives(), self openCJ\checkpoints::getCurrentCheckpointID(), FPSModeNum, flags, saveNum);
    return saveNum;
}

getSavedPosition(backwardsCount)
{
    error = self savePosition_selectSave(backwardsCount);
    if (error == 0) // No error
    {
        save = spawnStruct();
        save.origin = self savePosition_getOrigin();
        save.angles = self savePosition_getAngles();
        save.explosiveJumps = self savePosition_getExplosiveJumps();
        save.doubleExplosives = self savePosition_getDoubleExplosives();
        save.checkpointID = self savePosition_getCheckpointID();
        save.flags = self savePosition_getFlags();
        save.FPSMode = self openCJ\fps::FPSModeToString(self savePosition_getFPSMode());
        save.saveNum = self savePosition_getSaveNum();

        groundEntity = self savePosition_getGroundEntity();

        if(isDefined(groundEntity))
        {
            x = vectorScale(anglesToForward(groundEntity.angles), save.origin[0]);
            y = vectorScale(anglesToRight(groundEntity.angles), save.origin[1]);
            z = vectorScale(anglesToUp(groundEntity.angles), save.origin[2]);
            save.origin = groundEntity.origin + x + y + z;
            save.angles = (save.angles[0], save.angles[1] + groundEntity.angles[1], save.angles[2]);
        }

        return save;
    }

    return undefined;
}

incrementBackwardsCount(amount)
{
    if(amount == 0)
    {
        return self resetBackwardsCount();
    }
    else
    {
        self.savePosition_backwardsCount += amount;
    }
    return self.savePosition_backwardsCount;
}

resetBackwardsCount()
{
    self.savePosition_backwardsCount = 0;
    return 0;
}

getBackwardsCount()
{
    return self.savePosition_backwardsCount;
}

onPlayerCommand(args)
{
    switch(args[0])
    {
        case "save":
        {
            self openCJ\events\eventHandler::onSavePositionRequest();
            return true;
        }
        case "load":
        {
            self openCJ\events\eventHandler::onLoadPositionRequest(0);
            return true;
        }
        case "loadsecondary":
        {
            self openCJ\events\eventHandler::onLoadPositionRequest(1);
            return true;
        }
        case "mr":
        {
            if(isDefined(args[3]))
            {
                if(args[3] == "load")
                {
                    self openCJ\events\eventHandler::onLoadPositionRequest(0);
                    return true;
                }
                else if(args[3] == "save")
                {
                    self openCJ\events\eventHandler::onSavePositionRequest();
                    return true;
                }
                else if(args[3] == "loadsecondary")
                {
                    self openCJ\events\eventHandler::onLoadPositionRequest(1);
                    return true;
                }
            }
        }
    }
    return false;
}