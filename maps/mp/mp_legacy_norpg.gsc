main()
{
          

   addFunc("no_rpg", ::no_rpg);
          
}

addFunc(targetname, function)
{
   entArray = getEntArray("no_rpg", "targetname");

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
         if(user hasWeapon("deserteaglegold_mp"))
            user switchToWeapon("deserteaglegold_mp");
         else if(!user hasWeapon("deserteaglegold_mp") && user hasWeapon("deserteagle_mp"))
            user switchToWeapon("deserteagle_mp");

         wait 1;
      }

      wait 0.75;
   }

   user.no_rpg = undefined;
}







