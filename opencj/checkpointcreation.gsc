#include openCJ\util;

// Grounded planar checkpoint routes, with alternatives and shared openings.
// A draft is private to the account/map/route. Publishing is a separate action.
onInit()
{
    if (getCodVersion() != 4)
        return;
    cmd = openCJ\commands_base::registerCommand("checkpoint", "!cp <route> [#RRGGBB] (start or continue your draft) | list | reset <route> | split <routes> | merge <routes> | rename <old> <new> | detect | corner | confirm | alternative | area | undo | finish | double | ele | ground | allowsave | height [units] | select <number> | new | discard | edit [number|last] | postsert | presert | insert (help) | replace | delete [area] | test | save | finalize | stop", ::command, 0, 17, openCJ\commands_base::checkpointEditorLevel());
    openCJ\commands_base::addAlias(cmd, "cp");
    openCJ\commands_base::addAlias(cmd, "cpc");
}

isEditing()
{
    return isDefined(self.cpc);
}

// Editor permissions are role-based; account IDs do not grant access.
hasEditorAccess()
{
    return self openCJ\login::isLoggedIn() && isDefined(self.adminLevel) &&
        self.adminLevel >= openCJ\commands_base::checkpointEditorLevel();
}

command(args)
{
    if (self isEditing() && isDefined(self.cpc.finalizing))
        return;
    if (!self hasEditorAccess())
    {
        self iprintln("Checkpoint editing requires admin level 20");
        return;
    }
    if (!getCvarInt("opencj_checkpoint_editor"))
    {
        self iprintln("Enable opencj_checkpoint_editor on the development server first");
        return;
    }
    if (args.size == 0)
    {
        if (self isEditing())
            self stop();
        else
            self sendLocalChatMessage("Start or continue a draft with !cpc <route>; use !cpc list to see your routes.");
        return;
    }
    if (toLower(args[0]) == "list")
    {
        self openCJ\checkpointList::show();
        return;
    }
    if (toLower(args[0]) == "reset")
    {
        if (args.size != 2)
        {
            self sendLocalChatMessage("Use !cpc reset <route>, for example !cpc reset hard.");
            return;
        }
        self openCJ\checkpointReset::reset(toLower(args[1]));
        return;
    }
    // Non-command names open the player's existing draft or create a new one.
    args[0] = toLower(args[0]);
    commands = "|list|reset|rename|split|merge|edit|insert|postsert|presert|replace|deletearea|select|stop|save|finalize|publish|test|finish|double|ele|ground|allowsave|height|undo|discard|alternative|area|detect|corner|confirm|new|previous|next|delete|";
    if ((args.size == 1 || args.size == 2) && !isSubStr(commands, "|" + args[0] + "|"))
    {
        route = args[0];
        if (!_validName(route) || self.sessionState != "playing" || self openCJ\demos::isPlayingDemo())
        {
            self iprintln("Spawn first; route names use 1-20 letters, digits, underscores or +");
            return;
        }
        hex = undefined;
        if (args.size == 2)
            hex = toLower(args[1]);
        if (isDefined(hex) && !isDefined(routeRGB(hex)))
        {
            self iprintln("Use a six-digit color, for example !cpc easy #ffffff");
            return;
        }
        previous = undefined;
        wasNetwork = false;
        if (self isEditing())
        {
            previous = self.cpc.route;
            wasNetwork = isDefined(self.cpc.network);
            if (!self stop(true))
                return;
        }
        self _start(route, hex);
        if (wasNetwork && self isEditing())
            self sendLocalChatMessage("Network draft saved. Complete all routes, then !cp finalize to make them playable.");
        else if (isDefined(previous) && previous != route && self isEditing())
            self sendLocalChatMessage("Opened " + route + ". " + previous + " draft saved; use !cpc " + previous + " then !cp finalize to make that draft playable.");
        return;
    }
    if(args[0]=="insert")
    {
        self sendLocalChatMessage("To add after the selected checkpoint, use !cpc postsert. To add before it, use !cpc presert. Select it with !cpc edit first.");
        return;
    }
    if (!self isEditing())
    {
        self iprintln("Start or continue your draft with !cpc easy or !cpc hard");
        return;
    }
    if (args[0] == "rename" && args.size == 3)
    {
        self openCJ\checkpointNetwork::rename(toLower(args[1]),toLower(args[2]));
        return;
    }
    if (isDefined(self.cpc.insertAfter) && (args[0]=="split" || args[0]=="merge" || args[0]=="edit" || args[0]=="select"))
    {
        self sendLocalChatMessage("Confirm or discard the insertion first.");
        return;
    }
    if (args[0] == "split")
    {
        for (i = 1; i < args.size; i++)args[i] = toLower(args[i]);
        self openCJ\checkpointNetwork::split(args);
        return;
    }
    if (args[0] == "merge")
    {
        for (i = 1; i < args.size; i++)args[i] = toLower(args[i]);
        self openCJ\checkpointNetwork::merge(args);
        return;
    }
    if (args[0] == "edit" && args.size == 1)
    {
        if (self.cpc.testing)
        {
            self sendLocalChatMessage("Exit checkpoint testing with !cp test before editing.");
            return;
        }
        idx = self checkpointAt(self.cpc.rows, self.origin, self isOnGround());
        if (idx < 0)
        {
            message = "No checkpoint in the current draft at your position.";
            if (idx == -2) message = "Multiple checkpoints overlap here; use !cp edit <number> to select one.";
            self sendLocalChatMessage(message);
            return;
        }
        if (idx != self.cpc.selected && openCJ\checkpointNetwork::pendingEdit(self.cpc))
        {
            self sendLocalChatMessage("Confirm/apply your current selection first, or Undo/Discard it before editing another checkpoint.");
            return;
        }
        if (idx == self.cpc.selected && openCJ\checkpointNetwork::pendingEdit(self.cpc))
            return;
        args[1] = "" + (idx + 1);
    }
    if ((args[0] == "select" || args[0] == "edit") && args.size == 2 && (isValidInt(args[1]) || args[1] == "last"))
    {
        idx = self.cpc.rows.size - 1;
        if (args[1] != "last")idx = int(args[1]) - 1;
        if (idx >= 0 && idx < self.cpc.rows.size)
        {
            self _remember();
            self.cpc.alternativeBlocked = undefined;
            self.cpc.overlap = undefined;
            self.cpc.selected = idx;
            self.cpc.draft = _decode(self.cpc.rows[idx]);
            self.cpc.status = "Editing checkpoint " + (idx + 1) + "; confirm/apply with Num Enter";
            self _save();
        }
        return;
    }
    if (args[0] == "delete" && args.size > 1)
    {
        if (args.size != 2 || toLower(args[1]) != "area")
        {
            self sendLocalChatMessage("Use !cp delete area for one area, or !cp delete for the whole checkpoint.");
            return;
        }
        self _action("deletearea");
        return;
    }
    if(args[0]=="height" && args.size>1)
    {
        if(args.size!=2 || !isValidFloat(args[1])){self sendLocalChatMessage("Use !cpc height to toggle editing, or !cpc height <units>");return;}
        self.cpc.heightRequestValue=float(args[1]);self _action("heightset");return;
    }
    self _action(args[0]);
}

// Detection warns without selecting, overwriting or blocking intentional edits.
// Only this player's draft and public gameplay checkpoints are inspected.
detectedCheckpointWarning(points)
{
    for (i = 0; i < self.cpc.rows.size; i++)
    {
        // Editing/appending alternatives to this logical checkpoint is allowed.
        if (i == self.cpc.selected) continue;
        cp = _decode(self.cpc.rows[i]);
        if (!isDefined(cp)) continue;
        match = openCJ\checkpointNetwork::areaOverlap(self.cpc.draft, cp, cp.points);
        for (j = 0; !match && j < cp.alternatives.size; j++)
            match = openCJ\checkpointNetwork::areaOverlap(self.cpc.draft, cp, cp.alternatives[j]);
        if (match)
            return "Checkpoint #" + (i + 1) + " already exists here in " + self.cpc.route + ". Use !cp edit " + (i + 1) + " to edit it.";
    }
    if (isDefined(level.checkpoints_checkpoints))
        for (i = 0; i < level.checkpoints_checkpoints.size; i++)
        {
            cp = level.checkpoints_checkpoints[i];
            if (!isDefined(cp.area) || !openCJ\checkpointNetwork::areaOverlap(self.cpc.draft, cp, cp.area)) continue;
            route = "";
            if (isDefined(cp.routeInfo)) route = " (" + cp.routeInfo.name + ")";
            return "Published checkpoint #" + cp.id + route + " already exists here.";
        }
    return "";
}

