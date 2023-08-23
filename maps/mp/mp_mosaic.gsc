main()
{
	maps\mp\_load::main();
		
	
	game["allies"] = "sas";
	game["axis"] = "opfor";
	game["attackers"] = "axis";
	game["defenders"] = "allies";
	game["allies_soldiertype"] = "woodland";
	game["axis_soldiertype"] = "woodland";

	thread TeleportEasyStart();	 	//teleports player to beginning of easy way
	thread EasyComplete();			//trigger signifying completion of easy way

	thread TeleportInterStart();    //teleports player to beginning of inter way
    thread InterComplete();  		//trigger signifying completion of inter way

	thread TeleportInterPlusStart();//teleports player to beginning of inter+ way
    thread InterPlusComplete();     //trigger signifying completion of inter+ way

	thread TeleportHardStart(); 	//teleports player to beginning of hard way
    thread HardComplete();			//trigger signifying completion of hard way

	thread TeleportSpeedrunStart();
	thread speedrunStartTimer();
	thread speedrunEndtimer();
	thread speedrunEndtimer2();


    thread TeleportGay();
	thread TeleportGay2();
	thread TeleportInter2();
	thread TeleportSpeedrun1();
	thread TeleportSpeedrun2();
	thread TeleportSpeedrun3();
	thread TeleportSpeedrun4();
	thread TeleportSpeedrunBonus();
	thread TeleportInterPlus2();
	
	thread TeleportFinalRoom1();
	thread TeleportFinalRoom2();
	thread TeleportFinalRoom3();
	thread TeleportFinalRoom4();
	thread TeleportFinalRoom5();
	thread TeleportFinalRoom6();
	thread FinalRoom();
	thread FinalRoom2();
	thread TeleportSpawn();
	thread TeleportSpawn2();


	thread waitforconnect();
}

