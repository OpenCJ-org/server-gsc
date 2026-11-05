#include openCJ\util;

onInit()
{
    // Use OpenCJ votes exclusively; stock callvote bypasses the alpha policy.
    setCvar("g_allowVote", 0);
    cmd = openCJ\commands_base::registerCommand("vote", "Vote for something. Usage: !vote <extend|map mp_mapname|yes|no>", ::vote, 1, 2, 0);
    openCJ\commands_base::addAlias(cmd, "v");

    cmd = openCJ\commands_base::registerCommand("maprestart", "Restart the current map", ::onCmdRestartMap, 0, 0, 60);
    openCJ\commands_base::addAlias(cmd, "restartmap");

    level.vote = undefined; // Will be filled in with spawnStruct
    level.autoExtendThreshold = (5 * 60); // 5 minutes
    thread _autoExtendTimeLoop();
}

onCmdRestartMap(args)
{
    _changeMap(getCvar("mapname"));
}

onRemainingTimeIncreased() // Also called when end map vote changes remaining time, so be wary
{
    if (level.remainingTimeSeconds >= level.autoExtendThreshold)
    {
        // Time *increased* to above the auto extend threshold, so reset variable
        level.hasRequestedAutoExtend = false;
    }
}

_autoExtendTimeLoop() // For auto extend time
{
    level endon("map_ended");
    level endon("game_ended");

    level.hasRequestedAutoExtend = false;
    while (1)
    {
        if (!level.hasRequestedAutoExtend && (level.remainingTimeSeconds < level.autoExtendThreshold))
        {
            // Always call an auto extend vote when the time is low enough
            _setupVote(undefined, "Vote: extend time (30m)", undefined);
            level.hasRequestedAutoExtend = true;
        }
        wait .1;
    }
}

voteSingleArg(arg) // Helper for externally calling vote command
{
    args = [];
    args[0] = arg;
    vote(args);
}

vote(args) //args[0] = map, extend, yes/no
{
    if(!self openCJ\login::isLoggedIn())
    {
        return;
    }

    if(isValidBool(args[0]) && isDefined(level.vote)) // Yes/no
    {
        vote = strToBool(args[0]);

        // Don't allow vote to be cast twice
        if(isDefined(self.vote) && (self.vote == vote))
        {
            return;
        }

        self.vote = vote;
        level _updateVoteCount();
    }
    else
    {
        // Vote cooldown
        canVoteIn = int(self.canVoteAt - (getTime() / 1000) + 0.5);
        if (canVoteIn > 0)
        {
            self iprintln("You can vote in another ^1" + canVoteIn + "^7 seconds");
            return;
        }

        // If an auto extend is queued, don't allow player to vote (edge case)
        if (isDefined(level.isAutoExtendQueued) && level.isAutoExtendQueued)
        {
            return;
        }

        if((args[0] == "map") && isDefined(args[1]))
        {
            mapName = toLower(args[1]);
            if (getCvar("mapname") != mapName)
            {
                self thread _doVoteMap(mapName);
            }
            else
            {
                self sendLocalChatMessage("You can't vote for the current map", true);
            }
        }
        else if(args[0] == "extend")
        {
            self thread _doVoteExtend();
        }
    }
}

onPlayerLogin()
{
    if(isDefined(level.vote))
    {
        self _setMapVoteImage(level.vote.mapImage);
        self _writeVoteCountString();
        self _writeVoteString();
    }
    else
    {
        self setClientCvar("openCJ_voteTimeString", "");
        self setClientCvar("openCJ_voteHeaderString", "");
        self _setMapVoteImage();
    }

    // TODO: when server gets more popular, change back to 60-120
    self _setVoteCooldown(5);
    self thread menuResponse();
}

_setVoteCooldown(seconds)
{
    self.canVoteAt = (getTime() / 1000) + seconds;
}

menuResponse()
{
    while (1)
    {
        self waittill("menuresponse", menu, response);
        if (response == "cjvoteyes")
        {
            self voteSingleArg("yes");
        }
        else if (response == "cjvoteno")
        {
            self voteSingleArg("no");
        }
    }
}

