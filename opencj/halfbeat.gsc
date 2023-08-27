#include openCJ\util;

onInit()
{
    underlyingCmd = openCJ\settings::addSettingBool("allowhalfbeat", false, "Allow the use of halfbeat in your runs", ::_onSettingHalfBeat);
    openCJ\commands_base::addAlias(underlyingCmd, "halfbeat");
}

_onSettingHalfBeat(newVal)
{
    if (!newVal && self.allowHalfBeat && self openCJ\playerRuns::hasRunStarted())
    {
        self sendLocalChatMessage("Your run allows halfbeat, so load back or !reset your run", true);
    }
    else
    {
        self.allowHalfBeat = newVal;
    }
}

onPlayerConnected()
{
    self.allowHalfBeat = false;
    self.hbMessagePrinted = false;
    thread _detectHalfBeat();
}

onLoadPosition()
{
    self.hbMessagePrinted = false;
}

onRunStarted()
{
    self.allowHalfBeat = self openCJ\settings::getSetting("allowhalfbeat");
    self.hbMessagePrinted = false;
}

onRunRestored()
{
    // The load position that occurs will properly set whether or not halfbeat is allowed
    self.hbMessagePrinted = false;
}

isHalfBeatAllowed()
{
    return self.allowHalfBeat;
}

setAllowHalfBeat(val)
{
    // If saved position allowed halfbeat, it'll be enforced
    self.allowHalfBeat = val;
}

_detectHalfBeat()
{
    self endon("disconnect");

    while (true)
    {
        if (self openCJ\settings::getSetting("allowhalfbeat"))
        {
            wait .05;
            continue;
        }

        velocity = self getVelocity();
        if (!self isSpectator() && self isPlayerReady(true) && !self openCJ\playerRuns::isRunPaused() && !self openCJ\playerRuns::isRunFinished() && !self isOnGround())
        {
            // User doesn't allow halfbeat, so start monitoring for it
            leftButtonPressed = self leftButtonPressed();
            rightButtonPressed = self rightButtonPressed();
            forwardButtonPressed = self forwardButtonPressed();
            if (!forwardButtonPressed && (leftButtonPressed || rightButtonPressed))
            {
                minSpeedThreshold = 300; // Don't apply reduction factor when lower than this x or y velocity
                minSpeedGainThreshold = 20; // Don't apply reduction factor when gaining speed less than this number.
                // ^ this is to ensure a normal hold A tech is not or barely affected, while a halfbeat hold A tech is punished.
                if (isDefined(self.hbPrevVel) && ((abs(velocity[0]) >= minSpeedThreshold) || (abs(velocity[1]) >= minSpeedThreshold)))
                {
                    reductionFactor = 0.20;
                    speedGainX = abs(velocity[0]) - abs(self.hbPrevVel[0]);
                    speedGainY = abs(velocity[1]) - abs(self.hbPrevVel[1]);
                    newVelX = velocity[0];
                    newVelY = velocity[1];

                    shouldChangeVel = false;
                    if (speedGainX > minSpeedGainThreshold)
                    {
                        newVelX *= (1 - reductionFactor);
                        shouldChangeVel = true;
                    }
                    if (speedGainY > minSpeedGainThreshold)
                    {
                        newVelY *= (1 - reductionFactor);
                        shouldChangeVel = true;
                    }

                    if (shouldChangeVel)
                    {
                        velocity = (newVelX, newVelY, velocity[2]);
                        self setVelocity(velocity);
                        if (!self.hbMessagePrinted)
                        {
                            self iprintln("Reduced acceleration (^5!allowhalfbeat^7)");
                            self.hbMessagePrinted = true;
                        }
                    }
                }
            }
        }
        self.hbPrevVel = velocity;
        wait .1;
    }
}

