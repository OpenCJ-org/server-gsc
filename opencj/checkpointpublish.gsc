// Publish a complete sequential route into the existing checkpoint graph.
// No waits inside the transaction: every statement uses the same sync connection.
publish()
{
    if (isDefined(self.cpc.network))return self openCJ\checkpointNetwork::publish();
    if (self.cpc.rows.size == 0)
    {
        self.cpc.status = "Confirm checkpoints before publishing";
        return false;
    }
    if (self.cpc.draft.points.size > 0 || self.cpc.draft.alternatives.size > 0)
    {
        self.cpc.status = "Confirm your current edit first (or Undo / New to discard it)";
        return false;
    }
    error = validationError(self.cpc.rows);
    if (error != "")
    {
        self.cpc.status = error;
        return false;
    }
    if (!openCJ\mapID::hasMapID())
    {
        self.cpc.status = "Map has no database ID";
        return false;
    }
    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointAreas LIMIT 0")))
    {
        self.cpc.status = "Install server-db/migrations/001-checkpoint-areas.sql first";
        return false;
    }
    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT colorRGB FROM routes LIMIT 0")))
        return self _fail("Install server-db/migrations/002-route-colors.sql first");
    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("START TRANSACTION")))
    {
        self.cpc.status = "Cannot start database transaction; draft retained";
        return false;
    }
    if (!self _writeRoute())
    {
        openCJ\mySQL::mysqlSyncQuery("ROLLBACK");
        self iprintln(self.cpc.status);
        return false;
    }
    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("COMMIT")))
    {
        openCJ\mySQL::mysqlSyncQuery("ROLLBACK");
        self.cpc.status = "Database commit failed; draft retained";
        return false;
    }
    return true;
}

validationError(rows)
{
    if (rows.size == 0)
        return "Confirm checkpoints before finalizing";
    hasFinish = false;
    for (i = 0; i < rows.size; i++)
    {
        cp = openCJ\checkpointCreation::_decode(rows[i]);
        if (!isDefined(cp) || openCJ\checkpointArea::validate(cp.points) != "")
            return "Every checkpoint needs valid confirmed geometry";
        if (hasFinish && !cp.finish)
            return "Finish checkpoints must come after all ordinary checkpoints";
        if (cp.finish)
            hasFinish = true;
    }
    if (!hasFinish)
        return "Mark and confirm at least one Finish before !cp finalize";
    return "";
}

// Refresh the graph without invalidating other players' checkpoint references.
activate()
{
    openCJ\checkpoints::onInit();
    players = getEntArray("player", "classname");
    for (i = 0; i < players.size; i++)
    {
        player = players[i];
        if (!isDefined(player.checkpoints_checkpoint))
            continue;
        current = openCJ\checkpoints::getCheckpointByID(player.checkpoints_checkpoint.id);
        if (!isDefined(current))
            current = level.checkpoints_startCheckpoint;
        player.checkpoints_checkpoint = current;
        player.route = openCJ\checkpoints::getRouteNameForCheckpoint(current);
        for (j = 0; j < player.checkpoints_passed.size; j++)
            player.checkpoints_passed[j] = openCJ\checkpoints::getCheckpointByID(player.checkpoints_passed[j].id);
        if (!player openCJ\checkpointCreation::isEditing())
            player openCJ\checkpointPointers::onCheckpointsChanged();
    }
}

_writeRoute()
{
    if (isDefined(self.cpc.sharedRoute))
        return self openCJ\checkpointBranch::publish();
    return self _writeSequentialRoute();
}

