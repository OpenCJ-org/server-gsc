#include openCJ\util;

onInit()
{
    level.runInfoShader["hax"] = "opencj_icon_fpshax";
    level.runInfoShader["mix"] = "opencj_icon_fpsmix";
    level.runInfoShader["125"] = "opencj_icon_fps125";
    level.runInfoShader["ele"] = "opencj_icon_ele";
    level.iconWidth = 16;
    level.iconHeight = 20;
	precacheShader(level.runInfoShader["hax"]);
	precacheShader(level.runInfoShader["mix"]);
	precacheShader(level.runInfoShader["125"]);
	precacheShader(level.runInfoShader["ele"]);
}

onStartDemo()
{
	self _hideRunInfo();
}

whileAlive()
{
	spectators = getSpectatorList(false);
	for(i = 0; i < spectators.size; i++)
	{
		spectators[i] _showRunInfo(self);
	}
    self _showRunInfo(self);
}

onSpectatorClientChanged(newClient)
{
	self _showRunInfo(newClient);
}

onSpawnSpectator()
{
	self _hideRunInfo();
}

onSpawnPlayer()
{
	self _showRunInfo(self);
}

onPlayerConnect()
{
	self _createRunInfoHud();
}

onPlayerKilled(inflictor, attacker, damage, meansOfDeath, weapon, vDir, hitLoc, psOffsetTime, deathAnimDuration)
{
	spectators = getSpectatorList(false);
	for(i = 0; i < spectators.size; i++)
	{
		spectators[i] _hideRunInfo();
	}
}

_showRunInfo(player)
{
	if (player openCJ\fps::hasUsedHaxFPS())
	{
        self.hudRunInfo["fps"] setShader(level.runInfoShader["hax"], level.iconWidth, level.iconHeight);
		self.hudRunInfo["fps"].alpha = 1;
	}
    else if (player openCJ\fps::hasUsedMixFPS())
    {
        self.hudRunInfo["fps"] setShader(level.runInfoShader["mix"], level.iconWidth, level.iconHeight);
        self.hudRunInfo["fps"].alpha = 1;
    }
    else
    {
        self.hudRunInfo["fps"] setShader(level.runInfoShader["125"], level.iconWidth, level.iconHeight);
        self.hudRunInfo["fps"].alpha = 1;
    }
	
    if (player openCJ\elevate::hasEleOverrideEver())
	{
		self.hudRunInfo["ele"].alpha = 1;
	}
    else
    {
        self.hudRunInfo["ele"].alpha = 0.2;
    }
}

_hideRunInfo()
{
    self.hudRunInfo["fps"].alpha = 0;
    self.hudRunInfo["ele"].alpha = 0;
}

_createRunInfoHud()
{
	self.hudRunInfo = [];

    firstIconX = 55;
    yAboveProgressBar = 460; // Right above progress bar
    spaceBetweenIcons = 5;
	self.hudRunInfo["fps"] = newClientHudElem(self);
	self.hudRunInfo["fps"].horzAlign = "fullscreen";
	self.hudRunInfo["fps"].vertAlign = "fullscreen";
	self.hudRunInfo["fps"].alignX = "left";
	self.hudRunInfo["fps"].alignY = "bottom";
	self.hudRunInfo["fps"].x = firstIconX;
	self.hudRunInfo["fps"].y = yAboveProgressBar;
	self.hudRunInfo["fps"].alpha = 0;
	self.hudRunInfo["fps"].archived = false;
    self.hudRunInfo["fps"] setShader(level.runInfoShader["125"], level.iconWidth, level.iconHeight);

	self.hudRunInfo["ele"] = newClientHudElem(self);
	self.hudRunInfo["ele"].horzAlign = "fullscreen";
	self.hudRunInfo["ele"].vertAlign = "fullscreen";
	self.hudRunInfo["ele"].alignX = "left";
	self.hudRunInfo["ele"].alignY = "bottom";
	self.hudRunInfo["ele"].x = firstIconX + spaceBetweenIcons + level.iconWidth;
	self.hudRunInfo["ele"].y = yAboveProgressBar;
	self.hudRunInfo["ele"].alpha = 0;
	self.hudRunInfo["ele"].archived = false;
	self.hudRunInfo["ele"] setShader(level.runInfoShader["ele"], level.iconWidth, level.iconHeight);
}