getMapImage(mapName)
{
    if(isDefined(mapName))
    {
        if (getCodVersion() == 4)
        {
            return "loadscreen_" + mapName;
        }
        switch(mapName)
        {
            case "jm_pier_2": return "jhs_jm_pier_2";
        }
    }
    return "default";
}

onPlayerDisconnect()
{
    level _updateVoteCount();
}

onAFKChanged(isNowAFK)
{
    level _updateVoteCount();
}

queueAutoExtendVote()
{
    if (!isDefined(level.hasAutoExtended) || !level.hasAutoExtended && !level.isAutoExtendQueued)
    {
        level.isAutoExtendQueued = true;
    }
}

_setMapVoteImage(image)
{
    if(isDefined(image))
    {
        self setClientCvar("openCJ_mapvoteImage", image);
    }
    else
    {
        self setClientCvar("openCJ_mapvoteImage", "");
    }
}

_doVoteMap(mapName)
{
    self endon("disconnect");

    // Only one vote at a time
    if(isDefined(level.vote))
    {
        self iprintln("Another vote is already in progress");
        return;
    }

    map = self _findMapByName(mapName, true);
    if (!isDefined(map)) return;
    if (map == getCvar("mapname"))
    {
        self sendLocalChatMessage("You can't vote for the current map", true);
        return;
    }

    // Create the vote object that serves as a hudElem
    _setupVote(map, "Vote: change map\n  " + map, self);
}

_doVoteExtend()
{
    self endon("disconnect");

    // Create the vote object that serves as a hudElem
    _setupVote(undefined, "Vote: extend time (30m)", self);
}

_setupVote(mapName, text, playerEnt)
{
    // Only one vote at a time
    if (isDefined(level.vote))
    {
        if (isDefined(playerEnt))
        {
            playerEnt iprintln("Another vote is already in progress");
        }
        return;
    }

    if (isDefined(playerEnt))
    {
        playerEnt _setVoteCooldown(2 * 60);
    }

    level.vote = spawnStruct();
    level.vote.str = text;
    if (isDefined(mapName))
    {
        level.vote.map = mapName;
    }
    else
    {
        level.vote.extend = true;
    }
    level.vote.mapImage = getMapImage(mapName);
    level.vote.yesCount = 0;
    level.vote.noCount  = 0;
    level.vote.timeLeft = 30; // Seconds

    // Initialize all players' initial votes
    players = getEntArray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        players[i].vote = undefined;
    }

    // Let everyone know
    if (isDefined(playerEnt))
    {
        iprintln(playerEnt.name + " ^7started a vote");
        playerEnt.vote = true;
        // Add the player's vote
        level _updateVoteCount();
    }
    else
    {
        iprintln("Automatic extend time vote");
    }

    // Keep monitoring the vote
    if (isDefined(level.vote)) // Could have already passed/failed immediately
    {
        level thread _monitorVote();
    }
}

_findMapByName(string, recurse)
{
    string = toLower(string);
    // Exact names also cover maps installed since the catalogue was loaded.
    if (openCJ\maps::canVoteMap(string, self.adminLevel)) return string;
    maps = openCJ\maps::voteMaps(self.adminLevel);
    matches = [];
    if (string != "")
        for (i = 0; i < maps.size; i++)
            if (isSubStr(maps[i]["name"], string)) matches[matches.size] = maps[i]["name"];
    if (matches.size == 1) return matches[0];
    if (matches.size > 5)
        self sendLocalChatMessage("Too many available maps match (" + matches.size + ")", true);
    else if (matches.size > 1)
        self sendLocalChatMessage("Available matches: " + arrayConcat(matches, ", "), true);
    else
        self sendLocalChatMessage("Map not installed or unavailable for alpha voting", true);
    return undefined;
}

