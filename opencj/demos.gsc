#include openCJ\util;

onInit()
{
    clearAllDemos();
    level.demoCache = [];
    openCJ\demoRecording::onInit();
    cmd = openCJ\commands_base::registerCommand("demo", "!demo [walkthrough|wt|speedrun|sr|lowrpg|rpg|low|stop]", ::_onCommandPlayback, 0, 1, 0);
    openCJ\commands_base::addAlias(cmd,"playback");
    setting = openCJ\settings::addSettingBool("demoloop", true, "Loop demo playback");
    openCJ\commands_base::addAlias(setting,"loop");
}

_onCommandPlayback(args)
{
    if ((args.size && args[0]=="stop") || (!args.size && self isPlayingDemo()))
    {
        self cancelRequest();
        self thread doNextFrame(::stopDemo);
        return;
    }
    kind="walkthrough";
    if (args.size) kind=toLower(args[0]);
    if(kind=="wt")kind="walkthrough";
    if(kind=="sr")kind="speedrun";
    if(kind=="rpg" || kind=="low")kind="lowrpg";
    if(kind!="walkthrough" && kind!="speedrun" && kind!="lowrpg")
    {
        self sendLocalChatMessage("Use !demo wt, !demo sr, !demo rpg, or !demo stop.",true);
        return;
    }
    self thread request(kind);
}

request(kind)
{
    self cancelRequest();
    self endon("demo_request");
    self endon("disconnect");
    if (!self canWatch()) return;
    route=self.route;
    if(!isDefined(route))
    {
        routes=getArrayKeys(level.routeEnders);
        if(routes.size!=1)
        {
            self sendLocalChatMessage("Choose a route first, then use !demo.",true);
            return;
        }
        route=routes[0];
    }
    fps=self openCJ\fps::getCurrentFPSMode();
    mask=int(self openCJ\anyPct::hasAnyPct())+2*int(self openCJ\elevate::hasUsedEle())+4*int(self openCJ\halfBeat::isHalfBeatAllowed())+8*int(self openCJ\tas::hasHardTAS());
    if(kind=="walkthrough")
    {
        mask=0;
        if(fps=="hax")fps="mix";
        fpsFilter="("+dbStr(fps)+")";
    }
    else fpsFilter=openCJ\menus\board_base::getFPSModeStr(fps);
    order="d.timePlayed,d.explosiveJumps";
    if(kind=="lowrpg")order="d.explosiveJumps,d.timePlayed";
    query="SELECT d.runID,d.modeMask FROM demoWinners w JOIN demoRuns d ON d.runID=w.runID WHERE d.ready=1 AND w.mapID="+openCJ\mapID::getMapID()+" AND w.routeName="+dbStr(route)+" AND w.kind="+dbStr(kind)+" AND (w.modeMask & "+mask+")=w.modeMask AND w.FPSMode IN "+fpsFilter+" ORDER BY "+order+",BIT_COUNT(d.modeMask),FIELD(d.FPSMode,'125','mix','hax'),d.runID LIMIT 1";
    rows=self openCJ\mySQL::mysqlAsyncQuery(query);
    if(!isDefined(rows)||!rows.size)
    {
        self sendLocalChatMessage("No matching demo is available for this route and these modes.",true);
        return;
    }
    self playRun(int(rows[0][0]),false);
}

canWatch()
{
    if(!level.demoStorageReady)
    {
        self sendLocalChatMessage("Demo storage has not been initialized.",true);
        return false;
    }
    if(isDefined(self.playerRuns_runFinishing) && self.playerRuns_runFinishing)return false;
    if(self.sessionState!="playing" || self openCJ\checkpointCreation::isEditing() || self isPlayingDemo())
    {
        self sendLocalChatMessage("Spawn and leave CPC/current playback before watching a demo.",true);
        return false;
    }
    return true;
}

