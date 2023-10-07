#include openCJ\util;

// What this does: detect FLAT rectangular (angled or not) platform that the player is standing on
// Why: very quick checkpoints for rectangular platforms
// How: Using physicsTraces
// Good to know: a physicsTrace from inside a solid doesn't immediately return, instead it will only return when changing to a different type, that's the only reason why this all works
//
// Pseudocode:
// For each direction (90 degrees) from where the player is currently looking at:
//    1. Physics trace in this direction from under the player's feet (so inside the platform)
//    2. If it hit something, use that as end point. If it didn't hit anything, use the distance specified to the physicsTrace to determine endpoint
//    3. From that point do a physicsTrace back to the platform, this will hit the platform and informs us of the origin of a side of the rectangle
// Now you can calculate the corners for the rectangular platform

getRectangularPlatformOrgs()
{
    if (!self isOnGround())
    {
        self iprintln("^1You can only detect rectangular platforms while on ground");
        return undefined;
    }

    // First determine the starting point, which is below the player (inside the platform)
    startTrace = physicsTrace(self.origin, self.origin - (0, 0, 10)); // n units below the feet of the player
    if (!isDefined(startTrace))
    {
        self iprintln("^1Auto-detect platform failed: no solid brush under you");
        return undefined;
    }
    startOrg = startTrace - (0, 0, 1); // Because has to be *inside* the platform

    // Maximum length of the platform, used to specify the limit of the physics traces
    maxPlatformLength = 1000;

    // Forward
    forwardAngles = (0, int(self getPlayerAngles()[1]), 0);
    forwardVector = anglesToForward(forwardAngles);
    forwardScaledVector = vectorScale(forwardVector, maxPlatformLength);
    forwardNormalizedVector = vectorScale(forwardVector, 1); // TODO: is this normalized or unity?

    // Right
    rightVector = anglesToRight(forwardAngles);
    rightScaledVector = vectorScale(rightVector, maxPlatformLength);
    rightNormalizedVector = vectorScale(rightVector, 1);

    // Backwards
    backwardAngles = (0, int(forwardAngles[1] + 180) % 360, 0);
    backwardVector = anglesToForward(backwardAngles);
    backwardScaledVector = vectorScale(backwardVector, maxPlatformLength);
    backwardNormalizedVector = vectorScale(backwardVector, 1);

    // Left
    leftAngles = (0, int(forwardAngles[1] + 90) % 360, 0);
    leftVector = anglesToForward(leftAngles);
    leftScaledVector = vectorScale(leftVector, maxPlatformLength);
    leftNormalizedVector = vectorScale(leftVector, 1);

    // These will be looped through to determine a point on each side of the rectangular platform
    scaledDirections = [];
    normalizedDirections = [];
    dirStrings = [];
    scaledDirections[0] = forwardScaledVector;
    normalizedDirections[0] = forwardNormalizedVector;
    dirStrings[0] = "forward";
    scaledDirections[1] = rightScaledVector;
    normalizedDirections[1] = rightNormalizedVector;
    dirStrings[1] = "right";
    scaledDirections[2] = backwardScaledVector;
    normalizedDirections[2] = backwardNormalizedVector;
    dirStrings[2] = "backward";
    scaledDirections[3] = leftScaledVector;
    normalizedDirections[3] = leftNormalizedVector;
    dirStrings[3] = "left";

    points = []; // To store results
    for (i = 0; i < scaledDirections.size; i++) // Rectangles have 4 sides
    {
        // Start a trace from the point in the platform under the player to the max distance ahead
        trace = physicsTrace(startOrg, startOrg + scaledDirections[i]);
        if (!isDefined(trace))
        { 
            self iprintln("^1Auto-detect platform failed: " + dirStrings[i] + " failed (way there)");
            return undefined;
        }

        // Now trace back, so we hit the platform
        trace = physicsTrace(trace + normalizedDirections[i], startOrg);
        if (!isDefined(trace))
        {
            self iprintln("^1Auto-detect platform failed: " + dirStrings[i] + " (way back)");
            return undefined;
        }

        points[i] = trace;
    }

    // The 4 points are stored. Calculate the corners of the rectangle now, so those can be used as coordinates for checkpoint
    lenFront = (points[0] - startOrg); // [0] is forward
    lenBehind = (points[2] - startOrg); // [2] is backward
    lenRight = (points[1] - startOrg); // [1] is right
    lenLeft = (points[3] - startOrg); // [3] is left

    // Now we can calculate the 4 origins/vertices that make up this rectangular platform:
    orgs = [];
    orgs[0] = startOrg + lenFront + lenLeft;
    orgs[1] = startOrg + lenFront + lenRight;
    orgs[2] = startOrg + lenBehind + lenRight;
    orgs[3] = startOrg + lenBehind + lenLeft;

    self iprintln("^2Auto-detected rectangular platform: " + orgs[0] + ", " + orgs[1] + ", " + orgs[2] + ", " + orgs[3]);
    return orgs;
}
