#include openCJ\util;

// Grounded planar checkpoint routes, with alternatives and shared openings.
// A draft is private to the account/map/route. Publishing is a separate action.
onInit()
{
    if (getCodVersion() != 4)
        return;
    cmd = openCJ\commands_base::registerCommand("checkpoint", "!cp start <route> [#RRGGBB] | split <routes> | merge <routes> | rename <old> <new> | detect | corner | confirm | alternative | area | undo | finish | double | ground | select <number> | new | discard | edit <number|last> | delete | test | save | finalize | stop", ::command, 1, 17, 0);
    openCJ\commands_base::addAlias(cmd, "cp");
    openCJ\commands_base::addAlias(cmd, "cpc");
}

isEditing()
{
    return isDefined(self.cpc);
}

command(args)
{
    if (self isEditing() && isDefined(self.cpc.finalizing))
        return;
    if (self.adminLevel < 40 && self openCJ\login::getPlayerID() != getCvarInt("opencj_checkpoint_editor_playerid"))
    {
        self iprintln("Checkpoint editing requires admin level 40 or explicit editor access");
        return;
    }
    if (!getCvarInt("opencj_checkpoint_editor"))
    {
        self iprintln("Enable opencj_checkpoint_editor on the development server first");
        return;
    }
    if (args[0] == "start" && (args.size == 2 || args.size == 3))
    {
        route = toLower(args[1]);
        if (!_validName(route) || self.sessionState != "playing" || self openCJ\demos::isPlayingDemo())
        {
            self iprintln("Spawn first; route names use 1-20 letters, digits, underscores or +");
            return;
        }
        hex = undefined;
        if (args.size == 3)
            hex = toLower(args[2]);
        if (isDefined(hex) && !isDefined(routeRGB(hex)))
        {
            self iprintln("Use a six-digit color, for example !cp start easy #ffffff");
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
            self sendLocalChatMessage("Opened " + route + ". " + previous + " draft saved; use !cp start " + previous + " then !cp finalize to make that draft playable.");
        return;
    }
    if (!self isEditing())
    {
        self iprintln("Start with !cp start easy or !cp start hard");
        return;
    }
    if (args[0] == "rename" && args.size == 3)
    {
        self openCJ\checkpointNetwork::rename(toLower(args[1]),toLower(args[2]));
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
            self _save();
        }
        return;
    }
    self _action(args[0]);
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
    return cp;
}

_encode(cp)
{
    text = int(cp.finish) + ":" + int(cp.double) + ":p" + openCJ\checkpointArea::encode(cp.points);
    for (i = 0; i < cp.alternatives.size; i++)
        text += "|p" + openCJ\checkpointArea::encode(cp.alternatives[i]);
    if (!cp.onGround) text += ":0";
    return text;
}

