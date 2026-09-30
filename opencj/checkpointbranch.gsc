#include openCJ\util;

// Branch drafts retain a snapshot of the shared opening, so either can be
// finalized first and each file remains sufficient for disaster recovery.
split(first, second)
{
    if (!openCJ\checkpointCreation::_validName(first) || !openCJ\checkpointCreation::_validName(second) || first == second || first == self.cpc.route || second == self.cpc.route)
    {
        self sendLocalChatMessage("Use two different new route names: !cp split easy hard", true);
        return;
    }
    if (isDefined(self.cpc.sharedRoute))
    {
        self sendLocalChatMessage("Splitting an existing branch again is not supported yet; your draft is unchanged.", true);
        return;
    }
    if (self.cpc.rows.size == 0 || self.cpc.draft.points.size > 0 || self.cpc.draft.alternatives.size > 0)
    {
        self sendLocalChatMessage("Confirm the last shared landing, then use !cp split easy hard.", true);
        return;
    }
    for (i = 0; i < self.cpc.rows.size; i++)
    {
        cp = self openCJ\checkpointCreation::getConfirmed(i);
        if (cp.finish)
        {
            self sendLocalChatMessage("The shared opening cannot contain a Finish.", true);
            return;
        }
    }
    if (!openCJ\mapID::hasMapID())
    {
        self sendLocalChatMessage("Map has no database ID; draft retained.", true);
        return;
    }
    names = []; names[0] = first; names[1] = second;
    paths = [];
    for (i = 0; i < names.size; i++)
    {
        paths[i] = "checkpoints/drafts/" + self openCJ\login::getPlayerID() + "_" + getCvar("mapname") + "_" + names[i];
        existing = openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointAreas WHERE mapID=" + openCJ\mapID::getMapID() + " AND routeName=" + dbStr(names[i]) + " LIMIT 1");
        if (!isDefined(existing) || existing.size || FS_TestFile(paths[i] + ".a") || FS_TestFile(paths[i] + ".b"))
        {
            self sendLocalChatMessage("A draft or published route already uses " + names[i] + "; nothing was overwritten.", true);
            return;
        }
    }
    if (!self openCJ\checkpointCreation::_save())return;
    source = self.cpc;
    ok = true;
    for (i = 0; i < names.size; i++)
    {
        self.cpc = makeDraft(source, names[i], paths[i]);
        if (!self openCJ\checkpointCreation::_save())ok = false;
    }
    self.cpc = source;
    if (!ok)
    {
        self sendLocalChatMessage("Could not save both branches. Original draft retained; inspect draft files before retrying.", true);
        return;
    }
    self openCJ\checkpointCreation::_close();
    self openCJ\checkpointCreation::_start(first);
    self sendLocalChatMessage("Split saved: " + first + " and " + second + " share " + source.rows.size + " checkpoints. Continue " + first + "; !cp start " + second + " returns to this split to build the other side.");
}

makeDraft(source, route, path)
{
    draft = spawnStruct();
    draft.route = route;
    draft.path = path;
    draft.routeHex = openCJ\checkpointCreation::defaultRouteColor(route);
    draft.sharedRoute = source.route;
    draft.sharedHex = source.routeHex;
    draft.sharedCount = source.rows.size;
    draft.rows = [];
    for (i = 0; i < source.rows.size; i++)draft.rows[i] = source.rows[i];
    draft.selected = draft.rows.size;
    draft.draft = openCJ\checkpointCreation::_empty();
    draft.revision = 0;
    return draft;
}

