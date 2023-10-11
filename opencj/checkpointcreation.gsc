#include openCJ\util;

onInit()
{
    cmd = openCJ\commands_base::registerCommand("checkpoint", "Checkpoint creation mode with many subcommands", ::_onCommandCheckpoint, 1, undefined, 40); // TODO: adminLevel -> checkpointer role
    openCJ\commands_base::addAlias(cmd, "cpc");
    openCJ\commands_base::addAlias(cmd, "cp");

    level.cpcIndicatorModel = "me_fruit_watermelon_round"; // Yes, a watermelon. Probably tastes good.
    precacheModel(level.cpcIndicatorModel); // Shown for checkpoint corners

    level.cpcHudName = "cpc";
}

_onCommandCheckpoint(args)
{
    if (getCvarInt("net_port") == 28960)
    {
        self sendLocalChatMessage("Checkpoint creation is only available on test servers (for now)");
        return;
    }

    if (!isDefined(self.cpcIsCreating) || !self isPlayerReady(false))
    {
        // Player not yet logged in?
        return;
    }

    if (args.size == 0)
    {
        self sendLocalChatMessage("You can start checkpointing by creating a route: !cpc start <routeName>", false, false);
        return;
    }

    /*
    if ((args[0] == "undo") || (args[0] == "oops"))
    {
        self.cpcCheckpoint = self.cpcPrevCheckpoint;
        self sendLocalChatMessage("Removed last changed property from the checkpoint", false, false);
    }
    */
    if (args[0] == "import")
    {
        if (self.cpcIsCreating)
        {
            // To be safe: don't accidentally have players waste all their checkpoints if they do this
            self sendLocalChatMessage("Please try again after stopping cpc mode", true, false);
            return;
        }
        self _import(args);
    }
    else if (args[0] == "start") // Create a route to start checkpointing with
    {
        self _startCreation(args); // routeName
    }
    else
    {
        // Import and start are always allowed, but other commands are only allowed if in checkpoint creation mode
        if (!self.cpcIsCreating)
        {
            self sendLocalChatMessage("Please enter checkpoint creation mode before using checkpoint commands", true, false);
            return;
        }

        if (args[0] == "export")
        {
            self _export(args);
        }
        else if (args[0] == "stop")
        {
            self _stopCreation(false);
        }
        else if ((args[0] == "clearall") || args[0] == "removeall")
        {
            self _clearAllCheckpoints();
        }
        else if ((args[0] == "confirm") || (args[0] == "commit") || (args[0] == "create"))
        {
            self _confirmCheckpoint(); // Any errors and such will be done in this function
        }
        else if (args[0] == "move")
        {
            self _moveOrg(args);
        }
        else if (args[0] == "reset")
        {
            self _resetCheckpoint(args);
        }
        else if (args[0] == "groundent")
        {
            self _setEntity(self getGroundEntity());
        }
        else if (args[0] == "detect")
        {
            orgs = self openCJ\platformDetect::getRectangularPlatformOrgs();
            if (isDefined(orgs))
            {
                // Remove existing orgs added by player
                self _clearOrgs();

                // Add newly detected orgs
                for (i = 0; i < orgs.size; i++)
                {
                    self _addOrg(orgs[i]);
                }
                self _updateCpcHud();
            }
        }
        /*
        else if ((args[0] == "remove") || (args[0] == "delete") || (args[0] == "del"))
        {
            self _removeCheckpoint(args);
        }
        */
        else if (args[0] == "addorg")
        {
            self _pickOrg();
        }
        else if (args[0] == "removeorg")
        {
            self _removeOrg();
        }
        else if ((args[0] == "select") || (args[0] == "sel"))
        {
            self _selectNearbyCheckpoint(args);
        }
        else
        {
            // Other commands are interpreted as setting properties for a checkpoint
            self _changeCheckpointProperty(args);
        }
    }
}

// TODO:
// - checkpointpointers hijack
// - warn if imported checkpoints were of a different map or map hash than currently loaded
// - numpad binds command or on Discord?

onPlayerLogin()
{
    self cpCreation_cleanup(self openCJ\login::getPlayerId());

    self.cpcIsCreating = false;
    self.cpcHasUnsaved = false;
    self.cpcRoute = undefined;
    self.cpcCheckpoint = undefined;
    self.cpcLastCommand = undefined; // To be able to undo last action

    //                                     name              x      y     alignX     alignY    hAlign     vAlign
    self openCJ\huds\base::initRegularHUD(level.cpcHudName, 5,    0,    "left",    "middle", "left",    "middle",
    //  foreground    font          hideInMenu   color            glowColor                        glowAlpha  fontScale  archived alpha
        1,            "objective",  true,        (1.0, 1.0, 1.0), ((20/255), (33/255), (125/255)), 0.0,       1.4,       false,   0);
}

