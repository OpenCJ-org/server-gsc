#include openCJ\util;

onInit()
{
    if(getCodVersion()!=4){level.clipStorageReady=false;return;}
    precacheMenu("opencj_clipedit");
    precacheMenu("opencj_clips");
    level.clipStorageReady=isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT clipID FROM demoClips LIMIT 0"));
    if(level.clipStorageReady)
    {
        rows=openCJ\mySQL::mysqlSyncQuery("SELECT UUID()");
        level.clipSession=rows[0][0];
        openCJ\mySQL::mysqlSyncQuery("INSERT INTO demoClipSessions(sessionID) VALUES("+dbStr(level.clipSession)+")");
        level thread sessionHeartbeat();
    }
    cmd=openCJ\commands_base::registerCommand("record","!record",::_record,0,0,0);
    openCJ\commands_base::addAlias(cmd,"startrecord");
    openCJ\commands_base::registerCommand("stoprecord","!stoprecord",::_stop,0,0,0);
    openCJ\commands_base::registerCommand("clipdemo","!clipdemo [id]",::_watch,0,1,0);
    openCJ\commands_base::registerCommand("renameclip","!renameclip <id> <name>",::_rename,2,undefined,0);
    openCJ\commands_base::registerCommand("deleteclip","!deleteclip <id>",::_delete,1,1,0);
}

sessionHeartbeat()
{
    for(;;)
    {
        openCJ\mySQL::mysqlAsyncQuery("UPDATE demoClipSessions SET heartbeat=NOW() WHERE sessionID="+dbStr(level.clipSession));
        // Old sessions are invisible immediately. Reclaim crashed-server payloads
        // after a grace period without touching another server's active session.
        openCJ\mySQL::mysqlAsyncQuery("DELETE FROM demoClipSessions WHERE heartbeat < NOW() - INTERVAL 10 MINUTE");
        openCJ\mySQL::mysqlAsyncQuery("DELETE FROM demoClips WHERE ready=0 AND createdAt < NOW() - INTERVAL 1 DAY");
        wait 60;
    }
}

onConnect()
{
    self thread responses();
}

available()
{
    if(!level.clipStorageReady || getCodVersion()!=4)
    {self sendLocalChatMessage("Clip storage is unavailable.",true);return false;}
    if(!isDefined(self openCJ\login::getPlayerID()))
    {self sendLocalChatMessage("Log in before using clips.",true);return false;}
    return true;
}

_record(args){self thread record();}
_stop(args){self thread edit();}
_watch(args){self thread nearby(args);}
_delete(args){self thread remove(int(args[0]));}
_rename(args)
{
    name=args[1];
    for(i=2;i<args.size;i++)name+=" "+args[i];
    self thread rename(int(args[0]),getSubStr(name,0,32));
}

record()
{
    self endon("disconnect");
    if(!self available())return;
    if(isDefined(self.clipRecording) || isDefined(self.clipEdit))
    {self sendLocalChatMessage("Finish or cancel your current clip first.",true);return;}
    if(!self openCJ\demos::canWatch())return;
    id=demoCreateTransient();
    if(!isDefined(id)){self sendLocalChatMessage("No recording capacity available.",true);return;}
    rec=spawnStruct();rec.id=id;rec.loaded=false;rec.saved=false;rec.lastTick=-1;
    rows=openCJ\mySQL::mysqlSyncQuery("SELECT NOW()");
    rec.date=rows[0][0];self.clipRecording=rec;
    self capture();
    self sendLocalChatMessage("Clip recording started. Keeping the last 60 seconds; use !stoprecord to edit.");
}

capture()
{
    if(!isDefined(self.clipRecording) || self openCJ\demos::isPlayingDemo() || self openCJ\checkpointCreation::isEditing() || self.sessionState!="playing")return;
    if(isDefined(self.isAFK) && self.isAFK)return;
    rec=self.clipRecording;
    if(rec.lastTick==getTime())return;
    fps=self openCJ\fps::getCurrentFPS();
    if(!isDefined(addFrameToDemo(rec.id,self.origin,self getPlayerAngles(),1,self openCJ\demoRecording::frameFlags(),int(rec.saved),int(rec.loaded),int(isDefined(self.eventQueue["rpg"])),int(fps),0,self getEntityNumber())))
    {destroyDemo(rec.id);self.clipRecording=undefined;self sendLocalChatMessage("Clip recording ran out of memory.",true);return;}
    demoKeepLast(rec.id,1200);
    rec.loaded=false;rec.saved=false;rec.lastTick=getTime();
}

