#include openCJ\util;

// Local HUD visibility follows the client's hold bind. Only visible viewers
// receive changed rows; no database queries or server HUD elements are needed.
onInit()
{
    if(getCodVersion()!=4)return;
    if(getCvar("opencj_public_hostname")=="")setCvar("opencj_public_hostname","eu.opencj.org");
    precacheMenu("opencj_scoreboard_setup");
    openCJ\commands_base::registerCommand("scoreboard","!scoreboard",::command,0,0,0);
}

onPlayerConnected()
{
    if(getCodVersion()!=4)return;
    self.scoreboardCache=[];
    self setClientCvar("opencj_sb_held",0);
    self setClientCvar("opencj_sb_active",0);
    self thread installControls();
    self thread watch();
}

installControls()
{
    self endon("disconnect");
    self setClientCvar("opencj_sb_ready", "0");
    // Connection hooks open/close other menus in this same frame.
    waittillframeend;
    for(attempt=0;attempt<3;attempt++)
    {
        self openMenu("opencj_scoreboard_setup");
        for(check=0;check<10;check++)
        {
            wait 0.1;
            if(self getUserinfo("opencj_sb_ready")=="3")return;
        }
    }
    printf("Scoreboard controls: client did not acknowledge initialization.\n");
}

command(args)
{
    self sendLocalChatMessage("Hold scoreboard: exec ui_mp/opencj_scoreboard_keys.cfg in console (Tab).");
}

watch()
{
    self endon("disconnect");
    nextUpdate=0;
    for(;;)
    {
        if(self getUserinfo("opencj_sb_active")=="1")
        {
            if(getTime()>=nextUpdate)
            {
                self update();
                nextUpdate=getTime()+1000;
            }
        }
        else nextUpdate=0;
        wait 0.2;
    }
}

spectatorRow(player)
{
    // Playback uses spectator presentation but remains a jumper activity.
    return player.sessionState=="spectator" && !player openCJ\demos::isPlayingDemo() && !isDefined(player.cpc);
}

status(player)
{
    if(isDefined(player.cpc))return "^5CPC";
    if(isDefined(player.clipEdit))return "^5Clip editor";
    if(isDefined(player.clipPreview))return "^5Clip preview";
    if(player openCJ\demos::isPlayingDemo())
    {
        if(isDefined(player.clipPlayback))return "^5Clip";
        return "^5Demo";
    }
    if(isDefined(player.isAFK) && player.isAFK)return "^3AFK";
    if(spectatorRow(player))return "Spectating";
    if(isDefined(player.clipRecording))return "^1Recording";
    if(player openCJ\playerRuns::isRunFinished())return "^2Finished";
    if(!player openCJ\playerRuns::hasRunStarted())return "Ready";
    if(player openCJ\playerRuns::isRunPaused())return "^3Paused";
    return "^2Jumping";
}

// Quoted engine dvar transport must never contain player-controlled delimiters.
clean(text,limit)
{
    if(!isDefined(text))return "";
    text=""+text;out="";
    for(i=0;i<text.size && out.size<limit;i++)
        if(text[i]!="\"" && text[i]!="\\" && text[i]!="\n" && text[i]!="\r")out+=text[i];
    if(out.size && out[out.size-1]=="^")out=getSubStr(out,0,out.size-1);
    return out;
}

row(player)
{
    r=[];
    r["name"]=clean(player.name,20);
    r["country"]=clean(player openCJ\country::getCountry(),2);
    country=toLower(r["country"]);
    if(country=="uk")country="gb";
    r["flag"]="";
    if(isSubStr(" ad ae af ag ai al am ao aq ar as at au aw ax az ba bb bd be bf bg bh bi bj bl bm bn bo bq br bs bt bv bw by bz ca cc cd cf cg ch ci ck cl cm cn co cp cr cu cv cw cx cy cz de dg dj dk dm do dz ec ee eg eh er es et eu fi fj fk fm fo fr ga gb gd ge gf gg gh gi gl gm gn gp gq gr gs gt gu gw gy hk hm hn hr ht hu ic id ie il im in io iq ir is it je jm jo jp ke kg kh ki km kn kp kr kw ky kz la lb lc li lk lr ls lt lu lv ly ma mc md me mf mg mh mk ml mm mn mo mp mq mr ms mt mu mv mw mx my mz na nc ne nf ng ni nl no np nr nu nz om pa pc pe pf pg ph pk pl pm pn pr ps pt pw py qa re ro rs ru rw sa sb sc sd se sg sh si sj sk sl sm sn so sr ss st sv sx sy sz tc td tf tg th tj tk tl tm tn to tr tt tv tw tz ua ug um un us uy uz va vc ve vg vi vn vu wf ws xk xx ye yt za zm zw "," "+country+" "))r["flag"]="opencj_flag_"+country;
    r["ping"]=""+player getPing();
    variation=player getPingVariation();
    r["pingText"]=r["ping"];
    if(variation>=0)r["pingText"]+=" (+/- "+variation+" ms)";
    r["route"]="-";r["progress"]=-1;r["time"]="-";r["rpg"]="-";
    r["fps"]=0;r["ele"]=0;r["hb"]=0;r["tas"]=0;r["any"]=0;
    if(isDefined(player.cpc))
    {
        r["route"]=player.cpc.route;
        return r;
    }
    if(player openCJ\demos::isPlayingDemo() || spectatorRow(player))return r;
    if(!player openCJ\playerRuns::hasRunID() || !player openCJ\playerRuns::hasRunStarted())return r;
    if(isDefined(player.route))r["route"]=player.route;
    current=player openCJ\checkpoints::getCurrentCheckpoint();
    if(isDefined(current))
    {
        route=openCJ\checkpoints::getRouteNameForCheckpoint(current);
        if(isDefined(route))r["route"]=route;
        if(!player openCJ\anyPct::hasAnyPct())
        {
            passed=openCJ\checkpoints::getPassedCheckpointCount(current);
            remaining=openCJ\checkpoints::getRemainingCheckpointCount(current);
            if(isDefined(remaining) && passed+remaining>0)
                r["progress"]=int(100.0*passed/(passed+remaining));
        }
    }
    if(player openCJ\anyPct::hasAnyPct())r["progress"]=-1;
    else if(player openCJ\playerRuns::isRunFinished())r["progress"]=100;
    r["time"]=formatTimeString(player openCJ\playTime::getTimePlayed(),true);
    r["rpg"]=player openCJ\statistics::getExplosiveJumps();
    fps=player openCJ\fps::getCurrentFPSMode();
    r["fps"]=1;
    if(fps=="mix")r["fps"]=2;
    if(fps=="hax")r["fps"]=3;
    r["ele"]=int(player openCJ\elevate::hasUsedEle());
    r["hb"]=int(player openCJ\halfBeat::isHalfBeatAllowed());
    r["tas"]=int(player openCJ\tas::hasHardTAS());
    r["any"]=int(player openCJ\anyPct::hasAnyPct());
    return r;
}

