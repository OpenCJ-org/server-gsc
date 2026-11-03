#include openCJ\util;

onMeleeButton()
{
    if(!self isPlayerReady())
    {
        return;
    }
    if(self.sessionState != "playing")
    {
        return;
    }

    if (self openCJ\demos::isPlayingDemo())
    {
        self openCJ\demos::onPlayPauseDemo();
        return;
    }

    if(isDefined(self.buttons_lastMelee) && getTime() - self.buttons_lastMelee < 500)
    {
        //save
        self.buttons_lastUse = undefined;
        self.buttons_lastMelee = undefined;
        self openCJ\events\eventHandler::onSavePositionRequest();
    }
    else
    {
        self.buttons_lastMelee = getTime();
    }
}

onUseButton()
{
    if(!self isPlayerReady())
    {
        return;
    }
    if(self.sessionState != "playing")
    {
        return;
    }

    if(isDefined(self.buttons_lastUse) && getTime() - self.buttons_lastUse < 500)
    {
        //load
        self.buttons_lastUse = undefined;
        self.buttons_lastMelee = undefined;
        self openCJ\events\eventHandler::onLoadPositionRequest(0);
    }
    else
    {
        self.buttons_lastUse = getTime();
    }
}

onAttackButton()
{
    if(!self isPlayerReady())
    {
        return;
    }
    if(self.sessionState != "playing")
    {
        return;
    }

    if(self useButtonPressed())
    {
        //load secondary
        self openCJ\events\eventHandler::onLoadPositionRequest(1);
    }
}

resetButtons()
{
    self.buttons_lastFrag = undefined;
    if (isDefined(self.eventQueue)) self.eventQueue["aimTeleport"] = undefined;
    self.buttons_lastMelee = undefined;
    self.buttons_lastUse = undefined;
}

onJump(time)
{
    if(!self isPlayerReady())
    {
        return;
    }
    if(self.sessionState != "playing")
    {
        return;
    }

    if (self openCJ\demos::isPlayingDemo())
    {
        return;
    }

    self openCJ\statistics::onJump();
}
// A released-and-pressed pair within 300 ms is deliberate but comfortable.
onFragButton()
{
    if (!self isPlayerReady() || self.sessionState != "playing" || self openCJ\demos::isPlayingDemo())
    {
        self.buttons_lastFrag = undefined;
        return;
    }
    if (!self registerFragTap(getTime()))
        return;
    // Input callbacks run outside the movement/animation context. Queue only;
    // setOriginAndAngles invokes Pmove and must run from the normal game frame.
    request = spawnStruct();
    request.eye = self getEyePos();
    request.angles = self getPlayerAngles();
    self.eventQueue["aimTeleport"] = request;
}

processFragTeleport()
{
    if (!isDefined(self.eventQueue["aimTeleport"])) return;
    request = self.eventQueue["aimTeleport"];
    self.eventQueue["aimTeleport"] = undefined;
    if (!self isPlayerReady() || self.sessionState != "playing" || self openCJ\demos::isPlayingDemo()) return;
    destination = aimTeleportDestination(request.eye, request.eye + vectorScale(anglesToForward(request.angles), 100000), self getEntityNumber());
    if (!isDefined(destination))
    {
        self sendLocalChatMessage("No clear teleport destination at that surface", true);
        return;
    }
    // Mark before moving: no save/checkpoint can observe an unflagged teleport.
    self openCJ\cheating::setCheating(true);
    self openCJ\noclip::disableNoclip();
    self openCJ\mapBoost::cancel();
    self setOriginAndAngles(destination, self getPlayerAngles());
}

registerFragTap(now)
{
    if (!isDefined(self.buttons_lastFrag) || now < self.buttons_lastFrag || now - self.buttons_lastFrag > 300)
    {
        self.buttons_lastFrag = now;
        return false;
    }
    self.buttons_lastFrag = undefined;
    return true;
}
