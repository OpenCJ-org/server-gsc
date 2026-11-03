// Pure matching only: one contiguous edit between unchanged endpoints.
plan(oldRows,newRows)
{
    if(oldRows.size<2 || newRows.size<2 || oldRows[0]!=newRows[0] || oldRows[oldRows.size-1]!=newRows[newRows.size-1])return undefined;
    first=0;
    while(first<oldRows.size && first<newRows.size && oldRows[first]==newRows[first])first++;
    tail=0;
    while(tail<oldRows.size-first && tail<newRows.size-first && oldRows[oldRows.size-1-tail]==newRows[newRows.size-1-tail])tail++;
    removed=oldRows.size-first-tail;added=newRows.size-first-tail;
    if(removed>3 || added>3 || (removed>0 && added>0 && (removed!=1 || added!=1)))return undefined;
    for(i=first;i<first+removed;i++)
    {
        cp=openCJ\checkpointCreation::_decode(oldRows[i]);if(cp.finish)return undefined;
        if(!added && (cp.double || cp.allowEle || !cp.allowSave || !cp.onGround))return undefined;
    }
    for(i=first;i<first+added;i++)
    {
        cp=openCJ\checkpointCreation::_decode(newRows[i]);if(cp.finish)return undefined;
        for(j=0;j<oldRows.size;j++)if(oldRows[j]==newRows[i])return undefined;
        if(removed==1 && added==1)
        {
            prior=openCJ\checkpointCreation::_decode(oldRows[first]);
            if(cp.double!=prior.double || cp.allowEle!=prior.allowEle || cp.allowSave!=prior.allowSave || cp.onGround!=prior.onGround)return undefined;
        }
        else if(cp.double || cp.allowEle || !cp.allowSave || !cp.onGround)return undefined;
    }
    p=spawnStruct();p.mapping=[];
    for(i=0;i<newRows.size;i++)
    {
        p.mapping[i]=-1;
        if(i<first)p.mapping[i]=i;
        else if(i>=newRows.size-tail)p.mapping[i]=oldRows.size-(newRows.size-i);
        else if(removed==1 && added==1)p.mapping[i]=first;
    }
    return p;
}