_writeSequentialRoute()
{
    entries = self _entries();
    mapID = openCJ\mapID::getMapID();
    route = openCJ\mySQL::escapeString(self.cpc.route);
    where = "mapID=" + mapID + " AND routeName='" + route + "'";
    // Lock the map row to serialize publishers of the same map.
    locked = openCJ\mySQL::mysqlSyncQuery("SELECT mapID FROM mapids WHERE mapID=" + mapID + " FOR UPDATE");
    if (!isDefined(locked) || locked.size != 1)
        return self _fail("Cannot lock map for publishing");
    existing = openCJ\mySQL::mysqlSyncQuery("SELECT cpID,(SELECT bigBrotherID FROM checkpointBrothers b WHERE b.cpID=checkpointAreas.cpID),(SELECT ender FROM checkpoints c WHERE c.cpID=checkpointAreas.cpID) FROM checkpointAreas WHERE " + where + " ORDER BY ordinal");
    if (!isDefined(existing))
        return self _fail("Cannot read published checkpoint IDs");
    // Existing recorded routes must not change meaning underneath player records/saves.
    if (existing.size > 0)
    {
        used = openCJ\mySQL::mysqlSyncQuery("SELECT a.cpID FROM checkpointAreas a WHERE a.mapID=" + mapID + " AND a.routeName='" + route + "' AND (EXISTS (SELECT 1 FROM checkpointStatistics s WHERE s.cpID=a.cpID) OR EXISTS (SELECT 1 FROM playerSaves s WHERE s.checkpointID=a.cpID) OR EXISTS (SELECT 1 FROM playerSaves_test s WHERE s.checkpointID=a.cpID) OR EXISTS (SELECT 1 FROM playerRuns r WHERE r.finishcpID=a.cpID)) LIMIT 1");
        if (!isDefined(used))return self _fail("Cannot check existing checkpoint records");
        if (used.size > 0)
        {
            // A new route may join a finished, already-played route. Reusing its
            // identical checkpoint chain must not rewrite IDs or player records.
            if (self unchangedPublished(entries, existing))return true;
            return self _fail("Published checkpoints have records/saves. Draft retained; changes need a record migration");
        }
        if (existing.size != entries.size)
            return self _fail("Published route length differs. Draft retained; checkpoint IDs will not be deleted");
        for (i = 0; i < entries.size; i++)
        {
            if (entries[i].cp.finish != isDefined(existing[i][2]))
                return self _fail("Published finish layout differs; draft retained");
            if (entries[i].leader == i && isDefined(existing[i][1]))
                return self _fail("Published area grouping differs; draft retained");
            if (entries[i].leader != i && (!isDefined(existing[i][1]) || int(existing[i][1]) != int(existing[entries[i].leader][0])))
                return self _fail("Published area grouping differs; draft retained");
        }
    }
    else
    {
        collision = openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpoints WHERE mapID=" + mapID + " AND ender='" + route + "' LIMIT 1");
        if (!isDefined(collision) || collision.size > 0)
            return self _fail("An existing route already uses that name; it will not be overwritten");
    }
    ids = [];
    groups = [];
    for (i = 0; i < self.cpc.rows.size; i++)
        groups[i] = [];
    for (i = 0; i < entries.size; i++)
    {
        cp = entries[i].cp;
        points = entries[i].points;
        origin = (0, 0, 0);
        for (j = 0; j < points.size; j++)
            origin += points[j];
        origin = vectorScale(origin, 1.0 / points.size);
        finish = "NULL";
        if (cp.finish)
            finish = "'" + route + "'";
        values = "x=" + int(origin[0]) + ",y=" + int(origin[1]) + ",z=" + int(origin[2]) + ",radius=NULL,onGround=" + int(cp.onGround) + ",ender=" + finish;
        if (existing.size == 0)
        {
            result = openCJ\mySQL::mysqlSyncQuery("INSERT INTO checkpoints SET mapID=" + mapID + "," + values);
            if (!isDefined(result))
                return self _fail("Failed to insert checkpoint; transaction rolled back");
            idRow = openCJ\mySQL::mysqlSyncQuery("SELECT LAST_INSERT_ID()");
            if (!isDefined(idRow) || idRow.size != 1)
                return self _fail("Failed to obtain checkpoint ID");
            ids[i] = int(idRow[0][0]);
        }
        else
        {
            ids[i] = int(existing[i][0]);
            if (!isDefined(openCJ\mySQL::mysqlSyncQuery("UPDATE checkpoints SET " + values + " WHERE cpID=" + ids[i])))
                return self _fail("Failed to update checkpoint");
        }
        group = entries[i].group;
        groups[group][groups[group].size] = ids[i];
        vertices = openCJ\mySQL::escapeString(openCJ\checkpointArea::encode(points));
        result = openCJ\mySQL::mysqlSyncQuery("INSERT INTO checkpointAreas (cpID,mapID,routeName,ordinal,vertices,allowDoubleRPG) VALUES (" + ids[i] + "," + mapID + ",'" + route + "'," + i + ",'" + vertices + "'," + int(cp.double) + ") ON DUPLICATE KEY UPDATE vertices=VALUES(vertices),allowDoubleRPG=VALUES(allowDoubleRPG)");
        if (!isDefined(result))
            return self _fail("Failed to save checkpoint area");
        if (existing.size == 0 && entries[i].leader != i)
        {
            if (!isDefined(openCJ\mySQL::mysqlSyncQuery("INSERT INTO checkpointBrothers (cpID,bigBrotherID) VALUES (" + ids[i] + "," + ids[entries[i].leader] + ")")))
                return self _fail("Failed to link alternative area");
        }
    }
    if (existing.size == 0)
    {
        parent = 0;
        first = self openCJ\checkpointCreation::getConfirmed(0);
        for (i = 1; i < groups.size; i++)
        {
            previous = self openCJ\checkpointCreation::getConfirmed(i - 1);
            if (!previous.finish)
                parent = i - 1;
            else if (first.finish)
                continue;
            for (j = 0; j < groups[parent].size; j++)
            {
                for (k = 0; k < groups[i].size; k++)
                {
                    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("INSERT INTO checkpointConnections (cpID,childcpID) VALUES (" + groups[parent][j] + "," + groups[i][k] + ")")))
                        return self _fail("Failed to connect checkpoint groups");
                }
            }
        }
    }
    hex = self.cpc.routeHex;
    if (!isDefined(hex))
        hex = openCJ\checkpointCreation::defaultRouteColor(self.cpc.route);
    color = openCJ\checkpointCreation::routeRGB(hex);
    if (!isDefined(color))
        return self _fail("Invalid route color; draft retained");
    packed = int(color[0]*255+0.5)*65536 + int(color[1]*255+0.5)*256 + int(color[2]*255+0.5);
    if (!isDefined(openCJ\mySQL::mysqlSyncQuery("INSERT INTO routes (cpID,routeName,colorRGB) VALUES (" + ids[0] + ",'" + route + "'," + packed + ") ON DUPLICATE KEY UPDATE routeName=VALUES(routeName),colorRGB=VALUES(colorRGB)")))
        return self _fail("Failed to store route color; transaction rolled back");
    return true;
}

