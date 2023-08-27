//Map by Arkani (steam: "rextrus")
//Scripts by VC' Blade & Arkani
main()
{
    maps\mp\_load::main();

    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "allies";
    game["defenders"] = "axis";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";
   
    setdvar("env_fog", "0");
    setdvar("r_glowbloomintensity0",".1");
    setdvar("r_glowbloomintensity1",".1");
    setdvar("r_glowskybleedintensity0",".1");
    setdvar("compassmaxrange","1900");
    setdvar( "r_specularcolorscale", "1.86" );
    setdvar("jump_slowdownenable","0");
    setDvar("bg_fallDamageMaxHeight", 9999);
    setDvar("bg_fallDamageMinHeight", 9998);
 
    level.astralglow=(0,0,0);

    thread onPlayerConnect();
    thread wayHuds();
    thread teleporter();
    thread advert();
    thread finish();
    thread vc_logo();
    thread zeez();
    thread creditshit();
    thread training();
    thread training_join();
    thread welcomecreator();
    thread fuck();
    thread hard_sec();
    thread secret_roof2();
    thread artefacts();
}
onPlayerConnect()
{
    level endon("game_ended");
    
    for(;;)
    {
        level waittill("connected", player);
        

        //player setClientDvar("compassmaxrange", "25000");
        wait 20;
    }
}

vc_logo()
{
    logo = getent("vc_logo_inter","targetname");
    logo2 = getent("vc_logo_easy","targetname");
    logo3 = getent("logo_lobby", "targetname");
    logo4 = getent("logo_hard", "targetname");
    logo5 = getent("secret_ogo", "targetname");
    
    while(1){
        logo rotateyaw(360, 10);
        logo2 rotateyaw(360, 10);
        logo3 rotateyaw(360, 10);
        logo4 rotateyaw(360, 10);
        logo5 rotateyaw(360, 10);
        wait 10;
    }
}
advert()
{
    while(1)
    {
        iprintln("Map created by ^5Arkani");
        wait 300+randomint(30);
    }
}
 
wayHuds()
{
    thread lobby(); // spawn
    thread easyway(); //easy_way
    thread interway();//inter_way
    thread hardway();//hard_way - You don't say mf :s
    thread secretway(); // :D :D :D :D :D have fun with finding this shit :D^(it's in the music room ;))
    thread sec_fin_2();

    for(;;)
    {
        level waittill("connected",p);
        p thread user_ondeath();
    }
}

lobby()
{
    trig = getent("spawn", "targetname");

    for(;;)
    {
        trig waittill("trigger",who);
        who.cjWay="";
        who thread lobby_settings();
        wait .25;
        if (isDefined(who))
            who notify("update_ways");
    }
}