// Alternatives belong to one checkpoint; distinct overlapping checkpoints are ambiguous.
checkpointAt(rows, origin, grounded)
{
    found = -1;
    for (i = 0; i < rows.size; i++)
    {
        cp = _decode(rows[i]);
        if (!isDefined(cp) || !self contains(cp, origin, grounded))
            continue;
        if (found >= 0)
            return -2;
        found = i;
    }
    return found;
}

_validName(name)
{
    if (name.size < 1 || name.size > 20)
        return false;
    for (i = 0; i < name.size; i++)
    {
        if (!isSubStr("abcdefghijklmnopqrstuvwxyz0123456789_+", name[i]))
            return false;
    }
    return true;
}

defaultRouteColor(route)
{
    switch (toLower(route))
    {
        case "easy": return "#00ff00";
        case "inter": return "#ffff00";
        case "inter+": return "#ff8800";
        case "hard": return "#ff7777";
        case "hard+": return "#aa0000";
        case "adv":
        case "advanced": return "#aa55ff";
        case "adv+":
        case "advanced+": return "#ff77cc";
    }
    return "#00ccff";
}

routeRGB(hex)
{
    if (hex.size != 7 || hex[0] != "#")
        return undefined;
    hex = toLower(hex);
    digits = "0123456789abcdef";
    channels = [];
    for (i = 0; i < 3; i++)
    {
        value = 0;
        for (j = 0; j < 2; j++)
        {
            for (n = 0; n < 16 && digits[n] != hex[1 + i * 2 + j]; n++) {}
            if (n == 16)
                return undefined;
            value = value * 16 + n;
        }
        channels[i] = value / 255.0;
    }
    return (channels[0], channels[1], channels[2]);
}

_empty()
{
    cp = spawnStruct();
    cp.points = [];
    cp.alternatives = [];
    cp.finish = false;
    cp.double = false;
    cp.onGround = true;
    cp.allowSave = true;
    cp.allowEle = false;
    cp.heightAbove = 0;
    return cp;
}

_encode(cp)
{
    text = int(cp.finish) + ":" + int(cp.double) + ":p" + openCJ\checkpointArea::encode(cp.points);
    for (i = 0; i < cp.alternatives.size; i++)
        text += "|p" + openCJ\checkpointArea::encode(cp.alternatives[i]);
    if (cp.heightAbove>0)
    {
        key="-";if(openCJ\checkpointMoving::isMoving(cp))key=cp.platformRef;
        return text+":"+int(cp.onGround)+":"+int(cp.allowSave)+":"+int(cp.allowEle)+":"+key+":"+floatToPreciseString(cp.heightAbove);
    }
    if (openCJ\checkpointMoving::isMoving(cp)) text += ":" + int(cp.onGround) + ":" + int(cp.allowSave) + ":" + int(cp.allowEle) + ":" + cp.platformRef;
    else if (cp.allowEle) text += ":" + int(cp.onGround) + ":" + int(cp.allowSave) + ":1";
    else if (!cp.allowSave) text += ":" + int(cp.onGround) + ":0";
    else if (!cp.onGround) text += ":0";
    return text;
}

_decode(row)
{
    values = strTok(row, ":");
    if ((values.size != 3 && values.size != 4 && values.size != 5 && values.size != 6 && values.size != 7 && values.size != 8) || (values[0] != "0" && values[0] != "1") || (values[1] != "0" && values[1] != "1"))
        return undefined;
    if (values[2][0] != "p")
        return undefined;
    cp = _empty();
    cp.finish = int(values[0]);
    cp.double = int(values[1]);
    if (values.size >= 4)
    {
        if (values[3] != "0" && values[3] != "1") return undefined;
        cp.onGround = int(values[3]);
    }
    if (values.size >= 5)
    {
        if (values[4] != "0" && values[4] != "1") return undefined;
        cp.allowSave = int(values[4]);
    }
    if (values.size >= 6)
    {
        if (values[5] != "0" && values[5] != "1") return undefined;
        cp.allowEle = int(values[5]);
    }
    if (values.size == 8)
    {
        if(!isValidFloat(values[7]))return undefined;
        cp.heightAbove=float(values[7]);
        if(!openCJ\checkpointHeight::valid(cp.heightAbove))return undefined;
    }
    if (values.size == 7 || (values.size == 8 && values[6]!="-"))
    {
        if (values[6].size < 2 || values[6].size > 101 || (values[6][0] != "b" && values[6][0] != "n")) return undefined;
        cp.platformRef = values[6];
    }
    areas = strTok(values[2], "|");
    if (areas.size > 8)
        return undefined;
    if (openCJ\checkpointMoving::isMoving(cp) && areas.size != 1) return undefined;
    cp.points = openCJ\checkpointArea::decode(getSubStr(areas[0], 1));
    if (!isDefined(cp.points))
        return undefined;
    for (i = 1; i < areas.size; i++)
    {
        if (areas[i][0] != "p")
            return undefined;
        points = openCJ\checkpointArea::decode(getSubStr(areas[i], 1));
        if (!isDefined(points) || openCJ\checkpointArea::validate(points) != "")
            return undefined;
        cp.alternatives[cp.alternatives.size] = points;
    }
    return cp;
}

// The active area and its alternatives share requirements and one progress step.
contains(cp, origin, grounded)
{
    if (openCJ\checkpointMoving::isMoving(cp))
    {
        if (!isDefined(self) || !isPlayer(self)) return false;
        return self openCJ\checkpointMoving::touches(cp, grounded, self getGroundEntity());
    }
    if (openCJ\checkpointArea::touchesPlayer(cp.points, origin, grounded, cp.onGround, cp.heightAbove))
        return true;
    for (i = 0; i < cp.alternatives.size; i++)
    {
        if (openCJ\checkpointArea::touchesPlayer(cp.alternatives[i], origin, grounded, cp.onGround, cp.heightAbove))
            return true;
    }
    return false;
}

_addAlternative()
{
    selected = self.cpc.selected;
    cp = self.cpc.draft;
    if (selected == self.cpc.rows.size && cp.points.size == 0 && cp.alternatives.size == 0 && self.cpc.rows.size > 0)
    {
        selected--;
        cp = _decode(self.cpc.rows[selected]);
    }
    if (openCJ\checkpointMoving::isMoving(cp))
    {
        self.cpc.status = "This checkpoint already covers the whole moving platform";
        return;
    }
    // Validate before reopening a confirmed area. A rejected add must never
    // turn the following Detect into an edit of the previous platform.
    if (openCJ\checkpointArea::validate(cp.points) != "" || cp.alternatives.size >= 7)
    {
        self.cpc.alternativeBlocked = true;
        self.cpc.status = "Cannot add area: confirm a valid selection first; maximum 8 areas. Use Undo or New";
        return;
    }
    self.cpc.alternativeBlocked = undefined;
    self.cpc.selected = selected;
    self.cpc.draft = cp;
    cp.alternatives[cp.alternatives.size] = cp.points;
    cp.points = [];
    self.cpc.status = "Adding area " + (cp.alternatives.size + 1) + " to checkpoint " + (selected + 1);
}

