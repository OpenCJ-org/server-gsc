#include openCJ\util;

reset(route)
{
    if(!openCJ\checkpointCreation::_validName(route) || self.sessionState!="playing" || self openCJ\demos::isPlayingDemo())
        return self fail("Spawn first, then use !cpc reset <route>.");
    // Validate existence before saving, closing or changing any draft.
    if(!isDefined(level.routeEnders[route]) || !isDefined(level.checkpointRoutes[route]))
        return self fail("No active finalized route named "+route+"; draft unchanged.");
    base=self openCJ\checkpointNetwork::basePath();
    // Shared sections need a network-wide reset; never silently detach or edit other routes.
    if(FS_TestFile(base+"network.a") || FS_TestFile(base+"network.b"))
        return self fail("Reset of shared network drafts is not supported; all drafts kept.");
    ids=openCJ\mySQL::mysqlSyncQuery("SELECT cpID FROM checkpointAreas WHERE mapID="+openCJ\mapID::getMapID()+" AND routeName="+dbStr(route)+" ORDER BY ordinal");
    if(!isDefined(ids) || !ids.size)return self fail("Finalized route has no editable CPC areas; draft unchanged.");
    checkpoints=[];
    for(i=0;i<ids.size;i++)checkpoints[i]=openCJ\checkpoints::getCheckpointByID(int(ids[i][0]));
    rows=rowsFromActive(checkpoints,route);
    if(!isDefined(rows))return self fail("Cannot safely reconstruct this finalized route; draft unchanged.");
    path=base+route;
    if(self openCJ\checkpointCreation::isEditing() && !self openCJ\checkpointCreation::_save())
        return self fail("Could not save current draft; reset cancelled.");
    a=openCJ\checkpointCreation::_read(path+".a",route);b=openCJ\checkpointCreation::_read(path+".b",route);
    previous=a;if(isDefined(b) && (!isDefined(a) || b.revision>a.revision))previous=b;
    if(isDefined(previous) && isDefined(previous.sharedRoute))return self fail("Shared branch draft kept; reset requires a standalone route.");
    revision=0;if(isDefined(previous))revision=previous.revision;
    backup=backupDraft(path,revision);
    if(!isDefined(backup))return self fail("Could not back up the draft; reset cancelled.");
    replacement=spawnStruct();replacement.route=route;replacement.path=path;
    replacement.rows=rows;replacement.selected=rows.size;
    replacement.draft=openCJ\checkpointCreation::_empty();replacement.revision=revision;
    replacement.routeHex=level.checkpointRoutes[route].hex;
    if(isDefined(previous))replacement.savedPosition=previous.savedPosition;
    old=self.cpc;self.cpc=replacement;
    ok=self openCJ\checkpointCreation::_save();self.cpc=old;
    if(!ok)return self fail("Could not write restored draft; backup retained at "+backup);
    if(isDefined(old))self openCJ\checkpointCreation::_close();
    self openCJ\checkpointCreation::_start(route,replacement.routeHex);
    self sendLocalChatMessage("Reset "+route+" draft to "+rows.size+" finalized checkpoints. Previous draft backup: "+backup);
    return true;
}

// Preserve the active geometry and requirements, grouping alternative areas
// back into a single logical checkpoint. No database writes are performed.
rowsFromActive(checkpoints,route)
{
    if(!isDefined(checkpoints) || !checkpoints.size)return undefined;
    groups=[];indexes=[];
    for(i=0;i<checkpoints.size;i++)
    {
        cp=checkpoints[i];
        if(!isDefined(cp) || !isDefined(cp.area) || (!openCJ\checkpointMoving::isMoving(cp) && openCJ\checkpointArea::validate(cp.area)!=""))return undefined;
        if(isDefined(cp.ender) && cp.ender!=route)return undefined;
        if(isDefined(cp.bigBrother))
        {
            index=indexes[cp.bigBrother.id];
            if(!isDefined(index) || groups[index].alternatives.size>=7)return undefined;
            group=groups[index];
            if(!openCJ\checkpointHeight::same(group,cp) || group.finish!=isDefined(cp.ender) || group.double!=cp.allowDoubleRPG || group.onGround!=cp.onGround || group.allowSave!=cp.allowSave || group.allowEle!=cp.isEleAllowed)return undefined;
            group.alternatives[group.alternatives.size]=cp.area;
        }
        else
        {
            if(groups.size>=256 || isDefined(indexes[cp.id]))return undefined;
            group=openCJ\checkpointCreation::_empty();group.points=cp.area;
            group.platformRef=cp.platformRef;
            group.heightAbove=openCJ\checkpointHeight::above(cp);
            group.finish=isDefined(cp.ender);group.double=cp.allowDoubleRPG;
            group.onGround=cp.onGround;group.allowSave=cp.allowSave;group.allowEle=cp.isEleAllowed;
            indexes[cp.id]=groups.size;groups[groups.size]=group;
        }
    }
    rows=[];
    for(i=0;i<groups.size;i++)rows[i]=openCJ\checkpointCreation::_encode(groups[i]);
    if(openCJ\checkpointPublish::validationError(rows)!="")return undefined;
    return rows;
}

backupDraft(path,revision)
{
    backup="";
    for(i=0;i<10000;i++)
    {
        backup=path+".before-reset-"+revision+"-"+i;
        if(!FS_TestFile(backup+".a") && !FS_TestFile(backup+".b"))break;
    }
    if(i==10000)return undefined;
    if(!copySnapshot(path+".a",backup+".a") || !copySnapshot(path+".b",backup+".b"))return undefined;
    return backup;
}

copySnapshot(source,destination)
{
    if(!FS_TestFile(source))return true;
    input=FS_FOpen(source,"read");if(!input)return false;
    output=FS_FOpen(destination,"write");if(!output){FS_FClose(input);return false;}
    ok=true;
    for(;;)
    {
        line=FS_ReadLine(input);if(!isDefined(line))break;
        if(!FS_WriteLine(output,line)){ok=false;break;}
    }
    FS_FClose(input);FS_FClose(output);return ok;
}

fail(message)
{
    self sendLocalChatMessage(message,true);
    return false;
}
