// The event numbers in this file must not be changed because they match an enum in opencj_discord.cpp
//    PLAYER_MESSAGE          = 0,
//    MAP_STARTED             = 1,
//    PLAYER_COUNT_CHANGED    = 2,
//    PLAYER_JOINED           = 3,
//    PLAYER_LEFT             = 4,
//    PLAYER_FINISHED         = 5,
//    PLAYER_RENAMED          = 6,

#include openCJ\util;

onInit()
{
    level.discordIsConnected = false;

    // To maintain the Discord connection
    thread checkConnection();

    // Scripts are loaded, so that means a map change and a player count update
    thread _updateVariables();

    // Keep checking for Discord messages
    thread checkForEvents();
}

_updateVariables()
{
    onMapStart(getCvar("mapname"));
    _onPlayerCountChanged();
}

checkConnection()
{
    while (true)
    {
        // Connection may be lost at any point in time, as such we don't only check if there is no connection
        if (isDefined(discord_Connect()))
        {
            if (!level.discordIsConnected)
            {
                // Wasn't connected before, but now are. Let's send updated values because Discord module may have restarted
                thread _updateVariables();
                level.discordIsConnected = true;
            }
        }
        else
        {
            level.discordIsConnected = false;
        }
        wait 5; // Doesn't have to be too often
    }
}

// Events from game:

onMessage(playerName, message)
{
    // Called from chat.gsc :: onChatMessage
    discord_onEvent(0, playerName, message);
}

onMapStart(mapName)
{
    // Called from onInit directly, because that's when the script was loaded
    discord_onEvent(1, mapName);
}

onPlayerConnect()
{
    // Called from playerconnect :: main()
    _onPlayerCountChanged();
}

onPlayerLogin()
{
    discord_onEvent(3, self.name);
}

onPlayerDisconnect()
{
    // Called from playerdisconnect :: main()
    _onPlayerCountChanged();
    if (self openCJ\login::isLoggedIn())
    {
        // If not logged in, it wouldn't have printed a 'joined the game' event
        discord_onEvent(4, self.name);
    }
}

onRunFinished(runID, timeStr, route)
{
    discord_onEvent(5, self.name, runID, timeStr, getCvar("mapname"), route);
}

_onPlayerCountChanged()
{
    discord_onEvent(2, level.playerCount);
}

// Events from Discord:

checkForEvents()
{
    level endon("game_ended");
    while(true)
    {
        // Currently only messages arrive from Discord
        msg = discord_getEvent();
        if (isDefined(msg))
        {
            _onDiscordMessage(msg);
        }
        wait .1; // Should be fast enough :-)
    }
}

_onDiscordMessage(msg)
{
    players = getEntArray("player", "classname");
    for (i = 0; i < players.size; i++)
    {
        if (players[i] isPlayerReady(false))
        {
            players[i] sendChatMessage(msg);
        }
    }
}