onSaved()
{
    if(isDefined(self.clipRecording))self.clipRecording.saved=true;
}

onLoaded()
{
    if(isDefined(self.clipRecording))self.clipRecording.loaded=true;
}

edit()
{
    self endon("disconnect");
    if(!isDefined(self.clipRecording)){self sendLocalChatMessage("Use !record first.",true);return;}
    if(!self openCJ\demos::canWatch())return;
    self capture();
    if(!isDefined(self.clipRecording))return;
    rec=self.clipRecording;count=numberOfDemoFrames(rec.id);
    if(count<2){self sendLocalChatMessage("Record at least two frames first.",true);return;}
    self.clipRecording=undefined;
    info=demoClipInfo(rec.id,0);
    rec.first=info[2];rec.last=count-1;rec.permanent=false;rec.busy=false;
    completeDemo(rec.id);
    cache=spawnStruct();cache.ready=true;cache.loading=false;cache.refs=1;
    level.demoCache[""+rec.id]=cache;
    self.clipEdit=rec;
    cells=count;if(cells>40)cells=40;
    self setClientCvar("opencj_clip_cells",cells);
    layout=[];
    for(i=0;i<cells;i++)
    {
        first=int((count*i+cells-1)/cells);
        next=int((count*(i+1)+cells-1)/cells);
        layout["opencj_clip_cellx"+i]=20+first*600/count;
        layout["opencj_clip_cellw"+i]=(next-first)*600/count;
    }
    rec.layoutCommands=self numericCvars(layout);
    self openCJ\huds\hudOnScreenKeyboard::_hideKeyboard();
    self openCJ\huds\hudSpeedometer::_hideSpeedometer();
    self.demoStyle=0;self.demoBegin=0;self.demoEnd=count-1;self.demoCheckpointed=false;
    waittillframeend;
    self openCJ\demos::startDemo(rec.id);
    if(!self openCJ\demos::isPlayingDemo()){self.clipEdit=undefined;return;}
    self.playbackPaused=true;self.demoBegin=rec.first;self.demoEnd=rec.last;
    self seek(rec.first);
    self setClientCvar("opencj_clip_hint","Name clip, choose range, then Submit. Green: save | Red: load.");
    self updateEditor();
}

seek(frame)
{
    self.demoLoopPending=false;
    current=self skipPlaybackFrames(0);
    self skipPlaybackFrames(frame-current);
    self.demoFirstFrame=true;self.demoLastPresentedFrame=undefined;
}

updateEditor()
{
    if(!isDefined(self.clipEdit))return;
    rec=self.clipEdit;
    cells=numberOfDemoFrames(rec.id);if(cells>40)cells=40;
    self setClientCvar("opencj_clip_cells",cells);
    self setClientCvar("opencj_clip_trim","Start "+seconds(rec.first)+"s   End "+seconds(rec.last)+"s   Length "+seconds(rec.last-rec.first+1)+"s");
    self setClientCvar("opencj_clip_start",int(rec.first*cells/numberOfDemoFrames(rec.id)));
    self setClientCvar("opencj_clip_end",int(rec.last*cells/numberOfDemoFrames(rec.id)));
    count=numberOfDemoFrames(rec.id);
    self setClientCvar("opencj_clip_start_x",20+rec.first*600/count);
    self setClientCvar("opencj_clip_end_x",19+(rec.last+1)*600/count);
    info=demoClipInfo(rec.id,rec.first,rec.last);
    events=[];
    for(i=0;i<40;i++)
        if(!isDefined(rec.eventCells) || rec.eventCells[i]!=info[3][i])
            events["opencj_clip_event"+i]=info[3][i];
    rec.eventCommands=self numericCvars(events);
    rec.eventCells=info[3];
    self openCJ\demos::demoUpdateOverlay();
    kind="Until map changes";if(rec.permanent)kind="Permanently";
    self setClientCvar("opencj_clip_storage",kind);
}

seconds(frames){return frames*0.05;}

scopeFilter()
{
    return "(c.sessionID IS NULL OR c.sessionID="+dbStr(level.clipSession)+")";
}