onPlayerDisconnect()
{
    if (isDefined(self.cpcIsCreating) && self.cpcIsCreating)
    {
        // TODO: backup of current checkpoints?
    }
}

onWeaponFired()
{
    self _pickOrg(); // Firing weapon in checkpoint creation mode will select each corner of the checkpoint
}

whileAlive() // For showing the checkpoints that have been created and/or are being interacted with
{
    // TODO: this requires calculations to print when the player enters and leaves a checkpointed area
    // Also print the checkpoint index AND indices of children, so players can figure out parent and child indices easily by entering the checkpoint
}

isCreatingCheckpoints()
{
    return self.cpcIsCreating;
}

_pickOrg()
{
    if (!self.cpcIsCreating)
    {
        return;
    }

    if (isDefined(self.cpcCheckpoint.orgs) && (self.cpcCheckpoint.orgs.size >= 8))
    {
        self sendLocalChatMessage("You've selected the maximum number of corners", true, false);
        return;
    }

    if (isDefined(self.cpcCheckpoint.orgs) && isDefined(self.cpcCheckpoint.entity) && (self.cpcCheckpoint.orgs.size >= 1))
    {
        self sendLocalChatMessage("Entity-bound checkpoints only accept one offset", true, false);
        return;
    }

    eyePos = self getEyePos();
    trace = bulletTrace(eyePos, (eyePos + vectorScale(anglesToForward(self getPlayerAngles()), 500)), false, self); // Low max distance on purpose, to prevent a missclick from adding an origin
    if (isDefined(trace) && isDefined(trace["position"]))
    {
        self _addOrg(trace["position"]);
        self _updateCpcHud();
        //self iprintln("^3Added point #" + self.cpcCheckpoint.orgs.size + " at " + trace["position"]); // Not a chat message, causes too much spam
    }
    else
    {
        self iprintln("^1Could not trace bullet to an origin");
    }
}

_resetCheckpoint()
{
    self.cpcPrevCheckpoint = self.cpcCheckpoint;

    self _clearOrgs();
    self.cpcCheckpoint = undefined;
}

_removeCheckpoint(args)
{
    // TODO: remove currently selected checkpoint entirely
}

_selectNearbyCheckpoint(args)
{
    // TODO: select checkpoint closest to player's current origin
    idx = self cpCreation_getClosestCheckpointIdx(self getOrigin());
    if (!isDefined(idx))
    {
        self sendLocalChatMessage("Failed to find any nearby checkpoint", true, false);
        return false;
    }

    self _selectCheckpointByIndex(idx);
}

_handleValuelessProperty(arg)
{
    if ((arg == "air") || (arg == "inair"))
    {
        self.cpcCheckpoint.isInAir = !self.cpcCheckpoint.isInAir;
    }
    if ((arg == "ele") || (arg == "elevator"))
    {
        self.cpcCheckpoint.allowEle = !self.cpcCheckpoint.allowEle;
    }
    else if ((arg == "anyfps") || (arg == "hax"))
    {
        self.cpcCheckpoint.allowAnyFPS = !self.cpcCheckpoint.allowAnyFPS;
    }
    else if ((arg == "doublerpg") || (arg == "rpg") || (arg == "double"))
    {
        self.cpcCheckpoint.allowDoubleRPG = !self.cpcCheckpoint.allowDoubleRPG;
    }
    else if ((arg == "end") || (arg == "fin") || (arg == "finish"))
    {
        self.cpcCheckpoint.isFinish = !self.cpcCheckpoint.isFinish; // Checkpoint is a finish checkpoint
    }
    else if (arg == "clearparents")
    {
        self _clearParents();
    }
    else
    {
        self sendLocalChatMessage("Unknown argument: " + arg + ", or expected a value", true, false);
        return false;
    }

    self _updateCpcHud();
    return true;
}

_handleValueProperty(arg, val) // Property with a value
{
    if (arg == "addparent")
    {
        if (!self _addParent(val))
        {
            return false; // Function will have sent an error message
        }
    }
    else
    {
        self sendLocalChatMessage("Unknown argument: " + arg, true, false);
        return false;
    }

    self _updateCpcHud();
    return true;
}