_entries()
{
    entries = [];
    for (i = 0; i < self.cpc.rows.size; i++)
    {
        cp = self openCJ\checkpointCreation::getConfirmed(i);
        leader = entries.size;
        for (j = 0; j <= cp.alternatives.size; j++)
        {
            entry = spawnStruct();
            entry.cp = cp;
            entry.group = i;
            entry.leader = leader;
            entry.points = cp.points;
            if (j > 0)
                entry.points = cp.alternatives[j - 1];
            entries[entries.size] = entry;
        }
    }
    return entries;
}

_fail(message)
{
    self.cpc.status = message;
    return false;
}

loadAreas()
{
    level.checkpointRoutes = [];
    if (getCodVersion() != 4)
        return;
    tables = openCJ\mySQL::mysqlSyncQuery("SHOW TABLES LIKE 'checkpointAreas'");
    if (!isDefined(tables) || tables.size == 0)
        return;
    columns = openCJ\mySQL::mysqlSyncQuery("SHOW COLUMNS FROM routes LIKE 'colorRGB'");
    if (isDefined(columns) && columns.size > 0)
    {
        routes = openCJ\mySQL::mysqlSyncQuery("SELECT r.cpID,r.routeName,CONCAT('#',LPAD(HEX(r.colorRGB),6,'0')) FROM routes r JOIN checkpoints c ON c.cpID=r.cpID WHERE c.mapID=" + openCJ\mapID::getMapID() + " AND r.colorRGB IS NOT NULL");
        if (isDefined(routes))
        {
            for (i = 0; i < routes.size; i++)
            {
                info = spawnStruct();
                info.startID = int(routes[i][0]);
                info.name = routes[i][1];
                info.hex = toLower(routes[i][2]);
                info.color = openCJ\checkpointCreation::routeRGB(info.hex);
                level.checkpointRoutes[info.name] = info;
            }
        }
    }
    columns = openCJ\mySQL::mysqlSyncQuery("SHOW COLUMNS FROM checkpointAreas LIKE 'sectionName'");
    query = "SELECT cpID,vertices,allowDoubleRPG,routeName,NULL FROM checkpointAreas WHERE mapID=" + openCJ\mapID::getMapID();
    if (isDefined(columns) && columns.size)
        query = "SELECT a.cpID,a.vertices,a.allowDoubleRPG,a.routeName,CONCAT('#',LPAD(HEX(s.colorRGB),6,'0')) FROM checkpointAreas a LEFT JOIN checkpointSectionColors s ON s.mapID=a.mapID AND s.sectionName=a.sectionName WHERE a.mapID=" + openCJ\mapID::getMapID();
    rows = openCJ\mySQL::mysqlSyncQuery(query);
    if (!isDefined(rows))
        return;
    for (i = 0; i < rows.size; i++)
    {
        cp = openCJ\checkpoints::getCheckpointByID(int(rows[i][0]));
        points = openCJ\checkpointArea::decode(rows[i][1]);
        if (!isDefined(cp) || !isDefined(points))
            continue;
        if (openCJ\checkpointArea::validate(points) != "")
            continue;
        cp.area = points;
        cp.allowDoubleRPG = int(rows[i][2]);
        cp.routeInfo = level.checkpointRoutes[rows[i][3]];
        if (isDefined(rows[i][4]))
        {
            info = spawnStruct();info.name = rows[i][3];info.hex = toLower(rows[i][4]);
            info.color = openCJ\checkpointCreation::routeRGB(info.hex);cp.routeInfo = info;
        }
    }
}