update()
{
    // Leave headroom for gameplay commands on slow or reconnecting clients.
    if(self getQueuedReliableMessages()>16)return;
    if(!isDefined(level.scoreboardNextUpdate) || getTime()>=level.scoreboardNextUpdate)
        buildSnapshot();
    self sendChanged(level.scoreboardValues);
    personal=[];
    for(i=0;i<32;i++)
        personal["opencj_sb_r"+i+"_self"]=int(i<level.scoreboardPlayers.size && level.scoreboardPlayers[i]==self);
    self sendChanged(personal);
}

buildSnapshot()
{
    players=getEntArray("player","classname");jumpers=[];spectators=[];
    // Entity order is stable: the list does not jump around as timers update.
    for(i=0;i<players.size;i++)
    {
        if(!isDefined(players[i].isFullyConnected) || !players[i].isFullyConnected)continue;
        if(spectatorRow(players[i]))spectators[spectators.size]=players[i];
        else jumpers[jumpers.size]=players[i];
    }
    values=[];level.scoreboardPlayers=[];
    total=jumpers.size+spectators.size;
    if(total>32)total=32;
    rowHeight=16;
    if(total>24)rowHeight=384.0/total;
    height=86+total*rowHeight;
    values["opencj_sb_rowheight"]=rowHeight;
    top=(480-height)/2;
    if(top>90)top=90;
    if(top<8)top=8;
    values["opencj_sb_top"]=top;
    values["opencj_sb_height"]=height;
    values["opencj_sb_specy"]=top+43+jumpers.size*rowHeight+2;
    values["opencj_sb_footer"]=top+height-16;
    values["opencj_sb_map"]=getCvar("mapname");
    values["opencj_sb_servername"]=getCvar("sv_hostname");
    values["opencj_sb_hostname"]=getCvar("opencj_public_hostname")+":"+getCvar("net_port");
    values["opencj_sb_jumpers"]="Jumpers ("+jumpers.size+")";
    values["opencj_sb_spectators"]="Spectators ("+spectators.size+")";
    for(i=0;i<32;i++)
    {
        key="opencj_sb_r"+i+"_";
        values[key+"exists"]=int(i<total);
        if(i>=total)continue;
        player=undefined;y=top+43+i*rowHeight;
        if(i<jumpers.size)player=jumpers[i];
        else {player=spectators[i-jumpers.size];y+=17;}
        values[key+"y"]=y;
        level.scoreboardPlayers[i]=player;
        data=row(player);keys=getArrayKeys(data);
        for(j=0;j<keys.size;j++)values[key+keys[j]]=data[keys[j]];
    }
    level.scoreboardValues=values;
    level.scoreboardNextUpdate=getTime()+1000;
}

sendChanged(values)
{
    if(!isDefined(self.scoreboardCache))self.scoreboardCache=[];
    keys=getArrayKeys(values);command="v";
    for(i=0;i<keys.size;i++)
    {
        value=clean(values[keys[i]],160);
        if(isDefined(self.scoreboardCache[keys[i]]) && self.scoreboardCache[keys[i]]==value)continue;
        pair=" "+keys[i]+" \""+value+"\"";
        if(command.size+pair.size>800){self SV_GameSendServerCommand(command,true);command="v";}
        command+=pair;self.scoreboardCache[keys[i]]=value;
    }
    if(command!="v")self SV_GameSendServerCommand(command,true);
}