_addParent(val)
{
    if (!isValidInt(val) || (int(val) < 0))
    {
        self sendLocalChatMessage("That's not a valid positive integer", true, false);
        return false;
    }

    if (!isDefined(self.cpcCheckpoint.parents))
    {
        self.cpcCheckpoint.parents = [];
    }
    self.cpcCheckpoint.parents[self.cpcCheckpoint.parents.size] = int(val);

    return true;
}

_clearParents()
{
    self.cpcCheckpoint.parents = undefined;
}

_setEntity(ent)
{
    self.cpcCheckpoint.entity = ent; // If undefined, then this clears it.
    return true;
}

// Called when a user wants to change a property
_changeCheckpointProperty(args)
{
    // Process one command at a time
    if ((args.size < 1) || (args.size > 2))
    {
        self sendLocalChatMessage("Expected min. 1 and max. 2 arguments", true, false);
        return;
    }

    // Check if it's a value-less argument
    arg = args[0];
    if (args.size == 1)
    {
        if (!self _handleValuelessProperty(arg)) // Function will have sent an error message if something failed
        {
            return;
        }
    }
    else // Argument with a value
    {
        val = args[1];
        if (!self _handleValueProperty(arg, val)) // Function will have sent an error message if something failed
        {
            return;
        }
    }

    self _updateCpcHud();
}

_export(args)
{
    if (args.size != 2) // export <fileName>
    {
        self sendLocalChatMessage("Expected 1 parameter: <fileName without extension>", true, false);
        return;
    }

    success = self cpCreation_export(args[1], self openCJ\login::getPlayerID()); // This function will sanitize the file name
    if (!success)
    {
        self sendLocalChatMessage(self cpCreation_getError(), true, false);
    }
    else
    {
        self _stopCreation(true);

        self sendLocalChatMessage("Export successful", false, true);
    }
}

_import(args)
{
    self endon("disconnect");

    if (args.size != 2) // import <fileName>
    {
        self sendLocalChatMessage("Expected 1 parameter: <fileName without extension>", true, false);
        return;
    }

    success = self cpCreation_import(args[1], self openCJ\login::getPlayerID()); // This function will sanitize the file name and make sure it's a checkpoint file
    if (!success)
    {
        self sendLocalChatMessage(self cpCreation_getError(), true, false);
    }
    else
    {
        nrCheckpoints = self cpCreation_count();
        if (nrCheckpoints == 0)
        {
            self sendLocalChatMessage("Import had 0 checkpoints", true, false);
            return;
        }

        route = self cpCreation_getRoute();
        if (!isDefined(route))
        {
            self sendLocalChatMessage("Route not found, using default name 'normal'", true, false);
            route = "normal";
        }

        // Start checkpoint mode if it wasn't already started
        if (!self.cpcIsCreating)
        {
            args = [];
            args[0] = "start";
            args[1] = route;
            self _startCreation(args);
        }

        self sendLocalChatMessage("Successfully imported " + nrCheckpoints + " checkpoints.", false, true);

        idx = nrCheckpoints - 1;
        self _selectCheckpointByIndex(idx); // Get most recent checkpoint
        if (!isDefined(self.cpcCheckpoint))
        {
            self sendLocalChatMessage("Most recent checkpoint is corrupted?", true, false);
            // TODO: remove this corrupted checkpoint?
        }
        found = false;
        while(isDefined(self.cpcCheckpoint)) // Go to the most recent checkpoint that has an origin to teleport to
        {
            if (isDefined(self.cpcCheckpoint.orgs))
            {
                //self sendLocalChatMessage("Teleporting you to most recent checkpoint that has an origin", false, false);
                org = self.cpcCheckpoint.orgs[0];
                self setOrigin((org[0], org[1], (org[2] + 5))); // Prevent player getting stuck
                found = true;
                break;
            }
            else // Still trying to find a checkpoint that has an origin
            {
                idx--;
                self _selectCheckpointByIndex(idx);
            }
        }

        self.cpcPrevCheckpoint = undefined;
        if (!found)
        {
            self sendLocalChatMessage("Could not teleport you to a checkpoint since none have an origin", false, false);
        }
    }
}

