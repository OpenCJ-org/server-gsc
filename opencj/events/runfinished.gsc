#include openCJ\util;

main(cp, tOffset, route)
{
    self endon("disconnect");
    self endon("spawned");
    if (self openCJ\playerRuns::isRunPaused())
    {
        self iprintln("^5Finished while paused");
        self openCJ\checkpointPointers::onRunFinished(cp);
        return;
    }
    if (!self openCJ\playerRuns::hasRunID() || self openCJ\cheating::isCheating())
        return;
    cpID = openCJ\checkpoints::getCheckpointID(cp);
    if (!isDefined(cpID))
        return;

    self openCJ\demoRecording::capture(true);
    self.playerRuns_runFinishing = true;
    runID = self openCJ\playerRuns::getRunID();
    filters = self openCJ\playerRuns::finishSettings();
    self openCJ\playTime::setTimePlayed(self openCJ\playTime::getTimePlayed() + tOffset);
    timePlayed = self openCJ\playTime::getTimePlayed();
    self openCJ\playTime::onRunFinished(cp);
    // Finish statistics must exist before the run becomes leaderboard-visible.
    if (!self openCJ\checkpoints::storeCheckpointPassed(runID, cpID, timePlayed))
        return;
    if (!self openCJ\playerRuns::onRunFinished(cp, filters))
        return;
    self.playerRuns_runFinishing = false;
    self thread openCJ\finishSounds::onRunFinished(runID);
    self thread openCJ\challenges::awardRun(runID);
    self openCJ\demoRecording::onRunFinished();
    if (!isDefined(route))
        route = "<unknown route>";
    timeStr = formatTimeString(timePlayed, true);
    iprintln(self.name + "^7 finished " + route + " in: ^2" + timeStr);
    self thread _notifyFinishedMap(runID, cpID, timePlayed);
    self thread openCJ\discord::onRunFinished(runID, timeStr, route);
    self openCJ\checkpointPointers::onRunFinished(cp);
    self openCJ\showRecords::onRunFinished(cp);
    self openCJ\huds\hudProgressBar::onRunFinished(cp);
    self openCJ\statistics::onRunFinished();
    self openCJ\elevate::onRunFinished();
}
_notifyFinishedMap(runID, cpID, timePlayed)
{
    self endon("disconnect");
    self notify("mapFinishNotify");
    self endon("mapFinishNotify");
    rows = self openCJ\mySQL::mysqlAsyncQuery("SELECT MIN(cs.timePlayed) FROM checkpointStatistics cs INNER JOIN playerRuns pr ON pr.runID = cs.runID WHERE cs.cpID = " + cpID + " AND pr.finishcpID IS NOT NULL AND pr.runID != " + runID);
    if(rows.size && isDefined(rows[0][0]))
    {
        diff = timePlayed - int(rows[0][0]);
        if(diff > 0)
            self iprintlnbold("You finished the map ^1+" + formatTimeString(diff, false));
        else if( diff < 0)
            self iprintlnbold("You finished the map ^2-" + formatTimeString(-1 * diff, false));
        else
            self iprintlnbold("You finished the map, no difference");
    }
    else
        self iprintlnbold("You finished the map");
}