_start(route, hex)
{
    self openCJ\mapBoost::cancel();
    route = self openCJ\checkpointNetwork::resolve(route);
    if (!isDefined(route))
    {
        self sendLocalChatMessage("Network draft files exist but cannot be read; preserved for recovery.", true);
        return;
    }
    self notify("cpc_started");
    self.cpc = spawnStruct();
    self.cpc.route = route;
    self.cpc.rows = [];
    self.cpc.draft = _empty();
    self.cpc.selected = 0;
    self.cpc.revision = 0;
    self.cpc.history = [];
    self.cpc.testing = false;
    self.cpc.status = "";
    self.cpc.path = "checkpoints/drafts/" + self openCJ\login::getPlayerID() + "_" + getCvar("mapname") + "_" + route;
    a = _read(self.cpc.path + ".a", route);
    b = _read(self.cpc.path + ".b", route);
    if (!isDefined(a) && !isDefined(b) && (FS_TestFile(self.cpc.path + ".a") || FS_TestFile(self.cpc.path + ".b")))
    {
        self iprintln("Draft files exist but neither is valid. They have been preserved for recovery");
        self.cpc = undefined;
        return;
    }
    latest = a;
    if (isDefined(b) && (!isDefined(a) || b.revision > a.revision))
        latest = b;
    if (isDefined(latest))
    {
        self.cpc.sharedRoute = latest.sharedRoute;
        self.cpc.sharedHex = latest.sharedHex;
        self.cpc.sharedCount = latest.sharedCount;
        self.cpc.rows = latest.rows;
        self.cpc.draft = latest.draft;
        self.cpc.selected = latest.selected;
        self.cpc.insertAfter = latest.insertAfter;
        self.cpc.revision = latest.revision;
        self sendLocalChatMessage("Restored " + route + " draft (" + latest.rows.size + " confirmed checkpoints)");
        self.cpc.savedPosition = latest.savedPosition;
        self.cpc.restoreOrigin = restoreOrigin(latest);
        if (isDefined(latest.savedPosition))
        {
            self.cpc.restoreOrigin = latest.savedPosition.origin;
            self.cpc.restoreAngles = latest.savedPosition.angles;
        }
    }
    if (!isDefined(hex) && isDefined(latest) && isDefined(latest.routeHex))
        hex = latest.routeHex;
    if (!isDefined(hex) && isDefined(level.checkpointRoutes) && isDefined(level.checkpointRoutes[route]))
        hex = level.checkpointRoutes[route].hex;
    if (!isDefined(hex))
        hex = defaultRouteColor(route);
    if (isDefined(self.cpc.sharedRoute) && !isDefined(self.cpc.sharedHex))
        self.cpc.sharedHex = defaultRouteColor(self.cpc.sharedRoute);
    self.cpc.routeHex = hex;
    self.cpc.routeColor = routeRGB(hex);
    self openCJ\checkpointNetwork::opened();
    self.cpc.huds = [];
    for (i = 0; i < 4; i++)
    {
        if (i == 2) continue; // Properties use the client HUD for smaller, crisp text.
        self.cpc.huds[i] = newClientHudElem(self);
        self.cpc.huds[i].lastText = "";
        configureHud(self.cpc.huds[i]);
    }
    // Two compact columns: headers share the top row, body starts below them.
    self.cpc.huds[0].x = 282;
    self.cpc.huds[0].font = "objective";
    self.cpc.huds[0].color = (0.75,0.85,1);
    self.cpc.huds[1].y = 30;
    self.cpc.huds[3].fontScale = 1.4;
    self.cpc.huds[3].color = self.cpc.routeColor;
    self setClientCvar("developer", 1);
    self.cpc.positions = [];
    if (isDefined(self.cpcTravelPositions))
        self.cpc.positions = self.cpcTravelPositions;
    self.cpc.travelIndex = 0;
    // Entering the editor must not replace a manual save with the spawn position.
    if (!isDefined(self.cpc.restoreOrigin) && self.cpc.positions.size == 0)
    {
        pos = spawnStruct();
        pos.origin = self.origin;
        pos.angles = self getPlayerAngles();
        self rememberPosition(pos);
    }
    self openCJ\buttonPress::resetButtons();
    if (self openCJ\playerRuns::hasRunID())
        self openCJ\playerRuns::stopRun(false);
    self openCJ\huds\hudRunInfo::onRunStopped();
    self openCJ\huds\hudSpeedometer::_hideSpeedometer();
    self openCJ\huds\hudProgressBar::onRunStopped();
    // The mod's existing client-command menu applies these without a local cfg.
    self execClientCmd("bind KP_INS say !cp detect; bind KP_5 say !cp detect; " +
        "bind KP_ENTER say !cp confirm; bind KP_PLUS say !cp corner; bind KP_MINUS say !cp undo; " +
        "bind KP_UPARROW say !cp ele; bind KP_END say !cp double; bind KP_PGUP say !cp finish; bind KP_DOWNARROW say !cp ground; bind KP_PGDN say !cp allowsave; " +
        "bind KP_LEFTARROW say !cp previous; bind KP_RIGHTARROW say !cp next; " +
        "bind KP_DEL say !cp discard; bind KP_HOME say !cp height; bind KP_SLASH say !cp alternative; bind KP_STAR say !cp area");
    self thread _loop();
}

restoreOrigin(draft)
{
    cp=draft.draft;
    points = openCJ\checkpointMoving::points(cp);
    if (openCJ\checkpointArea::validate(points) != "" && draft.draft.alternatives.size > 0)
        points = draft.draft.alternatives[draft.draft.alternatives.size - 1];
    if (openCJ\checkpointArea::validate(points) != "" && draft.rows.size > 0)
    {
        index = draft.selected;
        if (index >= draft.rows.size)
            index = draft.rows.size - 1;
        cp = _decode(draft.rows[index]);
        points = openCJ\checkpointMoving::points(cp);
    }
    if (openCJ\checkpointArea::validate(points) != "")
        return undefined;
    // _center adds 12 for labels; leave two units above the capsule support height.
    extra=openCJ\checkpointHeight::above(cp);
    if(extra>0)extra+=4; // Resume above a curved surface, not inside its base plane.
    return _center(points) + (0, 0, openCJ\checkpointArea::supportOffset(points) - 10 + extra);
}

configureHud(hud)
{
    // The current pool is already close to its 31-element snapshot limit.
    hud.archived = true;
    hud.x = 124;
    hud.y = 6;
    hud.font = "default";
    hud.sort = 1;
    hud.alignX = "left";
    hud.alignY = "top";
    hud.horzAlign = "left";
    hud.vertAlign = "top";
    hud.fontScale = 1.4;
    hud.foreground = true;
    hud.hideWhenInMenu = true;
    hud.alpha = 1;
}

// Spectating suspends the editor without closing its draft or selection.
onSpawnSpectator()
{
    if (!self isEditing() || isDefined(self.cpc.suspended)) return;
    self.cpc.suspended = true;
    self.cpc.restoreOrigin = undefined;
    self.cpc.restoreAngles = undefined;
    self openCJ\buttonPress::resetButtons();
    keys = getArrayKeys(self.cpc.huds);
    for (i = 0; i < keys.size; i++) self.cpc.huds[keys[i]].alpha = 0;
    self setClientCvar("opencj_cpc_properties", "");
    self setClientCvar("opencj_cpc_panel_height", 0);
    self _save();
}

onSpawnPlayer()
{
    if (!self isEditing()) return;
    self.cpc.suspended = undefined;
    // Normal spawning must not replay a pending draft-restoration teleport.
    self.cpc.restoreOrigin = undefined;
    self.cpc.restoreAngles = undefined;
    keys = getArrayKeys(self.cpc.huds);
    for (i = 0; i < keys.size; i++) self.cpc.huds[keys[i]].alpha = 1;
    self.cpc.propertiesText = undefined;
    self.cpc.panelHeight = undefined;
    self openCJ\huds\hudRunInfo::onRunStopped();
    self openCJ\huds\hudStatistics::onRunStopped();
    self openCJ\huds\hudSpeedometer::_hideSpeedometer();
    self openCJ\showRecords::onRunStopped();
}

