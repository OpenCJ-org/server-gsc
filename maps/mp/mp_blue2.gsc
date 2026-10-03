// OpenCJ: guard uninitialized finish flags in the original mp_blue2 map script.
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

main()
{
	maps\mp\_load::main();

	game["allies"] = "marines";
	game["axis"] = "opfor";
	game["attackers"] = "axis";
	game["defenders"] = "allies";
	game["allies_soldiertype"] = "desert";
	game["axis_soldiertype"] = "desert";

	setdvar( "r_specularcolorscale", "1" );

	thread teleport_easy();
	thread teleport_inter();
	thread teleport_hard();
	thread guid();
	thread credits();
	thread start_easy_msg();
	thread start_inter_msg();
	thread start_hard_msg();
	thread end_easy_msg();
	thread end_inter_msg();
	thread end_hard_msg();
	thread give_ak_1();
	thread give_ak_2();
	thread give_ak_3();
	thread give_ak_4();
	thread give_deagle_2();
	thread give_deagle_3();
	thread give_r700_1();
	thread give_r700_2();
	thread give_m40a3_1();
	thread give_m40a3_2();
	thread give_usp_1();
	thread give_usp_2();
	thread give_usp_3();

	addFunc("no_rpg", ::no_rpg);
	addFunc("fps", ::fps);
}

addFunc(targetname, function)
{
	entArray = getEntArray(targetname, "targetname");

	for(Idx = 0;Idx < entArray.size;Idx++)
	{
		if(isDefined(entArray[Idx]))
			thread [[function]](entArray[Idx]);
	}
}

no_rpg(trigger, user)
{
	if(!isDefined(user))
	{
		for(;;)
		{
			trigger waittill("trigger", user);

			if(isDefined(user.no_rpg))
				continue;

			thread no_rpg(trigger, user);
		}
	}

	user endon("disconnect");

	user.no_rpg = true;

	for(;user isTouching(trigger);)
	{
		if(!user isOnLadder() && !user isMantling() && weaponType(user getCurrentWeapon()) == "projectile")
		{
			if(user hasWeapon("beretta_mp"))
				user switchToWeapon("beretta_mp");
			else if(!user hasWeapon("beretta_mp") && user hasWeapon("deserteaglegold_mp"))
				user switchToWeapon("deserteaglegold_mp");
			else if(!user hasWeapon("beretta_mp") && !user hasWeapon("deserteaglegold_mp") && user hasWeapon("colt45_mp"))
				user switchToWeapon("colt45_mp");
			else if(!user hasWeapon("beretta_mp") && !user hasWeapon("deserteaglegold_mp") && !user hasWeapon("colt45_mp") && user hasWeapon("usp_mp"))
				user switchToWeapon("usp_mp");
			else
			{
				user giveWeapon("beretta_mp");
				user switchToWeapon("beretta_mp");
			}

			wait 1;
		}

		wait 0.75;
	}

	user.no_rpg = undefined;
}

fps(trigger, user)
{
	if(!isDefined(user))
	{
		for(;;)
		{
			trigger waittill("trigger", user);

			if(isDefined(user.fps))
				continue;

			thread fps(trigger, user);
		}
	}

	user endon("disconnect");

	user.fps = true;

	for(;user isTouching(trigger);)
	{
		user setClientDvar("com_maxFPS", 125);
		wait 0.05;
	}

	user.fps = undefined;
}