// Called by leaderboard row selection. Explicit rows always play the full run.
playRun(id,full)
{
    self endon("disconnect");
    self endon("demo_request");
    if(!self canWatch())return;
    if(!isDefined(full))full=true;
    meta=self openCJ\mySQL::mysqlAsyncQuery("SELECT frameCount,modeMask FROM demoRuns WHERE ready=1 AND mapID="+openCJ\mapID::getMapID()+" AND runID="+id);
    if(!isDefined(meta)||!meta.size)
    {
        self sendLocalChatMessage("This run has no retained demo.",true);
        return;
    }
    key=""+id;
    load=false;
    if(!isDefined(level.demoCache[key]))
    {
        cache=spawnStruct();cache.loading=true;cache.ready=false;cache.refs=0;
        level.demoCache[key]=cache;
        load=true;
    }
    cache=level.demoCache[key];
    cache.refs++;
    self.demoPendingId=id;
    if(load)level thread _loadCache(id,int(meta[0][0]));
    while(cache.loading)wait 0.05;
    if(!cache.ready || !self canWatch())
    {
        if(!cache.ready)self sendLocalChatMessage("The recording could not be loaded.",true);
        self releasePending();
        return;
    }
    range=[];range[0]=0;range[1]=numberOfDemoFrames(id)-1;
    if(!full)
    {
        cp=self openCJ\checkpoints::getCurrentCheckpoint();
        cpID=0;
        if(isDefined(cp))
        {
            if(isDefined(cp.bigBrother))cp=cp.bigBrother;
            if(isDefined(cp.id))cpID=cp.id;
        }
        range=demoFindSegment(id,cpID,self.origin,int(meta[0][1])&1);
        if(!isDefined(range))
        {
            self sendLocalChatMessage("No matching demo segment is available at this checkpoint.",true);
            self releasePending();
            return;
        }
    }
    // Start outside a client-command / movement callback.
    waittillframeend;
    if(!self canWatch()){self releasePending();return;}
    self.demoPendingId=undefined;
    self.demoBegin=range[0];self.demoEnd=range[1];
    self startDemo(id);
}

_loadCache(id,expected)
{
    cache=level.demoCache[""+id];
    created=createDemo(id);
    ok=created==id;
    if(ok)
    {
        chunk=0;
        while(ok && numberOfDemoFrames(id)<expected)
        {
            rows=openCJ\mySQL::mysqlAsyncQuery("SELECT chunkNum,HEX(payload) FROM demoChunks WHERE runID="+id+" AND chunkNum>="+chunk+" ORDER BY chunkNum LIMIT 8");
            ok=isDefined(rows) && rows.size>0;
            for(i=0;ok && i<rows.size;i++)
            {
                if(int(rows[i][0])!=chunk || !isDefined(demoDecodeChunk(id,rows[i][1])))ok=false;
                chunk++;
            }
            wait 0.05;
        }
        if(ok)ok=numberOfDemoFrames(id)==expected;
        if(ok)completeDemo(id);
        else destroyDemo(id);
    }
    cache.ready=ok;cache.loading=false;
    if(!ok)printf("OpenCJ: failed to load demo "+id+".\n");
    if(cache.refs==0)releaseCache(id);
}

releaseCache(id)
{
    cache=level.demoCache[""+id];
    if(!isDefined(cache))return;
    if(cache.refs>0)cache.refs--;
    if(cache.refs==0 && !cache.loading)
    {
        if(cache.ready)destroyDemo(id);
        level.demoCache[""+id]=undefined;
    }
}

startDemo(demoID)
{
    if (getCodVersion() == 4 && !(self demoBeginPresentation()))
    {
        releaseCache(demoID);
        self sendLocalChatMessage("Could not prepare demo playback", true);
        return;
    }
    state=spawnStruct();
    state.origin=self.origin;state.angles=self getPlayerAngles();state.velocity=self getVelocity();
    state.stance=self getStance();state.weapon=self getCurrentWeapon();state.health=self.health;
    state.paused=self.playerRuns_runPaused;state.time=self openCJ\playTime::getTimePlayed();
    state.timerRunning=!isDefined(self.stopTime);
    state.fpshistory=self.fpshistory;state.fpsHistoryText=self.fpsHistoryText;
    state.speed=self.currSpeed;state.maxSpeed=self.maxSpeed;
    state.started=getTime();
    self.demoReturn=state;
    self.playingDemo=true;
    self.demoExitRequested=false;
    self hide();
    self.playerRuns_runPaused=true;
    self openCJ\playTime::pauseTimer();
    self.eventQueue=[];
    self.demoID=demoID;self.playbackPaused=false;self.slowmoCount=0;
    self.demoPreviousStance=state.stance;self.demoPreviousState="none";
    self.demoPreviousFPS=undefined;self.demoPreviousOnGround=true;
    self.demoFirstFrame=true;self.demoLastPresentedFrame=undefined;
    self.maxSpeed=0;
    self openCJ\huds\hudSpeedometer::_hideSpeedometer();
    self selectPlaybackDemo(demoID);
    self skipPlaybackFrames(self.demoBegin);
    self.demoLinker.origin=self.origin;
    self linkTo(self.demoLinker,"",(0,0,0),(0,0,0));
    self disableWeapons();
    self openCJ\showRecords::onStartDemo();
    self openCJ\checkpointPointers::onStartDemo();
    self openCJ\huds\hudStatistics::onStartDemo();
    self openCJ\huds\hudProgressBar::onStartDemo();
    self openCJ\buttonPress::resetButtons();
    self sendLocalChatMessage("Demo: Load or !demo stop to return; Melee pauses, A/D seek, Q/E seek faster, Jump slows playback.");
}

