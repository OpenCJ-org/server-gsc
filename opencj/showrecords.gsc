#include openCJ\util;

onInit()
{
    level.nrRecords = 5; // TODO: per player later on
    level.showRecordsHighlightShader = "white";
    precacheShader(level.showRecordsHighlightShader);
}

onPlayerConnect()
{
    self.showRecords_nameString = "";
    self.showRecords_timeString = "";

    self.showRecordsHighlight = newClientHudElem(self);
    self.showRecordsHighlight.horzAlign = "right";
    self.showRecordsHighlight.vertAlign = "top";
    self.showRecordsHighlight.alignX = "left";
    self.showRecordsHighlight.alignY = "bottom";
    self.showRecordsHighlight.x = -202;
    self.showRecordsHighlight.y = 50;
    self.showRecordsHighlight.archived = false;
    self.showRecordsHighlight.sort = -98;
    self.showRecordsHighlight.color = (0.00, 0.80, 0.85);
    self.showRecordsHighlight.hideWhenInMenu = true;
    self.showRecordsHighlight setShader(level.showRecordsHighlightShader, 195, 11);
    self _hideRecords(true);
}

onSortingChanged()
{
    if (!self isSpectator())
    {
        self thread _getRecords(self openCJ\checkpoints::getCurrentChildCheckpoints(), 0);
    }
}

onCheckpointsChanged()
{
    self thread _getRecords(self openCJ\checkpoints::getCurrentChildCheckpoints(), 0);
}

onCheckpointPassed(cp, timems)
{
    cps = [];
    cps[0] = cp;
    self thread _getRecords(cps, 1, timems);
}

onStartDemo()
{
    specs = self getSpectatorList(true);
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _hideRecords(true);
    }
}

onRunRestored()
{
    self _runChanged();
}

onRunStarted()
{
    self _runChanged();
}

onRunCreated()
{
    self _runChanged();
}

onRunStopped()
{
    specs = self getSpectatorList(true); // true -> include self as spectator
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _hideRecords(true);
    }
}

onSpawnSpectator()
{
    self _hideRecords(true);
}

onSpawnPlayer()
{
    specs = self getSpectatorList(true);
    for(i = 0; i < specs.size; i++)
    {
        if(self openCJ\playerRuns::isRunFinished())
        {
            timems = self openCJ\playTime::getTimePlayed();
            specs[i] _updateRecords(self, self.showRecords_rows, timems, false);
        }
        else if(self openCJ\playerRuns::hasRunID() && self openCJ\playerRuns::hasRunStarted())
        {
            specs[i] _updateRecords(self, self.showRecords_rows, undefined, false);
        }
        else
        {
            specs[i] _hideRecords(true);
        }
    }
}

onRunFinished(cp)
{
    cps = [];
    cps[0] = cp;
    timems = self openCJ\playTime::getTimePlayed();
    self thread _getRecords(cps, 2, timems);
}

onSpectatorClientChanged(newClient)
{
    if(!isDefined(newClient))
    {
        self _hideRecords(true);
    }
    else
    {
        if(newClient openCJ\demos::isPlayingDemo())
        {
            self _hideRecords(true);
        }
        else if(newClient openCJ\playerRuns::isRunFinished())
        {
            timems = newClient openCJ\playTime::getTimePlayed();
            self _updateRecords(newClient, newClient.showRecords_rows, timems, true);
        }
        else if (newClient openCJ\playerRuns::hasRunID())
        {
            self _updateRecords(newClient, newClient.showRecords_rows, undefined, true);
        }
    }
}

onPlayerKilled(inflictor, attacker, damage, meansOfDeath, weapon, vDir, hitLoc, psOffsetTime, deathAnimDuration)
{
    self _hideRecords(false);
}

_runChanged()
{
    self.showRecords_rows = [];
    specs = self getSpectatorList(true); // true -> include self as spectator
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _hideRecords(true);
    }
    self thread _getRecords(self openCJ\checkpoints::getCurrentChildCheckpoints(), 0);
}

_hideRecords(force)
{
    if(force || self.showRecords_nameString != "")
    {
        self setClientCvar("openCJ_records_names", "");
    }
    if(force || self.showRecords_timeString != "")
    {
        self setClientCvar("openCJ_records_times", "");
    }
    self.showRecords_nameString = "";
    self.showRecords_timeString = "";
    self.showRecordsHighlight.alpha = 0;
}