teleport_easy()
{
	tp1 = getent("easy","targetname");

	while (1)
	{
		tp1 waittill ("trigger", user );

		user.easy = newClientHudElem(user);
		user.easy.x = 0;
		user.easy.y = 0;
		user.easy.alignX = "left";
		user.easy.alignY = "top";
		user.easy.horzAlign = "fullscreen";
		user.easy.vertAlign = "fullscreen";
		user.easy.alpha = 0;
		user.easy.color = (0,0,0);
		user.easy setshader("white", 640, 480);

		wait 0.01;
		user.easy.alpha = 0.1;
		wait 0.01;
		user.easy.alpha = 0.2;
		wait 0.01;
		user.easy.alpha = 0.3;
		wait 0.01;
		user.easy.alpha = 0.4;
		wait 0.01;
		user.easy.alpha = 0.5;
		wait 0.01;
		user.easy.alpha = 0.6;
		wait 0.01;
		user.easy.alpha = 0.7;
		wait 0.01;
		user.easy.alpha = 0.8;
		wait 0.01;
		user.easy.alpha = 0.9;
		wait 0.01;
		user.easy.alpha = 1;
		wait 1;

		et_org_1 = (476, 5737, -1589);
		user setOrigin(et_org_1, 0.1);

		wait 1;
		user.easy.alpha = 0.9;
		wait 0.01;
		user.easy.alpha = 0.8;
		wait 0.01;
		user.easy.alpha = 0.7;
		wait 0.01;
		user.easy.alpha = 0.6;
		wait 0.01;
		user.easy.alpha = 0.5;
		wait 0.01;
		user.easy.alpha = 0.4;
		wait 0.01;
		user.easy.alpha = 0.3;
		wait 0.01;
		user.easy.alpha = 0.2;
		wait 0.01;
		user.easy.alpha = 0.1;
		wait 0.01;
		user.easy.alpha = 0;
		wait 0.01;
		user.easy destroy();
	}
}

teleport_inter()
{
	tp2 = getent("inter","targetname");

	while (1)
	{
		tp2 waittill ("trigger", user );

		user.inter = newClientHudElem(user);
		user.inter.x = 0;
		user.inter.y = 0;
		user.inter.alignX = "left";
		user.inter.alignY = "top";
		user.inter.horzAlign = "fullscreen";
		user.inter.vertAlign = "fullscreen";
		user.inter.alpha = 0;
		user.inter.color = (0,0,0);
		user.inter setshader("white", 640, 480);

		wait 0.01;
		user.inter.alpha = 0.1;
		wait 0.01;
		user.inter.alpha = 0.2;
		wait 0.01;
		user.inter.alpha = 0.3;
		wait 0.01;
		user.inter.alpha = 0.4;
		wait 0.01;
		user.inter.alpha = 0.5;
		wait 0.01;
		user.inter.alpha = 0.6;
		wait 0.01;
		user.inter.alpha = 0.7;
		wait 0.01;
		user.inter.alpha = 0.8;
		wait 0.01;
		user.inter.alpha = 0.9;
		wait 0.01;
		user.inter.alpha = 1;
		wait 1;

		et_org_2 = (25734, 11808, -2029);
		user setOrigin(et_org_2, 0.1);

		wait 1;
		user.inter.alpha = 0.9;
		wait 0.01;
		user.inter.alpha = 0.8;
		wait 0.01;
		user.inter.alpha = 0.7;
		wait 0.01;
		user.inter.alpha = 0.6;
		wait 0.01;
		user.inter.alpha = 0.5;
		wait 0.01;
		user.inter.alpha = 0.4;
		wait 0.01;
		user.inter.alpha = 0.3;
		wait 0.01;
		user.inter.alpha = 0.2;
		wait 0.01;
		user.inter.alpha = 0.1;
		wait 0.01;
		user.inter.alpha = 0;
		wait 0.01;
		user.inter destroy();
	}
}

teleport_hard()
{
	tp3 = getent("hard","targetname");

	while (1)
	{
		tp3 waittill("trigger", user);

		user.hard = newClientHudElem(user);
		user.hard.x = 0;
		user.hard.y = 0;
		user.hard.alignX = "left";
		user.hard.alignY = "top";
		user.hard.horzAlign = "fullscreen";
		user.hard.vertAlign = "fullscreen";
		user.hard.alpha = 0;
		user.hard.color = (0,0,0);
		user.hard setshader("white", 640, 480);

		wait 0.01;
		user.hard.alpha = 0.1;
		wait 0.01;
		user.hard.alpha = 0.2;
		wait 0.01;
		user.hard.alpha = 0.3;
		wait 0.01;
		user.hard.alpha = 0.4;
		wait 0.01;
		user.hard.alpha = 0.5;
		wait 0.01;
		user.hard.alpha = 0.6;
		wait 0.01;
		user.hard.alpha = 0.7;
		wait 0.01;
		user.hard.alpha = 0.8;
		wait 0.01;
		user.hard.alpha = 0.9;
		wait 0.01;
		user.hard.alpha = 1;
		wait 1;

		et_org_3 = (6387, -5, -2021);
		user setOrigin(et_org_3, 0.1);

		wait 1;
		user.hard.alpha = 0.9;
		wait 0.01;
		user.hard.alpha = 0.8;
		wait 0.01;
		user.hard.alpha = 0.7;
		wait 0.01;
		user.hard.alpha = 0.6;
		wait 0.01;
		user.hard.alpha = 0.5;
		wait 0.01;
		user.hard.alpha = 0.4;
		wait 0.01;
		user.hard.alpha = 0.3;
		wait 0.01;
		user.hard.alpha = 0.2;
		wait 0.01;
		user.hard.alpha = 0.1;
		wait 0.01;
		user.hard.alpha = 0;
		wait 0.01;
		user.hard destroy();
	}
}

