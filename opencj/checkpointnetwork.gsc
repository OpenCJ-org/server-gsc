#include openCJ\util;

// A route is an ordered list of section drafts. Merges reference one shared
// section file; they never copy its edits into several competing drafts.
basePath()
{
    return "checkpoints/drafts/" + self openCJ\login::getPlayerID() + "_" + getCvar("mapname") + "_";
}

readSection(name)
{
    path = self basePath() + name;
    a = openCJ\checkpointCreation::_read(path + ".a", name);
    b = openCJ\checkpointCreation::_read(path + ".b", name);
    if (isDefined(b) && (!isDefined(a) || b.revision > a.revision))a = b;
    return a;
}

readNetworkFile(path)
{
    f = FS_FOpen(path, "read");
    if (!f)return undefined;
    line = FS_ReadLine(f);
    if (!isDefined(line)){FS_FClose(f);return undefined;}
    h = strTok(line, " ");
    if (h.size != 4 || h[0] != "CPN1" || !isValidInt(h[1]) || !isValidInt(h[3]) || !openCJ\checkpointCreation::_validName(h[2])){FS_FClose(f);return undefined;}
    n = spawnStruct(); n.revision = int(h[1]); n.root = h[2]; n.paths = [];
    count = int(h[3]);
    if (count < 2 || count > 16){FS_FClose(f);return undefined;}
    for (i = 0; i < count; i++)
    {
        line = FS_ReadLine(f);
        if (!isDefined(line)){FS_FClose(f);return undefined;}
        fields = strTok(line, " ");
        if (fields.size != 3 || !openCJ\checkpointCreation::_validName(fields[0]) || !isDefined(openCJ\checkpointCreation::routeRGB(fields[1]))){FS_FClose(f);return undefined;}
        path = spawnStruct();path.hex = fields[1];path.sections = strTok(fields[2], ",");
        if (path.sections.size < 2 || path.sections.size > 64 || path.sections[0] != n.root || isDefined(n.paths[fields[0]])){FS_FClose(f);return undefined;}
        for (j = 0; j < path.sections.size; j++)
            if (!openCJ\checkpointCreation::_validName(path.sections[j])){FS_FClose(f);return undefined;}
        n.paths[fields[0]] = path;
    }
    line = FS_ReadLine(f); FS_FClose(f);
    if (!isDefined(line) || line != "END " + n.revision)return undefined;
    return n;
}

load()
{
    if (!isDefined(self.login_playerID))return undefined;
    path = self basePath() + "network";
    a = readNetworkFile(path + ".a");b = readNetworkFile(path + ".b");
    if (isDefined(b) && (!isDefined(a) || b.revision > a.revision))return b;
    return a;
}

save(n)
{
    names = getArrayKeys(n.paths);
    if (names.size < 2 || names.size > 16)return false;
    for (i = 0; i < names.size; i++)
    {
        sections = n.paths[names[i]].sections;
        if (sections.size < 2 || sections.size > 64 || sections[0] != n.root)return false;
    }
    revision = n.revision + 1;
    suffix = ".a";if (revision % 2)suffix = ".b";
    file = FS_FOpen(self basePath() + "network" + suffix, "write");
    if (!file)return false;
    names = getArrayKeys(n.paths);
    ok = FS_WriteLine(file, "CPN1 " + revision + " " + n.root + " " + names.size);
    for (i = 0; i < names.size; i++)
    {
        path = n.paths[names[i]];sections = path.sections[0];
        for (j = 1; j < path.sections.size; j++)sections += "," + path.sections[j];
        if (!FS_WriteLine(file, names[i] + " " + path.hex + " " + sections))ok = false;
    }
    if (!FS_WriteLine(file, "END " + revision))ok = false;
    FS_FClose(file);
    if (ok)n.revision = revision;
    return ok;
}

members(n, section)
{
    result = [];
    names = getArrayKeys(n.paths);
    for (i = 0; i < names.size; i++)
        for (j = 0; j < n.paths[names[i]].sections.size; j++)
            if (n.paths[names[i]].sections[j] == section){result[result.size] = names[i];break;}
    return result;
}

label(names)
{
    text = "";
    for (i = 0; i < names.size; i++){if (i)text += " + ";text += names[i];}
    return text;
}

// Called after the prior editor was saved/closed.
resolve(name)
{
    n = self load();
    if (!isDefined(n))
    {
        path = self basePath() + "network";
        if (FS_TestFile(path + ".a") || FS_TestFile(path + ".b"))return undefined;
        return name;
    }
    if (!isDefined(n.paths[name]))return name;
    path = n.paths[name].sections;
    return path[path.size - 1];
}