_getRecords(checkpoints, persist, timems)
{
    self endon("disconnect");
    if (!self openCJ\playerRuns::hasRunID())
    {
        return;
    }

    if(persist != 1)
    {
        self notify("writeRecordsRunning");
        self endon("writeRecordsRunning");
    }

    checkpointString = "(NULL";
    checkpoints = openCJ\checkpoints::filterOutBrothers(checkpoints);
    for(i = 0; i < checkpoints.size; i++)
    {
        cpID = openCJ\checkpoints::getCheckpointID(checkpoints[i]);
        if (isDefined(cpID))
        {
            checkpointString += ", " + cpID;
        }
    }
    checkpointString += ")";

    lbSort = self openCJ\settings::getSetting("lbsort");
    arr = strTok(lbSort, ":");
    sortStr = self openCJ\menus\leaderBoard::getSortStr(_toSupportedSortType(arr[0]), arr[1]);

    // TODO after alpha: make configurable so that it's not always based on time but based on player's current run type (defaults to time, but can be low RPG, ...)

    // For the checkpoint that was just passed, grab the player name and time played of up to 10 finished runs ordered by timePlayed (fastest first).
    // The query does this by:
    //  - finding runs by matching runID between playerRuns and checkpointStatistics to get the necessary information
    //  - verifying that the runs are finished by checking finishcpID having a value
    //  - verifying that it is not the current run by comparing runID
    //  - grabbing the player name by matching playerID between playerRuns and playerInformation
    //  - only selecting one best run per player (that's what the @prev is for, it compares it to the previous entry as it's sorted by playerID)

    query = "SELECT COUNT(*) OVER() AS totalNr, b.playerName, a.timePlayed, a.explosiveJumps, a.loadCount FROM (" +
                "SELECT pr.playerID, cs.timePlayed, cs.explosiveJumps, cs.loadCount, pr.finishTimeStamp, pr.FPSMode, pr.ele, pr.anyPct, pr.hb, pr.hardTas, cs.runID, cs.saveCount, (" + 
                    "ROW_NUMBER() OVER (PARTITION BY pr.playerID ORDER BY playerID, " + sortStr +
                ")) AS rn " + 
                "FROM checkpointStatistics cs INNER JOIN playerRuns pr ON pr.runID = cs.runID " + 
                "WHERE cs.cpID IN " + checkpointString +
                " AND pr.finishcpID IS NOT NULL" +
                " AND pr.finishTimeStamp IS NOT NULL" +
                " AND pr.ele <= " + self openCJ\elevate::hasUsedEle() +
                " AND pr.anyPct <= " + self openCJ\anyPct::hasAnyPct() +
                " AND pr.hb <= " + self openCJ\halfBeat::isHalfBeatAllowed() + 
                " AND pr.hardTAS <= " + self openCJ\tas::hasHardTAS() +
                " AND pr.FPSMode IN " + openCJ\menus\board_base::getFPSModeStr(self openCJ\fps::getCurrentFPSMode()) +
            " ) a INNER JOIN playerInformation b ON a.playerID = b.playerID " +
            "WHERE a.rn = 1 ORDER BY " + sortStr +
            " LIMIT " + level.nrRecords;

    printf("getRecords query:\n" + query + "\n"); // Debug

    rows = self openCJ\mySQL::mysqlAsyncQuery(query);

    if(!self openCJ\playerRuns::isRunFinished())
    {
        if(persist == 0)
        {
            self.showRecords_rows = rows;
        }
        else if(persist == 1)
        {
            self.showRecords_persistTime = getTime() + 2000;
        }
        else
        {
            return;
        }
    }
    else if(persist == 2)
    {
        self.showRecords_rows = rows;
    }
    else
    {
        return;
    }

    if(persist)
    {
        specs = self getSpectatorList(true);
        for(i = 0; i < specs.size; i++)
        {
            specs[i] _updateRecords(self, rows, timems, false);
        }
    }
}

_toSupportedSortType(sortType)
{
    if ((sortType != "time") && (sortType != "rpgs") && (sortType != "loads")) // Other types not supported (for now)
    {
        sortType = "time"; // Default to time for sorting that isn't easy to compare
    }
    return sortType;
}