_updateVoteCount()
{
    if(!isDefined(level.vote))
    {
        return;
    }

    yesCount = 0;
    noCount = 0;
    totalEligiblePlayers = 0;

    players = getEntArray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        if(players[i] openCJ\login::isLoggedIn())
        {
            if(isDefined(players[i].vote))
            {
                if(players[i].vote)
                {
                    yesCount++;
                }
                else
                {
                    noCount++;
                }

                // Player has voted so they were eligible
                totalEligiblePlayers++;
            }
            else if (!players[i] openCJ\AFK::isAFK())
            {
                // Player has not voted and is not AFK
                totalEligiblePlayers++;
            }
        }
    }

    level.vote.yesCount = yesCount;
    level.vote.noCount = noCount;

    // Check if votes have passed a ratio to succeed or fail the vote now
    voteThreshold = int(totalEligiblePlayers / 2);
    if(noCount > voteThreshold)
    {
        _voteFailed();
    }
    else if(yesCount > voteThreshold)
    {
        _voteSuccess();
    }
    else
    {
        for(i = 0; i < players.size; i++)
        {
            if(players[i] openCJ\login::isLoggedIn())
            {
                players[i] _writeVoteCountString();
            }
        }
    }
}

_getVoteCountString()
{
    voteYesStr = "Yes: ";
    voteNoStr = "No:   ";

    if(isDefined(self.vote))
    {
        if (self.vote)
        {
            voteYesStr += "^2";
        }
        else
        {
            voteNoStr += "^1";
        }
    }
    voteYesStr += level.vote.yesCount;
    voteNoStr += level.vote.noCount;

    return voteYesStr + "^7\n" + voteNoStr + "^7";
}

_destroyVote()
{
    level.vote = undefined;

    players = getEntArray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        players[i] _writeVoteString();
        players[i] _setMapVoteImage();
    }
}

_writeVoteString()
{
    if (isDefined(level.vote))
    {
        timeStr = "" + level.vote.timeLeft;
        if (level.vote.timeLeft < 5)
        {
            timeStr = "^1" + timeStr;
        }
        self setClientCvar("openCJ_voteTimeString", timeStr);
        self setClientCvar("openCJ_voteHeaderString", level.vote.str);
    }
    else
    {
        self setClientCvar("openCJ_voteTimeString", "");
        self setClientCvar("openCJ_voteHeaderString", "");
    }
}

_writeVoteCountString()
{
    self setClientCvar("openCJ_voteCounts", self _getVoteCountString());
}

_monitorVote()
{
    // Update the votes and menu for each player
    players = getEntArray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        if(!players[i] openCJ\login::isLoggedIn())
        {
            continue;
        }
        players[i] _writeVoteCountString();
    }

    // Start 30 second timer
    for(time = level.vote.timeLeft; time > 0; time--)
    {
        if(!isDefined(level.vote))
        {
            return;
        }

        // Update the vote string for everyone
        level.vote.timeLeft = time;
        players = getEntArray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            if(players[i] openCJ\login::isLoggedIn())
            {
                players[i] _setMapVoteImage(level.vote.mapImage);
                players[i] _writeVoteString();
            }
        }

        wait 1;
    }

    // If the vote went the full 30 seconds, then it means the vote failed
    if(isDefined(level.vote))
    {
        _voteFailed();
    }
}

_voteFailed()
{
    iprintln("Vote ^1failed^7");
    _destroyVote();
}

_voteSuccess()
{
    if(isDefined(level.vote.map))
    {
        iprintln("Vote ^2passed^7: " + level.vote.map);
        thread _changeMap(level.vote.map);
    }
    else if(isDefined(level.vote.extend))
    {
        iprintln("Vote ^2passed^7: " + "extend time");
        thread _extendTime(30);
    }

    _destroyVote();
}

_changeMap(map)
{
    if (getCvar("mapname") == map)
    {
        iprintlnbold("Current map will restart in 5 seconds..");
    }
    else
    {
        iprintlnbold("Changing map to " + map + " in 5 seconds..");
    }

    wait 5;
    self openCJ\menus\endMapVote::changeMap(map);
}

_extendTime(minutes)
{
    openCJ\timeLimit::addTimeSeconds(minutes * 60);
}