opened()
{
    n = self load();
    if (!isDefined(n))return;
    names = members(n, self.cpc.route);
    if (!names.size)return;
    if (names.size == 1 && n.paths[names[0]].hex != self.cpc.routeHex)
    {
        n.paths[names[0]].hex = self.cpc.routeHex;
        if (!self save(n))self.cpc.status = "Could not save route color to network";
    }
    self.cpc.network = n;
    self.cpc.displayRoutes = label(names);
    if (names.size > 1)self.cpc.displayRoutes += " (shared)";
    if (!isDefined(self.cpc.restoreOrigin))
    {
        sections = n.paths[names[0]].sections;
        for (i = 1; i < sections.size; i++)
            if (sections[i] == self.cpc.route)
            {
                prior = self readSection(sections[i-1]);
                if (isDefined(prior))self.cpc.restoreOrigin = openCJ\checkpointCreation::restoreOrigin(prior);
                break;
            }
    }
}

fail(message)
{
    self.cpc.status = message;
    self sendLocalChatMessage(message, true);
    return false;
}

newSection(name, hex, pending)
{
    if (isDefined(self readSection(name)))return false;
    original = self.cpc;
    draft = spawnStruct();draft.route = name;draft.routeHex = hex;
    draft.path = self basePath() + name;draft.rows = [];draft.selected = 0;draft.revision = 0;
    draft.draft = openCJ\checkpointCreation::_empty();
    if (isDefined(pending))draft.draft = pending;
    self.cpc = draft;ok = self openCJ\checkpointCreation::_save();self.cpc = original;
    return ok;
}

namesValid(args)
{
    if (args.size < 3 || args.size > 17)return false;
    for (i = 1; i < args.size; i++)
    {
        if (!openCJ\checkpointCreation::_validName(args[i]))return false;
        for (j = 1; j < i; j++)if (args[i] == args[j])return false;
    }
    return true;
}

split(args)
{
    if (!namesValid(args))return self fail("Use !cp split easy hard [more route names]");
    n = self load();
    if (isDefined(n) && self.cpc.selected < self.cpc.rows.size)
        return self splitExisting(args,n);
    if (self.cpc.rows.size == 0 || self.cpc.draft.points.size || self.cpc.draft.alternatives.size)
        return self fail("Confirm the last shared landing before splitting.");
    last = openCJ\checkpointCreation::_decode(self.cpc.rows[self.cpc.rows.size-1]);
    if (last.finish)return self fail("A Finish cannot split. Unmark it first.");
    if (!self openCJ\checkpointCreation::_save())return false;
    n = self load();fresh = !isDefined(n);
    if (fresh)
    {
        if (isDefined(self.cpc.sharedRoute))return self fail("Legacy branch draft: finish or migrate it before creating a network.");
        n = spawnStruct();n.root = self.cpc.route;n.revision = 0;n.paths = [];
        for (i = 1; i < args.size; i++)
            if (args[i] == n.root || isDefined(self readSection(args[i])))return self fail("A requested name already has a draft; nothing changed.");
    }
    else
    {
        owners = members(n, self.cpc.route);
        if (owners.size != args.size-1)return self fail("List all routes sharing this section when splitting.");
        for (i = 1; i < args.size; i++)
        {
            if (!isDefined(n.paths[args[i]]))return self fail("A later split must use the original route names.");
            sections = n.paths[args[i]].sections;
            if (sections[sections.size-1] != self.cpc.route)return self fail("Only the current end of a shared section can split.");
        }
    }
    for (i = 1; i < args.size; i++)
    {
        name = args[i];section = "section_" + (n.revision+1) + "_" + i;
        if (fresh)section = name;
        hex = openCJ\checkpointCreation::defaultRouteColor(name);
        if (!fresh)hex = n.paths[name].hex;
        if (!self newSection(section, hex))return self fail("Could not create section; existing network retained.");
        if (fresh){path = spawnStruct();path.hex = hex;path.sections = [];path.sections[0] = n.root;n.paths[name] = path;}
        path = n.paths[name];path.sections[path.sections.size] = section;
    }
    if (!self save(n))return self fail("Network save failed; section drafts retained.");
    self openCJ\checkpointCreation::_close();self openCJ\checkpointCreation::_start(args[1]);
    self sendLocalChatMessage("Split saved. Editing " + args[1] + "; !cp start " + args[2] + " opens the other approach. Detect the common landing, then !cp merge " + labelCommand(args) + ".");
    return true;
}

labelCommand(args)
{
    text = args[1];for(i=2;i<args.size;i++)text += " " + args[i];return text;
}

