CodeCallback_StartGameType()
{
	openCJ\events\init::main();
	maps\mp\gametypes\cj::onStartGameType();
}

CodeCallback_PlayerConnect()
{
	self thread openCJ\events\playerConnect::main();
}

CodeCallback_PlayerDisconnect()
{
	self thread openCJ\events\playerDisconnect::main(); // Needs to be threaded
}

CodeCallback_PlayerDamage(inflictor, attacker, damage, flags, meansOfDeath, weapon, vPoint, vDir, hitLoc, psOffsetTime)
{
	self openCJ\events\playerDamage::main(inflictor, attacker, damage, flags, meansOfDeath, weapon, vPoint, vDir, hitLoc, psOffsetTime);
}

CodeCallback_PlayerKilled(inflictor, attacker, damage, meansOfDeath, weapon, vDir, hitLoc, psOffsetTime, deathAnimDuration)
{
	self openCJ\events\playerKilled::main(inflictor, attacker, damage, meansOfDeath, weapon, vDir, hitLoc, psOffsetTime, deathAnimDuration);
}

CodeCallback_PlayerCommand(args)
{
	self thread openCJ\events\playerCommand::main(args);
}

CodeCallback_PlayerLastStand()
{
}

CodeCallback_RPGFired(rpg, name, time)
{
	self openCJ\events\rpgFired::main(rpg, name, time);
}

CodeCallback_FireGrenade(nade, name)
{
	self openCJ\events\grenadeThrow::main(nade, name);
}

CodeCallback_MeleeButton()
{
	self openCJ\buttonPress::onMeleeButton();
}

CodeCallback_UseButton()
{
	self openCJ\buttonPress::onUseButton();
}

CodeCallback_AttackButton()
{
	self openCJ\buttonPress::onAttackButton();
}

CodeCallback_UserInfoChanged(entNum) //entnum not required, legacy.
{
	self openCJ\events\userInfoChanged::main();
}

CodeCallback_StartJump(time)
{
	self openCJ\buttonPress::onJump(time);
}

CodeCallback_OnGroundChange(isOnGround, time, origin)
{
	self openCJ\events\onGroundChanged::main(isOnGround, time);
}

CodeCallback_OnElevate(isAllowedToEle)
{
	self openCJ\events\elevate::main(isAllowedToEle);
}

CodeCallback_PlayerBounced(serverTime)
{
	self openCJ\events\playerBounced::main(serverTime);
}

CodeCallback_SpectatorClientChanged(newClient, prevClient)
{
	self openCJ\events\spectatorClientChanged::main(newClient, prevClient);
}

CodeCallback_MoveForward()
{
	self openCJ\events\WASDPressed::main("w");
}

CodeCallback_MoveRight()
{
	self openCJ\events\WASDPressed::main("d");
}

CodeCallback_MoveBackward()
{
	self openCJ\events\WASDPressed::main("s");
}

CodeCallback_MoveLeft()
{
	self openCJ\events\WASDPressed::main("a");
}

CodeCallback_FPSChange(newFrameTime)
{
	self thread openCJ\events\fpsChange::onPmoveFPSChange(newFrameTime);
}

/*================
Called when a gametype is not supported.
================*/
AbortLevel()
{
	println("Aborting level - gametype is not supported");

	level.callbackStartGameType = ::callbackVoid;
	level.callbackPlayerConnect = ::callbackVoid;
	level.callbackPlayerDisconnect = ::callbackVoid;
	level.callbackPlayerDamage = ::callbackVoid;
	level.callbackPlayerKilled = ::callbackVoid;
	level.callbackPlayerLastStand = ::callbackVoid;
	
	setCvar("g_gametype", "cj");

	exitLevel(false);
}

/*================
================*/
callbackVoid()
{
}