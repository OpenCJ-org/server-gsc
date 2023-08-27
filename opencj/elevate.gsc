#include openCJ\util;

onInit()
{
    underlyingCmd = openCJ\settings::addSettingBool("allowele", false, "Used to (dis)allow elevators. Usage: !ele [on/off]", ::_onSettingAllowEle);
    openCJ\commands_base::addAlias(underlyingCmd, "ele");
}

_onSettingAllowEle(allow)
{
    if(!allow && self hasUsedEle() && self openCJ\playerRuns::hasRunStarted())
    {
        self sendLocalChatMessage("You already used an elevator this run, load back or !reset your run", true);
    }

    // Don't use _updateAllowEle here, since the value hasn't been applied yet so it will use the previous value
    self _setAllowElevate(allow);
}

_setAllowElevate(val)
{
    if (!isDefined(self.allowEle) || (val != self.allowEle))
    {
        self.allowEle = val;
        if (self.allowEle)
        {
            self allowElevate(true);
        }
        else
        {
            self allowElevate(false);
        }
    }
}

_updateAllowEle()
{
    allowEle = self hasUsedEle() || self openCJ\settings::getSetting("allowele") || self _isEleAllowedThisCheckpoint() ||
               !self openCJ\playerRuns::hasRunID() || self openCJ\playerRuns::isRunPaused() || self openCJ\playerRuns::isRunFinished() ||
               self openCJ\cheating::isCheating() || self openCJ\demos::isPlayingDemo();

    self _setAllowElevate(allowEle);
}

onStartDemo()
{
    self _updateAllowEle();
}

onRunCreated()
{
    self setUsedEle(false);
    self _updateAllowEle();
}

onRunResumed()
{
    self _updateAllowEle();
}

onCheckpointsChanged()
{
    // Checkpoint changed, maybe the next one allows an elevator to be used
    self _updateAllowEle();
}

onRunPaused()
{
    self _updateAllowEle();
}

onRunFinished()
{
    self _updateAllowEle();
}

setUsedEle(value)
{
    // If value is already the same, we're done here
    if (isDefined(self.hasUsedEle) && (value == self.hasUsedEle))
    {
        return;
    }

    self.hasUsedEle = value;
    self _updateAllowEle();
}

hasUsedEle()
{
    if (!isDefined(self.hasUsedEle))
    {
        return false;
    }
    return self.hasUsedEle;
}

onElevate()
{
    if (!isDefined(self.hasUsedEle) || !self.hasUsedEle)
    {
        if (!self.allowEle)
        {
            self iprintlnbold("Elevator detected, but your run doesn't allow them");
        }
        else
        {
            self.hasUsedEle = true;
        }
    }
}

_isEleAllowedThisCheckpoint()
{
    return (isDefined(self openCJ\checkpoints::getCurrentCheckpoint()) && openCJ\checkpoints::isEleAllowed(self openCJ\checkpoints::getCurrentCheckpoint()));
}