merge(args)
{
    if (!namesValid(args))return self fail("Use !cp merge easy hard [more route names]");
    n = self load();if (!isDefined(n))return self fail("Split the shared opening into routes first.");
    self checkOverlap(true);
    if (isDefined(self.cpc.overlapSection))return self mergeExisting(args,n);
    if (self.cpc.selected != self.cpc.rows.size || openCJ\checkpointArea::validate(self.cpc.draft.points) != "")
        return self fail("Detect the first common landing without confirming it, then !cp merge easy hard.");
    included = false;
    for (i = 1; i < args.size; i++)
    {
        if (!isDefined(n.paths[args[i]]))return self fail("Unknown route " + args[i]);
        path = n.paths[args[i]].sections;tail = path[path.size-1];
        owners = members(n, tail);
        for (j = 0; j < owners.size; j++)
        {
            listed = false;for(k=1;k<args.size;k++)if(args[k]==owners[j])listed=true;
            if (!listed)return self fail("Include every route already sharing an incoming section.");
        }
        draft = self readSection(tail);
        if (tail == self.cpc.route){draft = self.cpc;included = true;}
        if (!isDefined(draft) || draft.rows.size == 0)return self fail("Checkpoint " + args[i] + " up to its last separate landing first.");
        last = openCJ\checkpointCreation::_decode(draft.rows[draft.rows.size-1]);
        if (last.finish)return self fail(args[i] + " ends in a Finish; remove that flag before merging.");
        if (tail != self.cpc.route && (draft.draft.points.size || draft.draft.alternatives.size))return self fail("Confirm or discard the pending selection on " + args[i] + " first.");
    }
    if (!included)return self fail("The route being edited must be included in the merge.");
    section = "shared_" + (n.revision+1);
    root = self readSection(n.root);
    if (!self newSection(section, root.routeHex, self.cpc.draft))return self fail("Could not save the common landing; merge unchanged.");
    self.cpc.draft = openCJ\checkpointCreation::_empty();
    if (!self openCJ\checkpointCreation::_save())return false;
    for(i=1;i<args.size;i++){path=n.paths[args[i]];path.sections[path.sections.size]=section;}
    if (!self save(n))return self fail("Could not save merge; section draft retained.");
    self openCJ\checkpointCreation::_close();self openCJ\checkpointCreation::_start(section);
    self sendLocalChatMessage("Merged " + labelCommand(args) + ". Confirm this common landing and continue once for all routes. Use !cp split " + labelCommand(args) + " if they separate again.");
    return true;
}