_selectCheckpointByIndex(idx) // Select a checkpoint from the server C side array
{
    handle = self cpCreation_select(idx);
    if (!isDefined(handle))
    {
        self sendLocalChatMessage("Checkpoint with index " + idx + " was not found..", true, false);
        return undefined;
    }
    
    orgs = self cpCreation_getOrgs();
    isInAir = self cpCreation_getIsInAir();
    entTargetName = self cpCreation_getEntityName();
    ent = undefined;
    if (isDefined(entTargetName))
    {
        entIndex = self cpCreation_getEntityIndex();
        entArray = getEntArray(entTargetName, "targetname");
        if (isDefined(entArray) && (entArray.size > 0))
        {
            if (entArray.size > entIndex)
            {
                ent = entArray[entIndex];
            }
            else
            {
                printf("WARNING: cpc entityIndex (" + entIndex + ") is out of entity range for entArray: " + entTargetName + "\n");
                ent = entArray[0];
            }
        }
    }
    parents = self cpCreation_getParents();
    isFinish = self cpCreation_getIsFinish();
    allowEle = self cpCreation_getAllowEle();
    allowAnyFPS = self cpCreation_getAllowAnyFPS();
    allowDoubleRPG = self cpCreation_getAllowDoubleRPG();

    self _setCurrentCheckpoint(orgs, isInAir, ent, parents, isFinish, allowEle, allowAnyFPS, allowDoubleRPG);
}

_clearAllCheckpoints()
{
    if (!self.cpcHasUnsaved || (isDefined(self.cpcRequestedClearAll) && self.cpcRequestedClearAll))
    {
        self.cpcRequestedClearAll = false;

        nrCleared = self cpCreation_clearAll();
        self _stopCreation(true); // Updates HUD
        self sendLocalChatMessage("Removed " + nrCleared + " checkpoints", true, false);
    }
    else
    {
        self sendLocalChatMessage("If you're sure you want to CLEAR ALL checkpoints, please execute the command again", true, false);
        self.cpcRequestedClearAll = true;
    }
}

_startCreation(args)
{
    if (args.size < 2) // [0] = "start", [1] = routeName
    {
        self sendLocalChatMessage("Missing argument: routeName", true, false);
        return;
    }
    self _setCreation(true, args[1]);
}

_stopCreation(force)
{
    if (!force && self.cpcHasUnsaved)
    {
        self sendLocalChatMessage("You have unexported checkpoints. Please use 'export' or 'clearall' first.", true, false);
        return;
    }
    self _setCreation(false, undefined);
    self.cpcHasUnsaved = false;
    self.cpcPrevCheckpoint = undefined;
    self.cpcCheckpoint = undefined;
    self.cpcLastIdx = undefined;
    self.cpcPrevIdx = undefined;
    self.cpcRoute = undefined;
}

_setCreation(newVal, route)
{
    if (newVal && !isDefined(route))
    {
        return; // Sanity check
    }

    if (newVal && (route.size > 20))
    {
        self sendLocalChatMessage("Please pick a shorter route name", true, false);
        return;
    }

    if (newVal && isDefined(route))
    {
        route = toLower(route);
        if (newVal == self.cpcIsCreating) // Was already enabled?
        {
            // Change of route name?
            if (isDefined(self.cpcRoute) && (route != self.cpcRoute))
            {
                self sendLocalChatMessage("Renamed route from: " + self.cpcRoute + " to: " + route);
                self _setRoute(route);
                self _updateCpcHud();
            }
            return;
        }
    }

    cpStr = "checkpoint creation mode";
    self.cpcIsCreating = newVal;
    if (self.cpcIsCreating)
    {
        self openCJ\cheating::setCheating(true);
        self _setRoute(route);
        self _setupNewCheckpoint(); // Updates HUD
        self sendLocalChatMessage("Started " + cpStr + " for route: " + route, false, true);
    }
    else
    {
        self sendLocalChatMessage("Stopped " + cpStr + " for route: " + self.cpcRoute, true, false);
        self _resetCheckpoint(); // To clear indicators
        self _updateCpcHud();
    }
}

_setRoute(routeName)
{
    self.cpcRoute = routeName;
    self cpCreation_setRoute(routeName);
}

_setupNewCheckpoint()
{
    // onGround by default, and do not allow anything special (such as ele, anyFPS, doubleRPG)
    // This sets parent to last created checkpoint by default
    parents = undefined;
    if (isDefined(self.cpcLastIdx))
    {
        parents = [];
        parents[0] = self.cpcLastIdx;
    }
    self _setCurrentCheckpoint(undefined, false, undefined, parents, false, false, false, false);
}