_loop()
{
    self endon("disconnect");
    self endon("cpc_stopped");
    nextDraw = 0;
    while (self isEditing())
    {
        if (self.sessionState != "playing")
        {
            self onSpawnSpectator();
            nextDraw = 0;
            wait 0.05;
            continue;
        }
        // Starting/loading a run must not resume scoring while editing.
        if (self openCJ\playerRuns::hasRunID())
            self openCJ\playerRuns::stopRun(false);
        if (!self isEditing())
            return;
        if (self.cpc.testing)
            self _testStep();
        if (getTime() >= nextDraw)
        {
            nextDraw = getTime() + 500;
            self openCJ\checkpointNetwork::trackSharedLanding(self.origin, self isOnGround());
            self.cpc.drawCommands = 0;
            self _draw();
        }
        wait 0.05;
    }
}

_remember()
{
    snapshot = spawnStruct();
    snapshot.rows = [];
    for (i = 0; i < self.cpc.rows.size; i++)
        snapshot.rows[i] = self.cpc.rows[i];
    snapshot.draft = _encode(self.cpc.draft);
    snapshot.selected = self.cpc.selected;
    snapshot.insertAfter = self.cpc.insertAfter;
    if (self.cpc.history.size == 32)
    {
        for (i = 1; i < 32; i++)
            self.cpc.history[i - 1] = self.cpc.history[i];
        self.cpc.history[31] = undefined;
    }
    self.cpc.history[self.cpc.history.size] = snapshot;
}

_action(action)
{
    if(isDefined(self.cpc.insertAfter) && (action=="new" || action=="previous" || action=="next" || action=="delete" || action=="alternative" || action=="finalize" || action=="publish" || action=="test"))
    {
        self.cpc.status="Confirm or discard the insertion first";
        return;
    }
    if(action=="insert")
    {
        self.cpc.status="After: !cpc postsert | Before: !cpc presert";
        self sendLocalChatMessage("To add after the selected checkpoint, use !cpc postsert. To add before it, use !cpc presert.");
        return;
    }
    if(action=="postsert" || action=="presert")
    {
        self beginInsertion(action=="presert");
        return;
    }
    if (action == "stop")
    {
        self stop();
        return;
    }
    if (action == "save")
    {
        self _save();
        return;
    }
    if (action == "finalize" || action == "publish")
    {
        if (!isDefined(self.cpc.finalizing))
        {
            self.cpc.finalizing = true;
            self thread doNextFrame(::finalize);
        }
        return;
    }
    if (action == "test")
    {
        self.cpc.testing = !self.cpc.testing;
        self.cpc.testNext = 0;
        self.cpc.status = "Test uses confirmed checkpoints; !cp test returns to editing";
        return;
    }
    if (self.cpc.testing)
    {
        self.cpc.status = "Use !cp test to leave test mode before editing";
        return;
    }
    // When the panel shows the last checkpoint, property keys edit that checkpoint.
    if ((action == "finish" || action == "double" || action == "ele" || action == "ground" || action == "allowsave" || action == "height" || action == "heightset") &&
        !isDefined(self.cpc.insertAfter) && self.cpc.selected == self.cpc.rows.size && self.cpc.rows.size > 0 &&
        self.cpc.draft.points.size == 0 && self.cpc.draft.alternatives.size == 0)
        self _action("previous");
    if(isDefined(self.cpc.heightTarget))
    {
        if(action=="corner")action="heightup";
        else if(action=="undo")action="heightdown";
    }
    if (action == "undo")
    {
        self.cpc.alternativeBlocked = undefined;
        self.cpc.overlap = undefined;
        if (self.cpc.history.size == 0)
            return;
        n = self.cpc.history.size - 1;
        snapshot = self.cpc.history[n];
        self.cpc.rows = snapshot.rows;
        self.cpc.draft = _decode(snapshot.draft);
        self.cpc.selected = snapshot.selected;
        self.cpc.insertAfter = snapshot.insertAfter;
        self.cpc.heightTarget = undefined;
        self.cpc.history[n] = undefined;
        self.cpc.status = "Undone";
        self _save();
        return;
    }
    if (action == "discard")
    {
        self _discard();
        return;
    }
    if (isDefined(self.cpc.sharedCount) && action != "new" && action != "previous" && action != "next" && action != "area")
    {
        target = self.cpc.selected;
        if (action == "alternative" && target == self.cpc.rows.size && self.cpc.draft.points.size == 0)
            target--;
        if (target < self.cpc.sharedCount)
        {
            self.cpc.status = "Shared opening is read-only in a branch; use !cp new to continue";
            return;
        }
    }
    if (action == "new" || action == "previous" || action == "next")
    {
        self.cpc.alternativeBlocked = undefined;
        self.cpc.overlap = undefined;
    }
    if (isDefined(self.cpc.alternativeBlocked))
        return;
    if (action == "replace" && self.cpc.selected >= self.cpc.rows.size)
    {
        self.cpc.status = "Select an existing checkpoint with !cp edit <number> first";
        return;
    }
    self _remember();
    switch (action)
    {
        case "height":
        case "heightup":
        case "heightdown":
        case "heightset": self openCJ\checkpointHeight::edit(action);break;
        case "alternative":
            self _addAlternative();
            break;
        case "area":
            cp = self.cpc.draft;
            if (cp.alternatives.size > 0 && openCJ\checkpointArea::validate(cp.points) == "")
            {
                points = cp.points;
                cp.points = cp.alternatives[0];
                for (i = 1; i < cp.alternatives.size; i++)
                    cp.alternatives[i - 1] = cp.alternatives[i];
                cp.alternatives[cp.alternatives.size - 1] = points;
                self.cpc.status = "Selected another area of this checkpoint";
            }
            break;
        case "detect":
            ground = self getGroundEntity();
            if (self isOnGround() && isDefined(ground))
            {
                key = openCJ\checkpointMoving::reference(ground);
                if (!isDefined(key))
                {
                    self.cpc.status = "Cannot identify this platform persistently; selection unchanged";
                    break;
                }
                if (self.cpc.draft.alternatives.size)
                {
                    self.cpc.status = "Create a separate checkpoint for a whole moving platform";
                    break;
                }
                self.cpc.draft.platformRef = key;
                self.cpc.draft.points = openCJ\checkpointMoving::points(self.cpc.draft);
                self.cpc.status = "Moving platform selected: the whole platform counts";
                self.cpc.overlap = undefined;
                self openCJ\checkpointNetwork::selectDetectedShared();
                self openCJ\checkpointNetwork::checkOverlap();
                warning = self detectedCheckpointWarning(self.cpc.draft.points);
                if (warning != "") self sendLocalChatMessage(warning, true);
                break;
            }
            points = self openCJ\checkpointPlatform::getRectangularPlatformOrgs();
            if (isDefined(points))
            {
                self.cpc.draft.platformRef = undefined;
                self.cpc.draft.points = points;
                self.cpc.status = "Platform detected";
                self openCJ\checkpointNetwork::selectDetectedShared();
                self openCJ\checkpointNetwork::checkOverlap();
                if (!isDefined(self.cpc.overlap))
                {
                    warning = self detectedCheckpointWarning(points);
                    if (warning != "")
                    {
                        self.cpc.status = warning;
                        self.cpc.lastPanelStatus = warning;
                        self sendLocalChatMessage(warning, true);
                    }
                }
            }
            else
                self.cpc.status = "Detection failed; selection unchanged";
            break;
        case "corner":
            if (openCJ\checkpointMoving::isMoving(self.cpc.draft)) break;
            if (self.cpc.draft.points.size >= 8)
                break;
            eye = self getEyePos();
            trace = bulletTrace(eye, eye + vectorScale(anglesToForward(self getPlayerAngles()), 1000), false, self);
            if (trace["fraction"] < 1)
            {
                self.cpc.draft.points[self.cpc.draft.points.size] = trace["position"];
                self.cpc.draft.points = openCJ\checkpointArea::orderCorners(self.cpc.draft.points);
                self.cpc.status = "Corner added (" + self.cpc.draft.points.size + "/8)";
            }
            break;
        case "confirm":
            // Repair click-order crossings in drafts saved before automatic ordering.
            self.cpc.draft.points = openCJ\checkpointArea::orderCorners(self.cpc.draft.points);
            candidate=_decode(_encode(self.cpc.draft));
            if(openCJ\checkpointHeight::flatten(candidate))
            {
                collision=self openCJ\checkpointHeight::conflict(candidate);
                if(collision!=""){self.cpc.status="Cannot flatten: overlaps "+collision;return;}
                self.cpc.draft=candidate;
            }
            if(self.cpc.draft.heightAbove>0)
            {
                collision=self openCJ\checkpointHeight::conflict(self.cpc.draft);
                if(collision!=""){self.cpc.status="Cannot confirm: overlaps "+collision;return;}
            }
            self openCJ\checkpointNetwork::checkOverlap();
            if (isDefined(self.cpc.overlap))
            {
                self.cpc.status = "Overlapping section: merge the routes here; split where they separate";
                return;
            }
            error = openCJ\checkpointMoving::valid(self.cpc.draft);
            if (error != "")
            {
                self.cpc.status = error;
                return;
            }
            if (self.cpc.selected >= 256)
            {
                self.cpc.status = "Maximum 256 checkpoints per route";
                return;
            }
            followingShared = self openCJ\checkpointNetwork::followingShared();
            if(isDefined(self.cpc.insertAfter))
            {
                self confirmInsertion();
                break;
            }
            self.cpc.rows[self.cpc.selected] = _encode(self.cpc.draft);
            self.cpc.status = "";
            if (followingShared)
                break;
            self.cpc.selected = self.cpc.rows.size;
            self.cpc.draft = _empty();
            self.cpc.heightTarget=undefined;
            break;
        case "ele": self.cpc.draft.allowEle = !self.cpc.draft.allowEle; break;
        case "allowsave": self.cpc.draft.allowSave = !self.cpc.draft.allowSave; break;
        case "ground": self.cpc.draft.onGround = !self.cpc.draft.onGround; break;
        case "finish": self.cpc.draft.finish = !self.cpc.draft.finish; break;
        case "double": self.cpc.draft.double = !self.cpc.draft.double; break;
        case "new":
            self.cpc.selected = self.cpc.rows.size;
            self.cpc.draft = _empty();
            self.cpc.heightTarget=undefined;
            break;
        case "previous":
        case "next":
            if (self.cpc.rows.size > 0)
            {
                step = 1;
                if (action == "previous")
                    step = -1;
                self.cpc.selected = (self.cpc.selected + self.cpc.rows.size + step) % self.cpc.rows.size;
                self.cpc.draft = _decode(self.cpc.rows[self.cpc.selected]);
            }
            break;
        case "replace":
            // Keep the original confirmed row until Apply succeeds. Its index,
            // requirements, incoming link and outgoing link remain unchanged.
            self.cpc.draft.platformRef = undefined;
            self.cpc.draft.points = [];
            self.cpc.draft.alternatives = [];
            self.cpc.overlap = undefined;
            self.cpc.status = "Detect replacement, then Apply; checkpoint position and links are kept";
            break;
        case "deletearea":
            // Area cycling rotates the active geometry into points. Remove only
            // that geometry, promoting an alternative when one is available.
            self.cpc.draft = removeSelectedArea(self.cpc.draft);
            self.cpc.overlap = undefined;
            self.cpc.status = "Area removed from selection; Apply to keep, or detect its replacement";
            break;
        case "delete":
            if (self.cpc.selected < self.cpc.rows.size)
            {
                for (i = self.cpc.selected + 1; i < self.cpc.rows.size; i++)
                    self.cpc.rows[i - 1] = self.cpc.rows[i];
                self.cpc.rows[self.cpc.rows.size - 1] = undefined;
            }
            self.cpc.selected = self.cpc.rows.size;
            self.cpc.draft = _empty();
            self.cpc.status = "Removed from draft; Undo restores it";
            break;
        default:
            self.cpc.status = "Unknown action; use !help cp";
            return;
    }
    self _save();
}