submit(description)
{
    if(!isDefined(self.clipEdit) || self.clipEdit.busy)return;
    rec=self.clipEdit;
    if(!validDescription(description))
    {self setClientCvar("opencj_clip_hint","Use 1-32 letters, numbers and spaces only.");return;}
    rec.busy=true;
    // Capture the selected payload before yielding to SQL. Exit/load may restore
    // the run and release native playback while publication is in flight.
    payloads=[];
    for(first=rec.first;first<=rec.last;first+=64)
    {
        count=rec.last-first+1;if(count>64)count=64;
        payload=demoEncodeChunk(rec.id,first,count);
        if(!isDefined(payload)){rec.busy=false;self setClientCvar("opencj_clip_hint","Could not encode this clip.");return;}
        payloads[payloads.size]=payload;
    }
    owner=self openCJ\login::getPlayerID();map=openCJ\mapID::getMapID();
    scope=level.clipSession;session=dbStr(scope);
    if(rec.permanent){scope="permanent";session="NULL";}
    info=demoClipInfo(rec.id,rec.first);origin=info[0];
    rows=openCJ\mySQL::mysqlSyncQuery("SELECT UUID()");token=rows[0][0];self.clipUploadToken=token;
    id=undefined;
    for(slot=1;slot<=5;slot++)
    {
        query="INSERT IGNORE INTO demoClips(uploadToken,mapID,playerID,description,scopeKey,sessionID,slot,originX,originY,originZ,frameCount,recordedAt) VALUES("+dbStr(token)+","+map+","+owner+","+dbStr(openCJ\mySQL::escapeString(description))+","+dbStr(scope)+","+session+","+slot+","+origin[0]+","+origin[1]+","+origin[2]+","+(rec.last-rec.first+1)+","+dbStr(rec.date)+")";
        result=self openCJ\mySQL::mysqlAsyncQuery(query);
        if(!isDefined(result))break;
        rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT clipID FROM demoClips WHERE uploadToken="+dbStr(token));
        if(isDefined(rows) && rows.size){id=int(rows[0][0]);break;}
    }
    if(!isDefined(id))
    {rec.busy=false;self setClientCvar("opencj_clip_hint","No slot available (limit 5 per storage type). Use !deleteclip <id>.");return;}
    ok=true;
    for(chunk=0;chunk<payloads.size;chunk++)
    {
        result=self openCJ\mySQL::mysqlAsyncQuery("INSERT INTO demoClipChunks VALUES("+id+","+chunk+",UNHEX("+dbStr(payloads[chunk])+"))");
        if(!isDefined(result)){ok=false;break;}
    }
    if(ok)ok=isDefined(self openCJ\mySQL::mysqlAsyncQuery("UPDATE demoClips SET ready=1 WHERE clipID="+id));
    if(!ok)
    {
        self openCJ\mySQL::mysqlAsyncQuery("DELETE FROM demoClips WHERE clipID="+id+" AND ready=0");
        rec.busy=false;self setClientCvar("opencj_clip_hint","Upload failed. Your clip is still open; try again.");return;
    }
    self.clipUploadToken=undefined;
    self openCJ\demos::stopDemo();
    self sendLocalChatMessage("Clip #"+id+" submitted: "+description+". Remove it with !deleteclip "+id+".");
}

remove(id)
{
    self endon("disconnect");
    if(!self available() || id<1)return;
    owner=self openCJ\login::getPlayerID();
    rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT clipID FROM demoClips c WHERE clipID="+id+" AND playerID="+owner+" AND "+scopeFilter());
    if(!isDefined(rows) || !rows.size){self sendLocalChatMessage("No clip with that ID belongs to you.",true);return;}
    result=self openCJ\mySQL::mysqlAsyncQuery("DELETE FROM demoClips WHERE clipID="+id+" AND playerID="+owner);
    if(isDefined(result))self sendLocalChatMessage("Deleted clip #"+id+".");
}

