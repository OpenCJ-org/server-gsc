#include openCJ\util;

main()
{
    self openCJ\weapons::onRunRestored();
    self openCJ\healthRegen::onRunRestored();
    self openCJ\shellShock::onRunRestored();
    self openCJ\showRecords::onRunRestored();
    self openCJ\speedMode::onRunRestored();
    self openCJ\noclip::onRunRestored();
    self openCJ\anyPct::onRunRestored();
    self openCJ\tas::onRunRestored();
    self openCJ\fps::onRunRestored(); // Set hax/mix settings
    self openCJ\halfBeat::onRunRestored();
    self openCJ\huds\hudRunInfo::onRunRestored();
    self openCJ\huds\hudProgressBar::onRunRestored();
}