isPlayingDemo()
{
    if (isDefined(self.playingDemo))
    {
        return self.playingDemo;
    }
    
    return false;
}

onPlayerConnect()
{
    self.playingDemo = false;
    self openCJ\demoRecording::onConnect();
    self.playbackPaused = false;
    self.demoLinker = spawn("script_origin", (0, 0, 0));
}

onPlayPauseDemo()
{
    self.playbackPaused = !self.playbackPaused;
    if(self.playbackPaused)
    {
        self iprintln("Playback paused");
    }
    else
    {
        self iprintln("Playback resumed");
    }
}

_getDemoFrame(nrFramesToSkip, shouldSkipFails)
{
    if(shouldSkipFails)
    {
        newFrame = self skipPlaybackKeyFrames(nrFramesToSkip);
    }
    else
    {
        newFrame = self skipPlaybackFrames(nrFramesToSkip);
    }

    if(newFrame<self.demoBegin)newFrame=self skipPlaybackFrames(self.demoBegin-newFrame);
    if(newFrame>self.demoEnd)newFrame=self skipPlaybackFrames(self.demoEnd-newFrame);

    frame = spawnStruct();
    frame.origin = self readPlaybackFrame_origin();
    frame.angles = self readPlaybackFrame_angles();
    frame.saveNow = self readPlaybackFrame_saveNow();
    frame.loadNow = self readPlaybackFrame_loadNow();
    frame.rpgNow = self readPlaybackFrame_rpgNow();
    flags = self readPlaybackFrame_flags();

    frame.left = (flags & 1) != 0;
    frame.right = (flags & 2) != 0;
    frame.forward = (flags & 4) != 0;
    frame.back = (flags & 8) != 0;
    frame.sprint = (flags & 16) != 0;
    frame.jump = (flags & 32) != 0;

    frame.state = "none";
    if((flags & 128) != 0)
    {
        frame.state = "mantling";
    }
    else if((flags & 256) != 0)
    {
        frame.state = "ladder";
    }
    else if((flags & 64) != 0)
    {
        frame.state = "sprinting";
    }

    frame.stance = "stand"; //512
    if((flags & 1024) != 0)
    {
        frame.stance = "crouch";
    }
    else if((flags & 2048) != 0)
    {
        frame.stance = "prone";
    }

    if((flags & 4096) != 0)
    {
        frame.weapon = "rpg";
    }
    else
    {
        frame.weapon = "default";
    }
    frame.onGround = (flags & 8192) != 0;
    frame.bounce = (flags & 16384) != 0;
    
    frame.FPS = self readPlaybackFrame_FPS();
    frame.number = newFrame;

    return frame;
}

