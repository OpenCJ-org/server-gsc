onPlayerConnect()
{
    self.isActivelyPlaying = false;
}

whileAlive()
{
    if(self.activelyPlayingOrigin != self.origin)
    {
        self _setActivelyPlaying(true);
    }
    else if(self.activelyPlayingTimer < getTime())
    {
        self _setActivelyPlaying(false);
    }
}

onSpawnPlayer()
{
    self _setActivelyPlaying(true);
}

onRunCreated()
{
    self.startTime = getTime();
    self.stopTime = getTime();

    self _setActivelyPlaying(true); // Start in actively-playing mode to avoid lag script exploits
}

onRunFinished(cp)
{
    self pauseTimer();
}

isActivelyPlaying()
{
    return self.isActivelyPlaying;
}

_setActivelyPlaying(active)
{
    self.isActivelyPlaying = active;
    if(!active)
    {
        self pauseTimer();
    }
    else // Active
    {
        self.activelyPlayingTimer = getTime() + 5000;
        self.activelyPlayingOrigin = self.origin;
        if(self openCJ\playerRuns::hasRunStarted() && !self openCJ\playerRuns::isRunPaused())
        {
            self startTimer();
        }
    }
}

startTimer()
{
    if(self openCJ\playerRuns::isRunFinished())
    {
        return;
    }

    if(isDefined(self.stopTime))
    {
        self.startTime += getTime() - self.stopTime;
        self.stopTime = undefined;
    }
}

pauseTimer()
{
    if(!isDefined(self.stopTime))
    {
        self.stopTime = getTime();
    }
}

setTimePlayed(value) // Called when restoring a run
{
    if(isDefined(self.stopTime))
    {
        self.startTime = self.stopTime - value;
    }
    else
    {
        self.startTime = getTime() - value;
    }
}

getTimePlayed()
{
    if(isDefined(self.stopTime))
    {
        return (self.stopTime - self.startTime);
    }
    else
    {
        return (getTime() - self.startTime);
    }
}

getSecondsPlayed()
{
    timeMs = getTimePlayed();
    return int(timeMs / 1000);
}

getFrameNumber()
{
    return (self openCJ\playTime::getTimePlayed() / 50);
}

_resetAddTimeUntil()
{
    self endon("disconnect");
    self notify("resetAddTimeUntil");
    self endon("resetAddTimeUntil");
    waittillframeend;
    self.addTimeUntil = undefined;
}

addTimeUntil(newtime)
{
    if(self openCJ\playerRuns::isRunFinished())
    {
        return;
    }
    if(!isDefined(newtime))
    {
        return;
    }
    if(!self openCJ\playerRuns::hasRunStarted())
    {
        return;
    }

    // Some slightly complex logic here: we don't want time to be applied if we're still in the state that caused us to add time
    // For example: new shellshock during shellshock should not add the same duration again, but rather only the extra time
    if(!isDefined(self.addTimeUntil) && (newtime > getTime()))
    {
        self.startTime -= newtime - getTime();
        self.addTimeUntil = newtime;
    }
    else if(isDefined(self.addTimeUntil) && (newtime > self.addTimeUntil))
    {
        self.startTime -= newtime - self.addTimeUntil;
        self.addTimeUntil = newtime;
    }

    self thread _resetAddTimeUntil();
}