// These functions make it immediately obvious if one of the functions in this file doesn't properly fill in all values
_setCurrentCheckpoint(orgs, isInAir, ent, parents, isFinish, ele, anyFPS, doubleRPG)
{
    self.cpcPrevCheckpoint = self.cpcCheckpoint; // "Backup" for reverting last command
    self _clearOrgs();

    self.cpcCheckpoint = spawnStruct();
    self.cpcCheckpoint.isInAir = isInAir;
    self.cpcCheckpoint.parents = parents;
    self.cpcCheckpoint.isFinish = isFinish;
    self.cpcCheckpoint.allowEle = ele;
    self.cpcCheckpoint.allowAnyFPS = anyFPS;
    self.cpcCheckpoint.allowDoubleRPG = doubleRPG;
    if (isDefined(orgs))
    {
        size = orgs.size;
        for (i = 0; i < size; i++)
        {
            self _addOrg(orgs[i]); // To show indicators
        }
    }

    self _updateCpcHud();
}

_confirmCheckpoint() // Called when user wants to confirm the current checkpoint and move on to the next one
{
    if (!self _validateCheckpoint()) // Can fail if the type of checkpoint doesn't have all expected values filled in
    {
        self sendLocalChatMessage("Checkpoint is not valid, cannot confirm", true, false);
    }
    else
    {
        // Push all the properties of the new checkpoint
        for (i = 0; i < self.cpcCheckpoint.orgs.size; i++)
        {
            self cpCreation_addOrg(self.cpcCheckpoint.orgs[i]);
        }
        // Checkpoint could have an entity
        if (isDefined(self.cpcCheckpoint.entity))
        {
            entTargetName = self.cpcCheckpoint.entity.targetName;
            numOfEnt = findNumOfEnt(self.cpcCheckpoint.entity);
            self cpCreation_setEntity(entTargetName, numOfEnt);
        }

        self cpCreation_setIsInAir(self.cpcCheckpoint.isInAir);
        if (isDefined(self.cpcCheckpoint.parents))
        {
            for (i = 0; i < self.cpcCheckpoint.parents.size; i++)
            {
                self cpCreation_addParent(self.cpcCheckpoint.parents[i]);
            }
        }
        self cpCreation_setIsFinish(self.cpcCheckpoint.isFinish);
        self cpCreation_setAllowEle(self.cpcCheckpoint.allowEle);
        self cpCreation_setAllowAnyFPS(self.cpcCheckpoint.allowAnyFPS);
        self cpCreation_setAllowDoubleRPG(self.cpcCheckpoint.allowDoubleRPG);

        // Try to confirm the checkpoint. If any result is returned, it will be an error string.
        success = self cpCreation_confirm();
        if (success)
        {
            self.cpcPrevIdx = self.cpcLastIdx;
            self.cpcLastIdx = self cpCreation_getLastIndex(); // Used to set default parent for next checkpoint
            self.cpcHasUnsaved = true; // Because not exported yet
            self _setupNewCheckpoint(); // Updates HUD
            self sendLocalChatMessage("Successfully created checkpoint (idx = " + self.cpcLastIdx + ")", false, true);
        }
        else
        {
            self sendLocalChatMessage(self cpCreation_getError(), true, false);
        }
    }
}

_validateCheckpoint() // Helper function to determine if the checkpoint can be confirmed as per the user's request
{
    // TODO: validate that checkpoint is convex

    // Validate that checkpoint is fully filled in (at least 3 origins)
    minOrgs = 3;
    selectedOrgs = 0;
    if (isDefined(self.cpcCheckpoint.orgs))
    {
        selectedOrgs = self.cpcCheckpoint.orgs.size;
    }
    if (selectedOrgs < minOrgs)
    {
        self sendLocalChatMessage("Minimum number of required origins: " + minOrgs + " (you selected: " + selectedOrgs + ")", true, false);
        return false;
    }

    return true;
}

_getLowestAndHighestPoint()
{
    if (!isDefined(self.cpcCheckpoint.orgs))
    {
        return undefined;
    }

    lowestPoint = self.cpcCheckpoint.orgs[0][2]; // Z
    highestPoint = self.cpcCheckpoint.orgs[0][2];
    for (i = 1; i < self.cpcCheckpoint.orgs.size; i++)
    {
        if (self.cpcCheckpoint.orgs[i][2] < lowestPoint)
        {
            lowestPoint = self.cpcCheckpoint.orgs[i][2];
        }

        if (self.cpcCheckpoint.orgs[i][2] > highestPoint)
        {
            highestPoint = self.cpcCheckpoint.orgs[i][2];
        }
    }

    points = [];
    points[0] = lowestPoint;
    points[1] = highestPoint;
    return points;
}

