#include openCJ\util;

onInit()
{
    if (getCodVersion() == 4)
    {
        precacheShader("opencj_checkpoint_tint_obj");
        level.checkpointPalette = [];
        addPalette("aqua", (0,0.8,1));addPalette("lime", (0,1,0));
        addPalette("gold", (1,1,0));addPalette("orng", (1,0.5333,0));
        addPalette("soft", (1,0.4667,0.4667));addPalette("dark", (0.6667,0,0));
        addPalette("lila", (0.6667,0.3333,1));addPalette("pink", (1,0.4667,0.8));
        addPalette("tint", (1,1,1));
    }
    level.checkpointShaders = [];
    level.checkpointShaders["blue"] = "opencj_checkpoint_blue";
    level.checkpointShaders["cyan"] = "opencj_checkpoint_cyan";
    level.checkpointShaders["green"] = "opencj_checkpoint_green";
    level.checkpointShaders["orange"] = "opencj_checkpoint_orange";
    level.checkpointShaders["purple"] = "opencj_checkpoint_purple";
    level.checkpointShaders["red"] = "opencj_checkpoint_red";
    level.checkpointShaders["yellow"] = "opencj_checkpoint_yellow";
    level.checkpointShaders["default"] = level.checkpointShaders["blue"];


    level.checkpointShadersObjective = [];
    keys = GetArrayKeys(level.checkpointShaders);
    for (i = 0; i < keys.size; i++)
    {
        level.checkpointShadersObjective[keys[i]] = level.checkpointShaders[keys[i]];
        if (getCodVersion() == 4)
        {
            level.checkpointShadersObjective[keys[i]] += "_obj";
        }
    }

    colors = getArrayKeys(level.checkpointShaders);
    for(i = 0; i < colors.size; i++)
    {
        precacheShader(level.checkpointShaders[colors[i]]);
        precacheShader(level.checkpointShadersObjective[colors[i]]);
    }
}

onPlayerConnect()
{
    if (getCodVersion() == 4)
    {
        // Scale only the offscreen icon away; the engine draws its direction
        // pointer separately. Scale length must be positive (use subpixel fade).
        self setClientCvar("waypointOffscreenScaleLength", "0.001");
        self setClientCvar("waypointOffscreenScaleSmallest", "0");
    }
    self.checkpointPointers_huds = [];
    self.checkpointPointers_objectives = [];
    for(i = 0; i < 16; i++)
        self objective_player_delete(i);
}

onStartDemo()
{
    self _hideCheckpointPointers();
}

onRunCreated()
{
    self _hideCheckpointPointers(); // Showing them is triggered based on onCheckpointsChanged() instead
}

onRunStopped()
{
    self _hideCheckpointPointers();
}

onSpawnSpectator()
{
    self _hideCheckpointPointers();
}

onPlayerKilled(inflictor, attacker, damage, meansOfDeath, weapon, vDir, hitLoc, psOffsetTime, deathAnimDuration)
{
    self _hideCheckpointPointers();
}

onCheckpointsChanged()
{
    self showCheckpointPointers();
}

onRunFinished(cp)
{
    self _hideCheckpointPointers();
}

showCheckpointPointers()
{
    if (self.sessionState != "playing" || self openCJ\checkpointCreation::isEditing() || self openCJ\demos::isPlayingDemo() || !self openCJ\playerRuns::hasRunID() || self openCJ\playerRuns::isRunFinished())
    {
        self _hideCheckpointPointers();
        return;
    }
    checkpoints = self nextVisibleCheckpoints();

    for(i = 0; i < checkpoints.size; i++)
    {
        if(i >= self.checkpointPointers_huds.size)
        {
            self.checkpointPointers_huds[self.checkpointPointers_huds.size] = self _createNewCheckpointPointerHud();
        }

        shaderColor = openCJ\checkpoints::getCheckpointShaderColor(checkpoints[i]);
        shader_hud = _getShaderHud(shaderColor);
        shader_objective = _getShaderObjective(shaderColor);
        tint = (1,1,1);
        routeColored = getCodVersion() == 4 && isDefined(checkpoints[i].routeInfo);
        if (routeColored)
        {
            shader_hud = "opencj_checkpoint_tint_obj";
            shader_objective = paletteShader(checkpoints[i].routeInfo.color);
            tint = checkpoints[i].routeInfo.color;
        }

        size = 5;
        if (routeColored)
            size = 10;
        self.checkpointPointers_huds[i] setShader(shader_hud, size, size);
        self.checkpointPointers_huds[i].color = tint;
        if (routeColored)
        {
            self.checkpointPointers_huds[i].alpha = 1;
            self.checkpointPointers_huds[i] setWaypoint(true, shader_hud);
        }
        else
        {
            self.checkpointPointers_huds[i].alpha = 0.5;
            if (getCodVersion() == 4)
                self.checkpointPointers_huds[i] setWaypoint(true, shader_hud);
            else
                self.checkpointPointers_huds[i] setWaypoint(true);
        }

        self.checkpointPointers_huds[i].x = checkpoints[i].origin[0];
        self.checkpointPointers_huds[i].y = checkpoints[i].origin[1];
        self.checkpointPointers_huds[i].z = checkpoints[i].origin[2] + 10;
        //self.checkpointPointers_huds[i] thread _doJump(self);

        // Stock compass objectives have no RGB field. Default route colors have
        // matching materials; custom RGB uses the nearest palette arrow here.
        if(i < 16)
        {
            self.checkpointPointers_objectives[i] = true;
            if(getCodVersion() == 2)
            {
                self objective_player_add(i, "current", checkpoints[i].origin, shader_objective);
            }
            else
            {
                self objective_player_add(i, "active", checkpoints[i].origin, shader_objective);
            }
        }
    }

    for(i = self.checkpointPointers_huds.size - 1; i >= checkpoints.size; i--)
    {
        self.checkpointPointers_huds[i] notify("stopJump");
        self.checkpointPointers_huds[i] destroy();
        self.checkpointPointers_huds[i] = undefined;
        if(isDefined(self.checkpointPointers_objectives[i]))
        {
            self objective_player_delete(i);
            self.checkpointPointers_objectives[i] = undefined;
        }
    }
}

