main()
{  
    maps\mp\funk_music::main();
    maps\mp\_load::main();
 
    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "axis";
    game["defenders"] = "allies";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";
 
    setdvar("r_specularcolorscale","9");
    setdvar("r_glowbloomintensity0",".25");
    setdvar("r_glowbloomintensity1",".25");
    setdvar("r_glowskybleedintensity0",".3");
    setdvar("compassmaxrange","1800");
   
    //Threads
    thread connectListener();
    thread fx();
    thread secretroom();
    thread easysecret();
    thread intersecret();
    thread hardsecret();
    thread gravsecret();
    thread creatorspam();
    thread pawz();
	thread finland();
    thread funendtele();
	thread bhopsecret();
	thread hardwt();
   
    thread pipes1();
    thread pipes2();
    thread secretele();
 
    //Timers
    thread easy_timer_start();
    thread easy_timer_end();
    thread inter_timer_start();
    thread inter_timer_end();
    thread hard_timer_start();
    thread hard_timer_end();
    thread test_timer_start();
    thread test_timer_end();
    thread fun_timer_start();
    thread fun_timer_end();
    thread funky_timer_start();
    thread funky_timer_end();
 
    //Pass the entity targetname, true if you want all to see (false if just player), and text you want to display (entity, showAll, message)
    thread playerMessage("3xpclan", false, "^5<3 ^73xP' Clan ^5<3");
    thread playerMessage("creator", false, "Map created by ^1Funk");
    thread playerMessage("cocreator", false, "Co-Creators: \n^3Stagox \n^3Skorpiik");
    thread playerMessage("drizz", false, "'\'Noodles are nicer when boiled'\'\n - Drizzjeh");
    thread playerMessage("treax", false, "'\'Noob is gay'\'\n - Treaxer");
    thread playerMessage("toxic", false, "'\'Tits getting big lately'\'\n - Toxic");
    thread playerMessage("credits1", false, "Thank you to ^2Noob^7, ^2Skazy^7, ^2Boat^7, ^2BUSH1DO ^7and ^2Ultimate ^7for all of their mapping and scripting help!");
    thread playerMessage("credits2", false, "Thank you to ^4NoobAim^7, ^4Moug^7, ^4Drizzjeh ^7and ^4Treaxer ^7for their constant testing!");
    thread playerMessage("credits3", false, "Special thank you to ^6Drizzjeh ^7for making the ^4Intermediate ^7way Walkthrough!");
    thread playerMessage("credits4", false, "Special thank you to ^6NoobAim ^7for performing the ^1Hard ^7way Walkthrough!");
    thread playerMessage("credits5", false, "Thanks to all other testers for their feedback!");
    thread playerMessage("mapinfo", false, "^1mp_sierra ^7created by ^1Funk^7\nv1.1\nReleased in 6.8.2018");
    thread playerMessage("hawk", false, "^5hawk pls");
    thread playerMessage("frisbee", false, "^5frisbee <3");
    thread playerMessage("funky1", false, "^7Originally made in 2016, I hope you enjoyed!");
    thread playerMessage("funky2", false, "^7Rest in Pepperonis ^5mp_funky^7!");
	thread playerMessage("jack1", false, "^7Only Jack0p could land this...");
	thread playerMessage("jack2", false, "^7Oh it's you... Welcome, Jack0p!");
 
    //Setup teleporters
    teles = GetEntArray("teleport", "targetname");
    for(i = 0; i < teles.size; i++)
        teles[i] thread teleporter();
 
    //Setup elevator
    level.eleReady = true;
    eles = GetEntArray("trigger_armoryele", "targetname");
    for(i = 0; i < eles.size; i++)
        eles[i] thread armoryele();
 
    //Button/Key stuff for secrets
    level.buttons_count = [];
    level.buttons_count["^6BHOP^7"] = 0;
    level.buttons_count["^2EASY^7"] = 0;
    level.buttons_count["^4INTERMEDIATE^7"] = 0;
    level.buttons_count["^1HARD^7"] = 0;
    level.buttons_count["^3Gold Bar^7"] = 0;
 
    level.buttons_arr = [];
    level.buttons_arr["^6BHOP^7"] = GetEntArray("button","targetname");
    level.buttons_arr["^2EASY^7"] = GetEntArray("easy_button","targetname");
    level.buttons_arr["^4INTERMEDIATE^7"] = GetEntArray("inter_button","targetname");
    level.buttons_arr["^1HARD^7"] = GetEntArray("hard_button","targetname");
    level.buttons_arr["^3Gold Bar^7"] = GetEntArray("grav_button","targetname");
 
    setupKeys("^6BHOP^7");
    setupKeys("^2EASY^7");
    setupKeys("^4INTERMEDIATE^7");
    setupKeys("^1HARD^7");
    setupKeys("^3Gold Bar^7");
	
	//Setup bestTime for testway
    level.bestTime = undefined;
    level.bestName = undefined;
 
    //FX Stuff
    level._effect["blue_light"] = loadfx("codjumper/blue_light");
    level._effect["red_light"] = loadfx("codjumper/red_light");
    level._effect["green_light"] = loadfx("codjumper/green_light");
    level._effect["purple_light"] = loadfx("codjumper/purple_light");
    level._effect["yellow_light"] = loadfx("codjumper/yellow_light");
    level._effect["white_light"] = loadfx("codjumper/white_light");
    level._effect["cyan_light"] = loadfx("codjumper/cyan_light");
   
    wait 1;
    if(isDefined(game) && isDefined(game["music"]) && isDefined(game["music"]["suspense"]))
        for(i = 0;i < game["music"]["suspense"].size;i++)
            game["music"]["suspense"][i] = "null";
   
} //end Main
 
 
//Called for every player who connects, thread onPlayerSpawned()
connectListener()
{
    level endon("game_ended");
    while (1) {
        level waittill("connected", player);
        player.messageDone = undefined;
        player thread onPlayerSpawned();
        player thread resetCPs();
    }
}
//called from connectListener
onPlayerSpawned() {
    self endon("disconnect");
    while (1) {
        self waittill("spawned_player");
        self iprintln("Welcome to mp_sierra by Funk. Co-creators: Stagox and Skorpiik.");
        self iprintln("Special thanks to Drizzjeh, Noob, Skazy, Noobaim and 3xP' Clan. Have fun!");
    }
}
 
