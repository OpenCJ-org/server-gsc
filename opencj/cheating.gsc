#include openCJ\util;

// 'Cheating' in this context can be many things:
// - noclip
// - speedmode
// - teleport
// - a paused run
// - blocking a moving plat

addProtectedMovingPlatform(name)
{
    ent = getEnt(name, "targetname");
    if (isDefined(ent))
    {
        if (!isDefined(level.movingPlats))
        {
            level.movingPlats = [];
        }
        level.movingPlats[level.movingPlats.size] = ent;
    }
}

onRunCreated()
{
    self.cheating = false;
}

isCheating()
{
    return self.cheating;
}

setCheating(isCheating)
{
    if (self.cheating != isCheating)
    {
        self.cheating = isCheating;
        if (self.cheating)
        {
            self openCJ\playerRuns::pauseRun();
        }
        else
        {
            self openCJ\playerRuns::resumeRun();
        }
    }
}

// Other form of cheating: blocking moving platforms
whileAlive()
{
    if (!isDefined(level.movingPlats))
    {
        return;
    }
    for (i = 0; i < level.movingPlats.size; i++)
    {
        if (self isTouching(level.movingPlats[i]))
        {
            self openCJ\noclip::disableNoclip();
            self suicide();
            self iprintln("^1Please do not block moving platforms");
        }
    }
}