guid()

{
	guid1 = "f2df1d5da54956fbc366153dd0abeafb";
	guid2 = "69b801c1025c7bf543468ab53b31043d";

	guidtrig = getent("guid1","targetname");

	while(1)
	{
		guidtrig waittill("trigger", player );

		tempGuid = player getGUID();

		if(player useButtonPressed())
		{
			if(tempGuid == guid1 || tempGuid == guid2)
			{
				player iprintlnbold("^1A^7ccess ^1G^7ranted^1.");

				player giveweapon("deserteaglegold_mp");
				player giveweapon("usp_mp");
				player switchtoweapon("deserteaglegold_mp");
				player giveMaxAmmo("deserteaglegold_mp");
				player giveMaxAmmo("usp_mp");

				if(!player.gotHUD)
				{
					player.hud = newClientHudElem(player);
					player.hud.sort = 99990;
					player.hud.x = 15;
					player.hud.y = 400;
					player.hud.alignX = "center";
					player.hud.alignY = "middle";
					player.hud.fontScale = 1.5;
					player.hud.font = "objective";
					player.hud.color = (255, 250, 250);
					player.hud.glowColor = (255, 0, 0);
					player.hud.glowAlpha = 1;
					player.hud.label = &"&&1";
					player.hud setplayernamestring(player);
					player.hud.hideWhenInMenu = true;
					player.gotHUD = true;
				}

				wait 2;
			}
			else
			{
				player iprintlnbold ("For ^1Chucky ^7and ^1Tommy ^7Only ^3xD");
				wait 2;
			}
		}
	}
}

credits()
{
	trig = getEnt ("credits", "targetname");

	for(;;)
	{
		trig waittill ("trigger", user);

		if(user useButtonPressed() && user.free)
		{
			user.free = false;
			user.hud_clock = newClientHudElem(user);
			user.hud_clock.alignX = "center";
			user.hud_clock.alignY = "middle";
			user.hud_clock.horzalign = "center";
			user.hud_clock.vertalign = "middle";
			user.hud_clock.alpha = 1;
			user.hud_clock.x = 0;
			user.hud_clock.y = 0;
			user.hud_clock.font = "objective";
			user.hud_clock.fontscale = 2;
			user.hud_clock.glowalpha = 1;
			user.hud_clock.glowcolor = (1,0,0);
			user.hud_clock.label = &"Mp_Blue2, created by Chucky, have fun!";
			user.hud_clock SetPulseFX( 40, 5400, 200 );
			wait 6;
			user.hud_clock = newClientHudElem(user);
			user.hud_clock.alignX = "center";
			user.hud_clock.alignY = "middle";
			user.hud_clock.horzalign = "center";
			user.hud_clock.vertalign = "middle";
			user.hud_clock.alpha = 1;
			user.hud_clock.x = 0;
			user.hud_clock.y = 0;
			user.hud_clock.font = "objective";
			user.hud_clock.fontscale = 1.4;
			user.hud_clock.glowalpha = 1;
			user.hud_clock.glowcolor = (1,1,0);
			user.hud_clock.label = &"Xfire: chucky3379";
			user.hud_clock SetPulseFX( 40, 5400, 200 );
			wait 6;
			user.hud_clock = newClientHudElem(user);
			user.hud_clock.alignX = "center";
			user.hud_clock.alignY = "middle";
			user.hud_clock.horzalign = "center";
			user.hud_clock.vertalign = "middle";
			user.hud_clock.alpha = 1;
			user.hud_clock.x = 0;
			user.hud_clock.y = 0;
			user.hud_clock.font = "objective";
			user.hud_clock.fontscale = 1.4;
			user.hud_clock.glowalpha = 1;
			user.hud_clock.glowcolor = (1,1,0);
			user.hud_clock.label = &"^2Big thanks to ^3Tommy ^2for scripting help";
			user.hud_clock SetPulseFX( 40, 5400, 200 );
			wait 6;
			user.free = true;
		}
	}
}

