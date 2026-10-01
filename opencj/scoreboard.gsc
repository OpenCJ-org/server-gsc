#include openCJ\util;

// Local HUD visibility follows the client's hold bind. Only visible viewers
// receive changed rows; no database queries or server HUD elements are needed.
onInit()
{
    if(getCodVersion()!=4)return;
    if(getCvar("opencj_public_hostname")=="")setCvar("opencj_public_hostname","eu.opencj.org");
    precacheMenu("opencj_scoreboard_setup");
    precacheMenu("opencj_scoreboard_input");
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
    self thread scrollInput();
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
    nextUpdate=0;inputOpen=false;
    for(;;)
    {
        if(self getUserinfo("opencj_sb_active")=="1")
        {
            if(!inputOpen){self openMenu("opencj_scoreboard_input");inputOpen=true;}
            if(getTime()>=nextUpdate)
            {
                self update();
                nextUpdate=getTime()+1000;
            }
        }
        else
        {
            nextUpdate=0;self.scoreboardOffset=0;
            if(inputOpen){self closeMenu("opencj_scoreboard_input");inputOpen=false;}
        }
        wait 0.2;
    }
}

scrollInput()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("menuresponse",menu,response);
        if(menu!="opencj_scoreboard_input")continue;
        if(response=="close")
        {
            self setClientCvar("opencj_sb_held",0);
            self setClientCvar("opencj_sb_active",0);
            self closeMenu(menu);continue;
        }
        if(self getUserinfo("opencj_sb_active")!="1")continue;
        if(response!="up" && response!="down")continue;
        if(isDefined(self.scoreboardScrollTime) && getTime()-self.scoreboardScrollTime<75)continue;
        self.scoreboardScrollTime=getTime();
        if(!isDefined(self.scoreboardOffset))self.scoreboardOffset=0;
        if(response=="up")self.scoreboardOffset-=3;else self.scoreboardOffset+=3;
        self update();
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
    r["points"]=points(player);
    rank=1;if(isDefined(player.challengeRank))rank=player.challengeRank;
    r["rank"]="opencj_rank_"+rank;
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

// A fixed viewport keeps ranks, modes and player text readable at full capacity.
viewLayout(offset,total,jumpers)
{
    v=spawnStruct();v.maxOffset=total-15;if(v.maxOffset<0)v.maxOffset=0;
    v.first=offset;if(v.first<0)v.first=0;if(v.first>v.maxOffset)v.first=v.maxOffset;
    v.count=total-v.first;if(v.count>15)v.count=15;
    v.split=jumpers>v.first && jumpers<v.first+v.count;
    v.height=69+v.count*22;if(v.split)v.height+=17;
    v.top=(480-v.height)/2;if(v.top>90)v.top=90;
    return v;
}

update()
{
    if(self getQueuedReliableMessages()>16)return;
    if(!isDefined(level.scoreboardNextUpdate) || getTime()>=level.scoreboardNextUpdate)
        buildSnapshot();
    self sendChanged(level.scoreboardValues);
    if(!isDefined(self.scoreboardOffset))self.scoreboardOffset=0;
    v=viewLayout(self.scoreboardOffset,level.scoreboardPlayers.size,level.scoreboardJumperCount);
    self.scoreboardOffset=v.first;
    personal=[];
    personal["opencj_sb_rowheight"]=22;personal["opencj_sb_iconsize"]=20;
    personal["opencj_sb_top"]=v.top;personal["opencj_sb_height"]=v.height;
    personal["opencj_sb_footer"]=v.top+v.height-16;
    personal["opencj_sb_spec_visible"]=int(v.split);
    personal["opencj_sb_specy"]=v.top+43+(level.scoreboardJumperCount-v.first)*22;
    title="Jumpers ("+level.scoreboardJumperCount+")";
    if(v.first>=level.scoreboardJumperCount && v.count>0)title=level.scoreboardValues["opencj_sb_spectators"];
    personal["opencj_sb_section"]=title;
    personal["opencj_sb_scroll_visible"]=int(v.maxOffset>0);
    personal["opencj_sb_scroll_label"]=(v.first+1)+"-"+(v.first+v.count)+" / "+level.scoreboardPlayers.size+"   Mouse wheel";
    personal["opencj_sb_track_y"]=v.top+43;
    trackHeight=v.count*22;if(v.split)trackHeight+=17;
    personal["opencj_sb_track_h"]=trackHeight;
    thumbHeight=trackHeight;
    if(level.scoreboardPlayers.size>0)thumbHeight=trackHeight*v.count/level.scoreboardPlayers.size;
    personal["opencj_sb_thumb_h"]=thumbHeight;
    thumbY=v.top+43;if(v.maxOffset>0)thumbY+=(trackHeight-thumbHeight)*v.first/v.maxOffset;
    personal["opencj_sb_thumb_y"]=thumbY;
    for(i=0;i<15;i++)
    {
        key="opencj_sb_r"+i+"_";personal[key+"exists"]=int(i<v.count);
        if(i>=v.count)continue;
        index=v.first+i;y=v.top+43+i*22;
        if(v.split && index>=level.scoreboardJumperCount)y+=17;
        personal[key+"y"]=y;
        personal[key+"self"]=int(level.scoreboardPlayers[index]==self);
        data=level.scoreboardRows[index];keys=getArrayKeys(data);
        for(j=0;j<keys.size;j++)personal[key+keys[j]]=data[keys[j]];
    }
    self sendChanged(personal);
}

points(player)
{
    if(isDefined(player.challengePoints))return player.challengePoints;
    return 0;
}

sortByPoints(players)
{
    for(i=1;i<players.size;i++)
    {
        player=players[i];j=i;
        while(j>0 && points(players[j-1])<points(player))
        {
            players[j]=players[j-1];j--;
        }
        players[j]=player;
    }
    return players;
}

buildSnapshot()
{
    players=getEntArray("player","classname");jumpers=[];spectators=[];
    // Stable point ordering within each team; tied players retain entity order.
    for(i=0;i<players.size;i++)
    {
        if(!isDefined(players[i].isFullyConnected) || !players[i].isFullyConnected)continue;
        if(spectatorRow(players[i]))spectators[spectators.size]=players[i];
        else jumpers[jumpers.size]=players[i];
    }
    jumpers=sortByPoints(jumpers);spectators=sortByPoints(spectators);
    values=[];level.scoreboardPlayers=[];level.scoreboardRows=[];
    total=jumpers.size+spectators.size;if(total>32)total=32;
    level.scoreboardJumperCount=jumpers.size;
    values["opencj_sb_map"]=getCvar("mapname");
    values["opencj_sb_servername"]=getCvar("sv_hostname");
    values["opencj_sb_hostname"]=getCvar("opencj_public_hostname")+":"+getCvar("net_port");
    values["opencj_sb_spectators"]="Spectators ("+spectators.size+")";
    for(i=0;i<total;i++)
    {
        if(i<jumpers.size)player=jumpers[i];else player=spectators[i-jumpers.size];
        level.scoreboardPlayers[i]=player;level.scoreboardRows[i]=row(player);
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
