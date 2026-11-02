#include openCJ\util;

main()
{
    self.isFullyConnected = true;
    // Client dvars survive reconnects. Clear the CPC menu only after begin,
    // when reliable client commands can be delivered.
    self setClientCvar("opencj_cpc_properties", "");
    self setClientCvar("opencj_cpc_panel_height", 0);
    self thread openCJ\clientInit::onConnected();
    self openCJ\scoreboard::onPlayerConnected();

    self openCJ\login::onPlayerConnected();
    self openCJ\challenges::onPlayerConnected();
    self openCJ\shop::onPlayerConnected();
    self openCJ\country::onPlayerConnected();
    self openCJ\huds\infiniteHuds::onPlayerConnected();
    self openCJ\graphics::onPlayerConnected();
    self openCJ\menus\endMapVote::onPlayerConnected();
    self openCJ\menus\board_base::onPlayerConnected();
    self openCJ\menus\quickMessages::onPlayerConnected();
    self openCJ\huds\hudStatistics::onPlayerConnected();
    self openCJ\huds\hudSpectatorList::onPlayerConnected();
    self openCJ\halfBeat::onPlayerConnected();
    self openCJ\cheating::onPlayerConnected();
    self openCJ\menus\mapList::onPlayerConnected();
    self openCJ\menus\helper::onPlayerConnected();
    self openCJ\menus\ingame::onPlayerConnected();

    self openCJ\events\spawnSpectator::main();
}