nearby(args)
{
    self endon("disconnect");
    if(!self available() || !self openCJ\demos::canWatch())return;
    o=self.origin;
    query="SELECT c.clipID,c.description FROM demoClips c WHERE c.ready=1 AND c.mapID="+openCJ\mapID::getMapID()+" AND "+scopeFilter()+" AND POW(c.originX-("+o[0]+"),2)+POW(c.originY-("+o[1]+"),2)<=16384 AND ABS(c.originZ-("+o[2]+"))<=70";
    if(args.size)query+=" AND c.clipID="+int(args[0]);
    rows=self openCJ\mySQL::mysqlAsyncQuery(query+" ORDER BY c.clipID LIMIT 11");
    if(!isDefined(rows) || !rows.size){self sendLocalChatMessage("No matching clip nearby.",true);return;}
    if(rows.size==1){self play(int(rows[0][0]),false);return;}
    self sendLocalChatMessage("Nearby clips: choose with !clipdemo <id>.");
    for(i=0;i<rows.size && i<10;i++)self sendLocalChatMessage("#"+rows[i][0]+" - "+rows[i][1]);
    if(rows.size>10)self sendLocalChatMessage("More clips are available in the Clips menu.");
}

browser()
{
    if(!self available())return;
    if(!isDefined(self.clipPage))self.clipPage=0;
    if(!isDefined(self.clipTab))self.clipTab="permanent";
    scope=level.clipSession;if(self.clipTab=="permanent")scope="permanent";
    rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT c.clipID,c.description,p.playerName,c.frameCount,DATE_FORMAT(c.recordedAt,'%Y-%m-%d %H:%i:%s'),COUNT(*) OVER() FROM demoClips c JOIN playerInformation p ON c.playerID=p.playerID WHERE c.ready=1 AND c.mapID="+openCJ\mapID::getMapID()+" AND c.scopeKey="+dbStr(scope)+" ORDER BY c.clipID DESC LIMIT 4 OFFSET "+(self.clipPage*4));
    self.clipRows=rows;
    total=0;if(isDefined(rows) && rows.size)total=int(rows[0][5]);
    if(!total && self.clipPage>0){self.clipPage=0;self browser();return;}
    self.clipPages=int((total+3)/4);if(self.clipPages<1)self.clipPages=1;
    self setClientCvar("opencj_clips_page","Page "+(self.clipPage+1)+" / "+self.clipPages);
    label="Show: This map session";if(self.clipTab=="permanent")label="Show: Permanent clips";
    self setClientCvar("opencj_clips_tab",label);
    self setClientCvar("opencj_clips_previous",int(self.clipPage>0));
    self setClientCvar("opencj_clips_next",int(self.clipPage+1<self.clipPages));
    self setClientCvar("opencj_clips_hint","Select once to preview the location; select again to play. Delete your clips: !deleteclip <id>");
    if(!total)self setClientCvar("opencj_clips_hint","No clips in this category yet. Use !record, then !stoprecord to create one.");
    for(i=0;i<4;i++)
    {
        exists=isDefined(rows) && i<rows.size;
        self setClientCvar("opencj_clips_exists"+i,int(exists));
        fields=[];fields[0]="";fields[1]="";fields[2]="";fields[3]="";fields[4]="";
        if(exists)
        {
            fields[0]="#"+rows[i][0];fields[1]=rows[i][1];fields[2]=rows[i][2];
            if(fields[2].size>16)fields[2]=getSubStr(fields[2],0,16);
            fields[3]=""+seconds(int(rows[i][3]))+"s";fields[4]=rows[i][4];
        }
        for(col=0;col<5;col++)self setClientCvar("opencj_clips_cell"+i+"_"+col,fields[col]);
    }
}