publish()
{
    original = self.cpc;n = self load();
    if (!isDefined(n))return self fail("Network draft cannot be read.");
    names = getArrayKeys(n.paths); drafts = [];
    root = self readSection(n.root);
    for(i=0;i<names.size;i++)
    {
        name=names[i];path=n.paths[name];flat=spawnStruct();flat.route=name;flat.routeHex=path.hex;
        flat.sharedRoute=n.root;flat.sharedHex=root.routeHex;flat.sharedCount=root.rows.size;
        flat.rows=[];flat.sections=[];flat.draft=openCJ\checkpointCreation::_empty();
        for(j=0;j<path.sections.size;j++)
        {
            section=path.sections[j];part=self readSection(section);
            if (!isDefined(part) || part.rows.size==0)return self fail("Complete section " + section + " before finalizing the network.");
            if(pendingEdit(part))return self fail("Confirm the pending area in " + section + " first.");
            for(k=0;k<part.rows.size;k++){flat.sections[flat.rows.size]=section;flat.rows[flat.rows.size]=part.rows[k];}
        }
        error=openCJ\checkpointPublish::validationError(flat.rows);
        if(error!="")return self fail(name + ": " + error);
        if(flat.rows.size>256)return self fail(name + " exceeds 256 checkpoints.");
        drafts[i]=flat;
    }
    if(!isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT sectionName FROM checkpointSectionColors LIMIT 0")))return self fail("Install migration 005-checkpoint-sections.sql first.");
    if(!isDefined(openCJ\mySQL::mysqlSyncQuery("START TRANSACTION")))return self fail("Cannot begin network publication.");
    ok=true;message="";
    for(i=0;i<drafts.size;i++)
    {
        self.cpc=drafts[i];
        if(!self openCJ\checkpointPublish::_writeRoute()){ok=false;message=self.cpc.status;break;}
        entries=self openCJ\checkpointPublish::_entries();
        // Logical checkpoints retain route-specific records through a merge.
        // Shared geometry is authored once in its section draft; the legacy
        // runtime receives one ordered continuation per route after the fork.
        rows=openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointAreas WHERE mapID="+openCJ\mapID::getMapID()+" AND routeName="+dbStr(self.cpc.route)+" ORDER BY ordinal");
        prefixEntries=0;
        for(j=0;j<entries.size;j++)if(entries[j].group<self.cpc.sharedCount)prefixEntries++;
        if(!isDefined(rows) || rows.size!=entries.size-prefixEntries){ok=false;message="Cannot read published section IDs";break;}
        for(j=prefixEntries;j<entries.size;j++)
        {
            section=self.cpc.sections[entries[j].group];
            if(!isDefined(openCJ\mySQL::mysqlSyncQuery("UPDATE checkpointAreas SET sectionName="+dbStr(section)+" WHERE cpID="+int(rows[j-prefixEntries][0])))){ok=false;message="Cannot assign checkpoint section";break;}
        }
        if(!ok)break;
    }
    self.cpc=original;
    if(ok)
    {
        sections=[];
        for(i=0;i<names.size;i++)for(j=0;j<n.paths[names[i]].sections.size;j++)sections[n.paths[names[i]].sections[j]]=true;
        keys=getArrayKeys(sections);
        for(i=0;i<keys.size;i++)
        {
            part=self readSection(keys[i]);color=openCJ\checkpointCreation::routeRGB(part.routeHex);
            packed=int(color[0]*255+0.5)*65536+int(color[1]*255+0.5)*256+int(color[2]*255+0.5);
            query="INSERT INTO checkpointSectionColors(mapID,sectionName,colorRGB) VALUES ("+openCJ\mapID::getMapID()+","+dbStr(keys[i])+","+packed+") ON DUPLICATE KEY UPDATE colorRGB=VALUES(colorRGB)";
            if(!isDefined(openCJ\mySQL::mysqlSyncQuery(query))){ok=false;message="Cannot save section color";break;}
        }
    }
    if(ok)ok=isDefined(openCJ\mySQL::mysqlSyncQuery("COMMIT"));
    if(!ok){openCJ\mySQL::mysqlSyncQuery("ROLLBACK");return self fail("Network not published: "+message);}
    self.cpc.publishedLabel=label(names);
    return true;
}

// Compare actual coplanar areas, not merely nearby centers. Also check edge
// midpoints so touching a common boundary alone does not report an overlap.
overlap(a,b)
{
    ca=openCJ\checkpointCreation::_center(a)-(0,0,12);
    cb=openCJ\checkpointCreation::_center(b)-(0,0,12);
    if(openCJ\checkpointArea::contains(a,cb,true) || openCJ\checkpointArea::contains(b,ca,true))return true;
    for(i=0;i<a.size;i++)
    {
        p=vectorScale(a[i]+ca,0.5);
        if(openCJ\checkpointArea::contains(b,p,true))return true;
    }
    for(i=0;i<b.size;i++)
    {
        p=vectorScale(b[i]+cb,0.5);
        if(openCJ\checkpointArea::contains(a,p,true))return true;
    }
    return false;
}

checkOverlap(quiet)
{
    self.cpc.overlap=undefined;self.cpc.overlapSection=undefined;self.cpc.overlapIndex=undefined;
    if (openCJ\checkpointArea::validate(self.cpc.draft.points)!="")return;
    n=self load();if(!isDefined(n))return;
    sections=[];names=getArrayKeys(n.paths);
    for(i=0;i<names.size;i++)for(j=0;j<n.paths[names[i]].sections.size;j++)sections[n.paths[names[i]].sections[j]]=true;
    keys=getArrayKeys(sections);
    for(i=0;i<keys.size;i++)
    {
        if(keys[i]==self.cpc.route)continue;
        part=self readSection(keys[i]);if(!isDefined(part))continue;
        for(j=0;j<part.rows.size;j++)
        {
            cp=openCJ\checkpointCreation::_decode(part.rows[j]);areas=[];areas[0]=cp.points;
            for(k=0;k<cp.alternatives.size;k++)areas[areas.size]=cp.alternatives[k];
            for(k=0;k<areas.size;k++)if(overlap(self.cpc.draft.points,areas[k]))
            {
                self.cpc.overlap=cp;self.cpc.overlapSection=keys[i];self.cpc.overlapIndex=j;
                self.cpc.status="Overlaps "+label(members(n,keys[i]))+" section "+keys[i]+" #"+(j+1);
                if (!isDefined(quiet) || !quiet)self sendLocalChatMessage(self.cpc.status+". Use !cp merge <routes> at the first common landing; use !cp split <routes> where they separate again. Do not confirm duplicate platforms.",true);
                return;
            }
        }
    }
}


// At a section boundary, show the separate incoming approaches in their colors.
drawConnections(cp)
{
    if (!isDefined(self.cpc.network) || self.cpc.selected > 0 || cp.points.size == 0)return;
    n=self.cpc.network;names=members(n,self.cpc.route);seen=[];
    for(i=0;i<names.size;i++)
    {
        sections=n.paths[names[i]].sections;
        for(j=1;j<sections.size;j++)if(sections[j]==self.cpc.route)
        {
            previous=sections[j-1];if(isDefined(seen[previous]))break;seen[previous]=true;
            part=self readSection(previous);if(!isDefined(part)||part.rows.size==0)break;
            prior=openCJ\checkpointCreation::_decode(part.rows[part.rows.size-1]);
            color=openCJ\checkpointCreation::_vec(openCJ\checkpointCreation::routeRGB(part.routeHex))+" 1";
            self openCJ\checkpointCreation::_outlineGroup(prior,color);
            self openCJ\checkpointCreation::_line(openCJ\checkpointCreation::_center(prior.points),openCJ\checkpointCreation::_center(cp.points),color);
            break;
        }
    }
}


hasName(args,name)
{
    for(i=1;i<args.size;i++)if(args[i]==name)return true;
    return false;
}

sectionIndex(path,section)
{
    for(i=0;i<path.size;i++)if(path[i]==section)return i;
    return -1;
}

uniqueSection(n)
{
    for(i=0;i<1024;i++)
    {
        name="part_"+(n.revision+1)+"_"+i;
        if(!FS_TestFile(self basePath()+name+".a")&&!FS_TestFile(self basePath()+name+".b"))return name;
    }
    return undefined;
}

writeSection(name,part)
{
    original=self.cpc;
    part.route=name;part.path=self basePath()+name;
    self.cpc=part;ok=self openCJ\checkpointCreation::_save();self.cpc=original;
    return ok;
}

sliceSection(n,part,first,end,hex)
{
    name=self uniqueSection(n);if(!isDefined(name))return undefined;
    slice=spawnStruct();slice.rows=[];slice.routeHex=hex;slice.revision=0;
    for(i=first;i<end;i++)slice.rows[slice.rows.size]=part.rows[i];
    slice.selected=slice.rows.size;slice.draft=openCJ\checkpointCreation::_empty();
    if(!self writeSection(name,slice))return undefined;
    return name;
}

replaceSection(n,old,first,second)
{
    names=getArrayKeys(n.paths);
    for(i=0;i<names.size;i++)
    {
        previous=n.paths[names[i]].sections;updated=[];
        for(j=0;j<previous.size;j++)
        {
            if(previous[j]!=old){updated[updated.size]=previous[j];continue;}
            if(isDefined(first))updated[updated.size]=first;
            if(isDefined(second))updated[updated.size]=second;
        }
        n.paths[names[i]].sections=updated;
    }
}

mergeExisting(args,n)
{
    source=self.cpc.route;target=self.cpc.overlapSection;index=self.cpc.overlapIndex;
    if(target==n.root)return self fail("This is the shared opening, not a later merge. Select the actual joining landing.");
    if(self.cpc.selected!=self.cpc.rows.size || self.cpc.rows.size==0)return self fail("Merge from a new detected landing after your last separate checkpoint.");
    sourceOwners=members(n,source);targetOwners=members(n,target);
    for(i=0;i<sourceOwners.size;i++)
    {
        path=n.paths[sourceOwners[i]].sections;
        if(path[path.size-1]!=source || sectionIndex(path,target)>=0)return self fail("Split the existing continuation first; merge from the end of a new approach.");
    }
    for(i=0;i<sourceOwners.size;i++)if(!hasName(args,sourceOwners[i]))return self fail("Include every route on the incoming approach.");
    for(i=0;i<targetOwners.size;i++)if(!hasName(args,targetOwners[i]))return self fail("Include every route already using the detected landing.");
    incomingNames=[];template=undefined;
    for(i=1;i<args.size;i++)
    {
        if(!isDefined(n.paths[args[i]]))return self fail("Unknown route "+args[i]);
        sections=n.paths[args[i]].sections;
        if(sectionIndex(sections,target)>=0)
        {
            if(!isDefined(template))template=args[i];
            continue;
        }
        tail=sections[sections.size-1];owners=members(n,tail);
        for(j=0;j<owners.size;j++)if(!hasName(args,owners[j]))return self fail("Include every route sharing an incoming approach.");
        draft=self readSection(tail);if(tail==source)draft=self.cpc;
        if(!isDefined(draft)||!draft.rows.size)return self fail("Complete the separate approach for "+args[i]+" first.");
        last=openCJ\checkpointCreation::_decode(draft.rows[draft.rows.size-1]);
        if(last.finish||(tail!=source&&pendingEdit(draft)))return self fail("Confirm the approach for "+args[i]+" without a Finish before merging.");
        incomingNames[incomingNames.size]=args[i];
    }
    if(!isDefined(template)||!incomingNames.size)return self fail("Choose an incoming route and an existing continuation.");
    // The first named existing route supplies the continuation for new arrivals.
    // Other existing routes keep their own later divergences untouched.
    continuation=n.paths[template].sections;targetPos=sectionIndex(continuation,target);
    for(i=0;i<incomingNames.size;i++)
    {
        incoming=n.paths[incomingNames[i]].sections;
        for(j=targetPos;j<continuation.size;j++)if(sectionIndex(incoming,continuation[j])>=0)return self fail("Merge would create a cycle; draft unchanged.");
    }
    part=self readSection(target);
    if(!isDefined(part)||pendingEdit(part))return self fail("Confirm or discard the existing route's pending edit before merging.");
    prefix=undefined;
    if(index>0){prefix=self sliceSection(n,part,0,index,part.routeHex);if(!isDefined(prefix))return self fail("Could not save existing approach; original retained.");}
    root=self readSection(n.root);
    shared=self sliceSection(n,part,index,part.rows.size,root.routeHex);
    if(!isDefined(shared))return self fail("Could not save shared continuation; original retained.");
    self replaceSection(n,target,prefix,shared);
    tail=[];tail[0]=shared;
    for(j=targetPos+1;j<continuation.size;j++)tail[tail.size]=continuation[j];
    for(i=0;i<incomingNames.size;i++)
    {
        path=n.paths[incomingNames[i]];
        for(j=0;j<tail.size;j++)path.sections[path.sections.size]=tail[j];
    }
    // Save the incoming approach without duplicating the joining checkpoint.
    pending=self.cpc.draft;self.cpc.draft=openCJ\checkpointCreation::_empty();
    if(!self openCJ\checkpointCreation::_save()){self.cpc.draft=pending;return false;}
    if(!self save(n)){self.cpc.draft=pending;self openCJ\checkpointCreation::_save();return self fail("Could not save merge; original paths retained.");}
    self openCJ\checkpointCreation::_close();self openCJ\checkpointCreation::_start(shared);
    self selectAndTeleport(0);
    self sendLocalChatMessage("Merged "+labelCommand(args)+" here. Existing checkpoints and Finish are preserved. Select the last shared checkpoint and !cp split <keep existing route> <new branch route> if they separate later.");
    return true;
}

selectAndTeleport(index)
{
    self.cpc.selected=index;self.cpc.draft=openCJ\checkpointCreation::_decode(self.cpc.rows[index]);
    self.cpc.overlap=undefined;self.cpc.overlapSection=undefined;
    // Consume travel on the game update, replacing the draft-opening destination.
    self.cpc.restoreOrigin=openCJ\checkpointCreation::restoreOrigin(self.cpc);
    self openCJ\checkpointCreation::_save();
}

sameCheckpoint(a,b)
{
    if(a.allowSave!=b.allowSave||a.onGround!=b.onGround||a.finish!=b.finish||a.double!=b.double||a.points.size!=b.points.size||a.alternatives.size!=b.alternatives.size)return false;
    for(i=0;i<a.points.size;i++)if(distanceSquared(a.points[i],b.points[i])>0.0001)return false;
    for(i=0;i<a.alternatives.size;i++)
    {
        if(a.alternatives[i].size!=b.alternatives[i].size)return false;
        for(j=0;j<a.alternatives[i].size;j++)if(distanceSquared(a.alternatives[i][j],b.alternatives[i][j])>0.0001)return false;
    }
    return true;
}

splitExisting(args,n)
{
    owners=members(n,self.cpc.route);
    if(owners.size!=args.size-1)return self fail("List every route sharing the selected section.");
    for(i=0;i<owners.size;i++)if(!hasName(args,owners[i]))return self fail("List every route sharing the selected section.");
    index=self.cpc.selected;confirmed=openCJ\checkpointCreation::_decode(self.cpc.rows[index]);
    if(!sameCheckpoint(confirmed,self.cpc.draft))return self fail("Confirm or undo changes to the selected checkpoint before splitting.");
    if(confirmed.finish)return self fail("Select the last shared landing before the Finish.");
    if(self.cpc.route==n.root)return self fail("The opening already has a split; select a later merged section.");
    // First argument keeps the existing continuation; other routes receive a
    // new approach from this landing, without changing their earlier history.
    keep=args[1];keepPath=n.paths[keep].sections;at=sectionIndex(keepPath,self.cpc.route);
    if(at<0)return self fail("The retained route does not use this section.");
    prefix=self sliceSection(n,self.cpc,0,index+1,self.cpc.routeHex);
    if(!isDefined(prefix))return self fail("Could not save split boundary; original retained.");
    suffix=undefined;
    if(index+1<self.cpc.rows.size)
    {
        suffix=self sliceSection(n,self.cpc,index+1,self.cpc.rows.size,n.paths[keep].hex);
        if(!isDefined(suffix))return self fail("Could not preserve existing continuation; original retained.");
    }
    old=self.cpc.route;self replaceSection(n,old,prefix,suffix);
    if(!isDefined(suffix) && at==keepPath.size-1)
    {
        branch=self uniqueSection(n);
        if(!isDefined(branch)||!self newSection(branch,n.paths[keep].hex))return self fail("Could not create retained route's new section.");
        path=n.paths[keep];path.sections[path.sections.size]=branch;
    }
    for(i=2;i<args.size;i++)
    {
        name=args[i];previous=n.paths[name].sections;stop=sectionIndex(previous,prefix);
        branch=self uniqueSection(n);
        if(!isDefined(branch)||!self newSection(branch,n.paths[name].hex))return self fail("Could not create branch; original network retained.");
        updated=[];for(j=0;j<=stop;j++)updated[updated.size]=previous[j];updated[updated.size]=branch;
        n.paths[name].sections=updated;
    }
    if(!self save(n))return self fail("Could not save split; original network retained.");
    self openCJ\checkpointCreation::_close();self openCJ\checkpointCreation::_start(args[2]);
    self sendLocalChatMessage("Split saved: "+keep+" keeps its existing continuation. Editing "+args[2]+" from the selected landing; other branches can rejoin using !cp merge.");
    return true;
}


pendingEdit(part)
{
    if(!part.draft.points.size && !part.draft.alternatives.size)return false;
    if(part.selected>=part.rows.size)return true;
    return !sameCheckpoint(part.draft,openCJ\checkpointCreation::_decode(part.rows[part.selected]));
}

rename(old,name)
{
    if(!openCJ\checkpointCreation::_validName(old)||!openCJ\checkpointCreation::_validName(name)||old==name||name=="network")return self fail("Use !cp rename <currentName> <newName> with distinct route names.");
    if(!self openCJ\checkpointCreation::_save())return false;
    n=self load();previous=self load();
    oldPart=self readSection(old);target=self readSection(name);
    routeRename=isDefined(n)&&isDefined(n.paths[old]);
    if(!isDefined(oldPart)&&!routeRename)return self fail("No route or section named "+old);
    if(isDefined(target)||(isDefined(n)&&isDefined(n.paths[name])))return self fail("The new name is already used; nothing overwritten.");
    if(isDefined(oldPart)&&isDefined(oldPart.sharedRoute))return self fail("Rename legacy branches after converting their shared-opening references.");
    map=openCJ\mapID::getMapID();
    collision=openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointAreas WHERE mapID="+map+" AND routeName="+dbStr(name)+" UNION SELECT cpID FROM checkpoints WHERE mapID="+map+" AND ender="+dbStr(name)+" LIMIT 1");
    if(!isDefined(collision)||collision.size)return self fail("That name is already published; nothing overwritten.");
    if(isDefined(oldPart))
    {
        if(!self writeSection(name,oldPart))return self fail("Could not save renamed draft; original retained.");
        if(isDefined(n))
        {
            self replaceSection(n,old,name,undefined);
            if(n.root==old)n.root=name;
        }
    }
    if(routeRename){n.paths[name]=n.paths[old];n.paths[old]=undefined;}
    if(!isDefined(openCJ\mySQL::mysqlSyncQuery("START TRANSACTION")))return self fail("Cannot begin rename; original retained.");
    queries=[];
    queries[0]="SELECT mapID FROM mapids WHERE mapID="+map+" FOR UPDATE";
    queries[1]="UPDATE checkpointAreas SET routeName="+dbStr(name)+" WHERE mapID="+map+" AND routeName="+dbStr(old);
    queries[2]="UPDATE checkpoints SET ender="+dbStr(name)+" WHERE mapID="+map+" AND ender="+dbStr(old);
    queries[3]="UPDATE routes r JOIN checkpoints c ON c.cpID=r.cpID SET r.routeName="+dbStr(name)+" WHERE c.mapID="+map+" AND r.routeName="+dbStr(old);
    queries[4]="UPDATE checkpointAreas SET sectionName="+dbStr(name)+" WHERE mapID="+map+" AND sectionName="+dbStr(old);
    queries[5]="UPDATE checkpointSectionColors SET sectionName="+dbStr(name)+" WHERE mapID="+map+" AND sectionName="+dbStr(old);
    queries[6]="UPDATE demoRuns SET routeName="+dbStr(name)+" WHERE mapID="+map+" AND routeName="+dbStr(old);
    queries[7]="UPDATE demoWinners SET routeName="+dbStr(name)+" WHERE mapID="+map+" AND routeName="+dbStr(old);
    for(i=0;i<queries.size;i++)if(!isDefined(openCJ\mySQL::mysqlSyncQuery(queries[i])))
    {
        openCJ\mySQL::mysqlSyncQuery("ROLLBACK");return self fail("Rename failed; existing database records unchanged. New draft copy retained.");
    }
    if(isDefined(n)&&!self save(n)){openCJ\mySQL::mysqlSyncQuery("ROLLBACK");return self fail("Cannot save renamed network; original retained.");}
    if(!isDefined(openCJ\mySQL::mysqlSyncQuery("COMMIT")))
    {
        openCJ\mySQL::mysqlSyncQuery("ROLLBACK");
        if(isDefined(previous)){previous.revision=n.revision;self save(previous);}
        return self fail("Rename commit failed; original names restored.");
    }
    // Keep an explicit recovery snapshot outside the active draft names.
    if(isDefined(oldPart))
    {
        original=self.cpc;oldPart.route=old;oldPart.path=self basePath()+old+".renamed";self.cpc=oldPart;
        archived=self openCJ\checkpointCreation::_save();self.cpc=original;
        if(archived)
        {
            if(FS_TestFile(self basePath()+old+".a"))FS_Remove(self basePath()+old+".a");
            if(FS_TestFile(self basePath()+old+".b"))FS_Remove(self basePath()+old+".b");
        }
    }
    active=self.cpc.route;if(active==old)active=name;
    self openCJ\checkpointCreation::_close();
    openCJ\checkpointPublish::activate();
    self openCJ\checkpointCreation::_start(active);
    self sendLocalChatMessage("Renamed "+old+" to "+name+". Colors, checkpoint IDs and records retained; separately named branches are unchanged.");
    return true;
}


followingShared()
{
    return isDefined(self.cpc.network) && members(self.cpc.network,self.cpc.route).size > 1
        && self.cpc.selected < self.cpc.rows.size;
}

selectDetectedShared()
{
    n=self load();if(!isDefined(n)||members(n,self.cpc.route).size<2)return false;
    for(i=0;i<self.cpc.rows.size;i++)
    {
        cp=openCJ\checkpointCreation::_decode(self.cpc.rows[i]);areas=[];areas[0]=cp.points;
        for(j=0;j<cp.alternatives.size;j++)areas[areas.size]=cp.alternatives[j];
        for(j=0;j<areas.size;j++)if(overlap(self.cpc.draft.points,areas[j]))
        {
            self.cpc.selected=i;self.cpc.draft=cp;
            self.cpc.status="Shared landing "+(i+1)+" selected";
            return true;
        }
    }
    if (self followingShared())
    {
        // Detection is navigation here, not permission to overwrite a shared landing.
        self.cpc.draft=openCJ\checkpointCreation::_decode(self.cpc.rows[self.cpc.selected]);
        self.cpc.status="Outside shared path: split from the last shared landing first";
        self sendLocalChatMessage("This landing is not in the shared section. Last shared checkpoint stays selected. Use !cp split <keep route> <new branch> (e.g. !cp split easy hard), then detect this landing again.",true);
    }
    return false;
}

// Observe all existing landings, not just the next one. Never replace pending edits.
trackSharedLanding(origin, grounded)
{
    if (self.cpc.testing || !isDefined(self.cpc.network) || members(self.cpc.network,self.cpc.route).size < 2 || !grounded)
        return;
    found = -1;
    for (i = 0; i < self.cpc.rows.size; i++)
    {
        cp = openCJ\checkpointCreation::_decode(self.cpc.rows[i]);
        if (openCJ\checkpointCreation::contains(cp,origin,true))
        {
            found = i;
            break;
        }
    }
    if (isDefined(self.cpc.sharedPresence) && self.cpc.sharedPresence == found)
        return;
    self.cpc.sharedPresence = found;
    if (found < 0 || pendingEdit(self.cpc))
        return;
    self.cpc.selected = found;
    self.cpc.draft = openCJ\checkpointCreation::_decode(self.cpc.rows[found]);
    self.cpc.overlap = undefined;
    self.cpc.overlapSection = undefined;
    self.cpc.status = "";
    self openCJ\checkpointCreation::_save();
}