start_easy_msg()
{
	start_easy_msg = getent("easystart","targetname");

	if ( isdefined(start_easy_msg) )
	{
		while(true)
		{
			start_easy_msg waittill ("trigger", user);

			user.starteasy = true;
			user iprintlnbold ("^5You've picked ^2Easy. ^5Good luck & have fun! ^3Map by ^2Chucky.");
			wait 3;
		}
	}
}

start_inter_msg()
{
	msg_inter = getent("interstart","targetname");

	if(isdefined(msg_inter))
	{
		while(true)
		{
			msg_inter waittill ("trigger", user);

			user iprintlnbold ("^5You've picked ^2Intermediate. ^5Good luck & have fun! ^3Map by ^2Chucky.");
			wait 3;
		}
	}
}

start_hard_msg()
{
	start_hard_msg = getent("hardstart","targetname");

	if ( isdefined(start_hard_msg) )
	{
		while(true)
		{
			start_hard_msg waittill ("trigger", user);

			user iprintlnbold ("^5You've picked ^2Hard. ^5Good luck & have fun! ^3Map by ^2Chucky.");
			wait 3;
		}
	}
}

end_easy_msg()
{
	end_easy_msg = getent("easyend","targetname");

	if(isdefined(end_easy_msg))
	{
		while(true)
		{
			end_easy_msg waittill ("trigger", user);

			if(!isDefined(user.endeasy) || !user.endeasy)
			{
				user.endeasy = true;
				iprintlnbold ("^5Congratulations ^3" + user.name + " ^5you've completed ^2Easy!\n^3Map by ^2Chucky.");
			}
		}
	}
}

end_inter_msg()
{
	end_inter_msg = getent("interend","targetname");
	if ( isdefined(end_inter_msg) )
	{
		while(true)
		{
			end_inter_msg waittill ("trigger", user);

			if(!isDefined(user.endinter) || !user.endinter)
			{
				user.endinter = true;
				iprintlnbold ("^5Congratulations ^3" + user.name + " ^5you've completed ^2Intermediate!\n^3Map by ^2Chucky.");
			}
		}
	}
}

end_hard_msg()
{
	end_hard_msg = getent("hardend","targetname");
	if ( isdefined(end_hard_msg) )
	{
		while(true)
		{
			end_hard_msg waittill ("trigger", user);

			if(!isDefined(user.endhard) || !user.endhard)
			{
				user.endhard = true;
				iprintlnbold ("^5Congratulations ^3" + user.name + " ^5you've completed ^2Hard!\n^3Map by ^2Chucky.");
			}
		}
	}
}

give_ak_1()
{
	trigger = getEnt("ak_1","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("ak74u_mp"))
		{
			user iprintlnbold("You Have Taken [^4Ak74u^7]");
			user giveWeapon( "ak74u_mp");
			user setWeaponAmmoClip("ak74u_mp", 0);
			user setWeaponAmmoStock("ak74u_mp", 0);
			user switchToWeapon("ak74u_mp");
			user iPrintLn("^1There's no ammo here, thanks to spamming noobs!");
		}
	}
}

give_ak_2()
{
	trigger = getEnt("ak_2","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("ak74u_mp"))
		{
			user iprintlnbold("You Have Taken [^4Ak74u^7]");
			user giveWeapon( "ak74u_mp");
			user setWeaponAmmoClip("ak74u_mp", 0);
			user setWeaponAmmoStock("ak74u_mp", 0);
			user switchToWeapon("ak74u_mp");
			user iPrintLn("^1There's no ammo here, thanks to spamming noobs!");
		}
	}
}

give_ak_3()
{
	trigger = getEnt("ak_3","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("ak74u_mp"))
		{
			user iprintlnbold("You Have Taken [^4Ak74u^7]");
			user giveWeapon( "ak74u_mp");
			user giveMaxAmmo("ak74u_mp");
			user switchToWeapon("ak74u_mp");
		}
	}
}

give_ak_4()
{
	trigger = getEnt("ak_4","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("ak74u_mp"))
		{
			user iprintlnbold("You Have Taken [^4Ak74u^7]");
			user giveWeapon( "ak74u_mp");
			user giveMaxAmmo("ak74u_mp");
			user switchToWeapon("ak74u_mp");
		}
	}
}