play(id,preview)
{
    self endon("disconnect");
    if(isDefined(self.clipRecording) || isDefined(self.clipEdit))
    {self sendLocalChatMessage("Finish your clip recording/editor first.",true);return;}
    if(self openCJ\demos::isPlayingDemo())
    {
        if(!isDefined(self.clipPreview))return;
        if(self.clipPreview==id)
        {
            self.clipPreview=undefined;self.playbackPaused=false;self.demoFirstFrame=true;
            self openCJ\demos::demoMovementHudInMenu(false);
            self closeInGameMenu();self closeMenu();
            self setClientCvar("g_scriptMainMenu","opencj_demo");self openMenu("opencj_demo");return;
        }
        self openCJ\demos::stopDemo(false);
    }
    if(!self openCJ\demos::canWatch())return;
    if(isDefined(self.demoPendingId))return;
    rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT frameCount,description FROM demoClips c WHERE c.ready=1 AND c.clipID="+id+" AND c.mapID="+openCJ\mapID::getMapID()+" AND "+scopeFilter());
    if(!isDefined(rows) || !rows.size){self sendLocalChatMessage("This clip is no longer available.",true);return;}
    if(isDefined(self.demoPendingId) || !self openCJ\demos::canWatch())return;
    native=demoCreateTransient();if(!isDefined(native))return;
    expected=int(rows[0][0]);ok=true;chunk=0;
    cache=spawnStruct();cache.ready=true;cache.loading=false;cache.refs=1;
    level.demoCache[""+native]=cache;self.demoPendingId=native;
    while(ok && numberOfDemoFrames(native)<expected)
    {
        data=self openCJ\mySQL::mysqlAsyncQuery("SELECT chunkNum,HEX(payload) FROM demoClipChunks WHERE clipID="+id+" AND chunkNum>="+chunk+" ORDER BY chunkNum LIMIT 8");
        if(!isDefined(self.demoPendingId) || self.demoPendingId!=native)return;
        ok=isDefined(data) && data.size>0;
        for(i=0;ok && i<data.size;i++)
        {
            ok=int(data[i][0])==chunk && isDefined(demoDecodeChunk(native,data[i][1]));chunk++;
        }
    }
    cache.loading=false;
    if(!ok || numberOfDemoFrames(native)!=expected){self openCJ\demos::releasePending();return;}
    completeDemo(native);
    if(!self openCJ\demos::canWatch()){self openCJ\demos::releasePending();return;}
    self.demoBegin=0;self.demoEnd=expected-1;self.demoCheckpointed=false;self.demoStyle=0;
    waittillframeend;
    if(!isDefined(self.demoPendingId) || self.demoPendingId!=native)return;
    self.demoPendingId=undefined;
    if(preview)self.clipPreview=id;
    self.clipDescription=rows[0][1];
    self openCJ\demos::startDemo(native);
    if(!self openCJ\demos::isPlayingDemo()){self.clipDescription=undefined;return;}
    self.clipPlayback=true;
    if(preview)
    {
        self.clipPreview=id;self.playbackPaused=true;

    }
}

onPlaybackStopped()
{
    self.clipEdit=undefined;self.clipPreview=undefined;self.clipPlayback=undefined;self.clipDescription=undefined;
}

onDisconnect()
{
    if(isDefined(self.clipUploadToken))level thread openCJ\mySQL::mysqlAsyncQuery("DELETE FROM demoClips WHERE ready=0 AND uploadToken="+dbStr(self.clipUploadToken));
    self cancelRecording();
}

responses()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("menuresponse",menu,response);
        if(menu=="opencj_clips")
        {
            if(response=="close")
            {self closeInGameMenu();self closeMenu();if(isDefined(self.clipPreview))self.demoExitRequested=true;continue;}
            if(response=="open" || response=="toggle" || response=="session" || response=="permanent" || response=="next" || response=="previous")
            {
                if(response=="toggle"){if(isDefined(self.clipTab) && self.clipTab=="permanent")response="session";else response="permanent";}
                if(response=="session" || response=="permanent"){self.clipTab=response;self.clipPage=0;}
                if(response=="next" && isDefined(self.clipPages) && self.clipPage+1<self.clipPages)self.clipPage++;
                if(response=="previous" && isDefined(self.clipPage) && self.clipPage>0)self.clipPage--;
                self browser();
            }
            else if(getSubStr(response,0,4)=="row:")
            {
                index=int(getSubStr(response,4));
                if(isDefined(self.clipRows) && index>=0 && index<self.clipRows.size)self play(int(self.clipRows[index][0]),true);
            }
        }
        else if(menu=="opencj_clipedit" && isDefined(self.clipEdit))
        {
            if(self.clipEdit.busy)continue;
            frame=self skipPlaybackFrames(0);last=numberOfDemoFrames(self.demoID)-1;
            if(response=="stop"){self.demoExitRequested=true;continue;}
            if(response=="submit"){wait 0.1;if(isDefined(self.clipEdit))self submit(self getUserinfo("opencj_clip_description"));continue;}
            if(response=="storage")self.clipEdit.permanent=!self.clipEdit.permanent;
            if(response=="start"){self.playbackPaused=true;self.clipEdit.first=frame;if(frame>self.clipEdit.last)self.clipEdit.last=frame;}
            if(response=="end"){self.playbackPaused=true;self.clipEdit.last=frame;if(frame<self.clipEdit.first)self.clipEdit.first=frame;}
            if(response=="reset"){self.clipEdit.first=0;self.clipEdit.last=last;self.demoBegin=0;self.demoEnd=last;}
            if(response=="preview")
            {
                self.demoBegin=self.clipEdit.first;self.demoEnd=self.clipEdit.last;
                self seek(self.demoBegin);self.playbackPaused=false;self.demoRate=1;
            }
            if(response=="all"){self.demoBegin=0;self.demoEnd=last;}
            if(response=="pause")self.playbackPaused=true;
            if(response=="resume")self.playbackPaused=false;
            parts=strTok(response,":");
            if(parts.size==2 && parts[0]=="seek")
            {
                cells=last+1;if(cells>40)cells=40;
                cell=int(parts[1]);if(cell>=0 && cell<cells)
                {self.demoBegin=0;self.demoEnd=last;target=int(((last+1)*cell+cells-1)/cells);if(target>last)target=last;self seek(target);self.playbackPaused=true;}
            }
            if(parts.size==2 && parts[0]=="step")
            {
                step=int(parts[1]);if(step==-1 || step==1 || step==-20 || step==20)
                {self.demoBegin=0;self.demoEnd=last;target=frame+step;if(target<0)target=0;if(target>last)target=last;self seek(target);self.playbackPaused=true;}
            }
            if(parts.size==2 && parts[0]=="speed")
            {rate=int(parts[1]);if(rate==1 || rate==2 || rate==4 || rate==-1 || rate==-2 || rate==-4){self.demoRate=rate;self.playbackPaused=false;}}
            self updateEditor();
        }
    }
}

