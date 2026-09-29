// Registration confirms reporting only; FPS legality remains in fps.gsc.
hasReportedFPS(value)
{
    return isDefined(value) && value != "";
}

canStart()
{
    if (getCodVersion() != 4)
        return true;
    if (isDefined(self.fpsRegistrationPending) && self.fpsRegistrationPending)
        return false;
    return hasReportedFPS(self getUserInfo("com_maxfps"));
}

onConnected()
{
    self endon("disconnect");
    level endon("game_ended");
    if (getCodVersion() != 4)
        return;

    self.fpsRegistrationPending = true;
    self.fpsRegistrationMessageAt = undefined;
    if (hasReportedFPS(self getUserInfo("com_maxfps")))
    {
        self.fpsRegistrationPending = false;
        return;
    }

    // Client menus may not be ready immediately after the begin notification.
    wait 1;
    for (attempt = 0; attempt < 3; attempt++)
    {
        if (hasReportedFPS(self getUserInfo("com_maxfps")))
            break;
        self openCJ\menus::openFPSUserinfoMenu();
        // The menu temporarily sets 999 and queues restoration one frame later.
        // Keep starts blocked throughout this interval.
        wait 0.5;
        self closeMenu();
        wait 0.5;
    }
    self.fpsRegistrationPending = false;
    if (!hasReportedFPS(self getUserInfo("com_maxfps")))
    {
        self explainBlocked();
        return;
    }

    // Complete an initial spawn that was held while registration was pending.
    if (isDefined(self.fpsRegistrationSpawnPending) && self.fpsRegistrationSpawnPending)
    {
        self.fpsRegistrationSpawnPending = false;
        self openCJ\events\spawnPlayer::main(self.fpsRegistrationSpawnAtSave);
    }
}

explainBlocked()
{
    if (isDefined(self.fpsRegistrationMessageAt) && getTime() < self.fpsRegistrationMessageAt + 5000)
        return;
    self.fpsRegistrationMessageAt = getTime();
    if (isDefined(self.fpsRegistrationPending) && self.fpsRegistrationPending)
        self iprintln("^3Verifying FPS before starting a run. Please wait.");
    else
        self iprintlnbold("^1Cannot start run: FPS registration failed. Reconnect; contact an admin if it persists.");
}
