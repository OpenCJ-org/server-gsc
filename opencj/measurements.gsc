#include openCJ\util;

onInit()
{
    cmd = openCJ\commands_base::registerCommand("measure", "Shoot two points to measure X, Y and Z distances. Use !measure again to cancel.", ::onCommandMeasure, 0, 0, 0);
    cmd = openCJ\commands_base::registerCommand("height", "Set a height goal", ::onCommandMeasureHeight, 0, 0, 0);
    openCJ\commands_base::addAlias(cmd, "mb");

    cmd = openCJ\commands_base::registerCommand("gap", "Measure a gap", ::onCommandMeasureGap, 0, 0, 0);
    openCJ\commands_base::addAlias(cmd, "mg");

    underlyingCmd = openCJ\settings::addSettingBool("rpgtiming", true, "Enable RPG timing prints", undefined);
    underlyingCmd = openCJ\settings::addSettingBool("rpgangle", false, "Enable RPG angle prints", ::onCommandRPGAngle);
}

onCommandRPGAngle(val)
{
    if (val && !self openCJ\settings::getSetting("rpgtiming"))
    {
        self openCJ\settings::setSettingByScript("rpgtiming", true); // If you want angle information, you also get timing
    }
}

RPGMeasurement(calledByRPGFired, eventTime)
{
    if (!self openCJ\settings::getSetting("rpgtiming"))
    {
        return;
    }

    thresholdMs = 500;

    // Determine RPG angle string
    angleStr = undefined;
    if (self openCJ\settings::getSetting("rpgangle") && isDefined(self.rpgAngle))
    {
        if (self.rpgAngle == 85)
        {
            angleStr = "perfect";
        }
        else
        {
            angleStr = floatToFixedDecimalString(self.rpgAngle, 2);
        }
        angleStr = " (angle: " + angleStr + ")";
    }
    else
    {
        angleStr = "";
    }

    // Determine RPG timing
    if (calledByRPGFired) // Called due to RPG being fired
    {
        // Bounce (already) occurred in last <thresholdMs> ms
        if(isDefined(self.bounceTime) && (self.bounceTime > (eventTime - thresholdMs)))
        {
            // RPG after bounce (late)
            self iprintlnSpectators("^3RPG was late by " + (eventTime - self.bounceTime) + "ms" + angleStr);
        }
    }
    else // Called due to player bounce
    {
        // RPG was (already) fired in last <thresholdMs> ms
        if(isDefined(self.rpgTime) && (self.rpgTime > (eventTime - thresholdMs)))
        {
            if ((eventTime - self.rpgTime) == 0)
            {
                // RPG exactly on bounce (perfect)
                self iprintlnSpectators("^6RPG timing was perfect" + angleStr);
            }
            else
            {
                // RPG before bounce (early)
                self iprintlnSpectators("^1RPG was early by " + (eventTime - self.rpgTime) + "ms" + angleStr);
            }
        }
    }
}

onCommandMeasureHeight(args)
{
    if (isDefined(self.heightGoal))
    {
        self.heightGoal = undefined;
        self sendLocalChatMessage("Cleared height goal", false);
    }
    else
    {
        self.heightGoal = self getOrigin()[2];
        self sendLocalChatMessage("Set height goal to: " + self.heightGoal, false);
    }
    self resetMaxHeight();
}

_measurement() // Call from thread
{
    self endon("disconnect");

    self iprintlnbold("Shoot at the first location");
    self waittill("measured", loc1);
    self iprintln("loc1: " + loc1);
    self iprintln("Shoot at the second location");
    self waittill("measured", loc2);
    self iprintln("loc2: " + loc2);

    useIdx = 0;
    xDiff = abs(loc1[0] - loc2[0]);
    yDiff = abs(loc1[1] - loc2[1]);
    zDiff = abs(loc1[2] - loc2[2]);
    if (yDiff > xDiff)
    {
        useIdx = 1;
    }
    if (zDiff > abs(loc1[useIdx] - loc2[useIdx]))
    {
        useIdx = 2;
    }

    diff = abs(loc1[useIdx] - loc2[useIdx]);
    self iprintlnBoldSpectators("Gap: " + diff);

    self.isMeasuringGap = undefined;
}

onCommandMeasureGap(args)
{
    if (!isDefined(self.isMeasuringGap))
    {
        self.isMeasuringGap = true;
        self thread _measurement();
    }
}

onOnGround(isOnGround)
{
    if (!isOnGround)
    {
        return;
    }

    self _handleHeightDiff();
}