lobby_settings()
{
    if(isdefined(self.astralWay) && self.astralWay==true)
        self.astralWay=false;
}
finish()
{
    thread hard_fin();
    thread hard_roof();
	thread easy_fin();
    thread easy_roof();
	thread inter_fin();
    thread inter_roof();
    thread secret_fin();
    thread secret_roof();
}
hard_fin()
{
    trigger = getent("hard_fin", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.hard_fin)
        {
            player.hard_fin = true;
            player.timeend = getTime() - player.timestart;
            player.timeend = calculateTimes(player.timeend);
           iprintln(player.name+" ^7 has finished ^1Hard ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            wait 1;
        }
    }
}
hard_roof()
{
    trigger = getent("hard_roof", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.hard_roof)
        {
            player.hard_roof = true;
            if(!player.hard_fin){
                player.timeend = getTime() - player.timestart;
                player.timeend = calculateTimes(player.timeend);
                iprintln(player.name+" ^7 has finished ^1Hard ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            }
            iprintln(player.name+" ^7 reached the motherducking hard roof.. ^1h^20^30^40^50^6l^7y^8 shieeet");
            wait 1;
        }
    }
}
secret_fin()
{
    trigger = getent("secret_fin", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.secret_fin)
        {
            player.secret_fin = true;
            player.timeend = getTime() - player.timestart;
            player.timeend = calculateTimes(player.timeend);
            iprintln(player.name+" ^7 has finished ^5Secret ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            wait 1;
        }
    }
}
secret_roof()
{
    trigger = getent("secret_roof", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.secret_roof)
        {
            player.secret_roof = true;
            if(!player.secret_roof){
                player.timeend = getTime() - player.timestart;
                player.timeend = calculateTimes(player.timeend);
                iprintln(player.name+" ^7 has finished ^5Secret ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            }
            iprintln(player.name+" ^7 landed on ^5secret ^7roof. niceee");
            wait 1;
        }
    }
}
secret_roof2()
{
    trigger = getent("secret_roof2", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.secret_roof2)
        {
            player.secret_roof2 = true;
            iprintln("g fucking g, "+player.name);
        }

            wait 1;
    }
}


 
////////////////////////////////////EASY WAY////////////////////////////////////
easyWay()
{
	trig = getEnt( "easy_way", "targetname" );

	for(;;)
    {
        trig waittill( "trigger", who );

        if(!isdefined(who.astralWay) || !who.astralWay)
        {
            who.astralWay=true;

	        if(!isdefined(who.easyJoin) || !who.easyJoin)
	        {
                who.timestart = getTime();
	            who.easyJoin=true;
	            who iPrintLnBold( "You chose the ^2Easy^7 way. Good luck!" );
	        }
            who.cjWay="easy";
            wait .25;
            if (isDefined(who))
                who notify("update_ways");
        }
        wait .05;
    }
}
easy_fin()
{
    trigger = getent("easy_fin", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.easy_fin)
        {
            player.easy_fin = true;
            player.timeend = getTime() - player.timestart;
            player.timeend = calculateTimes(player.timeend);
            iprintln(player.name+" ^7 has finished ^2Easy ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            wait 1;
        }
    }
}
easy_roof()
{
    trigger = getent("easy_roof", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.easy_roof)
        {
            player.easy_roof = true;
            if(!player.easy_fin){
                player.timeend = getTime();
                player.fintime = calculateTimes(player.time);
                iprintln(player.name+" ^7 has finished ^2Easy ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            }
            iprintln(player.name+" landed on ^2Easy ^7Way Roof!");
            player.easy_fin = true;
            wait 1;
        }
    }
}
////////////////////////////////////INTER WAY////////////////////////////////////
interWay()
{
	trig = getEnt( "inter_way", "targetname" );

	for(;;)
    {
        trig waittill( "trigger", who );
        if(!isdefined(who.astralWay) || !who.astralWay)
        {
            who.astralWay=true;
            if(!isdefined(who.interJoin) || !who.interJoin)
	        {
	            who.interJoin=true;
                who.timestart = getTime();
	            who iPrintLnBold( "You chose the ^4Intermediate^7 way. Good luck!" );
	        }
            who.cjWay="inter";
            wait .25;
            if (isDefined(who))
                who notify("update_ways");
        }
        wait .05;
    }
}

inter_fin()
{
    trigger = getent("inter_fin", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.inter_fin)
        {
            player.inter_fin = true;
            player.timeend = getTime() - player.timestart;
            player.timeend = calculateTimes(player.timeend);
            iprintln(player.name+" ^7 has finished ^5Inter ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            wait 1;
        }
    }
}
inter_roof()
{
    trigger = getent("inter_roof", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.inter_roof)
        {
            player.inter_roof = true;
            
            if(!player.inter_fin){
                player.timeend = getTime() - player.timestart;
                player.timeend = calculateTimes(player.timeend);
                iprintln(player.name+" ^7 has finished ^5Inter ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            }
            iprintln(player.name+" ^7 landed on ^5Inter ^7Way Roof!");
            player.inter_fin = true;
            wait 1;
        }
    }
}
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////HARD WAY////////////////////////////////////
hardWay()
{
	trig = getEnt( "hard_way", "targetname" );

	for(;;)
    {
        trig waittill( "trigger", who );
        if(!isdefined(who.astralWay) || !who.astralWay)
        {
            who.astralWay=true;
            if(!isdefined(who.hardJoin) || !who.hardJoin)
	        {
	            who.hardJoin=true;
                who.timestart = getTime();
	            who iPrintLnBold( "You chose the ^1Hard^7 way. Good luck!" );
	        }
            who.cjWay="hard";
            wait .25;
            if (isDefined(who))
                who notify("update_ways");
        }
        wait .05;
    }
}
//////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////Sec wayY////////////////////////////////////
secretway()
{
	trig = getEnt( "secretway", "targetname" );

	for(;;)
    {
        trig waittill( "trigger", who );
        if(!isdefined(who.astralWay) || !who.astralWay)
        {
            who.astralWay=true;
            if(!isdefined(who.secretjoin) || !who.secretjoin)
	        {
	            who.secretjoin=true;
                who.timestart = getTime();
	            who iPrintLnBold( "ouh, you found the ^5secret^7 way.\n difficulty is ^2easy^7-^5inter^7. good luck" );
	        }
            who.cjWay="";
            wait .25;
            if (isDefined(who))
                who notify("update_ways");
        }
        wait .05;
    }
}
//////////////////////////////////////////////////////////////////////////////////

calculateTimes(time) {
    fintime = [];
   fintime["min"] = int(time / 1000 / 60);
   fintime["sec"] = int((time - fintime["min"] * 60 * 1000) / 1000);
   if(fintime["sec"] < 10){
        temp = fintime["sec"];
        fintime["sec"] = "0";
        fintime["sec"] += temp;
   }

   fintime["msec"] = int((time - (fintime["min"] * 60 * 1000) - (int(fintime["sec"]) * 1000)));
    return fintime;
}
 
teleporter()
{
    tele=getentarray("teleport","targetname");
    if(isdefined(tele))
    {
        for(i=0;i<tele.size;i++)
            tele[i] thread portMe();
    }
}
portMe()
{
    for(;;)
    {
        self waittill("trigger",who);
        targ=getent(self.target,"targetname");
        who freezecontrols(1);
        who setorigin(targ.origin);
        who setplayerangles(targ.angles);
        wait 0.01;
        if (isDefined(who))
            who freezecontrols(0);
    }
}
///////////////////////////////////////////////////////////////////////////////
 
//following script was written by Blade
welcomecreator()
{
    if(!isdefined(level.creatoron))
        level.creatoron=false;
 
    for(;;)
    {
        level waittill("connected",who);
 		wait 20;
        if (isDefined(who))
            who iprintln("Welcome to ^5Astral");
        wait 2;
        if (isDefined(who))
            who iprintln("Map by ^5Arkani");
    }
}

getnamestring(name)
{
    switch(name)
    {
        case "hard":    name="Hard";            break;
        case "inter":   name="Inter";    break;
        case "easy":    name="Easy";            break;
        default:        name="";                break;
    }
    return name;
}

getcolorstring(color)
{
    switch(color)
    {
        case "hard":    color=(1,0,0);          break;
        case "inter":   color=(0,0,1);          break;
        case "easy":    color=(0,1,0);          break;
        default:        color=(.35,.35,.35);    break;
    }
    return color;
}

user_ondeath()
{
    self waittill("death");

    if(isdefined(self.astralWay) && self.astralWay==true)
        self.astralWay=false;
}

zeez()
{
    trigger = getent("zeez", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.zeez) || !who.zeez)
        {
            who.zeez = true;
            who iprintlnbold("Thanks to ^5ZeeZ^7 for giving me this GAPS!");
            wait 1;
        }
    }
}
creditshit()
{
	thread credit1();
	thread credit2();
	thread credit3();
	thread credit4();
	thread credit5();
	thread credit6();
	thread credit7();

}
credit2()
{
	trigger = getent("credit2", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit2) || !who.credit2)
        {
            who.credit2 = true;
            who iprintlnbold("Credit to Viruz and ^5ZeeZ^7 for giving a lot advices!");
            wait 1;
        }
    }
}
credit1()
{
	trigger = getent("credit1", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit1) || !who.credit1)
        {
            who.credit1 = true;
            who iprintlnbold("Thanks to ^5Noob^7Aim(v1 :D) and Moug for helping me with ^1hard^7! ^5:^7D");
            wait 1;
        }
    }
}
sec_fin_2()
{
	trigger = getent("secret_fin2", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.secret_fin2) || !who.secret_fin2)
        {
            who.secret_fin2 = true;
            who iprintlnbold("nice, but that's not the roof. :P");
            wait 1;
        }
    }
}
training_join()
{
	trigger = getent("training_orig_", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.training_orig_) || !who.training_orig_)
        {
            who.training_orig_ = true;
            who iprintlnbold("Welcome to the training path \n This way is the ^2easiest^7 on this map!\nHave fun! (125 FPS only!)");
            wait 1;
        }
    }
}
training()
{
	trigger = getent("training", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.training) || !who.training)
        {
            who.training = true;
            who iprintlnbold("You have finished the training path!\n Now swing your ^1sexy ass^7 into the ^2Easy^7 Way!! :D");
            wait 1;
        }
    }
}
credit3()
{
	trigger = getent("credit3", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit3) || !who.credit3)
        {
            who.credit3 = true;
            who iprintlnbold("Obviesly thanks to all other testers for your feedback!^1 :D");
            wait 1;
        }
    }
}
credit4()
{
	trigger = getent("credit4", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit4) || !who.credit4)
        {
            who.credit4 = true;
            who iprintlnbold("ezpz scripts by VC' Blade, thanks!");
            wait 1;
        }
    }
}
hard_sec()
{
	trigger = getent("hard_sec", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.hard_sec) || !who.hard_sec)
        {
            who.hard_sec = true;
            who iprintlnbold("gl hf :)");
            wait 1;
        }
    }
}
credit5()
{
	trigger = getent("credit5", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit5) || !who.credit5)
        {
            who.credit5 = true;
            who iprintlnbold("and also thanks to ^2Alter^7Ego and again ^5Noob^7Aim for making walkthroughs! :D");
            wait 1;
        }
    }
}
sec_mess()
{
	trigger = getent("secret_hard_message", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.secret_hard_message) || !who.secret_hard_message)
        {
            who.secret_hard_message = true;
            iprintln(who.name+" is ^1Pro^7!");
            wait 1;
        }
    }
}
fuck()
{
	trigger = getent("fuck", "targetname");

	trigger waittill("trigger", who);

	trigger hide();
}
credit6()
{
	trigger = getent("credit6", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit6) || !who.credit6)
        {
            who.credit6 = true;
            iprintln("^5A^7rkani > ^5"+who.name);
            wait 1;
        }
    }
}
credit7()
{
	trigger = getent("credit7", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(!isDefined(who.credit7) || !who.credit7)
        {
            who.credit7 = true;
            iprintln("Thanks for playing mp_^5Astral^7!\nMap by ^5Arkani");
            wait 1;
        }
    }
}

