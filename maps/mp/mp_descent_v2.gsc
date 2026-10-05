// OpenCJ: finish flags are undefined until a route has been completed.
/*                          __                          __          ___
   ____ ___  ____      ____/ /__  _____________  ____  / /_   _   _|__ \
  / __ `__ \/ __ \    / __  / _ \/ ___/ ___/ _ \/ __ \/ __/  | | / /_/ /
 / / / / / / /_/ /   / /_/ /  __(__  ) /__/  __/ / / / /_    | |/ / __/
/_/ /_/ /_/ .___/____\__,_/\___/____/\___/\___/_/ /_/\__/____|___/____/
         /_/   /_____/                                 /_____/
   _____           _       __          __         	 ______
  / ___/__________(_)___  / /______   / /_  __  __	/_  __/___  ____ ___  ____ ___  __  __
  \__ \/ ___/ ___/ / __ \/ __/ ___/  / __ \/ / / /	 / / / __ \/ __ `__ \/ __ `__ \/ / / /
 ___/ / /__/ /  / / /_/ / /_(__  )  / /_/ / /_/ / 	/ / / /_/ / / / / / / / / / / / /_/ /
/____/\___/_/  /_/ .___/\__/____/  /_.___/\__, /   / / / /_/ / / / / / / / / / / / /_/ /
                /_/                      /____/   /_/  \____/_/ /_/ /_/_/ /_/ /_/\__, /
																				/____/
									XFire: noheadman
				feel free to use any of this code, but please give credits
*/

main()
{
	maps\mp\_load::main();

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

	thread easyStart();
	thread easyEnd();
	thread hardStart();
	thread hardEnd();
	thread msg1();
	thread msg2();
	thread msg3();
	thread msg4();
	thread msg5();
	thread msg6();
	thread teleport_top();
	thread teleport_out();
	thread teleport_in();
	thread teleport_loop();
}

easyStart()
{
	level endon("game_ended");

	trigger = getent("easybegin", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing" || isDefined(player.startTimeEasy))
			wait 0.05;
		else
			player.startTimeEasy = getTime();
	}
}

easyEnd()
{
	level endon("game_ended");

	trigger = getent("easyend", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing" || (isDefined(player.easyEnd) && player.easyEnd) || !isDefined(player.startTimeEasy))
			wait 0.05;
		else
		{
			number = getTime() - player.startTimeEasy;

			if(number/1000/60 >= 1)
				minutes = number/1000/60 - (number % 60000)/60/1000;
			else
				minutes = 0;
			seconds = int((number % 60000)/1000);

			if(seconds <= 9)
				player iPrintLnBold("Congratulations, you finished ^5mp_descent_v2 ^2Easy ^7in ^3" + minutes + ":0" + seconds);
			else
				player iPrintLnBold("Congratulations, you finished ^5mp_descent_v2 ^2Easy ^7in ^3" + minutes + ":" + seconds);

                        if(minutes <= 5)
				iPrintLnBold("^3 " + player.name + " , WHY ARE YOU CHEATING?");
                        else if(minutes <= 7)
				player iPrintLnBold("^1GOD LIKE!!!!!!!!!!!!!!");
                        else if(minutes <= 8)
				player iPrintLnBold("^1RIDICULOUS!!!!!!!!");
			else if(minutes <= 10)
				player iPrintLnBold("^2SICK!!!!");
                        else if(minutes <= 13)
				player iPrintLnBold("^2Very Nice!!!");
                        else if(minutes <= 15)
				player iPrintLnBold("^5Great Job!!");
                        else if(minutes <= 20)
				player iPrintLnBold("^7Good ^7Time!");
			else if(minutes <= 30)
				player iPrintLnBold("^7Nice");
                        else if(minutes <= 45)
				player iPrintLnBold("^7Not Bad");
                        else if(minutes > 150)
			        iPrintLnBold("^6CHANGE THE MAP ALREADY!!");


			player.easyEnd = true;
		}
	}
}

hardStart()
{
	level endon("game_ended");

	trigger = getent("hardbegin", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing" || isDefined(player.startTimeHard))
			wait 0.05;
		else
			player.startTimeHard = getTime();
	}
}