// Keep pending insertion geometry outside rows until Confirm succeeds.
beginInsertion(before)
{
    if(!isDefined(before))before=false;
    if(self.cpc.testing || isDefined(self.cpc.insertAfter) || self.cpc.selected>=self.cpc.rows.size)
    {self.cpc.status="Select a checkpoint with !cpc edit first";return false;}
    if(openCJ\checkpointNetwork::pendingEdit(self.cpc))
    {self.cpc.status="Apply or undo changes to the selected checkpoint first";return false;}
    if(self.cpc.rows.size>=256)
    {self.cpc.status="Maximum 256 checkpoints per route";return false;}
    index=self.cpc.selected+1-int(before);
    if(isDefined(self.cpc.sharedCount) && index<self.cpc.sharedCount)
    {self.cpc.status="Edit the shared opening draft to insert there";return false;}
    if(!before && self.cpc.draft.finish)
    {self.cpc.status="Select a checkpoint before the finish to insert after it";return false;}
    self _remember();
    self.cpc.insertAfter=index-1;
    self.cpc.selected=self.cpc.rows.size;
    self.cpc.draft=_empty();
    self.cpc.heightTarget=undefined;
    self.cpc.overlap=undefined;
    self.cpc.alternativeBlocked=undefined;
    self.cpc.status="Insert checkpoint "+(index+1)+": detect the missing landing, then confirm";
    self _save();
    return true;
}

confirmInsertion()
{
    index=self.cpc.insertAfter+1;
    for(i=self.cpc.rows.size;i>index;i--)self.cpc.rows[i]=self.cpc.rows[i-1];
    self.cpc.rows[index]=_encode(self.cpc.draft);
    self.cpc.selected=self.cpc.rows.size;
    self.cpc.draft=_empty();
    self.cpc.insertAfter=undefined;
    self.cpc.heightTarget=undefined;
    self.cpc.status="Inserted checkpoint "+(index+1)+"; following checkpoints shifted forward";
}

// Physical order in the draft also determines the incoming/outgoing links.
nextPreviewIndex(draft)
{
    if(isDefined(draft.insertAfter))return draft.insertAfter+1;
    return draft.selected+1;
}

// Geometry-only edit: callers retain the selected row and confirm explicitly.
removeSelectedArea(cp)
{
    cp.points = [];
    if (cp.alternatives.size > 0)
    {
        cp.points = cp.alternatives[0];
        for (i = 1; i < cp.alternatives.size; i++)
            cp.alternatives[i - 1] = cp.alternatives[i];
        cp.alternatives[cp.alternatives.size - 1] = undefined;
    }
    return cp;
}

// Delete the selected existing checkpoint; otherwise discard the pending new
// checkpoint, or the last confirmed checkpoint when in the empty append slot.
_discard()
{
    if(isDefined(self.cpc.insertAfter))
    {
        self _remember();
        self.cpc.selected=self.cpc.insertAfter;
        if(self.cpc.selected<0)self.cpc.selected=0;
        self.cpc.insertAfter=undefined;
        self.cpc.draft=_decode(self.cpc.rows[self.cpc.selected]);
        self.cpc.heightTarget=undefined;
        self.cpc.overlap=undefined;
        self.cpc.status="Insertion discarded; existing checkpoints unchanged";
        self _save();
        return;
    }
    if (self.cpc.selected < self.cpc.rows.size)
    {
        // Reuse Delete so selection, sequential links, shared protection and
        // Undo all behave identically to the explicit command.
        self _action("delete");
        return;
    }
    self.cpc.overlap = undefined;
    pending = self.cpc.selected == self.cpc.rows.size && (self.cpc.draft.points.size > 0 || self.cpc.draft.alternatives.size > 0);
    if (!pending && (self.cpc.rows.size == 0 || (isDefined(self.cpc.sharedCount) && self.cpc.rows.size <= self.cpc.sharedCount)))
    {
        self.cpc.status = "No branch checkpoint to discard; shared opening is protected";
        return;
    }
    self _remember();
    self.cpc.alternativeBlocked = undefined;
    if (pending)
        self.cpc.status = "Discarded unconfirmed checkpoint; [Num -] Undo";
    else
    {
        number = self.cpc.rows.size;
        self.cpc.rows[number - 1] = undefined;
        self.cpc.status = "Discarded checkpoint " + number + "; [Num -] Undo";
    }
    self.cpc.selected = self.cpc.rows.size;
    self.cpc.draft = _empty();
    self _save();
}