validDescription(name)
{
    if(!isDefined(name) || name.size<1 || name.size>32)return false;
    nonSpace=false;
    for(i=0;i<name.size;i++)
    {
        c=getSubStr(name,i,i+1);
        if(c!=" ")
        {
            if(!isAlphaNumeric(c))return false;
            nonSpace=true;
        }
    }
    return nonSpace;
}

rename(id,name)
{
    self endon("disconnect");
    if(!self available() || id<1)return;
    if(!validDescription(name)){self sendLocalChatMessage("Use 1-32 letters, numbers and spaces only.",true);return;}
    if(isDefined(self.clipRenameAt) && getTime()-self.clipRenameAt<10000)
    {self sendLocalChatMessage("Wait 10 seconds between clip rename requests.",true);return;}
    // Reserve the cooldown before yielding, including unsuccessful requests.
    self.clipRenameAt=getTime();
    owner=self openCJ\login::getPlayerID();
    rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT clipID FROM demoClips c WHERE ready=1 AND clipID="+id+" AND playerID="+owner+" AND "+scopeFilter());
    if(!isDefined(rows) || !rows.size){self sendLocalChatMessage("No available clip with that ID belongs to you.",true);return;}
    result=self openCJ\mySQL::mysqlAsyncQuery("UPDATE demoClips SET description="+dbStr(openCJ\mySQL::escapeString(name))+" WHERE clipID="+id+" AND playerID="+owner);
    if(isDefined(result))self sendLocalChatMessage("Renamed clip #"+id+" to "+name+".");
}

cancelRecording()
{
    if(!isDefined(self.clipRecording))return;
    destroyDemo(self.clipRecording.id);
    self.clipRecording=undefined;
}

onSpawnSpectator()
{
    if(!isDefined(self.clipRecording))return;
    self cancelRecording();
    self sendLocalChatMessage("Unfinished clip discarded when entering spectator mode.");
}

// CoD4's "v" command accepts multiple dvar/value pairs. Keep each command
// below the engine's 1024-byte limit instead of filling its reliable queue.
// Callers supply only fixed UI dvar names and numeric values.
numericCvars(values)
{
    keys=getArrayKeys(values);command="v";sent=0;
    for(i=0;i<keys.size;i++)
    {
        pair=" "+keys[i]+" \""+values[keys[i]]+"\"";
        if(command.size+pair.size>800)
        {self SV_GameSendServerCommand(command,true);sent++;command="v";}
        command+=pair;
    }
    if(command!="v"){self SV_GameSendServerCommand(command,true);sent++;}
    return sent;
}
