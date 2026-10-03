#include openCJ\util;

main() // Not threaded as it returns a result
{
    if(isDefined(self.shopInspect))return undefined;
    if(!self openCJ\login::isLoggedIn())
    {
        return undefined;
    }

    if (!self openCJ\checkpoints::canSaveHere())
    {
        self sendLocalChatMessage("Saving is not allowed in this checkpoint area (except in any%).", true);
        return undefined;
    }

    saveNum = self openCJ\savePosition::setSavedPosition();
    self openCJ\savePosition::resetBackwardsCount();
    self openCJ\savePosition::printSaveSuccess();

    self openCJ\clips::onSaved();
    self openCJ\measurements::onSavePosition();
    self thread openCJ\huds\hudSpeedometer::onSavePosition();

    return saveNum;
}