waitforconnect()
{
    level endon("game_ended");

    while(1)
    {
      level waittill("connected", player);
      player thread onPlayerSpawn();
      player thread welcomemsg();
      player thread loopmessages();
	  
      player setclientdvar("r_specular", 1);
    }    
} 
onPlayerSpawn()
{
    self endon("disconnect");

    while(1)
    {
    self waittill("spawned_player");
    self setclientdvar("r_glowbloomintensity0",1);
    self setclientdvar("r_glowbloomintensity1",1);
    self setclientdvar("r_glowskybleedintensity0",1);
    self setclientdvar("r_specularcolorscale",5);
    self setclientdvar("sm_sunSampleSizeNear", 3);

    self waittill("death");
    wait (1);
    }
}
welcomemsg()
{
	self endon("disconnect");	
    self waittill("spawned_player");  
    self iPrintLnBold("^7Welcome to ^1mp_mosaic^7, "+self.name+"!");
    wait (6);
    self iPrintLnBold("^7Map by ^1hawkslayerr");
    wait(1); 
}
loopmessages()
{
    self endon("disconnect");
  while(1)
  {
    wait (1000);  
    //self iprintln("^7Thanks for playing ^0mp_mosaic^7, "+self.name+"^7!");
    //wait (5);
    self iprintln("Map by hawkslayerr");
  }
}  
TeleportSpawn()
{
	trig = getEnt("trigger_teleportSpawn", "targetname");
	tele = getEnt("origin_teleportSpawn", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportSpawn2()
{
	trig = getEnt("trigger_teleportSpawn2", "targetname");
	tele = getEnt("origin_teleportSpawn", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportEasyStart()
{
	trig = getEnt("trigger_teleport4", "targetname");
	tele4 = getEnt("origin_teleport4", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele4.origin);
		player setPlayerAngles(tele4.angles);
		player iPrintLnBold("You have chosen the ^2Easy ^7route");
	}
}
EasyComplete()
{
	trig = getEnt("easy_finish", "targetname");
	
	while(1)
    {
        trig waittill("trigger", player);
        if(!isdefined(player.easydone))
        {
			iprintln("^7"+player.name+" finished ^2Easy ^7way!");
			player.easydone = true;
        }      
        wait 0.05;
    }
}
TeleportInterStart()
{
	trig = getEnt("trigger_teleport2", "targetname");
	tele2 = getEnt("origin_teleport2", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele2.origin);
		player setPlayerAngles(tele2.angles);
		player iPrintLnBold("You have chosen the ^5Intermediate ^7route");
	}
}
InterComplete()
{
	trig = getEnt("inter_finish", "targetname");
	
	while(1)
    {
        trig waittill("trigger", player);
        if(!isdefined(player.interdone))
        {
			iprintln("^7"+player.name+" finished ^5Inter ^7way!");
			player.interdone = true;
        }      
        wait 0.05;
    }
}
TeleportInterPlusStart()
{
	trig = getEnt("trigger_teleport8", "targetname");
	tele8 = getEnt("origin_teleport8", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele8.origin);
		player setPlayerAngles(tele8.angles);
		player iPrintLnBold("You have chosen the ^4Intermediate + ^7route");
	}
}
InterPlusComplete()
{
	trig = getEnt("inter_plus_finish", "targetname");
	
	while(1)
    {
        trig waittill("trigger", player);
        if(!isdefined(player.interplusdone))
        {
			iprintln("^7"+player.name+" finished ^4Inter+ ^7way!");
			player.interplusdone = true;
        }      
        wait 0.05;
    }
}
TeleportHardStart()
{
	trig = getEnt("trigger_teleport1", "targetname");
	tele1 = getEnt("origin_teleport1", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele1.origin);
		player setPlayerAngles(tele1.angles);
		player iPrintLnBold("You have chosen the ^1Hard ^7route");
	}
}
HardComplete()
{
	trig = getEnt("hard_finish", "targetname");
	
	while(1)
    {
        trig waittill("trigger", player);
        if(!isdefined(player.harddone))
        {
			iprintln("^7"+player.name+" finished ^1Hard ^7way!");
			player.harddone = true;
        }      
        wait 0.05;
    }
}
TeleportSpeedrunStart()
{
	trig = getEnt("trigger_teleport7", "targetname");
	tele7 = getEnt("origin_teleport7", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele7.origin);
		player setPlayerAngles(tele7.angles);
		player iPrintLnBold("You have chosen the ^6Speedrun ^7route");
	}
}
//speedrun way timer start
speedrunStartTimer()
{
    level endon("game_ended");
   
    speedruntimerstart = getent("trigger_teleport7", "targetname");
 
    while(1)
    {
        speedruntimerstart waittill("trigger", player);
       
        if(player.sessionstate == "playing")
        {
            player checkpointreset();
            player.startTimeSpeedrun = getTime();
            player.speedrunend = undefined;
            player thread speedrunchk();
        }                      
    }
}
speedrunEndtimer()
{
    level endon("game_ended");
   
    trig = getent("speedrun_finish", "targetname");
    while(1)
    {
        trig waittill("trigger", player);
       
        if(player.sessionstate != "playing" || isDefined(player.speedrunend) || !isDefined(player.startTimeSpeedrun))
            continue;
   
        else
        {
            if(isDefined(player.speedrunchk1) && isDefined(player.speedrunchk2) && isDefined(player.speedrunchk3) && isDefined(player.speedrunchk4) && isDefined(player.speedrunchk5) && isDefined(player.speedrunchk6) && isDefined(player.speedrunchk7) && isDefined(player.speedrunchk8) && isDefined(player.speedrunchk9))
            {
                number = getTime() - player.startTimeSpeedrun;
                iPrintLn("^1"+player.name+" ^7completed ^6Speedrun^7 Way in " + realtime(number));
                player.speedrunEnd = true;
                player.startTimeSpeedrun = undefined;
                player notify("speedrun_stop");
                player thread checkpointreset();
            }    
        }
       wait 0.01;
    }
}
speedrunEndtimer2()
{
    level endon("game_ended");
   
    trig = getent("speedrun_secret_finish", "targetname");
    while(1)
    {
        trig waittill("trigger", player);
       
        if(player.sessionstate != "playing" || isDefined(player.speedrunend) || !isDefined(player.startTimeSpeedrun))
            continue;
   
        else
        {
            if(isDefined(player.speedrunchk1) && isDefined(player.speedrunchk2) && isDefined(player.speedrunchk3) && isDefined(player.speedrunchk4) && isDefined(player.speedrunchk5) && isDefined(player.speedrunchk6) && isDefined(player.speedrunchk7) && isDefined(player.speedrunchk8) && isDefined(player.speedrunchk9))
            {
                number = getTime() - player.startTimeSpeedrun;
                iPrintLn("^1"+player.name+" ^7completed The ^6Speedrun Secret^7 in " + realtime(number));
                player.speedrunEnd = true;
                player.startTimeSpeedrun = undefined;
                player notify("speedrun_stop");
                player thread checkpointreset();
            }    
        }
       wait 0.01;
    }
}
speedrunchk()
{
    self notify("speedrun_stop");
    self endon("speedrun_stop");
    self endon("disconnect");
    trig1 = getEnt("speedrun_chk_1", "targetname");
    trig2 = getEnt("speedrun_chk_2", "targetname");
    trig3 = getEnt("speedrun_chk_3", "targetname");
    trig4 = getEnt("speedrun_chk_4", "targetname");
    trig5 = getEnt("speedrun_chk_5", "targetname");
    trig6 = getEnt("speedrun_chk_6", "targetname");
    trig7 = getEnt("speedrun_chk_7", "targetname");
    trig8 = getEnt("speedrun_chk_8", "targetname");
    trig9 = getEnt("speedrun_chk_9", "targetname");
 
    while(1)
    {
        if(!isDefined(self.speedrunchk1) && self isTouching(trig1))
            self.speedrunchk1 = true;
        if(!isDefined(self.speedrunchk2) && self isTouching(trig2))
            self.speedrunchk2 = true;
        if(!isDefined(self.speedrunchk3) && self isTouching(trig3))
            self.speedrunchk3 = true;
        if(!isDefined(self.speedrunchk4) && self isTouching(trig4))
            self.speedrunchk4 = true;
        if(!isDefined(self.speedrunchk5) && self isTouching(trig5))
            self.speedrunchk5 = true;
        if(!isDefined(self.speedrunchk6) && self isTouching(trig6))
            self.speedrunchk6 = true;    
        if(!isDefined(self.speedrunchk7) && self isTouching(trig7))
            self.speedrunchk7 = true;
        if(!isDefined(self.speedrunchk8) && self isTouching(trig8))
            self.speedrunchk8 = true;
        if(!isDefined(self.speedrunchk9) && self isTouching(trig9))
            self.speedrunchk9 = true;            
        wait (0.05);
    }
 
} 
realtime(number)
{
    self endon("disconnect");

    if(number == 999999999)
    {
        playertime = "???";
        return playertime;
    }
 
    seconds = int(number / 1000);
    hours = int(seconds/3600);
    seconds = seconds % 3600;
    minutes = int(seconds/60);
    seconds = seconds % 60;
 
    if(seconds <= 9)
        seconds = "0" + seconds;
    if(minutes <= 9)
        minutes = "0" + minutes;
    if(hours <= 9)
        hours = "0" + hours;
 
     playertime =  "" + hours + ":" + minutes + ":" + seconds;
 
    return playertime;
}
checkpointreset()
{
    self endon("disconnect");

    self.speedrunchk1 = undefined;
    self.speedrunchk2 = undefined;
    self.speedrunchk3 = undefined;
    self.speedrunchk4 = undefined;
    self.speedrunchk5 = undefined;
    self.speedrunchk6 = undefined;
    self.speedrunchk7 = undefined;
    self.speedrunchk8 = undefined;
    self.speedrunchk9 = undefined;

    self.SpeedEnd = undefined;
    self.startTimeSpeedrun = undefined;
}
//////////////teleports inside the ways/////////////////
TeleportInter2()
{
	trig = getEnt("trigger_teleport3", "targetname");
	tele3 = getEnt("origin_teleport3", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele3.origin);
		player setPlayerAngles(tele3.angles);
	}
}
TeleportGay()
{
	trig = getEnt("trigger_teleport5", "targetname");
	tele5 = getEnt("origin_teleport5", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele5.origin);
		player setPlayerAngles(tele5.angles);
	}
}
TeleportGay2()
{
	trig = getEnt("trigger_teleport13", "targetname");
	tele5 = getEnt("origin_teleport5", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele5.origin);
		player setPlayerAngles(tele5.angles);
	}
}
TeleportSpeedrun1()
{
	trig = getEnt("trigger_teleport6", "targetname");
	tele6 = getEnt("origin_teleport6", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele6.origin);
		player setPlayerAngles(tele6.angles);
	}
}
TeleportSpeedrun2()
{
	trig = getEnt("trigger_teleport9", "targetname");
	tele9 = getEnt("origin_teleport9", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele9.origin);
		player setPlayerAngles(tele9.angles);
	}
}
TeleportSpeedrun3()
{
	trig = getEnt("trigger_teleport10", "targetname");
	tele10 = getEnt("origin_teleport10", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele10.origin);
		player setPlayerAngles(tele10.angles);
	}
}
TeleportSpeedrun4()
{
	trig = getEnt("trigger_teleport11", "targetname");
	tele11 = getEnt("origin_teleport11", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele11.origin);
		player setPlayerAngles(tele11.angles);
	}
}
TeleportSpeedrunBonus()
{
	trig = getEnt("trigger_teleportbonus", "targetname");
	tele = getEnt("origin_teleportbonus", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportInterPlus2()
{
	trig = getEnt("trigger_teleport12", "targetname");
	tele12 = getEnt("origin_teleport12", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele12.origin);
		player setPlayerAngles(tele12.angles);
	}
}
TeleportFinalRoom1()
{
	trig = getEnt("trigger_teleport_end1", "targetname");
	tele = getEnt("origin_finalroom", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportFinalRoom2()
{
	trig = getEnt("trigger_teleport_end2", "targetname");
	tele = getEnt("origin_finalroom", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportFinalRoom3()
{
	trig = getEnt("trigger_teleport_end3", "targetname");
	tele = getEnt("origin_finalroom", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportFinalRoom4()
{
	trig = getEnt("trigger_teleport_end4", "targetname");
	tele = getEnt("origin_finalroom", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportFinalRoom5()
{
	trig = getEnt("trigger_teleport_end5", "targetname");
	tele = getEnt("origin_finalroom", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
TeleportFinalRoom6()
{
	trig = getEnt("trigger_teleport_end6", "targetname");
	tele = getEnt("origin_finalroom2", "targetname");
	
	for(;;)
	{
		trig waittill("trigger", player);
		player setOrigin(tele.origin);
		player setPlayerAngles(tele.angles);
	}
}
FinalRoom()
{
	trig = getEnt("finalroom1", "targetname");
	
	while(1)
    {
        trig waittill("trigger", player);
        if(!isdefined(player.finalroom))
        {
			player iPrintLnBold("^7Thank you for playing ^1mp_mosaic^7!");
			wait (5);
            if (isDefined(player))
            {
                player iPrintLn("Thanks to Spirit, Sycotic, Saajmon, Trickshot, Remix, Skazy, Lob, Pain, Steel, Nao & IKOA");
                wait (5);
            }
            if (isDefined(player))
            {
                player iPrintLnBold("Special thanks to ^1Terry^7, ^1Sard^7, ^1Funk^7, ^1Baddy^7, ^1Toxic^7, ^1Alter^7 & ^1Noob^7 for testing and helping");
                player.finalroom = true;
            }
        }      
        wait 0.05;
    }
}
FinalRoom2()
{
	trig = getEnt("finalroom2", "targetname");
	
	while(1)
    {
        trig waittill("trigger", player);
        if(!isdefined(player.finalroom))
        {
			player iPrintLnBold("^7Thank you for playing ^1mp_mosaic^7!");
			wait (5);
            if (isDefined(player))
            {
                player iPrintLn("Thanks to Spirit, Sycotic, Toxic, Saajmon, Trickshot, Remix, Skazy, Lob, Pain, Steel, Nao & IKOA");
                wait (5);
            }
            if (isDefined(player))
            {
                player iPrintLnBold("Special thanks to ^1Terry^7, ^1Sard^7, ^1Funk^7, ^1Alter^7 & ^1Noob^7 for testing and helping");
                player.finalroom = true;
            }
        }      
        wait 0.05;
    }
}
////////////////////////////////////////////////////////////////////////