nextVisibleCheckpoints()
{
    if (self openCJ\anyPct::hasAnyPct())
        return openCJ\checkpoints::getAllEndCheckpoints();
    next = self openCJ\checkpoints::getCurrentChildCheckpoints();
    visible = [];
    if (!isDefined(next))
        return visible;
    for (i = 0; i < next.size; i++)
    {
        route = openCJ\checkpoints::getRouteNameForCheckpoint(next[i]);
        if (!isDefined(self.route) || !isDefined(route) || self.route == route)
            visible[visible.size] = next[i];
    }
    return visible;
}

_getShaderHud(color)
{
    if(isDefined(color) && isDefined(level.checkpointShaders[color]))
    {
        return level.checkpointShaders[color];
    }
    return level.checkpointShaders["default"];
}

_getShaderObjective(color)
{
    if(isDefined(color) && isDefined(level.checkpointShadersObjective[color]))
    {
        return level.checkpointShadersObjective[color];
    }
    return level.checkpointShadersObjective["default"];
}

_doJump(player)
{
    player endon("disconnect");
    self notify("stopJump");
    self endon("stopJump");

    offset[0] = (0, 0, 20) + (self.x, self.y, self.z);
    offset[1] = (0, 0, 15) + (self.x, self.y, self.z);
    offset[2] = (0, 0, 10) + (self.x, self.y, self.z);
    offset[3] = (0, 0, 5) + (self.x, self.y, self.z);
    offset[4] = (0, 0, 0) + (self.x, self.y, self.z);
    offset[5] = (0, 0, 0) + (self.x, self.y, self.z);

    frames = 4;
    while(true)
    {
        for(i = 0; i < offset.size; i++)
        {
            curOffset = offset[i];
            nextOffset = offset[(i + 1) % offset.size];
            diff = nextOffset - curOffset;
            for(j = 0; j < frames; j++)
            {
                self.x = curOffset[0] + diff[0] * (1 / frames) * j;
                self.y = curOffset[1] + diff[1] * (1 / frames) * j;
                self.z = curOffset[2] + diff[2] * (1 / frames) * j;
                wait 0.05;
            }
        }
    }
}


_hideCheckpointPointers()
{
    for(i = self.checkpointPointers_huds.size - 1; i >= 0; i--)
    {
        self.checkpointPointers_huds[i] notify("stopJump");
        self.checkpointPointers_huds[i] destroy();
        self.checkpointPointers_huds[i] = undefined;
        if(isDefined(self.checkpointPointers_objectives[i]))
        {
            self objective_player_delete(i);
            self.checkpointPointers_objectives[i] = undefined;
        }
    }
}

_createNewCheckpointPointerHud()
{
    hud = newClientHudElem(self);
    hud.alpha = 0.5;
    // Let menus cover world checkpoint indicators, like the stock scoreboard.
    hud.foreground = false;
    hud.aligny = "top";
    hud.alignx = "center";
    return hud;
}


addPalette(name, color)
{
    entry = spawnStruct();entry.shader="opencj_checkpoint_"+name+"_obj";entry.color=color;
    precacheShader(entry.shader);level.checkpointPalette[level.checkpointPalette.size]=entry;
}

paletteShader(color)
{
    best=0;distance=100;
    for(i=0;i<level.checkpointPalette.size;i++)
    {
        delta=distanceSquared(color,level.checkpointPalette[i].color);
        if(delta<distance){distance=delta;best=i;}
    }
    return level.checkpointPalette[best].shader;
}