_addOrg(origin)
{
    lowestAndHighest = self _getLowestAndHighestPoint();
    lowestPoint = undefined;
    highestPoint = undefined;
    if (isDefined(lowestAndHighest))
    {
        lowestPoint = lowestAndHighest[0];
        highestPoint = lowestAndHighest[1];
    }
    else
    {
        self.cpcCheckpoint.orgs = [];
        lowestPoint = origin[2];
        highestPoint = origin[2];
    }

    self.cpcCheckpoint.orgs[self.cpcCheckpoint.orgs.size] = origin;

    if (!isDefined(self.cpcCheckpoint.bottomIndicators))
    {
        self.cpcCheckpoint.bottomIndicators = [];
        self.cpcCheckpoint.topIndicators = [];
    }

    idx = self.cpcCheckpoint.bottomIndicators.size;
    lowestOrigin = (origin[0], origin[1], lowestPoint);
    highestOrigin = (origin[0], origin[1], highestPoint);
    self.cpcCheckpoint.bottomIndicators[idx] = spawn("script_model", lowestOrigin);
    self.cpcCheckpoint.bottomIndicators[idx] hide();
    self.cpcCheckpoint.bottomIndicators[idx] showToPlayer(self);
    self.cpcCheckpoint.bottomIndicators[idx] setModel(level.cpcIndicatorModel);

    // The following code may spawn the bottom and top indicators inside each other if the checkpoint currently has no height - we don't really care
    self.cpcCheckpoint.topIndicators[idx] = spawn("script_model", highestOrigin);
    self.cpcCheckpoint.topIndicators[idx] hide();
    self.cpcCheckpoint.topIndicators[idx] showToPlayer(self);
    self.cpcCheckpoint.topIndicators[idx] setModel(level.cpcIndicatorModel);
}

_removeOrg()
{
    if (isDefined(self.cpcCheckpoint.orgs))
    {
        idx = self.cpcCheckpoint.orgs.size - 1;
        self.cpcCheckpoint.orgs[idx] = undefined;
        self.cpcCheckpoint.bottomIndicators[idx] delete();
        self.cpcCheckpoint.bottomIndicators[idx] = undefined;
        self.cpcCheckpoint.topIndicators[idx] delete();
        self.cpcCheckpoint.topIndicators[idx] = undefined;
        if (!isDefined(self.cpcCheckpoint.orgs[0]))
        {
            self.cpcCheckpoint.orgs = undefined;
            self.cpcCheckpoint.bottomIndicators = undefined;
            self.cpcCheckpoint.topIndicators = undefined;
        }

        self _updateCpcHud();
    }
}

_moveOrg(args)
{
    if ((args.size < 2) || (args.size > 3))
    {
        self sendLocalChatMessage("Expected at least 1 argument: <direction> [units]", true, false);
        return;
    }

    if (!isDefined(self.cpcCheckpoint) || !isDefined(self.cpcCheckpoint.orgs))
    {
        return;
    }

    nrUnitsPerMove = 5;
    if (args.size == 3)
    {
        if (!isValidInt(args[2]))
        {
            self sendLocalChatMessage("Provided number of units is not a valid integer", true, false);
            return;
        }

        val = int(args[2]);
        minUnits = 1;
        maxUnits = 100;
        if ((val < minUnits) || (val > maxUnits))
        {
            self sendLocalChatMessage("Number of units should be between " + minUnits + " and " + maxUnits, true, false);
            return;
        }

        nrUnitsPerMove = val;
    }

    dir = args[1];
    angles = self getPlayerAngles();
    org = self.cpcCheckpoint.orgs[self.cpcCheckpoint.orgs.size - 1];
    if (dir == "north")
    {
        org = (org[0], org[1] + nrUnitsPerMove, org[2]);
    }
    else if (dir == "east")
    {
        org = (org[0] + nrUnitsPerMove, org[1], org[2]);
    }
    else if (dir == "south")
    {
        org = (org[0], org[1] - nrUnitsPerMove, org[2]);
    }
    else if (dir == "west")
    {
        org = (org[0] - nrUnitsPerMove, org[1], org[2]);
    }
    else
    {
        self sendLocalChatMessage("Unknown direction provided (expected N/E/S/W)", true, false);
        return;
    }

    self.cpcCheckpoint.orgs[self.cpcCheckpoint.orgs.size - 1] = org;
    self _refreshIndicators();
}