//Buttons/keys for secrets
setupKeys(route) {
    for(i = 0; i < level.buttons_arr[route].size; i++)
        level.buttons_arr[route][i] thread trigFinder(route);
}
 
trigFinder(route){
    found = false;
    while(1){
        self waittill ("trigger", player);
 
        //if bhop route, teleport to 'auto15'
        target = getent("auto15", "targetname");
        if(route=="^6BHOP^7") {
            player setorigin(target.origin);
            player setplayerangles(target.angles);
        }
 
        if(!found)
            thread trigFound(route);
 
        found = true;
    }
}
 
trigFound(route){
    level.buttons_count[route]++;
    IPrintLn(level.buttons_count[route] + " of " + level.buttons_arr[route].size + " collectables found for " + route + " secret!");
}
 
 
secretroom() {
 trig = getEnt("secretroom", "targetname");
 object = getent("secretdoor","targetname");
 
 for(;;) {
    trig waittill ("trigger", player);
 
    if(level.buttons_count["^6BHOP^7"] == 10) {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^7All collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^2Access Granted");
        wait(1);
        object movez(-192, 3, 1, 2);
        object waittill("movedone");
        trig delete();
    }
    else {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold ("^7Only ^6" + level.buttons_count["^6BHOP^7"] + "/10 ^7collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^1Access Denied");
    }
 }
}
 
easysecret() {
 trig = getEnt("easytrigger", "targetname");
 end = getEnt ("auto18", "targetname");
 for(;;) {
    trig waittill ("trigger", player);
 
    if(level.buttons_count["^2EASY^7"] == 5) {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^7All collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^2Access Granted");
        wait(1);      
        if (isDefined(player))
        {
            player SetOrigin(end.origin);
            player SetPlayerAngles( end.angles );
        }
    }
    else {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold ("^7Only ^6" + level.buttons_count["^2EASY^7"] + "/5 ^7collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^1Access Denied");
    }
 }
}
 