_save()
{
    revision = self.cpc.revision + 1;
    suffix = ".a";
    if (revision % 2)
        suffix = ".b";
    file = FS_FOpen(self.cpc.path + suffix, "write");
    if (!file)
    {
        self.cpc.status = "SAVE FAILED - draft remains in memory; retry !cp save";
        return false;
    }
    hex = self.cpc.routeHex;
    if (!isDefined(hex))
        hex = defaultRouteColor(self.cpc.route);
    if (isDefined(self.cpc.sharedRoute) && !isDefined(self.cpc.sharedHex))
        self.cpc.sharedHex = defaultRouteColor(self.cpc.sharedRoute);
    header = "CPC4 " + getCvar("mapname") + " " + self.cpc.route + " " + revision + " " + self.cpc.rows.size + " " + self.cpc.selected + " " + hex;
    if (isDefined(self.cpc.sharedRoute))
        header = "CPC6 " + getCvar("mapname") + " " + self.cpc.route + " " + revision + " " + self.cpc.rows.size + " " + self.cpc.selected + " " + hex + " " + self.cpc.sharedRoute + " " + self.cpc.sharedCount + " " + self.cpc.sharedHex;
    ok = FS_WriteLine(file, header);
    for (i = 0; i < self.cpc.rows.size; i++)
    {
        if (!FS_WriteLine(file, self.cpc.rows[i]))
            ok = false;
    }
    if (!FS_WriteLine(file, _encode(self.cpc.draft)))
        ok = false;
    if (isDefined(self.cpc.insertAfter) && !FS_WriteLine(file,"INSERT "+self.cpc.insertAfter))ok=false;
    if (isDefined(self.cpc.savedPosition))
    {
        travel = [];
        travel[0] = self.cpc.savedPosition.origin;
        travel[1] = self.cpc.savedPosition.angles;
        if (!FS_WriteLine(file, "TRAVEL " + openCJ\checkpointArea::encode(travel)))
            ok = false;
    }
    if (!FS_WriteLine(file, "END " + revision))
        ok = false;
    FS_FClose(file);
    if (ok)
        self.cpc.revision = revision;
    else
        self.cpc.status = "SAVE FAILED - previous complete draft retained; retry !cp save";
    return ok;
}

_read(path, route)
{
    file = FS_FOpen(path, "read");
    if (!file)
        return undefined;
    result = _readFile(file, route);
    FS_FClose(file);
    return result;
}

_readFile(file, route)
{
    line = FS_ReadLine(file);
    if (!isDefined(line))
        return undefined;
    header = strTok(line, " ");
    coloredBranch = header.size == 10 && header[0] == "CPC6";
    branched = (header.size == 9 && header[0] == "CPC5") || coloredBranch;
    modern = (header.size == 7 && header[0] == "CPC4") || branched;
    legacy = header.size == 6 && (header[0] == "CPC2" || header[0] == "CPC3");
    if ((!modern && !legacy) || header[1] != getCvar("mapname") || header[2] != route)
        return undefined;
    if (modern && !isDefined(routeRGB(header[6])))
        return undefined;
    for (i = 3; i < 6; i++)
    {
        if (!isValidInt(header[i]))
            return undefined;
    }
    count = int(header[4]);
    if (count < 0 || count > 256 || int(header[5]) < 0 || int(header[5]) > count)
        return undefined;
    result = spawnStruct();
    if (modern)
        result.routeHex = header[6];
    if (branched)
    {
        if (!_validName(header[7]) || header[7] == route || !isValidInt(header[8]) || int(header[8]) < 1 || int(header[8]) > count)
            return undefined;
        result.sharedRoute = header[7];
        result.sharedCount = int(header[8]);
        result.sharedHex = defaultRouteColor(result.sharedRoute);
        if (coloredBranch)
        {
            if (!isDefined(routeRGB(header[9])))return undefined;
            result.sharedHex = header[9];
        }
    }
    result.revision = int(header[3]);
    result.selected = int(header[5]);
    result.rows = [];
    for (i = 0; i <= count; i++)
    {
        row = FS_ReadLine(file);
        if (!isDefined(row))
            return undefined;
        cp = _decode(row);
        if (!isDefined(cp))
            return undefined;
        if (i < count)
        {
            if (!openCJ\checkpointMoving::isMoving(cp) && openCJ\checkpointArea::validate(cp.points) != "")
                return undefined;
            result.rows[i] = row;
        }
        else
            result.draft = cp;
    }
    end = FS_ReadLine(file);
    if(isDefined(end) && getSubStr(end,0,7)=="INSERT ")
    {
        value=getSubStr(end,7);
        if(!isValidInt(value) || int(value)<-1 || int(value)>=count || result.selected!=count)return undefined;
        result.insertAfter=int(value);
        end=FS_ReadLine(file);
    }
    if (isDefined(end) && getSubStr(end, 0, 7) == "TRAVEL ")
    {
        travel = openCJ\checkpointArea::decode(getSubStr(end, 7));
        if (!isDefined(travel) || travel.size != 2) return undefined;
        result.savedPosition = spawnStruct();
        result.savedPosition.origin = travel[0];
        result.savedPosition.angles = travel[1];
        end = FS_ReadLine(file);
    }
    if (!isDefined(end) || end != "END " + result.revision)
        return undefined;
    return result;
}

stop(quiet)
{
    if (!self isEditing())
        return true;
    if (!self _save())
    {
        self iprintln(self.cpc.status);
        return false;
    }
    self _close();
    if (!isDefined(quiet) || !quiet)
        self iprintln("Checkpoint draft saved. Reset your run before normal play");
    return true;
}

_close()
{
    self notify("cpc_stopped");
    self setClientCvar("developer", 0);
    self setClientCvar("opencj_cpc_properties", "");
    // Properties use a client menu, leaving a hole in the HUD array.
    keys = getArrayKeys(self.cpc.huds);
    for (i = 0; i < keys.size; i++)
        if (isDefined(self.cpc.huds[keys[i]])) self.cpc.huds[keys[i]] destroy();
    self.cpcTravelPositions = self.cpc.positions;
    self.cpc = undefined;
    self openCJ\huds\hudProgressBar::onRunStopped();
}

finalize()
{
    if (!self isEditing())
        return;
    self.cpc.finalizing = true;
    if (!self _save() || !self openCJ\checkpointPublish::publish())
    {
        self.cpc.finalizing = undefined;
        self sendLocalChatMessage(self.cpc.status, true);
        return;
    }
    route = self.cpc.route;
    if (isDefined(self.cpc.publishedLabel))route = self.cpc.publishedLabel;
    self openCJ\checkpointPublish::activate();
    // Creating the fresh run waits for SQL. Keep CPC's scoring suppression until
    // onRunCreated has reset checkpoint state and actually spawned the player.
    self openCJ\playerRuns::stopRun(true);
    self _close();
    self openCJ\huds\hudProgressBar::onSpawnPlayer();
    self openCJ\checkpointPointers::showCheckpointPointers();
    self sendLocalChatMessage("Checkpoints for " + route + " finalized and ready to play.");
}

onDisconnect()
{
    if (self isEditing())
        self _save();
}

_testStep()
{
    n = self.cpc.testNext;
    if (n >= self.cpc.rows.size)
        return;
    cp = _decode(self.cpc.rows[n]);
    if (cp.finish)
    {
        for (i = n; i < self.cpc.rows.size; i++)
        {
            finish = _decode(self.cpc.rows[i]);
            if (finish.finish && self contains(finish, self.origin, self isOnGround()))
            {
                self.cpc.testNext = self.cpc.rows.size;
                self.cpc.status = "TEST: FINISH " + (i + 1);
                self iprintln(self.cpc.status);
                return;
            }
        }
        return;
    }
    if (self contains(cp, self.origin, self isOnGround()))
    {
        self.cpc.testNext++;
        self.cpc.status = "TEST: passed " + (n + 1) + " / " + self.cpc.rows.size;
        if (cp.finish)
            self.cpc.status += " - FINISH";
        self iprintln(self.cpc.status);
    }
    else
    {
        for (i = n + 1; i < self.cpc.rows.size; i++)
        {
            later = _decode(self.cpc.rows[i]);
            if (self contains(later, self.origin, self isOnGround()))
            {
                self.cpc.status = "TEST: out of order - expected " + (n + 1) + ", entered " + (i + 1);
                break;
            }
        }
    }
}

