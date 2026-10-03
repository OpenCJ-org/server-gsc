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
    value = self getUserInfo("com_maxfps");
    if (isDefined(self.fpsRegistrationRequested) && self.fpsRegistrationRequested)
        return hasRestoredFPS(value);
    return hasReportedFPS(value);
}

// During our menu handshake, 999 is the temporary value, not completion.
// Other reported values still undergo the unchanged FPS legality checks.
hasRestoredFPS(value)
{
    return hasReportedFPS(value) && value != "999";
}

onConnected()
{
    self endon("disconnect");
    level endon("game_ended");
    if (getCodVersion() != 4)
        return;

    self.fpsRegistrationRequested = false;
    self.fpsRegistrationPending = true;
    self.fpsRegistrationMessageAt = undefined;
    if (hasReportedFPS(self getUserInfo("com_maxfps")))
    {
        self.fpsRegistrationPending = false;
        return;
    }

    self.fpsRegistrationRequested = true;
    for (attempt = 0; attempt < 3; attempt++)
    {
        if (hasRestoredFPS(self getUserInfo("com_maxfps")))
            break;
        self openCJ\menus::openFPSUserinfoMenu();
        // Try immediately; only slow/unresponsive clients use the full timeout.
        // Do not close the menu before its one-frame restoration has completed.
        for (poll = 0; poll < 20; poll++)
        {
            wait 0.05;
            if (hasRestoredFPS(self getUserInfo("com_maxfps")))
                break;
        }
        self closeMenu();
        value = self getUserInfo("com_maxfps");
        if (hasRestoredFPS(value))
            break;
        // Reopening while restoration is stuck would save 999 into temp,
        // overwriting the player's original FPS. Fail rather than doing that.
        if (value == "999")
            break;
    }
    self.fpsRegistrationPending = false;
    if (!hasRestoredFPS(self getUserInfo("com_maxfps")))
    {
        // A pending message must never suppress the terminal failure message.
        self.fpsRegistrationMessageAt = undefined;
        self explainBlocked();
        return;
    }

    if (isDefined(self.fpsRegistrationMessageAt))
        self iprintln("^2FPS verified. Ready to play.");

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
        self iprintln("^3Checking FPS settings - you will join automatically.");
    else
        self iprintlnbold("^1Cannot start run: FPS registration failed. Reconnect; contact an admin if it persists.");
}
