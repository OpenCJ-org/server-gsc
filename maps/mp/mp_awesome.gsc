main()
{

	maps\mp\_load::main();
	maps\mp\_teleport::main(); //todo: fix tele

	bounce = getEntArray("bounce", "targetname");
	for(i = 0; i < bounce.size; i++)
	{
		bounce[i] thread bounce();
	}
	setdvar("r_specularcolorscale", "1");
 }
 
bounce()
{
	while(true)
	{
		self waittill("trigger", player);
		if(!isDefined(player.bouncing))
		{
			player.bouncing = true;
			player thread player_bounce(self);
		}
	}
}

player_bounce(trigger)
{
	self endon("disconnect");
	vel = self getVelocity();

	if(abs(vel[0]) >= 350 && abs(vel[1]) >= 350 || vel[2] > -350)
	{
		//dont bounce
		wait 1;
		self.bouncing = undefined;
		return;
	}

	kb_val = (vel[2]*-9) - 500;
	dmg_val = 1000;
	kb_dir = (0, 0, 1);
	self openCJ\mapApi::emulateKnockback(dmg_val, kb_dir, kb_val);

	wait 1;

	while(self isTouching(trigger))
	{
		wait 0.05;
	}

	self.bouncing = undefined;
}
	