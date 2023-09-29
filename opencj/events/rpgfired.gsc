#include openCJ\util;

main(rpg, name, angle, time)
{
    rpg hide();
    rpg showToPlayer(self);

    if (!self openCJ\playerRuns::hasRunStarted() && !self openCJ\demos::isPlayingDemo())
    {
        self openCJ\playerRuns::startRun();
    }

    if(self openCJ\weapons::isRPG(name))
    {
        self.rpgTime = time;
        self.rpgAngle = angle;
        self openCJ\measurements::RPGMeasurement(true, time);

        self openCJ\AFK::onRPGFired(rpg, name);
        self openCJ\weapons::onRPGFired(rpg, name);
        self openCJ\statistics::onRPGFired(rpg, name);
        self openCJ\events\eventHandler::onRPGFired(rpg, name);
    }
    else
    {
        rpg delete();
    }
}