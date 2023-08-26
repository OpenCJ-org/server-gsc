#include openCJ\util;

onInit()
{
    setClientNameMode("auto_change"); //allow renaming during round
    openCJ\commands_base::registerCommand("frename", "Force a name on a player. Usage: !frename [player] [newname]", ::_onFRenameCommand, 1, undefined, 90);
}

_onFRenameCommand(args)
{
    player = findPlayerByArg(args[0]);
    if(!isDefined(player) || !player openCJ\login::isLoggedIn())
    {
        self iprintln("Cannot find player");
        return;
    }
    if(!isDefined(args[1]))
    {
        player setForcedName(); // Remove their forced name
        return;
    }
    newName = args[1];
    for(i = 2; i < args.size; i++)
    {
        newName += " " + args[i];
    }
    player setForcedName(newName);
}

onPlayerConnect()
{
    self _createPlayerNameHud();
    self _hidePlayerNameHud();
}

onStartDemo()
{
    self _hidePlayerNameHud();
}

onPlayerLogin()
{
    self.forcedName = undefined;
}

onUserInfoChanged()
{
    if (isDefined(self getForcedName()))
    {
        // If player has a forced name, they cannot rename while in the server
        return;
    }

    newName = self getUserInfo("name");
    self _rename(newName);
}

_rename(newName)
{
    currentName = self.name;
    cleanedName = self renameClient(newName); // This will clean their name
    if (!isDefined(cleanedName)) // Sanity check because the function can return undefined
    {
        cleanedName = "UnnamedPlayer";
    }

    if ((currentName == cleanedName) || (isDefined(self.currentName) && (self.currentName == cleanedName)))
    {
        return; // Nothing to do
    }

    // Setting the player's name in their cvar will trigger another UserInfoChanged which in turn calls _rename
    // So, store this value so the next call will not also be processed
    self.currentName = cleanedName;
    self setClientCvar("name", cleanedName);

    // Only update database if player has a playerID
    if (self openCJ\login::isLoggedIn())
    {
        self thread _storeNewName(cleanedName);
    }
}

_storeNewName(newName)
{
    self notify("storeNewName");
    self endon("storeNewName");
    self endon("disconnect");
    wait 5; // Rate limiting
    self openCJ\mySQL::mysqlAsyncQueryNosave("CALL setName(" + self openCJ\login::getPlayerID() + ", '" + openCJ\mySQL::escapeString(newName) + "')");
}

getForcedName()
{
    return self.forcedName;
}

setForcedName(forcedName)
{
    if(!self openCJ\login::isLoggedIn())
    {
        return;
    }
    if(isDefined(forcedName))
    {
        // Forcibly rename client
        self _rename(forcedName);
    }
    else
    {
        // Remove forced name
        self setClientCvar("name", self.name);
    }
    self.forcedName = forcedName;
}

_createPlayerNameHud()
{
    self.playerNameHud = newClientHudElem(self);
    self.playerNameHud.horzAlign = "center_safearea";
    self.playerNameHud.vertAlign = "center_safearea";
    self.playerNameHud.alignX = "center";
    self.playerNameHud.alignY = "middle";
    self.playerNameHud.x = 0;
    self.playerNameHud.y = -50;
    self.playerNameHud.fontScale = 1.5;
    self.playerNameHud.archived = true;
    self.playerNameHud.sort = -1;
}

_hidePlayerNameHud()
{
    self.playerNameHud.alpha = 0;
}

onPlayerKilled(stuff)
{
    self _hidePlayerNameHud();
}

onSpawnSpectator()
{
    self _hidePlayerNameHud();
}

whileAlive()
{
    self _showPlayerNameHud();
}

whileSpectating()
{
    if(self.sessionTeam == "spectator" && (!isDefined(self getSpectatorClient()) || self getSpectatorClient() == self))
    {
        return;
    }
    self _showPlayerNameHud();
}

_showPlayerNameHud()
{
    if(self openCJ\settings::getSetting("hideall"))
    {
        return;
    }

    players = getEntArray("player", "classname");
    showPlayer = undefined;
    showPlayerClosestDist = undefined;
    maxDistSquared = 360;
    forward = anglesToForward(self getPlayerAngles());
    hideDist = self openCJ\settings::getSetting("hideradius");
    for(i = 0; i < players.size; i++)
    {
        if(players[i] == self)
        {
            continue;
        }
        if(!players[i] openCJ\login::isLoggedIn())
        {
            continue;
        }
        if(self openCJ\chat::isIgnoring(players[i]))
        {
            continue;
        }
        if(players[i] openCJ\chat::isMuted())
        {
            continue;
        }
        if(isDefined(players[i].sessionState) && players[i].sessionState == "playing")
        {
            diff = players[i] getEyePos() - self getEyePos();
            forwardDist = vectorDot(forward, diff);
            forwardVecScaled = self getEyePos() + vectorScale(forward, forwardDist);
            dist = distancesquared(forwardVecScaled, players[i] getEyePos());
            if(dist < (maxDistSquared * (1 + forwardDist / 1000)) && forwardDist > hideDist)
            {
                if(!isDefined(showPlayer) || showPlayerClosestDist > distancesquared(self getEyePos(), players[i] getEyePos()))
                {
                    showPlayerClosestDist = distancesquared(self getEyePos(), players[i] getEyePos());
                    showPlayer = players[i];
                }
            }
        }
        if(isDefined(showPlayer) && isDefined(self.playerNameHud))
        {
            trace = bullettrace(self getEyePos(), showPlayer getEyePos(), false, undefined);
            if(trace["fraction"] == 1)
            {
                self.playerNameHud.alpha = 0.6;
                self.playerNameHud setPlayerNameString(showPlayer);
                return;
            }
            else
            {
                self.playerNameHud.alpha = 0;
                return;
            }
        }
        else if(isDefined(self.playerNameHud))
        {
            self.playerNameHud.alpha = 0;
            return;
        }
    }
    self.playerNameHud.alpha = 0;
}