whilePlayingDemo()
{
    if (isDefined(self.demoExitRequested) && self.demoExitRequested)
    {
        self stopDemo();
        return;
    }
    skipFails = demoHasKeyFrames(self.demoID); // TODO: temp because we don't have specific keys for skipping key frames right now
    self linkTo(self.demoLinker, "", (0, 0, 0), (0, 0, 0));
    if (self.playbackPaused)
    {
        self demoApplyPresentation();
        return;
    }

    isInterpolatedFrame = false;
    if(self.demoFirstFrame)
    {
        self.demoFirstFrame=false;
        currFrame=_getDemoFrame(0,false);
    }
    else if(self leftButtonPressed()) // Reverse
    {
        currFrame = _getDemoFrame(-2, skipFails);
    }
    else if(self rightButtonPressed()) // Forward
    {
        currFrame = _getDemoFrame(2, skipFails);
    }
    else if(self leanLeftButtonPressed()) // Faster forward
    {
        currFrame = _getDemoFrame(-10, skipFails);
    }
    else if(self leanRightButtonPressed()) // Faster reverse
    {
        currFrame = _getDemoFrame(10, skipFails);
    }
    else if(self jumpButtonPressed()) // Slow motion
    {
        slowmoCount = 4; // 1 / 4 -> 0.25.

        self.slowmoCount++;
        currFrame = _getDemoFrame(1, skipFails);
        if(self.slowmoCount == slowmoCount)
        {
            self.slowmoCount = 0;
        }
        else
        {
            // Grab info of previous frame
            prevFrame = _getDemoFrame(-1, skipFails);
            isInterpolatedFrame = true;
            if(!currFrame.loadNow)
            {
                // Fix angles so we don't have strange behavior when slowing
                slowmoScale = (self.slowmoCount / slowmoCount);
                currFwd = anglesToForward(currFrame.angles);
                prevFwd = anglesToForward(prevFrame.angles);
                interpFwd = vectorScale(currFwd, slowmoScale) + vectorScale(prevFwd, (1 - slowmoScale));
                if(interpFwd != (0, 0, 0))
                {
                    interpAngles = vectorToAngles(interpFwd); // This already normalizes the vector

                    // CoD doesn't think (...that vectors are arrays)
                    // Also, the calculation for [2] is so angle 'roll' can be left untouched (normal interpolation)
                    interpAngles = (interpAngles[0], interpAngles[1], (currFrame.angles[2] * slowmoScale) + (prevFrame.angles[2] * (1 - slowmoScale)));
                    currFrame.angles = interpAngles;
                }

                currFrame.origin = vectorScale(currFrame.origin, slowmoScale) + vectorScale(prevFrame.origin, (1 - slowmoScale));
            }
            else
            {
                currFrame = prevFrame;
            }
        }
    }
    else
    {
        currFrame = _getDemoFrame(1, skipFails);
    }

    self.demoLinker.origin = currFrame.origin;
    self setPlayerAngles(currFrame.angles);
    if(currFrame.stance!=self.demoPreviousStance)self setStance(currFrame.stance);
    detailed = self demoApplyPresentation();
    if (!detailed)
    {
        self openCJ\weapons::switchToDemoWeapon(currFrame.weapon == "rpg");
        self openCJ\huds\hudSpeedometer::_hideSpeedometer();
    }
    else
    {
        self openCJ\huds\hudSpeedometer::whileAlive();
        sequential = !isDefined(self.demoLastPresentedFrame) || currFrame.number == self.demoLastPresentedFrame + 1;
        if (currFrame.rpgNow && sequential && !isInterpolatedFrame)
        {
            sound = self readPlaybackFrame_rpgSound();
            if (isDefined(sound))self playLocalSound(sound);
        }
    }
    if (!isInterpolatedFrame)self.demoLastPresentedFrame = currFrame.number;
    self openCJ\huds\hudOnScreenKeyboard::showKeyboardDemo(currFrame.forward, currFrame.back, currFrame.left, currFrame.right, currFrame.jump, currFrame.sprint);
    if(currFrame.stance != self.demoPreviousStance)
    {
        //self iprintlnbold("stance changed to " + currFrame.stance);
        self.demoPreviousStance = currFrame.stance;
    }
    if(currFrame.state != self.demoPreviousState)
    {
        /*if((currFrame.state == "sprinting" && self.demoPreviousState == "none") || (currFrame.state == "none" && self.demoPreviousState == "sprinting"))
            self iprintln("state changed to " + currFrame.state);
        else
            self iprintlnbold("state changed to " + currFrame.state);*/
        self.demoPreviousState = currFrame.state;
    }

    if(self.demoPreviousOnGround != currFrame.onGround) //onground fps history hud should be called before fps changes
    {
        if(!currFrame.onGround)
        {
            self openCJ\huds\hudFpsHistory::onDemoLeaveGround(openCJ\fps::getShortFPS(currFrame.FPS));
        }
        else
        {
            self openCJ\huds\hudFpsHistory::onDemoLand();
        }
        self.demoPreviousOnGround = currFrame.onGround;
    }

    if(currFrame.bounce && !isInterpolatedFrame)
    {
        self openCJ\huds\hudFpsHistory::onDemoBounce(openCJ\fps::getShortFPS(currFrame.FPS));
    }

    if(!isDefined(self.demoPreviousFPS) || self.demoPreviousFPS != currFrame.FPS)
    {
        if(currFrame.onGround)
        {
            self openCJ\huds\hudFpsHistory::clearAndSetDemoFPS(openCJ\fps::getShortFPS(currFrame.FPS));
        }
        else
        {
            self openCJ\huds\hudFpsHistory::addDemoFPSHistory(openCJ\fps::getShortFPS(currFrame.FPS));
        }
        self.demoPreviousFPS = currFrame.FPS;
    }
    
    // Check if demo ended.
    if(currFrame.number >= self.demoEnd)
    {
        self _endOfDemo();
    }
}

