main(weapon, name, time) // Non-RPG, non-grenade launcher weapon (type "bullet")
{
    self openCJ\checkpointCreation::onWeaponFired();
    self thread openCJ\measurements::onWeaponFired();
}