_decode(row)
{
    values = strTok(row, ":");
    if ((values.size != 3 && values.size != 4) || (values[0] != "0" && values[0] != "1") || (values[1] != "0" && values[1] != "1"))
        return undefined;
    if (values[2][0] != "p")
        return undefined;
    cp = _empty();
    cp.finish = int(values[0]);
    cp.double = int(values[1]);
    if (values.size == 4)
    {
        if (values[3] != "0" && values[3] != "1") return undefined;
        cp.onGround = int(values[3]);
    }
    areas = strTok(values[2], "|");
    if (areas.size > 8)
        return undefined;
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
    if (openCJ\checkpointArea::contains(cp.points, origin, grounded, cp.onGround))
        return true;
    for (i = 0; i < cp.alternatives.size; i++)
    {
        if (openCJ\checkpointArea::contains(cp.alternatives[i], origin, grounded, cp.onGround))
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
    route = self openCJ\checkpointNetwork::resolve(route);
    if (!isDefined(route))
    {
        self sendLocalChatMessage("Network draft files exist but cannot be read; preserved for recovery.", true);
        return;
    }
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
    for (i = 0; i < 5; i++)
    {
        self.cpc.huds[i] = newClientHudElem(self);
        self.cpc.huds[i].lastText = "";
        configureHud(self.cpc.huds[i]);
    }
    // Two compact columns: headers share the top row, body starts below them.
    self.cpc.huds[0].x = 282;
    self.cpc.huds[0].font = "objective";
    self.cpc.huds[0].color = (0.75,0.85,1);
    self.cpc.huds[1].y = 30;
    self.cpc.huds[2].x = 282;
    self.cpc.huds[2].y = 30;
    self.cpc.huds[3].fontScale = 1.4;
    self.cpc.huds[3].color = self.cpc.routeColor;
    self.cpc.huds[4].x = 116;
    self.cpc.huds[4].y = 0;
    self.cpc.huds[4].color = (0,0,0);
    self.cpc.huds[4].alpha = 0.55;
    self.cpc.huds[4].sort = -1;
    self.cpc.huds[4] setShader("white", 320, 104);
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
    self openCJ\playerRuns::stopRun(false);
    self openCJ\huds\hudRunInfo::onRunStopped();
    self openCJ\huds\hudSpeedometer::_hideSpeedometer();
    self openCJ\huds\hudProgressBar::onRunStopped();
    // The mod's existing client-command menu applies these without a local cfg.
    self execClientCmd("bind KP_INS say !cp detect; bind KP_5 say !cp detect; " +
        "bind KP_ENTER say !cp confirm; bind KP_PLUS say !cp corner; bind KP_MINUS say !cp undo; " +
        "bind KP_UPARROW say !cp double; bind KP_PGUP say !cp finish; bind KP_DOWNARROW say !cp ground; " +
        "bind KP_LEFTARROW say !cp previous; bind KP_RIGHTARROW say !cp next; " +
        "bind KP_DEL say !cp discard; bind KP_HOME say !cp new; bind KP_SLASH say !cp alternative; bind KP_STAR say !cp area");
    self thread _loop();
}

restoreOrigin(draft)
{
    points = draft.draft.points;
    if (openCJ\checkpointArea::validate(points) != "" && draft.draft.alternatives.size > 0)
        points = draft.draft.alternatives[draft.draft.alternatives.size - 1];
    if (openCJ\checkpointArea::validate(points) != "" && draft.rows.size > 0)
    {
        index = draft.selected;
        if (index >= draft.rows.size)
            index = draft.rows.size - 1;
        cp = _decode(draft.rows[index]);
        points = cp.points;
    }
    if (openCJ\checkpointArea::validate(points) != "")
        return undefined;
    // _center adds 12 for labels; leave two units above the capsule support height.
    return _center(points) + (0, 0, openCJ\checkpointArea::supportOffset(points) - 10);
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
    hud.hideWhenInMenu = false;
    hud.alpha = 1;
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
            self stop();
            return;
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
    if ((action == "finish" || action == "double" || action == "ground") &&
        self.cpc.selected == self.cpc.rows.size && self.cpc.rows.size > 0 &&
        self.cpc.draft.points.size == 0 && self.cpc.draft.alternatives.size == 0)
        self _action("previous");
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
    self _remember();
    switch (action)
    {
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
            points = self openCJ\checkpointPlatform::getRectangularPlatformOrgs();
            if (isDefined(points))
            {
                self.cpc.draft.points = points;
                self.cpc.status = "Platform detected";
                self openCJ\checkpointNetwork::selectDetectedShared();
                self openCJ\checkpointNetwork::checkOverlap();
            }
            else
                self.cpc.status = "Detection failed; selection unchanged";
            break;
        case "corner":
            if (self.cpc.draft.points.size >= 8)
                break;
            eye = self getEyePos();
            trace = bulletTrace(eye, eye + vectorScale(anglesToForward(self getPlayerAngles()), 1000), false, self);
            if (trace["fraction"] < 1)
                self.cpc.draft.points[self.cpc.draft.points.size] = trace["position"];
            break;
        case "confirm":
            self openCJ\checkpointNetwork::checkOverlap();
            if (isDefined(self.cpc.overlap))
            {
                self.cpc.status = "Overlapping section: merge the routes here; split where they separate";
                return;
            }
            error = openCJ\checkpointArea::validate(self.cpc.draft.points);
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
            self.cpc.rows[self.cpc.selected] = _encode(self.cpc.draft);
            self.cpc.status = "";
            if (followingShared)
                break;
            self.cpc.selected = self.cpc.rows.size;
            self.cpc.draft = _empty();
            break;
        case "ground": self.cpc.draft.onGround = !self.cpc.draft.onGround; break;
        case "finish": self.cpc.draft.finish = !self.cpc.draft.finish; break;
        case "double": self.cpc.draft.double = !self.cpc.draft.double; break;
        case "new":
            self.cpc.selected = self.cpc.rows.size;
            self.cpc.draft = _empty();
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

// Discard the newest checkpoint, independent of which older checkpoint is
// selected. An unconfirmed new selection is discarded before confirmed rows.
_discard()
{
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
            if (openCJ\checkpointArea::validate(cp.points) != "")
                return undefined;
            result.rows[i] = row;
        }
        else
            result.draft = cp;
    }
    end = FS_ReadLine(file);
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
    for (i = 0; i < self.cpc.huds.size; i++)
        self.cpc.huds[i] destroy();
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
    openCJ\checkpointPublish::activate();
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
            if (finish.finish && contains(finish, self.origin, self isOnGround()))
            {
                self.cpc.testNext = self.cpc.rows.size;
                self.cpc.status = "TEST: FINISH " + (i + 1);
                self iprintln(self.cpc.status);
                return;
            }
        }
        return;
    }
    if (contains(cp, self.origin, self isOnGround()))
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
            if (contains(later, self.origin, self isOnGround()))
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
    if (draft.selected != draft.rows.size || draft.rows.size == 0 || draft.draft.points.size > 0 || draft.draft.alternatives.size > 0)
        return false;
    last = _decode(draft.rows[draft.rows.size - 1]);
    return isDefined(last) && last.finish;
}

