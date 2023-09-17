#include openCJ\util;

main(key)
{
    if(!self openCJ\playerRuns::hasRunStarted() && !self openCJ\demos::isPlayingDemo())
    {
        self openCJ\playerRuns::startRun();
    }

    self openCJ\AFK::onWASDPressed();
}