unchangedPublished(entries, existing)
{
    if(entries.size!=existing.size)return false;
    rows=openCJ\mySQL::mysqlSyncQuery("SELECT a.vertices,a.allowDoubleRPG,c.onGround,c.ender FROM checkpointAreas a JOIN checkpoints c ON c.cpID=a.cpID WHERE a.mapID="+openCJ\mapID::getMapID()+" AND a.routeName="+openCJ\util::dbStr(self.cpc.route)+" ORDER BY a.ordinal");
    if(!isDefined(rows)||rows.size!=entries.size)return false;
    for(i=0;i<entries.size;i++)
    {
        points=openCJ\checkpointArea::decode(rows[i][0]);cp=entries[i].cp;
        if(!isDefined(points)||points.size!=entries[i].points.size||int(rows[i][1])!=int(cp.double)||int(rows[i][2])!=int(cp.onGround))return false;
        if(cp.finish!=isDefined(rows[i][3]))return false;
        if(cp.finish&&rows[i][3]!=self.cpc.route)return false;
        for(j=0;j<points.size;j++)if(distanceSquared(points[j],entries[i].points[j])>0.0001)return false;
        if(entries[i].leader==i && isDefined(existing[i][1]))return false;
        if(entries[i].leader!=i && (!isDefined(existing[i][1])||int(existing[i][1])!=int(existing[entries[i].leader][0])))return false;
    }
    return true;
}