_draw()
{
    cp = self.cpc.draft;
    number = self.cpc.selected + 1;
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
    error = openCJ\checkpointArea::validate(cp.points);
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
    if (!self.cpc.testing && !followingShared && empty && self.cpc.selected == self.cpc.rows.size && self.cpc.rows.size > 0)
    {
        props = _decode(self.cpc.rows[self.cpc.rows.size - 1]);
        heading = "Last checkpoint";
    }
    else if (self.cpc.selected < self.cpc.rows.size)
        heading = "Selected checkpoint";
    self.cpc.huds[0] _setPanelText(heading);
    doubleRPG = "Off"; finish = "No"; ground = "Yes";
    if (props.double) doubleRPG = "On";
    if (props.finish) finish = "Yes";
    if (!props.onGround) ground = "No";
    text = "Double RPG: " + doubleRPG + " [Num 8]";
    text += "\nFinish: " + finish + " [Num 9]";
    text += "\nOn ground: " + ground + " [Num 2]";
    self.cpc.huds[2] _setPanelText(text);
    if (self.cpc.testing)
        text = "Follow the outline\nExit test: !cp test";
    else if (followingShared)
    {
        text = "Follow shared landings\n^2Detect:^7 Num 0\n^5Split:^7 !cp split <routes>";
        if (cp.finish) text += "\n^2Finalize:^7 !cp finalize";
    }
    else if (empty || summary)
    {
        text = "^2Detect:^7 Num 0";
        if (self.cpc.rows.size > 0)
            text += "\n^3Edit:^7 Num 4\n^1Discard:^7 Num Del\n^5Add alternative:^7 Num /";
        if (summary) text += "\n^2Finalize:^7 !cp finalize";
    }
    else if (self.cpc.draft.points.size == 0)
        text = "^2Detect alternative:^7 Num 0\n^1Discard:^7 Num Del";
    else if (error != "")
        text = "^2Corner:^7 Num +\n^3Undo:^7 Num -\n^2Detect:^7 Num 0\n^1Discard:^7 Num Del";
    else
    {
        text = "^2Confirm:^7 Num Enter";
        if (self.cpc.selected < self.cpc.rows.size) text = "^3Apply:^7 Num Enter";
        text += "\n^2Detect again:^7 Num 0\n^1Discard:^7 Num Del";
        if (cp.alternatives.size > 0) text += "\n^5Cycle area:^7 Num *";
    }
    self.cpc.huds[1] _setPanelText(text);
    // Fit the current action list; do not reserve empty rows in shorter states.
    lines = 1;
    for (lineIndex = 0; lineIndex < text.size; lineIndex++)
        if (text[lineIndex] == "\n") lines++;
    if (lines < 3) lines = 3;
    panelHeight = 36 + lines * 17;
    if (!isDefined(self.cpc.panelHeight) || self.cpc.panelHeight != panelHeight)
    {
        self.cpc.huds[4] setShader("white", 320, panelHeight);
        self.cpc.panelHeight = panelHeight;
    }
    if (self.cpc.status != "" && (!isDefined(self.cpc.lastPanelStatus) || self.cpc.lastPanelStatus != self.cpc.status))
        self sendLocalChatMessage(self.cpc.status);
    self.cpc.lastPanelStatus = self.cpc.status;
    color = _vec(displayColor) + " 1";
    if (error != "")
        color = "1 0.3 0.1 1";
    if (self.cpc.testing && self.cpc.testNext >= self.cpc.rows.size)
        return;
    self _outlineGroup(cp, color);
    if (followingShared && self.cpc.selected + 1 < self.cpc.rows.size)
    {
        next = _decode(self.cpc.rows[self.cpc.selected + 1]);
        label = "#" + (self.cpc.selected + 2);
        if (next.finish)
            label += " FINISH";
        self _previewArea(next.points, label, "0 1 1 1");
        for (j = 0; j < next.alternatives.size; j++)
        {
            self _previewArea(next.alternatives[j], label, "1 0.2 1 1");
            self _line(_center(next.points), _center(next.alternatives[j]), "1 0.2 1 1");
        }
        self _line(_center(cp.points), _center(next.points), "1 0.8 0 1");
    }
    self openCJ\checkpointNetwork::drawConnections(cp);
    if (isDefined(self.cpc.overlap))self _outlineGroup(self.cpc.overlap, "1 0.2 0 1");
    // Only the previous checkpoint is drawn too; don't flood reliable commands for the entire map.
    previous = number - 2;
    while (previous >= 0 && previous < self.cpc.rows.size)
    {
        prior = _decode(self.cpc.rows[previous]);
        if (!prior.finish)
            break;
        previous--;
    }
    if (!followingShared && previous >= 0 && previous < self.cpc.rows.size)
    {
        prior = _decode(self.cpc.rows[previous]);
        self _outlineGroup(prior, "0.4 0.4 0.4 1");
        if (cp.points.size > 0)
            self _line(_center(prior.points), _center(cp.points), "1 0.8 0 1");
    }
}

// Preview just the landing boundary and checkpoint number, keeping the larger
// preview cheap and distinct from the selected area's editable corners.
_previewArea(points, label, color)
{
    for (i = 0; i < points.size; i++)
        self _line(points[i] + (0, 0, 2), points[(i + 1) % points.size] + (0, 0, 2), color);
    self _drawCommand("M t " + _vec(_center(points)) + ";" + color + ";0.8;400;" + label);
}

_outlineGroup(cp, color)
{
    self _outline(cp.points, color);
    for (i = 0; i < cp.alternatives.size; i++)
    {
        self _outline(cp.alternatives[i], "1 0.2 1 1");
        if (cp.points.size > 0)
            self _line(_center(cp.points), _center(cp.alternatives[i]), "1 0.2 1 1");
    }
}

_center(points)
{
    center = (0, 0, 0);
    for (i = 0; i < points.size; i++)
        center += points[i];
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

_outline(points, color)
{
    height = 6;
    if (openCJ\checkpointArea::validate(points) == "")
        height += openCJ\checkpointArea::supportOffset(points);
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
    self setoriginandangles(pos.origin, pos.angles);
    self setVelocity((0, 0, 0));
    self openCJ\savePosition::printLoadSuccess();
    return true;
}