_betterThanRecord(sortType, sortOrder, row, timePlayed, explosiveJumps, loads)
{
    // row:
    // [0] = totalNr
    // [1] = playerName
    // [2] = timePlayed
    // [3] = explosiveJumps
    // [4] = loadCount
    row[2] = int(row[2]);
    row[3] = int(row[3]);
    row[4] = int(row[4]);

    compare = [];
    compare[0] = undefined;
    compare[1] = undefined;
    compare[2] = timePlayed;
    compare[3] = explosiveJumps;
    compare[4] = loads;

    idxToCompare = 2; // timePlayed by default
    switch(sortType)
    {
        case "rpgs":
        {
            idxToCompare = 3;
        } break;
        case "loads":
        {
            idxToCompare = 4;
        } break;
        default:
        {

        }
    }

    if (sortOrder == "asc")
    {
        if (compare[idxToCompare] < row[idxToCompare])
        {
            return true;
        }
    }
    else // Assume "desc"
    {
        if (compare[idxToCompare] >= row[idxToCompare])
        {
            return true;
        }
    }

    return false;
}

_updateRecords(client, rows, overrideTime, force)
{
    if(!force && (!isDefined(overrideTime) && isDefined(client.showRecords_persistTime) && client.showRecords_persistTime > getTime()))
    {
        return;
    }
    if(client.sessionState != "playing")
    {
        return;
    }

    nameString = "";
    timeString = "";
    explosiveJumpsString = "";

    explosiveJumps = client openCJ\statistics::getExplosiveJumps();
    loads = client openCJ\statistics::getLoadCount();
    if(!isDefined(overrideTime))
    {
        timePlayed = client openCJ\playTime::getTimePlayed();
    }
    else
    {
        timePlayed = overrideTime;
    }

    // Determine how the player wants their records sorted
    lbSort = toLower(client openCJ\settings::getSetting("lbsort"));
    arr = strTok(lbSort, ":");
    sortType = _toSupportedSortType(arr[0]);
    sortOrder = arr[1];

    i = 0;
    if(isDefined(rows))
    {
        for(; i < rows.size; i++)
        {
            if (client _betterThanRecord(sortType, sortOrder, rows[i], timePlayed, explosiveJumps, loads))
            {
                for(j = rows.size; j > i; j--)
                {
                    rows[j] = rows[j - 1];
                }
                break;
            }
        }
    }
    else
    {
        rows = [];
        rows[0] = [];
    }

    ownNum = i;
    rows[i][1] = client.name;
    rows[i][2] = timePlayed;
    rows[i][3] = explosiveJumps;
    rows[i][4] = loads;
    self.showRecordsHighlight.y = 50 + 12 * ownNum;
    self.showRecordsHighlight.alpha = 0.30;

    if((rows.size > level.nrRecords) && (ownNum < level.nrRecords))
    {
        rows[level.nrRecords] = undefined;
    }
    for(i = 0; i < rows.size; i++)
    {
        if((i == ownNum) && (i == level.nrRecords))
        {
            nameString += "??. ";
        }
        else
        {
            nameString += (i + 1) + ". ";
        }
        nameString += rows[i][1] + "^7\n";
        extraInfo = rows[i][3]; // By default, add RPGs as extra info
        if (sortType == "loads")
        {
            // But if player is sorting by loads, then use that as extra info
            extraInfo = rows[i][4]; // Loads
        }
        timeString += formatTimeString(int(rows[i][2]), true) + " (" + extraInfo + ")" + "\n"; // We abuse timeString by adding explosive jumps or loads to it
    }
    if(self.showRecords_nameString != nameString)
    {
        self setClientCvar("openCJ_records_names", nameString);
        self.showRecords_nameString = nameString;
    }
    if(self.showRecords_timeString != timeString)
    {
        self setClientCvar("openCJ_records_times", timeString);
        self.showRecords_timeString = timeString;
    }
}

whileAlive()
{
    if (self openCJ\demos::isPlayingDemo())
    {
        return;
    }
    if (self openCJ\playerRuns::isRunFinished() || !self openCJ\playerRuns::hasRunID() || !self openCJ\playerRuns::hasRunStarted())
    {
        return;
    }
    if (!isDefined(self.showRecords_rows))
    {
        return;
    }

    specs = self getSpectatorList(true);
    for(i = 0; i < specs.size; i++)
    {
        specs[i] _updateRecords(self, self.showRecords_rows, undefined, false);
    }
}