artefacts()
{
    if(!isdefined(level.artefact1))
        level.artefact1=false;
    if(!isdefined(level.artefact2))
        level.artefact2=false;
    if(!isdefined(level.artefact3))
        level.artefact3=false;
    if(!isdefined(level.sec_orbit))
        level.sec_orbit=false;

    thread artefact1();
    thread artefact2();
    thread artefact3();
    thread allArts();
}

artefact1()
{
    locs=[];
    locs[0]=getent("art_origin1","targetname");
    locs[1]=getent("art_origin2","targetname");

    trigs=getent("art1_trig","targetname");
    artefact=getent("art1","targetname");

    
    random=randomint(2);
    artefact moveto(locs[random].origin, 1);
    trigs enableLinkTo();
    trigs linkTo(artefact);
    trigs waittill("trigger",who);

    artefact delete();
    trigs delete();

    iprintln("^5"+who.name+"^7 found an ^5Orbit^7!");
    level.artefact1 = true;
}

artefact2()
{
    locs=[];
    locs[0]=getent("art_origin3","targetname");
    locs[1]=getent("art_origin4","targetname");

    trigs=getent("art2_trig","targetname");
    artefact=getent("art2","targetname");

    
    random=randomint(2);
    artefact moveto(locs[random].origin,.1);
    trigs enableLinkTo();
    trigs linkTo(artefact);
    trigs waittill("trigger",who);

    artefact delete();
    trigs delete();

    iprintln("^5"+who.name+"^7 found an ^5Orbit^7!");
    level.artefact2 = true;
}

artefact3()
{
    locs=[];
    locs[0]=getent("art_origin5","targetname");
    locs[1]=getent("art_origin6","targetname");

    trigs=getent("art3_trig","targetname");
    artefact=getent("art3","targetname");
    
    random=randomint(2);
    artefact moveto(locs[random].origin, 1);
    trigs enableLinkTo();
    trigs linkTo(artefact);
    trigs waittill("trigger",who);

    artefact delete();
    trigs delete();

    iprintln("^5"+who.name+"^7 found an ^5Orbit^7!");
   	level.artefact3 = true;
}
allArts()
{
	brush = getent("sec_brush","targetname");
	while(1)
	{
		if(level.artefact1 == true && level.artefact2 == true && level.artefact3 == true && level.sec_orbit==false)
		{
			brush notsolid();
			iPrintLn("sth changed..");
			wait 2;
			level.sec_orbit=true;
		}
		wait 1;
	}
}