_clearOrgs()
{
    if (!isDefined(self.cpcCheckpoint) || !isDefined(self.cpcCheckpoint.orgs))
    {
        return;
    }

    size = self.cpcCheckpoint.orgs.size;
    for (i = 0; i < size; i++)
    {
        self _removeOrg();
    }
}

_refreshIndicators()
{
    if (!isDefined(self.cpcCheckpoint) || !isDefined(self.cpcCheckpoint.orgs))
    {
        return;
    }

    lowestAndHighestPoint = self _getLowestAndHighestPoint();
    lowestPoint = undefined;
    highestPoint = undefined;
    if (isDefined(lowestAndHighestPoint))
    {
        for (i = 0; i < self.cpcCheckpoint.orgs.size; i++)
        {
            bOrg = self.cpcCheckpoint.orgs[i];
            self.cpcCheckpoint.bottomIndicators[i] setEntOrigin((bOrg[0], bOrg[1], lowestPoint));
            self.cpcCheckpoint.topIndicators[i] setEntOrigin((bOrg[0], bOrg[1], highestPoint));
        }
    }
}

_updateCpcHud()
{
    if (!self.cpcIsCreating)
    {
        self openCJ\huds\base::disableHUD(level.cpcHudName);
        return;
    }
    self openCJ\huds\base::enableHUD(level.cpcHudName);

    // If updating HUD, it means we execute some checkpoint action, so to be safe we reset the 'clear all' requests here
    self.cpcRequestedClearAll = false;

    hudText = "Creating checkpoint (" + self.cpcRoute + "):\n";

    // Parent
    hudText += "- iParents: ";
    if (isDefined(self.cpcCheckpoint.parents))
    {
        for (i = 0; i < self.cpcCheckpoint.parents.size; i++)
        {
            hudText += self.cpcCheckpoint.parents[i];
            if (i != (self.cpcCheckpoint.parents.size - 1))
            {
                hudText += ", ";
            }
        }
    }
    else
    {
        hudText += "n/a";
    }
    hudText += "\n";

    // isFinish
    hudText += "- isFinish:  ";
    if (self.cpcCheckpoint.isFinish)
    {
        hudText += "yes";
    }
    else
    {
        hudText += "no";
    }
    hudText += "\n";

    // Origins
    hudText += "- #origins: ";
    if (isDefined(self.cpcCheckpoint.orgs))
    {
        hudText += self.cpcCheckpoint.orgs.size;
    }
    else
    {
        hudText += "0";
    }
    hudText += "\n";

    // Entity
    hudText += "- entity:    ";
    if (isDefined(self.cpcCheckpoint.entity))
    {
        entNum = findNumOfEnt(self.cpcCheckpoint.entity);
        if (!isDefined(entNum))
        {
            entNum = "?"; // Better indicate if it's unknown
        }
        hudText += self.cpcCheckpoint.entity.targetName + "[" + entNum + "]";
    }
    else
    {
        hudText += "n/a";
    }
    hudText += "\n";

    // inAir
    hudText += "- inAir:      ";
    if (self.cpcCheckpoint.isInAir)
    {
        hudText += "yes";
    }
    else
    {
        hudText += "no";
    }
    hudText += "\n";

    // Specials
    hudText += "- specials: ";
    specialText = "";
    if (self.cpcCheckpoint.allowEle)
    {
        specialText += "ele" + ", ";
    }
    if (self.cpcCheckpoint.allowAnyFps)
    {
        specialText += "anyFPS" + ", ";
    }
    if (self.cpcCheckpoint.allowDoubleRPG)
    {
        specialText += "doubleRPG" + ", ";
    }
    if (specialText.size > 0)
    {
        specialText = getSubStr(specialText, 0, specialText.size - 2); // Remove trailing comma and space
    }
    else
    {
        specialText = "none";
    }
    hudText += specialText + "\n";

    if (!isDefined(self.cpcHudText) || (self.cpcHudText != hudText))
    {
        self.hud[level.cpcHudName] setText(hudText);
        self.cpcHudText = hudText;
    }
}