_endOfDemo()
{
    if(self openCJ\settings::getSetting("demoloop"))
    {
        current=self skipPlaybackFrames(0);
        self skipPlaybackFrames(self.demoBegin-current);
        self.demoFirstFrame=true;self.demoLastPresentedFrame=undefined;
        self.maxSpeed=0;
        return;
    }
    self stopDemo();
}

stopDemo()
{
    if(!self isPlayingDemo())return;
    state=self.demoReturn;
    id=self.demoID;
    self unlink();
    self setoriginandangles(state.origin,state.angles);
    self setVelocity(state.velocity);
    self setStance(state.stance);
    self enableWeapons();
    if(state.weapon!="none" && state.weapon!="")self switchToWeapon(state.weapon);
    self demoEndPresentation();
    self.currSpeed=state.speed;self.maxSpeed=state.maxSpeed;
    self openCJ\huds\hudSpeedometer::whileAlive();
    self.health=state.health;
    self.playerRuns_runPaused=state.paused;
    self openCJ\playTime::setTimePlayed(state.time);
    self.demoExitRequested=false;
    self.playingDemo=false;
    self show();
    openCJ\playerCollision::onFrame();
    if(state.timerRunning)self openCJ\playTime::startTimer();
    self.activelyPlayingOrigin=state.origin;
    self.activelyPlayingTimer=getTime()+5000;
    self.previousOrigin=state.origin;
    self.previousOnground=self isOnGround();
    elapsed=getTime()-state.started;
    timestamps=[];timestamps[0]=level.statisticsStrings_lastExplosiveFiredTime;timestamps[1]=level.statisticsStrings_lastJumpTime;
    for(i=0;i<timestamps.size;i++)
        if(isDefined(self.statistics[timestamps[i]]))self.statistics[timestamps[i]]+=elapsed;
    self.eventQueue=[];
    self openCJ\buttonPress::resetButtons();
    self openCJ\checkpointPointers::showCheckpointPointers();
    self openCJ\showRecords::onSpawnPlayer();
    self openCJ\huds\hudStatistics::onSpawnPlayer();
    self openCJ\huds\hudProgressBar::onSpawnPlayer();
    self openCJ\huds\hudRunInfo::onSpawnPlayer();
    self.fpshistory=state.fpshistory;self.fpsHistoryText=state.fpsHistoryText;
    self.hud[level.fpsHistoryHudName] openCJ\huds\infiniteHuds::setInfiniteHudText(state.fpsHistoryText,self,false);
    self.demoID=undefined;self.demoReturn=undefined;
    releaseCache(id);
    self sendLocalChatMessage("Demo stopped. Your run has been restored.");
}

onDisconnect()
{
    self demoEndPresentation();
    self releasePending();
    if(self isPlayingDemo())releaseCache(self.demoID);
    if(isDefined(self.demoLinker))self.demoLinker delete();
}


releasePending()
{
    if(isDefined(self.demoPendingId))
    {
        releaseCache(self.demoPendingId);
        self.demoPendingId=undefined;
    }
}

cancelRequest()
{
    self notify("demo_request");
    self releasePending();
}