intersecret() {
 trig = getEnt("intertrigger", "targetname");
 end = getEnt ("auto21", "targetname");
 for(;;) {
    trig waittill ("trigger", player);
 
    if(level.buttons_count["^4INTERMEDIATE^7"] == 5) {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^7All collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^2Access Granted");
        wait(1);
        if (isDefined(player))
        {
            player SetOrigin(end.origin);
            player SetPlayerAngles( end.angles );
        }
    }
    else {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold ("^7Only ^6" + level.buttons_count["^4INTERMEDIATE^7"] + "/5 ^7collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^1Access Denied");
    }
 }
}
 
hardsecret() {
 trig = getEnt("hardtrigger", "targetname");
 object = getent("harddoor","targetname");
 
 for(;;) {
    trig waittill ("trigger", player);
 
    if(level.buttons_count["^1HARD^7"] == 5) {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^7All collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^2Access Granted");
        wait(1);
        object movez(184, 3, 1, 2);
        object waittill("movedone");
        trig delete();
    }
    else {
        player IPrintLnBold("^7Checking collectable status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold ("^7Only ^6" + level.buttons_count["^1HARD^7"] + "/5 ^7collectables found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^1Access Denied");
    }
 }
}
 
gravsecret() {
 trig = getEnt("gravtrigger", "targetname");
 end = getEnt ("auto19", "targetname");
 for(;;) {
    trig waittill ("trigger", player);
 
    if(level.buttons_count["^3Gold Bar^7"] == 3) {
        player IPrintLnBold("^7Checking ^3Gold Bar ^7status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^7All ^3Gold Bars ^7found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^2Access Granted");
        wait(1);    
        if (isDefined(player))
        {
            player SetOrigin(end.origin);
            player SetPlayerAngles( end.angles );
        }
    }
    else {
        player IPrintLnBold("^7Checking ^3Gold Bar ^7status...");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold ("^7Only ^6" + level.buttons_count["^3Gold Bar^7"] + "/3 ^3Gold Bars ^7found!");
        wait(1);
        if (isDefined(player))
            player IPrintLnBold("^1Access Denied");
    }
 }
}
 
creatorspam()
{
    while(1)
    {
        wait (900);
        iPrintLn("^7Map created by ^1Funk");
        wait (10);
        iPrintLn("^7Co-Creators:\n^3Stagox\n^3Skorpiik");
    }
}
 
teleporter()
{
    target = getent(self.target, "targetname");
    while(true)
    {
        self waittill("trigger", player);
        player setorigin(target.origin);
        player setplayerangles(target.angles);
 
        if(self.target == "shrinetp1_end")
            iPrintln(player.name + " ^6<3<3<3 ^7LEGENDS ^6<3<3<3");
 
        wait 0.1;
    }
}
 
 
playerMessage(entity, showAll, message)
{
     trigger = getEnt (entity, "targetname");
     while(1)
    {
        trigger waittill ("trigger", player);
        if(showAll)
        {
            iPrintln(message);
            wait(30);
        }
        else
        {
            player iPrintlnBold(message);
            wait(5);
        }
    }
}
 
youChose(way){
    self endon("disconnect");
    self IPrintLn("You chose " + way);
    self.spamblock = 1;
    wait 2; //time to wait before showing text again
    self.spamblock = undefined;
}
 
pawz()
{
     trigger = getEnt ("pawz", "targetname");
     while(1)
    {
        trigger waittill ("trigger", player);
        player iPrintlnBold("^6" + player.name + " ^7> Pawz");
        wait(30);
    }
}

finland()
{
    trigger = getEnt ("finland", "targetname");
    end = getEnt ("auto24", "targetname");
    while(1)
        {
        trigger waittill ("trigger", player);          
        player SetOrigin(end.origin);
        player SetPlayerAngles( end.angles );
		player IPrintLnBold("^4T^7O^4R^7I^4L^7L^4E^7!");
    }
}
 
funendtele()
{
    trigger = getEnt ("fun_end", "targetname");
    end = getEnt ("tele4_end", "targetname");
    while(1)
        {
        trigger waittill ("trigger", player);          
        player SetOrigin(end.origin);
        player SetPlayerAngles( end.angles );
    }
}
 
pipes1()
{
    trigger = getent("trigger_pipes","targetname");
    object = getent("pipes1","targetname");
    {
        trigger waittill ("trigger" , player);
        object movex(56, 3, 1, 2);
        object waittill("movedone");
    }
}
 
pipes2()
{
    trigger = getent("trigger_pipes","targetname");
    object = getent("pipes2","targetname");
    {
        trigger waittill ("trigger" , player);
        object movex(-56, 3, 1, 2);
        object waittill("movedone");
        iPrintln("The door to the ^6SECRET ^7area is now open!");
        wait(1);
        iprintln("Access it from the END room!");
    }
}
 
armoryele()
{
    object = getent("armoryele","targetname");
    while(1)
    {
        self waittill("trigger" , player);
        if(level.eleReady) {
            level.eleReady = false;
            wait(1);
            object movez(-444, 4, 1, 2);
            object waittill("movedone");
            wait(3);
            object movez(444, 4, 1, 2);
            object waittill("movedone");
            wait(1);
            level.eleReady = true;
        }
    }
}
 
secretele()
{
    trigger = getent("trigger_secretele","targetname");
    object = getent("secretele","targetname");
    while(1)
    {
        trigger waittill ("trigger" , player);
        wait(2);
        object movez(608, 5, 1, 2);
        object waittill("movedone");
        wait(2);
        object movez(-608, 5, 1, 2);
        object waittill("movedone");
        wait(1);
    }
}
 
 
//TIMERS
resetCPs() {
    self.inRun = true;
    self.easyCheck1 = false;
    self.easyCheck2 = false;
    self.easyCheck3 = false;
    self.interCheck1 = false;
    self.interCheck2 = false;
    self.interCheck3 = false;
    self.hardCheck1 = false;
    self.hardCheck2 = false;
    self.hardCheck3 = false;
    self.testCheck1 = false;
    self.testCheck2 = false;
    self.testCheck3 = false;
    self.funCheck1 = false;
    self.funCheck2 = false;
    self.funCheck3 = false;
    self.funkyCheck1 = false;
    self.funkyCheck2 = false;
    self.funkyCheck3 = false;
}
 
easy_timer_start()
{
    trig = getEnt("easy_start", "targetname");
    for(;;)
    {
        trig waittill("trigger", who);
        who thread resetCPs();
        who thread easyCP();
        who.timestartEasy = getTime();
 
        if(!isDefined(who.spamblock))
            who thread youChose("^2EASY ^7way!");
    }
}
easyCP() {
    self endon("finished");
    self endon("disconnect");
    a = getEnt("checkpoint_easy1", "targetname");
    b = getEnt("checkpoint_easy2", "targetname");
    c = getEnt("checkpoint_easy3", "targetname");
 
    while(1)
    {
        if(self isTouching(a))
            self.easyCheck1 = true;
        if(self isTouching(b))
           self.easyCheck2 = true;
        if(self isTouching(c))
            self.easyCheck3 = true;
        wait 0.05;
    }
}
easy_timer_end()
{
    trigger = getent("easy_end", "targetname");
    for(;;)
    {
        trigger waittill("trigger", who);
        if(who.inRun == true && who.easyCheck1 == true && who.easyCheck2 == true && who.easyCheck3 == true)
        {
            who.inRun = false;
            who.timeend = getTime() - who.timestartEasy;
            who.timeend = calculateTimes(who.timeend);
            iprintln(who.name+" ^7has finished ^2EASY ^7way in ^6" + who.timeend["min"] + ":" +who.timeend["sec"] + "^7!");
            who notify("finished");
         }
    }
}
 
 
 
inter_timer_start()
{
    trig = getEnt( "inter_start", "targetname" );
    for(;;)
    {
        trig waittill( "trigger", who );
        who thread resetCPs();
        who thread interCP();
        who.timestartInter = getTime();
 
        if(!isDefined(who.spamblock))
            who thread youChose("^4INTERMEDIATE ^7way!");
    }
}
interCP() {
    self endon("finished");
    self endon("disconnect");
    a = getEnt("checkpoint_inter1", "targetname");
    b = getEnt("checkpoint_inter2", "targetname");
    c = getEnt("checkpoint_inter3", "targetname");
 
    while(1)
    {
        if(self isTouching(a))
            self.interCheck1 = true;
        if(self isTouching(b))
           self.interCheck2 = true;
        if(self isTouching(c))
            self.interCheck3 = true;
        wait 0.05;
    }
}
inter_timer_end()
{
    trigger = getent("inter_end", "targetname");
    for(;;)
    {
        trigger waittill("trigger", who);
        if(who.inRun == true && who.interCheck1 == true && who.interCheck2 == true && who.interCheck3 == true)
        {
            who.inRun = false;
            who.timeend = getTime() - who.timestartInter;
            who.timeend = calculateTimes(who.timeend);
            iprintln(who.name+" ^7has finished ^4INTERMEDIATE ^7way in ^6" + who.timeend["min"] + ":" +who.timeend["sec"] + "^7!");
            who notify("finished");
         }
    }
}
 
 
hard_timer_start()
{
    trig = getEnt( "hard_start", "targetname" );
 
    for(;;)
    {
        trig waittill( "trigger", who );
        who thread resetCPs();
        who thread hardCP();
        who.timestartHard = getTime();
 
        if(!isDefined(who.spamblock))
            who thread youChose("^1HARD ^7way!");
    }
}
hardCP() {
    self endon("finished");
    self endon("disconnect");
    a = getEnt("checkpoint_hard1", "targetname");
    b = getEnt("checkpoint_hard2", "targetname");
    c = getEnt("checkpoint_hard3", "targetname");
 
    while(1)
    {
        if(self isTouching(a))
            self.hardCheck1 = true;
        if(self isTouching(b))
           self.hardCheck2 = true;
        if(self isTouching(c))
            self.hardCheck3 = true;
        wait 0.05;
    }
}
hard_timer_end()
{
    trigger = getent("hard_end", "targetname");
    for(;;)
    {
        trigger waittill("trigger", who);
        if(who.inRun == true && who.hardCheck1 == true && who.hardCheck2 == true && who.hardCheck3 == true)
        {
            who.inRun = false;
            who.timeend = getTime() - who.timestartHard;
            who.timeend = calculateTimes(who.timeend);
            iprintln(who.name+" ^7has finished ^1HARD ^7way in ^6" + who.timeend["min"] + ":" +who.timeend["sec"] + "^7!");
            who notify("finished");
         }
    }
}
 
test_timer_start()
{
    trig = getEnt( "test_start", "targetname" );
 
    for(;;)
    {
        trig waittill( "trigger", who );
        who thread resetCPs();
        who thread testCP();
        who.timestartTest = getTime();
 
        if(!isDefined(who.spamblock))
            who thread youChose("^3TEST ^7way!");
    }
}
testCP() {
    self endon("finished");
    self endon("disconnect");
    a = getEnt("checkpoint_test1", "targetname");
    b = getEnt("checkpoint_test2", "targetname");
    c = getEnt("checkpoint_test3", "targetname");
 
    while(1)
    {
        if(self isTouching(a))
            self.testCheck1 = true;
        if(self isTouching(b))
           self.testCheck2 = true;
        if(self isTouching(c))
            self.testCheck3 = true;
        wait 0.05;
    }
}
test_timer_end()
{
    trigger = getent("test_end", "targetname");
    for(;;)
    {
        trigger waittill("trigger", who);
        if(who.inRun == true && who.testCheck1 == true && who.testCheck2 == true && who.testCheck3 == true)
        {
            who.inRun = false;
            who.timeend = getTime() - who.timestartTest;
 
            //Best run
            if(!isDefined(level.bestTime) || who.timeend < level.bestTime) {
                level.bestTime = who.timeend;
                level.bestName = who.name;
            }
 
            //Print best run (this game) for player only
            tempStringArray = calculateTimes(level.bestTime);
            iprintln("Best ^5" + tempStringArray["min"] + ":" + tempStringArray["sec"] + "^7 by ^5" + level.bestName);
           
            //Print for everyone
            who.timeend = calculateTimes(who.timeend);
            iprintln(who.name+" ^7has finished ^3TEST ^7way in ^6" + who.timeend["min"] + ":" +who.timeend["sec"] + "^7!");
 
            who notify("finished");
         }
    }
}
 
fun_timer_start()
{
    trig = getEnt( "fun_start", "targetname" );
 
    for(;;)
    {
        trig waittill( "trigger", who );
        who thread resetCPs();
        who thread funCP();
        who.timestartFun = getTime();
 
        if(!isDefined(who.spamblock))
            who thread youChose("^3FUN ^7room!");
    }
}
funCP() {
    self endon("finished");
    self endon("disconnect");
    a = getEnt("checkpoint_fun1", "targetname");
    b = getEnt("checkpoint_fun2", "targetname");
    c = getEnt("checkpoint_fun3", "targetname");
 
    while(1)
    {
        if(self isTouching(a))
            self.funCheck1 = true;
        if(self isTouching(b))
           self.funCheck2 = true;
        if(self isTouching(c))
            self.funCheck3 = true;
        wait 0.05;
    }
}
fun_timer_end()
{
    trigger = getent("fun_end", "targetname");
    for(;;)
    {
        trigger waittill("trigger", who);
        if(who.inRun == true && who.funCheck1 == true && who.funCheck2 == true && who.funCheck3 == true)
        {
            who.inRun = false;
            who.timeend = getTime() - who.timestartFun;
            who.timeend = calculateTimes(who.timeend);
            iprintln(who.name+" ^7has reached the top of ^3FUN ^7room in ^6" + who.timeend["min"] + ":" +who.timeend["sec"] + "^7!");
            who notify("finished");
         }
    }
}
 
funky_timer_start()
{
    trig = getEnt( "funky_start", "targetname" );
 
    for(;;)
    {
        trig waittill( "trigger", who );
        who thread resetCPs();
        who thread funkyCP();
        who.timestartFunky = getTime();
 
        if(!isDefined(who.spamblock))
            who thread youChose("^5mp_funky SECRET ^7way!");
    }
}
funkyCP() {
    self endon("finished");
    self endon("disconnect");
    a = getEnt("checkpoint_funky1", "targetname");
    b = getEnt("checkpoint_funky2", "targetname");
    c = getEnt("checkpoint_funky3", "targetname");
 
    while(1)
    {
        if(self isTouching(a))
            self.funkyCheck1 = true;
        if(self isTouching(b))
           self.funkyCheck2 = true;
        if(self isTouching(c))
            self.funkyCheck3 = true;
        wait 0.05;
    }
}
funky_timer_end()
{
    trigger = getent("funky_end", "targetname");
    for(;;)
    {
        trigger waittill("trigger", who);
        if(who.inRun == true && who.funkyCheck1 == true && who.funkyCheck2 == true && who.funkyCheck3 == true)
        {
            who.inRun = false;
            who.timeend = getTime() - who.timestartFunky;
            who.timeend = calculateTimes(who.timeend);
            iprintln(who.name+" ^7has finished ^5mp_funky SECRET ^7way in ^6" + who.timeend["min"] + ":" +who.timeend["sec"] + "^7!");
            who notify("finished");
         }
    }
}
 
//calculateTimes script by Fr33g !t
calculateTimes(time) {
    fintime = [];
    fintime["min"] = int(time / 1000 / 60);
    fintime["sec"] = int((time - fintime["min"] * 60 * 1000) / 1000);
 
    if(fintime["sec"] < 10){
        temp = fintime["sec"];
        fintime["sec"] = "0" + temp; //Convert to string for a leading zero
    }
 
    fintime["msec"] = int((time - (fintime["min"] * 60 * 1000) - (int(fintime["sec"]) * 1000)));
 
    return fintime;
}
 
 
//FX Stuff
triggerCustomFX(fxid, origin, angle, delay){
    wait 0.05;
    if(delay > 0) wait delay;
 
    up = AnglesToUp(angle);
    forward = AnglesToForward(angle);
 
    level.fx = SpawnFX(level._effect[fxid], origin, forward, up);
    TriggerFX(level.fx);
}

bhopsecret()
{
	 trigger = getEnt ("bhopsecret", "targetname");
	 while(1)
	{
		trigger waittill ("trigger", player);
		player iPrintln("^7You chose ^6Bhop SECRET ^7way!");
		wait(5);
	}
}

hardwt()
{
	 trigger = getEnt ("hardwt", "targetname");
	 while(1)
	{
		trigger waittill ("trigger", player);
		player iPrintlnBold("^7Check out the ^1Hard ^7way walkthrough if you are having trouble!");
		wait(5);
	}
}
 
fx()
{
    triggerCustomFX( "blue_light", (6548, 4096, -1184), (270,0,0), 0);
    triggerCustomFX( "blue_light", (6548, 3648, -1184), (270,0,0), 0);
    triggerCustomFX( "blue_light", (946, 96, 484), (270,0,0), 0);
    triggerCustomFX( "blue_light", (946, -96, 484), (270,0,0), 0);
    triggerCustomFX( "blue_light", (24128, 6144, -9342), (270,0,0), 0);
    triggerCustomFX( "blue_light", (13476, -21295, -13336), (270,0,0), 0);
    triggerCustomFX( "blue_light", (-133, -64, -195), (270,0,0), 0);
    triggerCustomFX( "blue_light", (-133, 64, -195), (270,0,0), 0);
   
    triggerCustomFX( "red_light", (1352, 7408, -2420), (270,0,0), 0);
    triggerCustomFX( "red_light", (1352, 6768, -2420), (270,0,0), 0);
    triggerCustomFX( "red_light", (1106, 96, 1028), (270,0,0), 0);
    triggerCustomFX( "red_light", (1106, -96, 1028), (270,0,0), 0);
    triggerCustomFX( "red_light", (-6560, 12896, -6014), (270,0,0), 0);
    triggerCustomFX( "red_light", (-7296, 12160, -6014), (270,0,0), 0);
    triggerCustomFX( "red_light", (-8192, 18336, -6782), (270,0,0), 0);
    triggerCustomFX( "red_light", (-13884, 21184, -7696), (270,0,0), 0);
    triggerCustomFX( "red_light", (-13952, 21248, -7696), (270,0,0), 0);
    triggerCustomFX( "red_light", (-13472, 26208, -7230), (270,0,0), 0);
    triggerCustomFX( "red_light", (-11756, 26924, -10366), (270,0,0), 0);
    triggerCustomFX( "red_light", (-6336, 28288, -11198), (270,0,0), 0);
    triggerCustomFX( "red_light", (-6372, 28512, -11296), (270,0,0), 0);
    triggerCustomFX( "red_light", (-6372, 28576, -11296), (270,0,0), 0);
    triggerCustomFX( "red_light", (14464, 7472, -21310), (270,0,0), 0);
    triggerCustomFX( "red_light", (14064, 7760, -21758), (270,0,0), 0);
    triggerCustomFX( "red_light", (19768, 20248, -19646), (270,0,0), 0);
    triggerCustomFX( "red_light", (20016, 20288, -19262), (270,0,0), 0);
	triggerCustomFX( "red_light", (8203, -3200, 616), (270,0,0), 0);
   
    triggerCustomFX( "green_light", (786, 96, 100), (270,0,0), 0);
    triggerCustomFX( "green_light", (786, -96, 100), (270,0,0), 0);
    triggerCustomFX( "green_light", (1508, -256, 836), (270,0,0), 0);
    triggerCustomFX( "green_light", (-498, -309, 38), (270,0,0), 0);
    triggerCustomFX( "green_light", (1020, 376, 2146), (270,0,0), 0);
    triggerCustomFX( "green_light", (-288, -286, 2624), (270,0,0), 0);
    triggerCustomFX( "green_light", (462, 106, 2160), (270,0,0), 0);
    triggerCustomFX( "green_light", (608, 88, 2146), (270,0,0), 0);
    triggerCustomFX( "green_light", (492, -710, 2000), (270,0,0), 0);
    triggerCustomFX( "green_light", (702, 0, 1701), (270,0,0), 0);
    triggerCustomFX( "green_light", (7653, -7661, -23383), (270,0,0), 0);
    triggerCustomFX( "green_light", (7550, -4896, -24072), (270,0,0), 0);
    triggerCustomFX( "green_light", (7872, -5340, -24072), (270,0,0), 0);
	triggerCustomFX( "green_light", (8200, -3425, 616), (270,0,0), 0);
   
    triggerCustomFX( "purple_light", (-504, -128, 1344), (270,0,0), 0);
    triggerCustomFX( "purple_light", (-504, 128, 1344), (270,0,0), 0);
    triggerCustomFX( "purple_light", (68, 336, 2928), (270,0,0), 0);
    triggerCustomFX( "purple_light", (68, 544, 2928), (270,0,0), 0);
    triggerCustomFX( "purple_light", (2006, -5076, -1264), (270,0,0), 0);
    triggerCustomFX( "purple_light", (2038, -5076, -1264), (270,0,0), 0);
    triggerCustomFX( "purple_light", (2070, -5076, -1264), (270,0,0), 0);
    triggerCustomFX( "purple_light", (8160, -8032, -6462), (270,0,0), 0);
    triggerCustomFX( "purple_light", (8160, -9376, -6462), (270,0,0), 0);
    triggerCustomFX( "purple_light", (3232, 7568, -3742), (270,0,0), 0);
    triggerCustomFX( "purple_light", (3424, 7568, -3742), (270,0,0), 0);
	triggerCustomFX( "purple_light", (7720, -3427, 616), (270,0,0), 0);
   
    triggerCustomFX( "yellow_light", (-360, -1020, 200), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-216, -1020, 200), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-360, 1020, 200), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-216, 1020, 200), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-119, -327, 2198), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (1248, 544, 848), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (1248, 576, 848), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (1248, 608, 848), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-9568, -7876, -5904), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-9532, -7840, -5904), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-11484, -7808, -5792), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-11520, -7772, -5792), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-10052, -6624, -5488), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-10016, -6660, -5488), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-11240, -4772, -5912), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-12080, -5228, -5520), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-12044, -5264, -5520), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-15676, -7232, -7040), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-15484, -8508, -6544), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-15620, -8640, -6544), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-15744, -8764, -7040), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-15876, -8896, -7040), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-16192, -6724, -6384), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-16972, -5524, -7484), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-16324, -5248, -6304), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-19904, -2788, -6544), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-22560, -5884, -8032), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-22524, -5920, -8032), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-24800, -2596, -8632), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-25540, -320, -8544), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-25504, -356, -8544), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-24500, 864, -8392), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-24464, 828, -8392), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-22944, 1060, -8352), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (-19799, 352, -9904), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (7192, -7664, -23403), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (4608, 18944, -14975), (270,0,0), 0);
    triggerCustomFX( "yellow_light", (1780, -9, 12054), (270,0,0), 0);
	triggerCustomFX( "yellow_light", (7976, -3427, 616), (270,0,0), 0);
   
    triggerCustomFX( "white_light", (2688, 3968, 268), (270,0,0), 0);  
    triggerCustomFX( "white_light", (1018, -343, 2146), (270,0,0), 0);
    triggerCustomFX( "white_light", (-88, 0, -282), (270,0,0), 0);
    triggerCustomFX( "white_light", (-84, 313, 6), (270,0,0), 0);
 
    triggerCustomFX( "cyan_light", (1248, -528, 848), (270,0,0), 0);
    triggerCustomFX( "cyan_light", (1248, -560, 848), (270,0,0), 0);
    triggerCustomFX( "cyan_light", (1248, -592, 848), (270,0,0), 0);
    triggerCustomFX( "cyan_light", (75, -748, 32), (270,0,0), 0);
	triggerCustomFX( "cyan_light", (8203, -2944, 616), (270,0,0), 0);
}