// Called inside checkpointPublish's existing map-locked transaction.
publish()
{
    branch = self.cpc;
    count = branch.sharedCount;
    if (!isDefined(count) || count < 1 || count >= branch.rows.size)
        return self openCJ\checkpointPublish::_fail("Add this branch's checkpoints and Finish before finalizing");
    prefix = spawnStruct();
    prefix.route = branch.sharedRoute;
    prefix.routeHex = branch.sharedHex;
    if (!isDefined(prefix.routeHex))
        prefix.routeHex = openCJ\checkpointCreation::defaultRouteColor(branch.sharedRoute);
    prefix.rows = [];
    for (i = 0; i < count; i++)prefix.rows[i] = branch.rows[i];
    self.cpc = prefix;
    parentIDs = self ensurePrefix();
    status = self.cpc.status;
    self.cpc = branch;
    if (!isDefined(parentIDs))return self openCJ\checkpointPublish::_fail(status);

    suffix = spawnStruct();
    suffix.route = branch.route;
    suffix.routeHex = branch.routeHex;
    suffix.rows = [];
    for (i = count; i < branch.rows.size; i++)suffix.rows[suffix.rows.size] = branch.rows[i];
    self.cpc = suffix;
    ok = self openCJ\checkpointPublish::_writeSequentialRoute();
    status = self.cpc.status;
    self.cpc = branch;
    if (!ok)return self openCJ\checkpointPublish::_fail(status);
    first = openCJ\checkpointCreation::_decode(suffix.rows[0]);
    children = openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointAreas WHERE mapID=" + openCJ\mapID::getMapID() + " AND routeName=" + dbStr(branch.route) + " ORDER BY ordinal LIMIT " + (first.alternatives.size + 1));
    if (!isDefined(children) || children.size != first.alternatives.size + 1)
        return self openCJ\checkpointPublish::_fail("Cannot read branch connection IDs");
    for (i = 0; i < parentIDs.size; i++)
    {
        for (j = 0; j < children.size; j++)
        {
            parent = parentIDs[i]; child = int(children[j][0]);
            // This legacy edge table has no unique key; explicitly avoid duplicates.
            query = "INSERT INTO checkpointConnections(cpID,childcpID) SELECT " + parent + "," + child + " WHERE NOT EXISTS (SELECT 1 FROM checkpointConnections WHERE cpID=" + parent + " AND childcpID=" + child + ")";
            if (!isDefined(openCJ\mySQL::mysqlSyncQuery(query)))
                return self openCJ\checkpointPublish::_fail("Could not connect branch to shared opening");
        }
    }
    return true;
}

ensurePrefix()
{
    mapID = openCJ\mapID::getMapID();
    // Acquire the same lock before reading or creating the shared opening.
    lock = openCJ\mySQL::mysqlSyncQuery("SELECT mapID FROM mapids WHERE mapID=" + mapID + " FOR UPDATE");
    if (!isDefined(lock) || lock.size != 1)
    {
        self.cpc.status = "Cannot lock shared opening";
        return undefined;
    }
    entries = self openCJ\checkpointPublish::_entries();
    for (i = 0; i < entries.size; i++)
        if (entries[i].cp.finish){self.cpc.status = "Shared opening contains a Finish";return undefined;}
    where = "a.mapID=" + mapID + " AND a.routeName=" + dbStr(self.cpc.route);
    rows = openCJ\mySQL::mysqlSyncQuery("SELECT a.cpID,a.vertices,a.allowDoubleRPG,b.bigBrotherID,c.ender,c.onGround,c.allowSave FROM checkpointAreas a JOIN checkpoints c ON c.cpID=a.cpID LEFT JOIN checkpointBrothers b ON b.cpID=a.cpID WHERE " + where + " ORDER BY a.ordinal");
    if (!isDefined(rows)){self.cpc.status = "Cannot read shared opening";return undefined;}
    if (rows.size == 0)
    {
        if (!self openCJ\checkpointPublish::_writeSequentialRoute())return undefined;
        return self ensurePrefix();
    }
    if (rows.size != entries.size){self.cpc.status = "Shared opening differs from published checkpoints; draft retained";return undefined;}
    ids = [];
    for (i = 0; i < entries.size; i++)
    {
        points = openCJ\checkpointArea::decode(rows[i][1]);
        same = isDefined(points) && points.size == entries[i].points.size && int(rows[i][2]) == int(entries[i].cp.double) && !isDefined(rows[i][4]) && int(rows[i][5]) == int(entries[i].cp.onGround) && int(rows[i][6]) == int(entries[i].cp.allowSave);
        if (same)
            for (j = 0; j < points.size; j++)
                if (distanceSquared(points[j], entries[i].points[j]) > 0.0001)same = false;
        leader = entries[i].leader;
        if (leader == i && isDefined(rows[i][3]))same = false;
        if (leader != i && (!isDefined(rows[i][3]) || int(rows[i][3]) != int(rows[leader][0])))same = false;
        if (!same){self.cpc.status = "Shared geometry or requirements changed; existing checkpoints preserved";return undefined;}
        if (entries[i].group == self.cpc.rows.size - 1)ids[ids.size] = int(rows[i][0]);
    }
    return ids;
}
