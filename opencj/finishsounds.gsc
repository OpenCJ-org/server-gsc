onRunFinished(runID)
{
    self endon("disconnect");
    rows = self openCJ\mySQL::mysqlAsyncQuery(recordQuery(runID));
    self playLocalSound(soundForResult(rows));
}

soundForResult(rows)
{
    // A failed ranking lookup still gets the ordinary completion sound.
    if (isDefined(rows) && rows.size && isDefined(rows[0][0]) && int(rows[0][0]))
        return "opencj_route_record";
    return "opencj_route_complete";
}

recordQuery(runID)
{
    // Use the saved finish, not mutable player/menu settings after an async wait.
    // Mode inclusion and time/RPG tiebreaks match the route leaderboard.
    // Older run IDs win exact ties so repeating a record does not trigger fanfare.
    // Each player occupies only one place on each of the two boards.
    return "WITH finished AS (" +
        "SELECT r.*,c.ender AS routeName FROM playerRuns r JOIN checkpoints c ON c.cpID=r.finishcpID " +
        "WHERE r.runID=" + runID + " AND r.finishTimeStamp IS NOT NULL), eligible AS (" +
        "SELECT r.runID,r.playerID,s.timePlayed,s.explosiveJumps FROM finished f " +
        "JOIN playerRuns r ON r.mapID=f.mapID AND r.ele<=f.ele AND r.anyPct<=f.anyPct AND r.hb<=f.hb AND r.hardTAS<=f.hardTAS " +
        "AND (r.FPSMode=f.FPSMode OR r.FPSMode='125' OR (f.FPSMode='hax' AND r.FPSMode='mix')) " +
        "JOIN checkpoints c ON c.cpID=r.finishcpID AND c.ender=f.routeName " +
        "JOIN checkpointStatistics s ON s.runID=r.runID AND s.cpID=r.finishcpID WHERE r.finishTimeStamp IS NOT NULL), best AS (" +
        "SELECT e.*,ROW_NUMBER() OVER(PARTITION BY playerID ORDER BY timePlayed,explosiveJumps,runID) AS timeBest," +
        "ROW_NUMBER() OVER(PARTITION BY playerID ORDER BY explosiveJumps,timePlayed,runID) AS rpgBest FROM eligible e), podium AS (" +
        "SELECT runID,ROW_NUMBER() OVER(ORDER BY timePlayed,explosiveJumps,runID) AS place FROM best WHERE timeBest=1 UNION ALL " +
        "SELECT runID,ROW_NUMBER() OVER(ORDER BY explosiveJumps,timePlayed,runID) AS place FROM best WHERE rpgBest=1) " +
        "SELECT EXISTS(SELECT 1 FROM podium WHERE runID=" + runID + " AND place<=3)";
}