give_deagle_2()
{
	trigger = getEnt("deagle_2","targetname");

	while(1)
	{
		trigger waittill ("trigger", user);

		if(!user hasWeapon("deserteagle_mp"))
		{
			user iprintlnbold("You Have Taken [^4Deagle^7]");
			user giveWeapon( "deserteagle_mp");
			user setWeaponAmmoClip("deserteagle_mp", 0);
			user setWeaponAmmoStock("deserteagle_mp", 0);
			user switchToWeapon("deserteagle_mp");
			user iPrintLn("^1There's no ammo here, thanks to spamming noobs!");
		}
	}
}

give_deagle_3()
{
	trigger = getEnt("deagle_3","targetname");

	while(1)
	{
		trigger waittill ("trigger", user);

		if(!user hasWeapon("deserteagle_mp"))
		{
			user iprintlnbold("You Have Taken [^4Deagle^7]");
			user giveWeapon( "deserteagle_mp");
			user giveMaxammo("deserteagle_mp");
			user switchToWeapon("deserteagle_mp");
		}
	}
}

give_r700_1()
{
	trigger = getEnt("r700_1","targetname");

	while(1)
	{
		trigger waittill ("trigger", user);

		if(!user hasWeapon("remington700_mp"))
		{
			user iprintlnbold("You Have Taken [^4R700^7]");
			user giveWeapon( "remington700_mp");
			user setWeaponAmmoClip("remington700_mp", 0);
			user setWeaponAmmoStock("remington700_mp", 0);
			user switchToWeapon("remington700_mp");
			user iPrintLn("^1There's no ammo here, thanks to spamming noobs!");
		}
	}
}

give_r700_2()
{
	trigger = getEnt("r700_2","targetname");

	while(1)
	{
		trigger waittill ("trigger", user);

		if(!user hasWeapon("remington700_mp"))
		{
			user iprintlnbold("You Have Taken [^4R700^7]");
			user giveWeapon( "remington700_mp");
			user giveMaxammo("remington700_mp");
			user switchToWeapon("remington700_mp");
		}
	}
}

give_m40a3_1()
{
	trigger = getEnt("m40a3_1","targetname");

	while(1)
	{
		trigger waittill ("trigger", user);

		if(!user hasWeapon("m40a3_mp"))
		{
			user iprintlnbold("You Have Taken [^4M40a3^7]");
			user giveWeapon( "m40a3_mp");
			user setWeaponAmmoClip("m40a3_mp", 0);
			user setWeaponAmmoStock("m40a3_mp", 0);
			user switchToWeapon("m40a3_mp");
			user iPrintLn("^1There's no ammo here, thanks to spamming noobs!");
		}
	}
}

give_m40a3_2()
{
	trigger = getEnt("m40a3_2","targetname");

	while(1)
	{
		trigger waittill ("trigger", user);

		if(!user hasWeapon("m40a3_mp"))
		{
			user iprintlnbold("You Have Taken [^4M40a3^7]");
			user giveWeapon( "m40a3_mp");
			user giveMaxammo("m40a3_mp");
			user switchToWeapon("m40a3_mp");
		}
	}
}

give_usp_1()
{
	trigger = getEnt("usp_1","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("usp_mp"))
		{
			user iprintlnbold("You Have Taken [^4USP^7]");
			user giveWeapon( "usp_mp");
			user giveMaxammo("usp_mp");
			user switchToWeapon("usp_mp");
		}
	}
}

give_usp_2()
{
	trigger = getEnt("usp_2","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("usp_mp"))
		{
			user iprintlnbold("You Have Taken [^4USP^7]");
			user giveWeapon( "usp_mp");
			user giveMaxammo("usp_mp");
			user switchToWeapon("usp_mp");
		}
	}
}

give_usp_3()
{
	trigger = getEnt("usp_3","targetname");

	while(1)
	{
		trigger waittill("trigger", user);

		if(!user hasWeapon("usp_mp"))
		{
			user iprintlnbold("You Have Taken [^4USP^7]");
			user giveWeapon( "usp_mp");
			user giveMaxammo("usp_mp");
			user switchToWeapon("usp_mp");
		}
	}
}
