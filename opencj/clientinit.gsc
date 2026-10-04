// All connection-time menu work shares one request. The engine replaces unsent
// openMenu commands, so independent FPS/graphics/scoreboard requests lose work.
onConnected()
{
    self endon("disconnect");
    level endon("game_ended");
    if (getCodVersion() != 4)
        return;

    self.clientInitPending = true;
    self.clientInitAcknowledged = false;
    self.clientInitReady = false;
    self openCJ\fpsRegistration::begin();
    // Set once per connection, never once per retry: late duplicates must not
    // recapture graphics after saved settings apply or reset a held scoreboard.
    self setClientCvar("opencj_init_once", 1);
    self setClientCvar("opencj_init_fps", int(self.fpsRegistrationRequested));
    self thread watchAcknowledgement();

    for (attempt = 0; attempt < 3; attempt++)
    {
        self openMenu("opencj_client_init");
        for (poll = 0; poll < 20; poll++)
        {
            wait 0.05;
            if (self acknowledged())
                break;
        }
        if (self acknowledged())
            break;
        // The menu closes itself after its immediate work. Server closeMenu
        // would cancel a request that the client has deferred behind another UI.
    }

    self.clientInitReady = self acknowledged();
    self.clientInitPending = false;
    self notify("client_init_finished");
    self openCJ\fpsRegistration::finish();
    if (!self.clientInitReady)
        printf("Client startup: client did not acknowledge initialization.\n");
}

acknowledged()
{
    if (!self.clientInitAcknowledged)
        return false;
    if (!self.fpsRegistrationRequested)
        return true;
    return openCJ\fpsRegistration::hasRestoredFPS(self getUserInfo("com_maxfps"));
}

watchAcknowledgement()
{
    self endon("disconnect");
    self endon("client_init_finished");
    level endon("game_ended");
    for (;;)
    {
        self waittill("menuresponse", menu, response);
        // A response to this connection's request, not a persisted ready cvar.
        if (menu == "opencj_client_init" && response == "ready")
            self.clientInitAcknowledged = true;
    }
}

waitUntilFinished()
{
    while (isDefined(self.clientInitPending) && self.clientInitPending)
        wait 0.05;
}