// An empty next slot after a confirmed finish is a route summary, not a new area.
readyToFinalize(draft)
{
    if (isDefined(draft.insertAfter))return false;
    if (draft.selected != draft.rows.size || draft.rows.size == 0 || draft.draft.points.size > 0 || draft.draft.alternatives.size > 0)
        return false;
    last = _decode(draft.rows[draft.rows.size - 1]);
    return isDefined(last) && last.finish;
}

_draw()
{
    cp = self.cpc.draft;
    number = self.cpc.selected + 1;
    inserting=isDefined(self.cpc.insertAfter);
    if(inserting)number=self.cpc.insertAfter+2;
    followingShared = !self.cpc.testing && self openCJ\checkpointNetwork::followingShared();
    summary = !self.cpc.testing && !followingShared && readyToFinalize(self.cpc);
    if (summary)
    {
        number = self.cpc.rows.size;
        cp = _decode(self.cpc.rows[number - 1]);
    }
    if (self.cpc.testing && self.cpc.testNext < self.cpc.rows.size)
    {
        cp = _decode(self.cpc.rows[self.cpc.testNext]);
        number = self.cpc.testNext + 1;
    }
    error = openCJ\checkpointMoving::valid(cp);
    displayColor = self.cpc.routeColor;
    displayRoute = self.cpc.route;
    if (isDefined(self.cpc.displayRoutes))displayRoute = self.cpc.displayRoutes;
    if (isDefined(self.cpc.sharedCount) && number <= self.cpc.sharedCount)
    {
        displayColor = routeRGB(self.cpc.sharedHex);
        displayRoute = self.cpc.sharedRoute + " (shared)";
    }
    self.cpc.huds[3].color = displayColor;
    self.cpc.huds[3] _setPanelText(getSubStr(displayRoute, 0, 16) + " (" + self.cpc.rows.size + ")");
    props = cp;
    heading = "Selected checkpoint";
    empty = self.cpc.draft.points.size == 0 && self.cpc.draft.alternatives.size == 0;
    if (!inserting && !self.cpc.testing && !followingShared && empty && self.cpc.selected == self.cpc.rows.size && self.cpc.rows.size > 0)
    {
        props = _decode(self.cpc.rows[self.cpc.rows.size - 1]);
        heading = "Last checkpoint";
    }
    else if (self.cpc.selected < self.cpc.rows.size)
        heading = "Checkpoint #" + number;
    if(inserting)heading="Insert checkpoint "+number;
    if (openCJ\checkpointMoving::isMoving(props)) heading = "Moving platform";
    self.cpc.huds[0] _setPanelText(heading);
    doubleRPG = "Off"; finish = "No"; ground = "Yes";
    if (props.double) doubleRPG = "On";
    if (props.finish) finish = "Yes";
    if (!props.onGround) ground = "No";
    text = "Double RPG: " + doubleRPG + " [Num 1]";
    text += "\nFinish: " + finish + " [Num 9]";
    text += "\nOn ground: " + ground + " [Num 2]";
    saving = "Yes";
    if (!props.allowSave) saving = "No";
    text += "\nAllow save: " + saving + " [Num 3]";
    elevator = "No"; if (props.allowEle) elevator = "Yes";
    text += "\nAllow ele: " + elevator + " [Num 8]";
    if(isDefined(self.cpc.heightTarget))
    {
        text="Extra height: +"+openCJ\checkpointHeight::above(props)+" units\nStep: 4 units\nBottom: fixed\nOn ground: "+ground;
    }
    if (!isDefined(self.cpc.propertiesText) || self.cpc.propertiesText != text)
    {
        self setClientCvar("opencj_cpc_properties", text);
        self.cpc.propertiesText = text;
    }
    discardLabel = "^1Discard new:^7 Num Del";
    if (self.cpc.selected < self.cpc.rows.size)
        discardLabel = "^1Delete selected:^7 Num Del";
    else if (!inserting && (empty || summary))
        discardLabel = "^1Delete last:^7 Num Del";
    if (self.cpc.testing)
        text = "Follow the outline\nExit test: !cp test";
    else if(inserting)
    {
        text="Before checkpoint "+(self.cpc.insertAfter+2)+"\n^2Detect:^7 Num 0";
        if(self.cpc.insertAfter+1==self.cpc.rows.size)text="After checkpoint "+(self.cpc.insertAfter+1)+"\n^2Detect:^7 Num 0";
        if(!empty)text+="\n^2Confirm insert:^7 Num Enter";
        text+="\n"+discardLabel;
    }
    else if (followingShared)
    {
        text = "Follow shared landings\n^2Detect:^7 Num 0\n^5Split:^7 !cp split <routes>";
        if (cp.finish) text += "\n^2Finalize:^7 !cp finalize";
    }
    else if (empty && self.cpc.selected < self.cpc.rows.size)
        text = "^2Detect replacement:^7 Num 0\n^3Undo:^7 Num -";
    else if (empty || summary)
    {
        text = "^2Detect:^7 Num 0";
        if (self.cpc.rows.size > 0)
            text += "\n^3Edit:^7 Num 4\n" + discardLabel + "\n^5Add alternative:^7 Num /";
        if (summary) text += "\n^2Finalize:^7 !cp finalize";
    }
    else if (self.cpc.draft.points.size == 0)
        text = "^2Detect alternative:^7 Num 0\n" + discardLabel;
    else if (error != "")
        text = "^2Corner:^7 Num +\n^3Undo:^7 Num -\n^2Detect:^7 Num 0\n" + discardLabel;
    else
    {
        text = "^2Confirm:^7 Num Enter";
        if (self.cpc.selected < self.cpc.rows.size) text = "^3Apply changes:^7 Num Enter";
        text += "\n^2Detect again:^7 Num 0\n" + discardLabel;
        if (self.cpc.selected < self.cpc.rows.size) text += "\n^3Replace:^7 !cp replace";
        if (cp.alternatives.size > 0) text += "\n^5Cycle area:^7 Num *\n^1Remove area:^7 !cp delete area";
    }
    if(isDefined(self.cpc.heightTarget))text="^2Raise top:^7 Num +\n^3Lower top:^7 Num -\n^5Done editing height:^7 Num 7\n^2Apply:^7 Num Enter";
    else if(!empty)text+="\n^5Height:^7 Num 7";
    self.cpc.huds[1] _setPanelText(text);
    // Fit the current action list; do not reserve empty rows in shorter states.
    lines = 1;
    for (lineIndex = 0; lineIndex < text.size; lineIndex++)
        if (text[lineIndex] == "\n") lines++;
    if (lines < 4) lines = 4;
    panelHeight = 36 + lines * 17;
    if (!isDefined(self.cpc.panelHeight) || self.cpc.panelHeight != panelHeight)
    {
        self setClientCvar("opencj_cpc_panel_height", panelHeight);
        self.cpc.panelHeight = panelHeight;
    }
    if (self.cpc.status != "" && (!isDefined(self.cpc.lastPanelStatus) || self.cpc.lastPanelStatus != self.cpc.status))
        self sendLocalChatMessage(self.cpc.status);
    self.cpc.lastPanelStatus = self.cpc.status;
    color = _vec(displayColor) + " 1";
    if(inserting || self.cpc.selected==self.cpc.rows.size)color="0 1 0 1";
    if (error != "")
        color = "1 0.3 0.1 1";
    if (self.cpc.testing && self.cpc.testNext >= self.cpc.rows.size)
        return;
    // Resolve the whole neighborhood before drawing: sending line batches can
    // yield, allowing another editor command to change the current selection.
    next=undefined;prior=undefined;
    nextIndex=nextPreviewIndex(self.cpc);
    if (!self.cpc.testing && nextIndex < self.cpc.rows.size)
        next=_decode(self.cpc.rows[nextIndex]);
    noSelection=!self.cpc.testing && !inserting && empty && self.cpc.selected==self.cpc.rows.size;
    previous=number-2;
    if(noSelection && summary)previous=-1;
    while(previous>=0 && previous<self.cpc.rows.size)
    {
        prior=_decode(self.cpc.rows[previous]);
        if(!prior.finish)break;
        prior=undefined;previous--;
    }
    self _outlineGroup(cp,color);
    if(isDefined(next))
    {
        label="Next #"+(nextIndex+1+int(inserting));
        if(next.finish)label+=" FINISH";
        self _previewGroup(next,label,"0.2 0.6 1 1");
        if(cp.points.size>0)
            self _line(_center(openCJ\checkpointMoving::points(cp)),_center(openCJ\checkpointMoving::points(next)),"0.2 0.6 1 1");
    }
    if(isDefined(prior))
    {
        if(noSelection)self _outlineGroup(prior,"0.55 0.55 0.55 1");
        else self _previewGroup(prior,"Previous #"+(previous+1),"0.55 0.55 0.55 1");
        if(cp.points.size>0)
            self _line(_center(openCJ\checkpointMoving::points(prior)),_center(openCJ\checkpointMoving::points(cp)),"1 0.8 0 1");
        else if(inserting && isDefined(next))
            self _line(_center(openCJ\checkpointMoving::points(prior)),_center(openCJ\checkpointMoving::points(next)),"0.2 0.6 1 1");
    }
    self openCJ\checkpointNetwork::drawConnections(cp);
    if(isDefined(self.cpc.overlap))self _outlineGroup(self.cpc.overlap,"1 0.2 0 1");
}