hardEnd()
{
	level endon("game_ended");

	trigger = getent("hardend", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing" || (isDefined(player.hardEnd) && player.hardEnd) || !isDefined(player.startTimeHard))
			wait 0.05;
		else
		{
			number = getTime() - player.startTimeHard;

			if(number/1000/60 >= 1)
				minutes = number/1000/60 - (number % 60000)/60/1000;
			else
				minutes = 0;
			seconds = int((number % 60000)/1000);

			if(seconds <= 9)
				iPrintLnBold("^5" + player.name + " ^7finished ^5mp_descent_v2 ^1Hard ^7in ^3" + minutes + ":0" + seconds);
			else
				iPrintLnBold("^5" + player.name + " ^7finished ^5mp_descent_v2 ^1Hard ^7in ^3" + minutes + ":" + seconds);

                        if(minutes <= 5)
				iPrintLnBold(" " + player.name + " ,^3WHY ARE YOU CHEATING?");
                        else if(minutes <= 7)
				iPrintLnBold("^1How the hell?");
                        else if(minutes <= 8)
				iPrintLnBold("^1INCONCEIVABLE!!!!!!!!!!!!!!");
                        else if(minutes <= 9)
				iPrintLnBold("^1GOD LIKE!!!!!");
			else if(minutes <= 10)
				iPrintLnBold("^2UNBELIEVABLE!!!!");
                        else if(minutes <= 11)
				iPrintLnBold("^2Insane!!!");
                        else if(minutes <= 12)
				iPrintLnBold("^5Incredible!!");
                        else if(minutes <= 14)
				iPrintLnBold("^5Pro ^7Time!");
                        else if(minutes <= 16)
				iPrintLnBold("^5Very ^7Nice!");
			else if(minutes <= 19)
				iPrintLnBold("^7Great Time");
                        else if(minutes <= 24)
				iPrintLnBold("^7Good Time");
                        else if(minutes <= 29)
				iPrintLnBold("^7Not Bad");
                        else if(minutes <= 69)
				iPrintLnBold("^7 ");
                        else if(minutes <= 139)
				iPrintLnBold("^7lol");
                        else if(minutes >= 150)
				iPrintLnBold("^6CHANGE THE MAP ALREADY!!");

                        player.hardEnd = true;
		}
	}
}

msg1()
{
	level endon("game_ended");

	trigger = getent("msg1", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			iPrintLnBold("Thanks to ^3Paragon, Soap, Sycotic, ShadowLinkX, Furi, and Wez ^7for testing!"); //INSERT TEXT HERE
			wait 10;
		}
	}
}

msg2()
{
	level endon("game_ended");

	trigger = getent("msg2", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			iPrintLnBold("^4Map by: ^1=.VaRtaZiaN.="); //INSERT TEXT HERE
			iPrintLnBold("^3XFire: ^1vartazian147");  //INSERT TEXT HERE
			wait 10;
		}
	}
}

msg3()
{
	level endon("game_ended");

	trigger = getent("msg3", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			iPrintLnBold("Thanks to ^2Tommy ^7for most of  the scripting!"); //INSERT TEXT HERE
			wait 10;
		}
	}
}

msg4()
{
	level endon("game_ended");

	trigger = getent("msg4", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			iPrintLnBold("" + player.name + " ^7is a ^5BOSS"); //INSERT TEXT HERE
			wait 10;
		}
	}
}

msg5()
{
	level endon("game_ended");

	trigger = getent("msg5", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			iPrintLnBold("CoDRadiant ^8SUCKS ^7._."); //INSERT TEXT HERE
			wait 10;
		}
	}
}

msg6()
{
	level endon("game_ended");

	trigger = getent("msg6", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			iPrintLnBold("Map took ^410.12 GB ^7to compile."); //INSERT TEXT HERE
			wait 10;
		}
	}
}
teleport_top()
{
	level endon("game_ended");

	trigger = getent("tele1", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			player setOrigin((38208, 3072, 61200), 0.01);
			player setPlayerAngles((0, 270, 0));
		}
	}
}

teleport_out()
{
	level endon("game_ended");

	trigger = getent("tele2", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			player setOrigin((-84741, 75431, 11343), 0.01);
			player setPlayerAngles((0, 270, 0));
		}
	}
}

teleport_in()
{
	level endon("game_ended");

	trigger = getent("tele3", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			player setOrigin((407, 2581, 60889), 0.01);
			player setPlayerAngles((0, 270, 0));
		}
	}
}

teleport_loop()
{
	level endon("game_ended");

	trigger = getent("tele4", "targetname");

	while(1)
	{
		trigger waittill("trigger", player);

		if(player.sessionstate != "playing")
			wait 0.05;
		else
		{
			player setOrigin((407, 2581, 148229), 0.01);
			player setPlayerAngles((0, 290, 0));
		}
	}
}
