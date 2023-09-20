#include openCJ\util;

main()
{
    self.isFullyConnected = true;

    self openCJ\login::onPlayerConnected();
    self openCJ\country::onPlayerConnected();
    self openCJ\huds\infiniteHuds::onPlayerConnected();
    self openCJ\graphics::onPlayerConnected();
    self openCJ\menus\endMapVote::onPlayerConnected();
    self openCJ\menus\board_base::onPlayerConnected();
    self openCJ\menus\quickMessages::onPlayerConnected();
    self openCJ\huds\hudStatistics::onPlayerConnected();
    self openCJ\huds\hudSpectatorList::onPlayerConnected();
    self openCJ\halfBeat::onPlayerConnected();
    self openCJ\menus\mapList::onPlayerConnected();
    self openCJ\menus\helper::onPlayerConnected();
    self openCJ\menus\ingame::onPlayerConnected();

    self openCJ\events\spawnSpectator::main();
}