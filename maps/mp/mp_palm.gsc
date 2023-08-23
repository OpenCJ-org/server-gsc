 main()
{


/////////////////////////////////////////////////

 maps\mp\_load::main();
 maps\mp\teleports::main();
 
 
 game["allies"] = "marines";
 game["axis"] = "opfor";
 game["attackers"] = "axis";
 game["defenders"] = "allies";
 game["allies_soldiertype"] = "desert";
 game["axis_soldiertype"] = "desert";
 
 setdvar( "r_specularcolorscale", "9" );

 setdvar("r_glowbloomintensity0",".25");
 setdvar("r_glowbloomintensity1",".25");
 setdvar("r_glowskybleedintensity0",".3");
 setdvar("compassmaxrange","1800");
 
 thread msginter();
 thread msginterroof();
 thread msgfinishedeasy();
 thread msgeasyroof();
 thread msghardfinish();
 thread msghardroof();
 thread msgwelcome();
 thread msgthanks1();
 thread msgthanks2();
 thread msgpro();
}


///////////////////////////////////////////////////////
msgwelcome()
{
trigger = getent("msgwelcome","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.welcome ) ))
     {
   wait 6;
   if (isDefined(user))
   {
    user iprintlnbold ("Welcome to ^5mp_Palm");
 user iprintlnbold ("Map created by ^1Furi"); 
   
   user.welcome = true;
   }
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msginter()
{
trigger = getent("msginter","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.interfinish ) ))
     {
   iprintln ("" + user.name + " finished ^4Inter Way!");
user iprintlnbold ("Map created by ^1Furi");  
   user.interfinish = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msginterroof()
{
trigger = getent("msginterroof","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.interroof ) ))
     {
   iprintln ("" + user.name + " landed on ^4Inter ^7roof!");
   user.interroof = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msgfinishedeasy()
{
trigger = getent("msgfinishedeasy","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.easyfinish ) ))
     {
   user iprintln ("" + user.name + " finished ^2Easy Way!");
user iprintlnbold ("Map created by ^1Furi");  
   user.easyfinish = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msgeasyroof()
{
trigger = getent("msgeasyroof","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.easyroof ) ))
     {
   iprintln ("" + user.name + " landed on ^2Easy ^7roof!");
   user.easyroof = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msghardfinish()
{
trigger = getent("msghardfinish","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.hard ) ))
     {
   iprintln ("" + user.name + " has finished ^1Hard Way!");
user iprintlnbold ("Map created by ^1Furi");  
   user.hard = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msghardroof()
{
trigger = getent("msghardroof","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.hardroof ) ))
     {
   iprintln ("" + user.name + " has landed on ^1Hard ^7roof!");
   user.hardroof = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msgthanks1()
{
trigger = getent("msgthanks1","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.thanks ) ))
     {
   user iprintln ("Thanks to ^1Chusteen ^7and ^4Kev ^7for testing!");
   user.thanks = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////
msgthanks2()
{
trigger = getent("msgthanks2","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.thanks1 ) ))
     {
   user iprintln ("Thanks to ^1Chusteen ^7for all his mapping help!");
   user.thanks1 = true;
     }
 
 wait .05;
 }
}
/////////////////////////////////////////////////////////////////////////////////////////////////
msgpro()
{
trigger = getent("msgpro","targetname");

 while (1)
 {
  trigger waittill ("trigger", user );
  if ( isPlayer( user ) && isAlive( user ) && !(isdefined( user.pro ) ))
     {
   iprintln ("" + user.name + " is ^4Pro^7!");
   user.pro = true;
     }
 
 wait .05;
 }
}