prepare(entries,existing)
{
    if(isDefined(level.demoPersisting) && level.demoPersisting>0)return self fail("A demo is still saving; retry finalizing shortly");
    map=openCJ\mapID::getMapID();route=self.cpc.route;
    rows=openCJ\mySQL::mysqlSyncQuery("SELECT a.cpID,b.bigBrotherID,c.ender,a.vertices,a.allowDoubleRPG,c.onGround,c.allowSave,c.elevate,a.platformRef FROM checkpointAreas a JOIN checkpoints c ON c.cpID=a.cpID LEFT JOIN checkpointBrothers b ON b.cpID=a.cpID WHERE a.mapID="+map+" AND a.routeName="+openCJ\util::dbStr(route)+" ORDER BY a.ordinal");
    if(!isDefined(rows)||!rows.size)return self fail("Cannot read route for migration");
    old=[];groups=[];ids="(";
    for(i=0;i<rows.size;i++)
    {
        if(i)ids+=",";ids+=rows[i][0];
        cp=openCJ\checkpointCreation::_empty();cp.points=openCJ\checkpointArea::decode(rows[i][3]);
        if(isDefined(rows[i][8]))cp.platformRef=rows[i][8];
        cp.finish=isDefined(rows[i][2]);cp.double=int(rows[i][4]);cp.onGround=int(rows[i][5]);cp.allowSave=int(rows[i][6]);cp.allowEle=int(rows[i][7]);
        if(!isDefined(rows[i][1]))
        {
            group=[];group[0]=i;groups[groups.size]=group;old[old.size]=openCJ\checkpointCreation::_encode(cp);
        }
        else
        {
            g=groups.size-1;
            if(g<0 || int(rows[i][1])!=int(rows[groups[g][0]][0]))return self fail("Complex alternative grouping; draft retained");
            prior=openCJ\checkpointCreation::_decode(old[g]);prior.alternatives[prior.alternatives.size]=cp.points;
            if(prior.double!=cp.double || prior.allowEle!=cp.allowEle || prior.allowSave!=cp.allowSave || prior.onGround!=cp.onGround || prior.finish!=cp.finish)return self fail("Alternative requirements differ; draft retained");
            old[g]=openCJ\checkpointCreation::_encode(prior);groups[g][groups[g].size]=i;
        }
    }
    ids+=")";
    p=plan(old,self.cpc.rows);
    if(!isDefined(p))return self fail("Migration too complex: keep start/finish and requirements; change one checkpoint or insert/delete up to 3 together");
    outside=openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointConnections WHERE (cpID IN "+ids+" AND childcpID NOT IN "+ids+") OR (childcpID IN "+ids+" AND cpID NOT IN "+ids+") UNION SELECT cpID FROM checkpointBrothers WHERE bigBrotherID IN "+ids+" AND cpID NOT IN "+ids+" LIMIT 1");
    if(!isDefined(outside)||outside.size)return self fail("Shared route connections require manual migration; draft retained");
    players=getEntArray("player","classname");
    for(i=0;i<players.size;i++)
        if(players[i]!=self && players[i] openCJ\playerRuns::hasRunID() && isDefined(players[i].route) && players[i].route==route)
            return self fail("Another player has this route open; ask them to reset before finalizing");
    // Save old geometry before replacing the graph. This file is never overwritten.
    original=self.cpc;backup=spawnStruct();backup.route=route;backup.rows=old;backup.selected=old.size;
    backup.draft=openCJ\checkpointCreation::_empty();backup.revision=0;backup.routeHex=original.routeHex;
    prefix=original.path+".before-migration-"+getTime();backup.path=prefix;
    for(n=0;FS_TestFile(backup.path+".b");n++)backup.path=prefix+"-"+n;
    self.cpc=backup;ok=self openCJ\checkpointCreation::_save();self.cpc=original;
    if(!ok)return self fail("Cannot back up finalized geometry; migration cancelled");
    p.existing=[];kept="(";
    for(i=0;i<entries.size;i++)
    {
        target=[];oldGroup=p.mapping[entries[i].group];area=i-entries[i].leader;
        if(oldGroup>=0 && area<groups[oldGroup].size)
        {
            target=existing[groups[oldGroup][area]];
            if(kept!="(")kept+=",";kept+=target[0];
        }
        p.existing[i]=target;
    }
    kept+=")";
    queries=[];
    // Retain all checkpoint IDs, statistics, completed results, saves and footage.
    queries[queries.size]="UPDATE checkpoints SET retired=1 WHERE cpID IN "+ids+" AND cpID NOT IN "+kept;
    // Only replaceable layout definitions are rebuilt, inside publish's transaction.
    queries[queries.size]="DELETE FROM checkpointConnections WHERE cpID IN "+ids+" AND childcpID IN "+ids;
    queries[queries.size]="DELETE FROM checkpointBrothers WHERE cpID IN "+ids;
    queries[queries.size]="DELETE FROM checkpointAreas WHERE cpID IN "+ids;
    queries[queries.size]="UPDATE playerRuns r SET archived=1 WHERE r.finishcpID IS NULL AND (EXISTS(SELECT 1 FROM checkpointStatistics s WHERE s.runID=r.runID AND s.cpID IN "+ids+") OR EXISTS(SELECT 1 FROM playerSaves s WHERE s.runID=r.runID AND s.checkpointID IN "+ids+"))";
    // ready=2 retains old footage while excluding playback and winner comparison.
    queries[queries.size]="UPDATE demoRuns SET ready=2 WHERE mapID="+map+" AND routeName="+openCJ\util::dbStr(route);
    for(i=0;i<queries.size;i++)
        if(!isDefined(openCJ\mySQL::mysqlSyncQuery(queries[i])))return self fail("Migration failed; transaction rolled back and draft retained");
    return p;
}

fail(message)
{
    self.cpc.status=message;return undefined;
}