onWeaponFired() // Call from thread. Firing weapon is used to measure gaps
{
    if (!isDefined(self.isMeasuringGap) && !isDefined(self.measureHud))
    {
        return;
    }

    eyePos = self getEyePos();
    trace = bulletTrace(eyePos, (eyePos + vectorScale(anglesToForward(self getPlayerAngles()), 10000)), false, self);
    if (isDefined(self.measureHud)) self acceptMeasureTrace(trace);
    if (!isDefined(self.isMeasuringGap)) return;
    if (isDefined(trace) && isDefined(trace["position"]))
    {
        self notify("measured", trace["position"]);
    }
    else
    {
        self sendLocalChatMessage("Failed to measure, try again", true);
    }
}

onBounced()
{
    self.heightGoalBounced = true;
}

onSavePosition()
{
    self resetMaxHeight();
}

_handleHeightDiff()
{
    if (!isDefined(self.heightGoal))
    {
        return;
    }

    if (isDefined(self.heightGoalBounced) && self.heightGoalBounced)
    {
        maxReachedHeight = self getMaxHeight();
        diff = maxReachedHeight - self.heightGoal;
        diffAbsStr = floatToFixedDecimalString(abs(diff), 3);
        if (diff >= 0)
        {
            aboveStr = diffAbsStr + " units ^2above^7";

            // Check if player is on ground above height goal level. If not, they probably loaded as even though they had enough height, they did not land
            if (self getOrigin()[2] >= self.heightGoal)
            {
                // Player landed the bounce, auto-clear
                self.heightGoal = undefined;
                self iprintlnSpectators(aboveStr + ", cleared goal");
            }
            else
            {
                self iprintlnSpectators(aboveStr);
            }
        }
        else
        {
            self iprintlnSpectators(diffAbsStr + " units ^1below");
        }
        self.heightGoalBounced = false;
    }
    self resetMaxHeight();
}

// Absolute world-axis distances, in game units; independent of !gap.
onCommandMeasure(args)
{
    if (isDefined(self.measureHud))
    {
        self stopMeasure();
        self sendLocalChatMessage("Measuring cancelled", false);
        return;
    }
    if (self.sessionState != "playing")
    {
        self sendLocalChatMessage("Spawn before measuring", true);
        return;
    }
    self.measureFirst = undefined;
    self.measureHud = newClientHudElem(self);
    self.measureHud.alignx = "center";
    self.measureHud.aligny = "middle";
    self.measureHud.horzalign = "center";
    self.measureHud.vertalign = "middle";
    self.measureHud.y = 80;
    self.measureHud.fontscale = 1.6;
    self.measureHud.foreground = true;
    // Normal gameplay nearly fills the 31-element current HUD pool.
    self.measureHud.archived = true;
    self.measureHud.alpha = 1;
    self.measureHud.sort = 1;
    self.measureHud.hideWhenInMenu = true;
    self.measureHud setText("Shoot at the first point");
    self sendLocalChatMessage("Shoot at the first point", false);
    self thread stopMeasureOn("disconnect");
    self thread stopMeasureOn("death");
    self thread stopMeasureOn("spawned");
    self thread stopMeasureOn("spawned_spectator");
}

stopMeasureOn(event)
{
    self endon("measure_finished");
    self waittill(event);
    self stopMeasure();
}

stopMeasure()
{
    if (isDefined(self.measureHud)) self.measureHud destroy();
    self.measureHud = undefined;
    self.measureFirst = undefined;
    self notify("measure_finished");
}

acceptMeasureTrace(trace)
{
    if (!isDefined(trace) || !isDefined(trace["position"]) || !isDefined(trace["fraction"]) || trace["fraction"] >= 1)
    {
        self sendLocalChatMessage("No surface hit. Aim at a surface and shoot again.", true);
        return;
    }
    if (!isDefined(self.measureFirst))
    {
        self.measureFirst = trace["position"];
        self.measureHud setText("Shoot at the second point");
        self sendLocalChatMessage("Shoot at the second point", false);
        return;
    }
    result = measureResult(self.measureFirst, trace["position"]);
    self stopMeasure();
    self sendLocalChatMessage(result, false);
    self iprintlnbold(result);
}

measureResult(first, second)
{
    return "Distance (units): X: " + measureDecimal(abs(second[0] - first[0]))
        + "  Y: " + measureDecimal(abs(second[1] - first[1]))
        + "  Z: " + measureDecimal(abs(second[2] - first[2]));
}

measureDecimal(value)
{
    // The util formatter truncates. Round here and retain a trailing .0.
    tenths = int(value * 10 + 0.5);
    whole = int(tenths / 10);
    return "" + whole + "." + (tenths - whole * 10);
}
