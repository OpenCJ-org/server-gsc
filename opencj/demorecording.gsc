#include openCJ\util;

onInit()
{
    // Do not enable recording against an unmigrated database.
    level.demoStorageReady = isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT runID FROM demoRuns LIMIT 0"));
    // Reclaim abandoned uploads after crashes, with a generous grace period
    // so another server's active publication cannot be mistaken for an orphan.
    if(level.demoStorageReady)
        level thread openCJ\mySQL::mysqlAsyncQueryNosave("DELETE FROM demoRuns WHERE ready=0 AND createdAt < NOW() - INTERVAL 7 DAY");
}

onConnect()
{
    self.demoRecordings = [];
}

onRunStarted()
{
    if (!level.demoStorageReady || getCodVersion() != 4)
        return;
    id = self openCJ\playerRuns::getRunID();
    if (!isDefined(id) || isDefined(self.demoRecordings["" + id]))
        return;
    rec = spawnStruct();
    rec.id = id;
    rec.saves = [];
    rec.failed = false;
    rec.finishing = false;
    rec.lastTick = -1;
    self.demoRecordings["" + id] = rec;
    if (createDemo(id) != id)
        rec.failed = true;
    else
        self capture();
}

current()
{
    if (!self openCJ\playerRuns::hasRunID() || !isDefined(self.demoRecordings))
        return undefined;
    return self.demoRecordings["" + self openCJ\playerRuns::getRunID()];
}

capture(force)
{
    rec = self current();
    if (!isDefined(rec) || rec.failed || rec.finishing || (isDefined(self.playerRuns_runFinishing) && self.playerRuns_runFinishing) || self openCJ\demos::isPlayingDemo() || self openCJ\checkpointCreation::isEditing())
        return;
    // AFK pauses capture without discarding this session's run recording.
    if (isDefined(self.isAFK) && self.isAFK)
        return;
    if (self.sessionState != "playing" || self openCJ\playerRuns::isRunPaused() || self openCJ\cheating::isCheating())
        return;
    if (!isDefined(force) || !force)
    {
        if (self openCJ\playerRuns::isRunFinished() || !self openCJ\playTime::isActivelyPlaying() || rec.lastTick == getTime())
            return;
    }
    cp = self openCJ\checkpoints::getCurrentCheckpoint();
    cpID = 0;
    if (isDefined(cp))
    {
        if (isDefined(cp.bigBrother)) cp = cp.bigBrother;
        if (isDefined(cp.id)) cpID = cp.id;
    }
    fps = self openCJ\fps::getCurrentFPS();
    rpg = isDefined(self.eventQueue["rpg"]);
    if (!isDefined(addFrameToDemo(rec.id, self.origin, self getPlayerAngles(), 1, self frameFlags(), 0, 0, int(rpg), int(fps), cpID, self getEntityNumber())))
    {
        rec.failed = true;
        destroyDemo(rec.id);
        self sendLocalChatMessage("Demo recording stopped: memory limit reached. Your run is unaffected.", true);
        return;
    }
    rec.lastTick = getTime();
}

onSaved(saveNum)
{
    rec = self current();
    if (!isDefined(rec) || rec.failed || rec.finishing) return;
    self capture();
    if(rec.failed)return;
    rec.saves["" + saveNum] = numberOfDemoFrames(rec.id);
}

onLoaded(saveNum)
{
    rec = self current();
    if (!isDefined(rec) || rec.failed || rec.finishing) return;
    count = rec.saves["" + saveNum];
    if (!isDefined(count) || !isDefined(demoTruncate(rec.id, count)))
    {
        rec.failed = true;
        destroyDemo(rec.id);
        return;
    }
    keys = getArrayKeys(rec.saves);
    for (i=0;i<keys.size;i++)
        if (rec.saves[keys[i]] > count) rec.saves[keys[i]] = undefined;
    rec.lastTick = -1;
}

onDisconnect()
{
    if (!isDefined(self.demoRecordings)) return;
    keys = getArrayKeys(self.demoRecordings);
    for (i=0;i<keys.size;i++)
    {
        rec = self.demoRecordings[keys[i]];
        if (!rec.failed && !rec.finishing) destroyDemo(rec.id);
    }
    self.demoRecordings = [];
}

onRunFinished()
{
    rec = self current();
    if (!isDefined(rec) || rec.failed || rec.finishing) return;
    if (rec.failed) return;
    rec.finishing = true;
    completeDemo(rec.id);
    level thread persist(rec.id);
}

frameFlags()
{
    flags = 0;
    if (self leftButtonPressed()) flags |= 1;
    if (self rightButtonPressed()) flags |= 2;
    if (self forwardButtonPressed()) flags |= 4;
    if (self backButtonPressed()) flags |= 8;
    if (self sprintButtonPressed()) flags |= 16;
    if (self jumpButtonPressed()) flags |= 32;
    if (self isSprinting()) flags |= 64;
    if (self isMantling()) flags |= 128;
    if (self isOnLadder()) flags |= 256;
    stance = self getStance();
    if (stance == "stand") flags |= 512;
    else if (stance == "duck" || stance == "crouch") flags |= 1024;
    else flags |= 2048;
    if (openCJ\weapons::isRPG(self getCurrentWeapon())) flags |= 4096;
    if (self isOnGround()) flags |= 8192;
    if (isDefined(self.eventQueue["bounced"])) flags |= 16384;
    return flags;
}

