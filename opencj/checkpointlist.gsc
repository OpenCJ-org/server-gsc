#include openCJ\util;

// Current map only: private draft filenames are restricted to the caller's ID.
show()
{
    if (isDefined(self.cpcListTime) && getTime()-self.cpcListTime < 2000)return;
    self.cpcListTime=getTime();
    prefix=self openCJ\login::getPlayerID()+"_"+getCvar("mapname")+"_";
    files=opencjScanDir(getCvar("fs_homepath")+"/"+getCvar("fs_game")+"/checkpoints/drafts");
    names=[];
    if(isDefined(files))for(i=0;i<files.size;i++)
    {
        name=draftName(files[i],prefix);
        if(isDefined(name))names[name]=true;
    }
    if(isDefined(self.cpc))names[self.cpc.route]=true;
    n=self openCJ\checkpointNetwork::load();sections=[];
    if(isDefined(n))
    {
        routes=getArrayKeys(n.paths);
        for(i=0;i<routes.size;i++)
        {
            names[routes[i]]=true;
            for(j=0;j<n.paths[routes[i]].sections.size;j++)sections[n.paths[routes[i]].sections[j]]=true;
        }
    }
    published=[];
    if(openCJ\mapID::hasMapID())
    {
        rows=openCJ\mySQL::mysqlSyncQuery("SELECT routeName,cpID FROM checkpointAreas WHERE mapID="+openCJ\mapID::getMapID()+" ORDER BY routeName,ordinal");
        if(!isDefined(rows)){self sendLocalChatMessage("Could not read published routes; please try again.",true);return;}
        for(i=0;i<rows.size;i++)
        {
            route=rows[i][0];
            if(!isDefined(published[route]))published[route]=[];
            published[route][published[route].size]=openCJ\checkpoints::getCheckpointByID(int(rows[i][1]));
        }
    }
    if(isDefined(level.routeEnders))
    {
        routes=getArrayKeys(level.routeEnders);
        for(i=0;i<routes.size;i++)names[routes[i]]=true;
    }
    keys=getArrayKeys(names);count=0;
    self sendLocalChatMessage("Checkpoints on "+getCvar("mapname")+": ^1in progress ^7/ ^2completed^7.");
    for(i=0;i<keys.size;i++)
    {
        route=keys[i];
        // Network section files are implementation details, not extra routes.
        if(isDefined(sections[route]) && !isDefined(n.paths[route]))continue;
        part=self draft(route,n);
        complete=isDefined(level.routeEnders) && isDefined(level.routeEnders[route]);
        if(!isDefined(part) && !complete)continue;
        same=false;
        if(complete && isDefined(part) && isDefined(published[route]))
        {
            active=openCJ\checkpointReset::rowsFromActive(published[route],route);
            same=matches(part,active);
            if(same && isDefined(level.checkpointRoutes[route]) && isDefined(part.routeHex))
                same=part.routeHex==level.checkpointRoutes[route].hex;
        }
        if(complete){self sendLocalChatMessage("^2"+route+" - Completed^7");count++;}
        if(isDefined(part) && !same)
        {
            suffix=" - In progress";if(complete)suffix=" - Unpublished draft changes";
            self sendLocalChatMessage("^1"+route+suffix+" ("+part.rows.size+" checkpoints)^7 | !cpc "+route);count++;
        }
    }
    if(!count)self sendLocalChatMessage("No drafts of yours or completed routes on this map yet.");
}

draftName(file,prefix)
{
    if(file.size<=prefix.size+2 || getSubStr(file,0,prefix.size)!=prefix)return undefined;
    suffix=getSubStr(file,file.size-2,file.size);
    if(suffix!=".a" && suffix!=".b")return undefined;
    name=getSubStr(file,prefix.size,file.size-2);
    if(name=="network" || !openCJ\checkpointCreation::_validName(name))return undefined;
    return name;
}

part(name)
{
    if(isDefined(self.cpc) && self.cpc.route==name)return self.cpc;
    return self openCJ\checkpointNetwork::readSection(name);
}

draft(route,n)
{
    if(!isDefined(n) || !isDefined(n.paths[route]))return self part(route);
    result=spawnStruct();result.rows=[];result.routeHex=n.paths[route].hex;result.pending=false;
    for(i=0;i<n.paths[route].sections.size;i++)
    {
        section=self part(n.paths[route].sections[i]);
        if(!isDefined(section)){result.pending=true;continue;}
        if(openCJ\checkpointNetwork::pendingEdit(section))result.pending=true;
        for(j=0;j<section.rows.size;j++)result.rows[result.rows.size]=section.rows[j];
    }
    return result;
}

matches(part,rows)
{
    if(!isDefined(rows) || rows.size!=part.rows.size)return false;
    if(isDefined(part.pending)){if(part.pending)return false;}
    else if(openCJ\checkpointNetwork::pendingEdit(part))return false;
    for(i=0;i<rows.size;i++)
        if(!openCJ\checkpointNetwork::sameCheckpoint(openCJ\checkpointCreation::_decode(part.rows[i]),openCJ\checkpointCreation::_decode(rows[i])))return false;
    return true;
}