// Both neighbors use the same full-volume representation as the selection.
_previewGroup(cp,label,color)
{
    self _outlineGroup(cp,color);
    self _drawCommand("M t "+_vec(_center(openCJ\checkpointMoving::points(cp)))+";"+color+";0.8;400;"+label);
    for(i=0;i<cp.alternatives.size;i++)
        self _drawCommand("M t "+_vec(_center(cp.alternatives[i]))+";"+color+";0.8;400;"+label);
}

_outlineGroup(cp, color)
{
    self _outline(openCJ\checkpointMoving::points(cp), color, openCJ\checkpointHeight::above(cp));
    for (i = 0; i < cp.alternatives.size; i++)
    {
        self _outline(cp.alternatives[i], "1 0.2 1 1", openCJ\checkpointHeight::above(cp));
        if (cp.points.size > 0)
            self _line(_center(cp.points), _center(cp.alternatives[i]), "1 0.2 1 1");
    }
}

_center(points)
{
    center = (0, 0, 0);
    for (i = 0; i < points.size; i++)
        center += points[i];
    if (!points.size) return (0,0,0);
    return vectorScale(center, 1.0 / points.size) + (0, 0, 12);
}

_vec(v)
{
    return v[0] + " " + v[1] + " " + v[2];
}

boundedHudText(text)
{
    // Client HUD text formatting at 0x438230 silently rejects >255 characters.
    // Leave room for engine string control bytes; bound each panel block independently.
    return getSubStr(text, 0, 240);
}

_setPanelText(text)
{
    text = boundedHudText(text);
    if (text != self.lastText)
    {
        self setText(text);
        self.lastText = text;
    }
}

_line(a, b, color)
{
    // Durations count rendered frames; allow a larger group time to refresh.
    self _drawCommand("M l " + _vec(a) + ";" + _vec(b) + ";" + color + ";1;400");
}

_drawCommand(command)
{
    // At 64 unacknowledged commands CoD4x drops unsent disposable commands.
    // Yield small batches so snapshots can send them and receive acknowledgments.
    if (self.cpc.drawCommands >= 12)
    {
        wait 0.05;
        self.cpc.drawCommands = 0;
    }
    self SV_GameSendServerCommand(command, false);
    self.cpc.drawCommands++;
}

_outline(points, color, above)
{
    if(!isDefined(above))above=0;
    height = 6+above;
    if (openCJ\checkpointArea::validate(points) == "")
        height += openCJ\checkpointArea::supportOffset(points);
    if(points.size>=3 && (above>0 || isDefined(self.cpc.heightTarget)))
    {
        center=_center(points)-(0,0,12);
        self _drawCommand("M t "+_vec(center+(0,0,4+openCJ\checkpointArea::supportOffset(points)+above))+";0 1 1 1;0.6;400;Upper +"+above);
        self _drawCommand("M t "+_vec(center-(0,0,2))+";1 0.7 0 1;0.6;400;Base");
    }
    for (i = 0; i < points.size; i++)
    {
        a = points[i] - (0, 0, 2);
        b = points[(i + 1) % points.size] - (0, 0, 2);
        self _line(a, b, color);
        self _line(a + (0, 0, height), b + (0, 0, height), color);
        self _line(a, a + (0, 0, height), color);
        self _drawCommand("M t " + _vec(a + (0, 0, 10)) + ";1 1 1 1;0.6;400;" + (i + 1));
    }
}

getConfirmed(index)
{
    return _decode(self.cpc.rows[index]);
}

// Editor travel saves deliberately do not carry run IDs or checkpoint progress.
processTravelRequests()
{
    if (isDefined(self.cpc.finalizing))
        return;
    // Teleporting inside the client-command callback can re-enter movement/VM code.
    // Match normal play: consume travel commands from the scheduled game update.
    if (isDefined(self.cpc.restoreOrigin))
    {
        pos = spawnStruct();
        pos.origin = self.cpc.restoreOrigin;
        pos.angles = self getPlayerAngles();
        if (isDefined(self.cpc.restoreAngles)) pos.angles = self.cpc.restoreAngles;
        self.cpc.restoreAngles = undefined;
        self.cpc.restoreOrigin = undefined;
        self openCJ\mapBoost::cancel();
        self setoriginandangles(pos.origin, pos.angles);
        self setVelocity((0, 0, 0));
        self rememberPosition(pos);
    }
    if (isDefined(self.eventQueue["save"]))
        self savePosition();
    if (isDefined(self.eventQueue["load"]))
        self loadPosition(self.eventQueue["load"]);
    self.eventQueue = [];
}

savePosition()
{
    if (self.sessionState != "playing" || !self isOnGround())
    {
        self iprintln("Land before saving an editor position");
        return;
    }
    pos = spawnStruct();
    pos.origin = self.origin;
    pos.angles = self getPlayerAngles();
    self rememberPosition(pos);
    self.cpc.savedPosition = pos;
    if (self _save())
        self openCJ\savePosition::printSaveSuccess();
    else
        self iprintln("Position saved for this session, but draft write failed; use !cp save to retry");
}

// Bound session-only travel history; no run state or database writes.
rememberPosition(pos)
{
    last = self.cpc.positions.size;
    if (last > 255)
        last = 255;
    for (i = last; i > 0; i--)
        self.cpc.positions[i] = self.cpc.positions[i - 1];
    self.cpc.positions[0] = pos;
    self.cpc.travelIndex = 0;
}

loadPosition(backwardsAmount)
{
    if (!isDefined(self.cpc.travelIndex) || backwardsAmount == 0)
        self.cpc.travelIndex = 0;
    index = self.cpc.travelIndex + backwardsAmount;
    if (index < 0)
        index = 0;
    pos = self.cpc.positions[index];
    if (!isDefined(pos))
        pos = self openCJ\savePosition::getSavedPosition(index - self.cpc.positions.size);
    if (!isDefined(pos))
    {
        self iprintln("No editor position saved in this slot");
        return false;
    }
    self.cpc.travelIndex = index;
    self openCJ\mapBoost::cancel();
    self setoriginandangles(pos.origin, pos.angles);
    self setVelocity((0, 0, 0));
    self openCJ\savePosition::printLoadSuccess();
    return true;
}
