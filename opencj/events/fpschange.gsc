#include openCJ\util;

onPmoveFPSChange(newFrameTime)
{
    self endon("disconnect");
    self notify("fpschange");
    self endon("fpschange");

    wait 0.2;
    newFPS = int(1000 / newFrameTime);

    self openCJ\fps::onFPSChange(newFPS);
}

onUserInfoChanged()
{
    newFPS = self getUserInfo("com_maxfps");

    if(isDefined(newFPS))
    {
        self openCJ\fps::onFPSChange(int(newFPS));
    }
    else
    {
        self openCJ\fps::onFPSChange(undefined);
    }
}