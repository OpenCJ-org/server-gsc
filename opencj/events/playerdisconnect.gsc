#include openCJ\util;

main() // Threaded
{
    self openCJ\shop::stopInspect();
    level.playerCount--;
    self openCJ\clips::onDisconnect();
    self openCJ\demos::onDisconnect();
    self openCJ\demoRecording::onDisconnect();
    self openCJ\checkpointCreation::onDisconnect();

    // Call functions that need to use 'self' before the next frame
    self openCJ\commands::onPlayerDisconnect();
    self openCJ\menus\endMapVote::onPlayerDisconnect();
    self stopFollowingMe();
    self openCJ\huds\hudSpectatorList::onPlayerDisconnect();
    self thread openCJ\discord::onPlayerDisconnect();

    // Notify that the player is disconnected. After the next frame ends, player's "self" will really be gone
    self notify("disconnect");
    waittillframeend;

    // Call all other functions after the player's self is gone (postDisconnect waits until the next frame)
    // 'self' cannot be used for these functions!
    openCJ\vote::onPlayerDisconnect();
}