// Runs completed in this connection alone reach here; resumed historical runs
// have no in-memory recording. SQL holds only complete candidate payloads.
persist(id)
{
    count = numberOfDemoFrames(id);
    if (!isDefined(count) || count < 2)
    {
        destroyDemo(id);
        return;
    }
    query = "INSERT INTO demoRuns(runID,mapID,routeName,FPSMode,modeMask,timePlayed,explosiveJumps,frameCount) SELECT r.runID,r.mapID,c.ender,r.FPSMode,r.anyPct+2*r.ele+4*r.hb+8*r.hardTAS,s.timePlayed,s.explosiveJumps," + count + " FROM playerRuns r JOIN checkpoints c ON c.cpID=r.finishcpID JOIN checkpointStatistics s ON s.runID=r.runID AND s.cpID=r.finishcpID WHERE r.runID=" + id + " AND r.finishTimeStamp IS NOT NULL";
    ok = isDefined(openCJ\mySQL::mysqlAsyncQuery(query));
    for (first=0;ok && first<count;first+=64)
    {
        length = count-first;
        if (length>64) length=64;
        hex = demoEncodeChunk(id,first,length);
        if (!isDefined(hex)) {ok=false;break;}
        ok = isDefined(openCJ\mySQL::mysqlAsyncQuery("INSERT INTO demoChunks VALUES(" + id + "," + int(first/64) + ",UNHEX('" + hex + "'))"));
    }
    if (ok) ok = promote(id);
    if (!ok)
    {
        printf("OpenCJ: demo publication failed for run " + id + "; leaderboard result retained.\n");
        // Only our unpublished candidate can be removed here.
        openCJ\mySQL::mysqlAsyncQuery("DELETE FROM demoRuns WHERE runID=" + id + " AND ready=0");
    }
    destroyDemo(id);
}

// No yields inside this transaction; the map lock serializes winner changes
// across game servers. A single payload may hold several category references.
promote(id)
{
    rows = openCJ\mySQL::mysqlSyncQuery("SELECT mapID,routeName,FPSMode,modeMask,timePlayed,explosiveJumps FROM demoRuns WHERE runID=" + id);
    if (!isDefined(rows) || rows.size!=1) return false;
    row=rows[0];
    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("START TRANSACTION"))) return false;
    ok = isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT mapID FROM mapids WHERE mapID=" + row[0] + " FOR UPDATE"));
    kinds=[];kinds[0]="speedrun";kinds[1]="lowrpg";
    if (int(row[3])==0 && row[2]!="hax") kinds[2]="walkthrough";
    for (i=0;ok && i<kinds.size;i++)
    {
        where = "w.mapID="+row[0]+" AND w.routeName="+dbStr(row[1])+" AND w.FPSMode="+dbStr(row[2])+" AND w.modeMask="+row[3]+" AND w.kind="+dbStr(kinds[i]);
        old = openCJ\mySQL::mysqlSyncQuery("SELECT d.timePlayed,d.explosiveJumps FROM demoWinners w JOIN demoRuns d ON d.runID=w.runID WHERE "+where);
        if (!isDefined(old)) {ok=false;break;}
        better = old.size==0;
        if (!better) better = isBetter(kinds[i],int(row[4]),int(row[5]),int(old[0][0]),int(old[0][1]));
        if (better)
            ok = isDefined(openCJ\mySQL::mysqlSyncQuery("INSERT INTO demoWinners VALUES("+row[0]+","+dbStr(row[1])+","+dbStr(row[2])+","+row[3]+","+dbStr(kinds[i])+","+id+") ON DUPLICATE KEY UPDATE runID=VALUES(runID)"));
    }
    if (ok) ok = isDefined(openCJ\mySQL::mysqlSyncQuery("UPDATE demoRuns SET ready=1 WHERE runID="+id));
    if (ok) ok = isDefined(openCJ\mySQL::mysqlSyncQuery("DELETE d FROM demoRuns d LEFT JOIN demoWinners w ON w.runID=d.runID WHERE d.mapID="+row[0]+" AND d.ready=1 AND w.runID IS NULL"));
    if (ok) ok = isDefined(openCJ\mySQL::mysqlSyncQuery("COMMIT"));
    if (!ok) openCJ\mySQL::mysqlSyncQuery("ROLLBACK");
    return ok;
}

isBetter(kind,time,rpgs,oldTime,oldRpgs)
{
    if (kind=="lowrpg") return rpgs<oldRpgs || (rpgs==oldRpgs && time<oldTime);
    if (kind=="walkthrough") return time<oldTime;
    return time<oldTime || (time==oldTime && rpgs<oldRpgs);
}

// An explicitly abandoned run cannot be resumed through the runs menu.
discard(id)
{
    if(!isDefined(id) || !isDefined(self.demoRecordings))return;
    rec=self.demoRecordings[""+id];
    if(!isDefined(rec))return;
    if(!rec.failed && !rec.finishing)destroyDemo(id);
    self.demoRecordings[""+id]=undefined;
}
