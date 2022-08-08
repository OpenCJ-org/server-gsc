#include openCJ\util;

main(backwardsCount)
{
	if(!self openCJ\login::isLoggedIn() || !self openCJ\playerRuns::hasRunID())
		return;

	error = self openCJ\savePosition::canLoadError(backwardsCount);
	if(!error)
	{
		save = self openCJ\savePosition::getSavedPosition(backwardsCount);

		if(self openCJ\weapons::isRPG(self getCurrentWeapon()))
			giveRPG = true;
		else
			giveRPG = false;

		self openCJ\statistics::addTimeUntil(getTime() + (int(self getJumpSlowdownTimer() / 50) * 50)); //todo: make this flag-specific since disabling jump_slowdown should not give this delay, might already work baked-in to the function though

		if(self openCJ\cheating::isCheating() && !openCJ\savePosition::isCheating(save))
			self openCJ\cheating::safe();
		else if(!self openCJ\cheating::isCheating() && openCJ\savePosition::isCheating(save))
			self openCJ\cheating::cheat();

		self spawn(save.origin, save.angles);

		self openCJ\statistics::setRPGJumps(save.RPGJumps);
		self openCJ\statistics::setNadeJumps(save.nadeJumps);
		self openCJ\statistics::setDoubleRPGs(save.doubleRPGs);
		self openCJ\statistics::onLoadPosition();
		self openCJ\checkpoints::setCurrentCheckpointID(save.checkpointID); //does this also update checkpoint pointers?

		//set speed mode vars here
		self openCJ\speedMode::setSpeedModeEver(openCJ\savePosition::hasSpeedModeEver(save));
		self openCJ\speedMode::setSpeedMode(openCJ\savePosition::hasSpeedMode(save));

		self openCJ\events\spawnPlayer::setSharedSpawnVars(giveRPG);
		self openCJ\savePosition::printLoadSuccess();
		
		

		return true;
	}
	else
	{
		self openCJ\savePosition::printCanLoadError(error);
		return false;
	}
}