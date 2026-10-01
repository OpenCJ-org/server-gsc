#include openCJ\util;

// All challenge definitions, rules, awards, ranks and menu data live here.
// IDs are permanent. Link routeName only after confirming the published route.
// Mode bits: any%=1, elevators=2, halfbeat=4, TAS=8. FPS is specified separately.
definitions()
{
    level.challenges=[];
    add("spectrum.beginner",1,"mp_spectrum","Beginner");
    add("cj_sky_bounce.main_route",1,"mp_cj_sky_bounce","Main route");
    add("to_the_moon.easy",1,"mp_to_the_moon","Easy");
    add("palm.easy",1,"mp_palm","Easy");
    add("blue2.easy",1,"mp_blue2","Easy");
    add("spectrum.easy",1,"mp_spectrum","Easy");
    add("descent_v2.easy",1,"mp_descent_v2","Easy");
    add("mystic_v2.easy",1,"mp_mystic_v2","Easy");
    add("mystic_v3.easy",1,"mp_mystic_v3","Easy");
    add("galaxy.easy",1,"mp_galaxy","Easy");
    add("to_the_moon.inter",2,"mp_to_the_moon","Inter");
    add("palm.inter",2,"mp_palm","Inter");
    add("blue2.inter",2,"mp_blue2","Inter");
    add("mystic_v3.inter",2,"mp_mystic_v3","Inter");
    add("galaxy.inter",2,"mp_galaxy","Inter");
    add("to_the_moon.advanced",3,"mp_to_the_moon","Advanced");
    add("blue2.hard",3,"mp_blue2","Hard");
    add("palm.hard",3,"mp_palm","Hard");
    add("bone.hard",3,"mp_bone","Hard");
    add("insane.hard",3,"mp_insane","Hard");
    add("descent_v2.hard",4,"mp_descent_v2","Hard");
    add("descent.hard",4,"mp_descent","Hard");
    add("shade.advanced",4,"mp_shade","Advanced");
    add("dark.hard",4,"mp_dark","Hard");
    add("dark_v2.hard",4,"mp_dark_v2","Hard");
    add("mystic_v2.hard",5,"mp_mystic_v2","Hard");
    add("palm_v2.hard",5,"mp_palm_v2","Hard");
    add("qube_v2.hard",5,"mp_qube_v2","Hard");
    add("marble.hard",5,"mp_marble","Hard");
    add("restyled.hard",5,"mp_restyled","Hard");
    add("awe.advanced",6,"mp_awe","Advanced");
    add("bridge.hard",6,"mp_bridge","Hard");
    add("mystic_v3.hard",6,"mp_mystic_v3","Hard");
    add("dawn_v2.hard",6,"mp_dawn_v2","Hard");
    add("galaxy.hard",6,"mp_galaxy","Hard");
    add("edge.main_route_edge",7,"mp_edge","Main route (edge)");
    add("mushroom.fungal_hazards",7,"mp_mushroom","Fungal Hazards");
    add("heaven_v2.hard",7,"mp_heaven_v2","Hard");
    add("dark_v3.hard",7,"mp_dark_v3","Hard");
    add("sunset.hard",7,"mp_sunset","Hard");
    add("sunset_v2.advanced",8,"mp_sunset_v2","Advanced");
    add("cyber.reality_corp_advanced",8,"mp_cyber","Reality Corp - Advanced");
    add("new_york.hard",8,"mp_new_york","Hard");
    add("palm_v3.advanced",8,"mp_palm_v3","Advanced");
    add("palm_v3.challenge",8,"mp_palm_v3","Challenge");
    add("dark_final.hard",9,"mp_dark_final","Hard");
    add("restyled_v3.hard",9,"mp_restyled_v3","Hard");
    add("void_v2.advanced",9,"mp_void_v2","Advanced");
    add("edge_v2.brutal",9,"mp_edge_v2","Brutal");
    add("12.advanced",9,"mp_12","Advanced");
    c=add("dark_final.hard.timed",10,"mp_dark_final","Hard");c.maxTime=3600000;
    c=add("restyled_v3.hard.timed",10,"mp_restyled_v3","Hard");c.maxTime=3600000;
    c=add("void_v2.advanced.timed",10,"mp_void_v2","Advanced");c.maxTime=3600000;
    c=add("edge_v2.brutal.timed",10,"mp_edge_v2","Brutal");c.maxTime=3600000;
    c=add("12.advanced.timed",10,"mp_12","Advanced");c.maxTime=14400000;
    c=add("12.challenge.timed",10,"mp_12","Challenge");c.maxTime=28800000;
    level.challenges["dark.hard"].routeName="hard";
}
add(key,tier,mapName,routeLabel)
{
    c=spawnStruct();c.key=key;c.tier=tier;c.points=tier*10;
    c.mapName=mapName;c.routeLabel=routeLabel;c.routeName=undefined;
    c.maxTime=0;c.maxRPG=-1;c.allowed=0;c.required=0;c.fps="125,mix";
    level.challenges[key]=c;
    return c;
}
onInit()
{
    level.challengesReady=false;
    if(getCodVersion()!=4)return;
    definitions();
    precacheMenu("opencj_challenges");
    openCJ\commands_base::registerCommand("challenges","!challenges",::command,0,0,0);
    if(!isDefined(openCJ\mySQL::mysqlSyncQuery("SELECT challengeKey FROM challenges LIMIT 0")))return;
    level thread initialize();
}
initialize()
{
    keys=getArrayKeys(level.challenges);
    // An atomic catalogue refresh changes thresholds without touching earned awards.
    openCJ\mySQL::mysqlSyncQuery("START TRANSACTION");
    ok=isDefined(openCJ\mySQL::mysqlSyncQuery("UPDATE challenges SET active=0"));
    for(i=0;ok && i<keys.size;i++)
    {
        c=level.challenges[keys[i]];route="NULL";
        if(isDefined(c.routeName))route=dbStr(c.routeName);
        values="tier="+c.tier+",points="+c.points+",mapName="+dbStr(c.mapName)+",routeLabel="+dbStr(c.routeLabel)+",routeName="+route+",maxTimeMs="+c.maxTime+",maxRPG="+c.maxRPG+",allowedModes="+c.allowed+",requiredModes="+c.required+",fpsModes="+dbStr(c.fps)+",active=1";
        ok=isDefined(openCJ\mySQL::mysqlSyncQuery("INSERT INTO challenges SET challengeKey="+dbStr(c.key)+","+values+" ON DUPLICATE KEY UPDATE "+values));
    }
    if(!ok){openCJ\mySQL::mysqlSyncQuery("ROLLBACK");return;}
    openCJ\mySQL::mysqlSyncQuery("COMMIT");
    level.challengeTierPoints=[];
    for(t=1;t<=10;t++)level.challengeTierPoints[t]=0;
    for(i=0;i<keys.size;i++){c=level.challenges[keys[i]];level.challengeTierPoints[c.tier]+=c.points;}
    // Only proven, finalized run snapshots qualify, including existing players.
    result=openCJ\mySQL::mysqlAsyncQuery(awardSQL(""));
    if(!isDefined(result))return;
    level.challengesReady=true;
}
awardSQL(extra)
{
    mask="(r.anyPct+2*r.ele+4*r.hb+8*r.hardTAS)";
    return "INSERT IGNORE INTO challengeCompletions(playerID,challengeKey,runID) SELECT r.playerID,c.challengeKey,MIN(r.runID) FROM challenges c JOIN mapids m ON m.mapname=c.mapName JOIN playerRuns r ON r.mapID=m.mapID JOIN checkpoints cp ON cp.cpID=r.finishcpID JOIN checkpointStatistics s ON s.runID=r.runID AND s.cpID=r.finishcpID WHERE c.active=1 AND c.routeName IS NOT NULL AND LOWER(cp.ender)=LOWER(c.routeName) AND r.finishTimeStamp IS NOT NULL AND FIND_IN_SET(r.FPSMode,c.fpsModes)>0 AND ("+mask+" & c.allowedModes)="+mask+" AND ("+mask+" & c.requiredModes)=c.requiredModes AND (c.maxTimeMs=0 OR s.timePlayed<=c.maxTimeMs) AND (c.maxRPG<0 OR s.explosiveJumps<=c.maxRPG) "+extra+" GROUP BY r.playerID,c.challengeKey";
}
rankForPoints(points)
{
    rank=1;threshold=0;
    for(t=1;t<10;t++)
    {
        if(level.challengeTierPoints[t]<=0)break;
        threshold+=level.challengeTierPoints[t];
        if(points<threshold)break;
        rank=t+1;
    }
    return rank;
}
onPlayerConnected()
{
    if(getCodVersion()!=4)return;
    self.challengeRank=1;self.challengePoints=0;
    self setClientCvar("ocj_ch_height",388);
    self thread connected();self thread responses();
}
connected()
{
    self endon("disconnect");
    while(!level.challengesReady || !self openCJ\login::isLoggedIn())wait 0.25;
    self refresh();
}
refresh()
{
    id=self openCJ\login::getPlayerID();
    rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT COALESCE(SUM(c.points),0) FROM challengeCompletions a JOIN challenges c ON c.challengeKey=a.challengeKey AND c.active=1 WHERE a.playerID="+id);
    if(!isDefined(rows) || !rows.size)return;
    self.challengePoints=int(rows[0][0]);self.challengeRank=rankForPoints(self.challengePoints);
}
awardRun(runID)
{
    self endon("disconnect");
    if(!level.challengesReady)return;
    before=self.challengePoints;
    result=self openCJ\mySQL::mysqlAsyncQuery(awardSQL("AND r.runID="+int(runID)));
    if(!isDefined(result))return;
    self refresh();
    if(self.challengePoints>before)self sendLocalChatMessage("Challenge complete! +"+(self.challengePoints-before)+" points. Total: "+self.challengePoints+" | Level "+self.challengeRank);
}
command(args)
{
    self openMenu("opencj_challenges");
}
responses()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("menuresponse",menu,response);
        if(menu!="opencj_challenges")continue;
        if(isDefined(self.challengeLastRequest) && getTime()-self.challengeLastRequest<200)continue;
        self.challengeLastRequest=getTime();
        if(!isDefined(self.challengeTab)){self.challengeTab=0;self.challengePage=0;}
        if(response=="open"){self.challengeTab=0;self.challengePage=0;}
        else if(response=="next")self.challengePage++;
        else if(response=="previous"){if(self.challengePage>0)self.challengePage--;}
        else if(isValidInt(response)){tier=int(response);if(tier<0 || tier>10)continue;self.challengeTab=tier;self.challengePage=0;}
        else continue;
        self thread show();
    }
}
show()
{
    self endon("disconnect");
    self notify("challenge_menu_refresh");self endon("challenge_menu_refresh");
    self setClientCvar("ocj_ch_busy",1);
    if(!level.challengesReady || !self openCJ\login::isLoggedIn())
    {self setClientCvar("ocj_ch_summary","Challenges are loading. Reopen in a moment.");return;}
    self refresh();
    next="Maximum level";
    if(self.challengeRank<10)
    {
        threshold=0;for(t=1;t<=self.challengeRank;t++)threshold+=level.challengeTierPoints[t];
        next="Next level: "+threshold+" points";
    }
    self setClientCvar("ocj_ch_summary","Level "+self.challengeRank+" | "+self.challengePoints+" points | "+next);
    self setClientCvar("ocj_ch_rank",self.challengeRank);
    self.challengeMenuValues=[];
    tab=self.challengeTab;page=self.challengePage;
    self setUI("ocj_ch_tab",tab);
    title="Competitive - Top 10";hint="All challenge points count. Ties share position.";
    if(tab==0)
    {
        rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT p.playerName,COALESCE(SUM(c.points),0),p.playerID FROM playerInformation p LEFT JOIN challengeCompletions a ON a.playerID=p.playerID LEFT JOIN challenges c ON c.challengeKey=a.challengeKey AND c.active=1 GROUP BY p.playerID,p.playerName ORDER BY 2 DESC,p.playerID LIMIT 10");
        total=0;if(isDefined(rows))total=rows.size;
        lastPoints=-1;position=0;
        for(i=0;i<total;i++)
        {
            points=int(rows[i][1]);if(points!=lastPoints)position=i+1;lastPoints=points;
            self setUI("ocj_ch_name"+i,position+". "+openCJ\scoreboard::clean(rows[i][0],24));
            self setUI("ocj_ch_detail"+i,"Level "+rankForPoints(points));
            self setUI("ocj_ch_points"+i,""+points+" pts");
            self setUI("ocj_ch_state"+i,"");self setUI("ocj_ch_count"+i,"");self setUI("ocj_ch_done"+i,0);self setUI("ocj_ch_status"+i,0);
        }
        pages=1;
    }
    else
    {
        title="Tier "+tab+" challenges";
        hint="";
        rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT c.challengeKey,c.mapName,c.routeLabel,c.points,c.maxTimeMs,c.maxRPG,c.routeName,COUNT(a.playerID),MAX(a.playerID="+self openCJ\login::getPlayerID()+"),c.fpsModes,c.allowedModes FROM challenges c LEFT JOIN challengeCompletions a ON a.challengeKey=c.challengeKey WHERE c.active=1 AND c.tier="+tab+" GROUP BY c.challengeKey ORDER BY c.challengeKey");
        count=0;if(isDefined(rows))count=rows.size;
        pages=int((count+15)/16);if(pages<1)pages=1;
        if(page>=pages)page=pages-1;
        self.challengePage=page;
        total=count-page*16;if(total>16)total=16;
        for(i=0;i<total;i++)
        {
            row=rows[page*16+i];detail=row[2];target="Finish";
            if(int(row[4])>0)target=formatTimeString(int(row[4]),true);
            if(int(row[5])>=0)
            {
                if(int(row[4])>0)target+=" / ";else target="";
                target+=row[5]+" RPG";
            }
            self setUI("ocj_ch_target"+i,target);
            done=isDefined(row[8]) && int(row[8])!=0;
            status=1;state="Incomplete";
            if(!isDefined(row[6])){state="Not available yet";status=3;}
            if(done){state="Complete";status=2;}
            self setUI("ocj_ch_status"+i,status);
            icons=allowedModeIcons(row[9],int(row[10]));
            self setUI("ocj_ch_modes"+i,icons.size);
            for(m=0;m<icons.size;m++)self setUI("ocj_ch_mode"+i+"_"+m,icons[m]);
            self setUI("ocj_ch_name"+i,row[1]);self setUI("ocj_ch_detail"+i,detail);
            self setUI("ocj_ch_points"+i,row[3]+" pts");self setUI("ocj_ch_state"+i,state);
            self setUI("ocj_ch_count"+i,row[7]+" players");self setUI("ocj_ch_done"+i,int(done));
        }
    }
    self setUI("ocj_ch_title",title);self setUI("ocj_ch_hint",hint);
    self setUI("ocj_ch_rows",total);self setUI("ocj_ch_height",168+total*16);
    self setUI("ocj_ch_page",page);self setUI("ocj_ch_pages",pages);
    self openCJ\scoreboard::sendChanged(self.challengeMenuValues);
    self setClientCvar("ocj_ch_busy",0);
}

setUI(key,value)
{
    self.challengeMenuValues[key]=value;
}

// Display the same FPS list and mode mask used to validate this challenge.
allowedModeIcons(fps,allowed)
{
    icons=[];
    fpsModes=strTok(fps,",");
    for(m=0;m<fpsModes.size;m++)
    {
        if(fpsModes[m]=="125")icons[icons.size]="opencj_icon_fps_classic";
        else if(fpsModes[m]=="mix")icons[icons.size]="opencj_icon_fps_standard";
        else if(fpsModes[m]=="hax")icons[icons.size]="opencj_icon_fps_any";
    }
    if(allowed & 1)icons[icons.size]="opencj_icon_anypct";
    if(allowed & 2)icons[icons.size]="opencj_icon_ele";
    if(allowed & 4)icons[icons.size]="opencj_icon_halfbeat";
    if(allowed & 8)icons[icons.size]="opencj_icon_tas";
    return icons;
}
