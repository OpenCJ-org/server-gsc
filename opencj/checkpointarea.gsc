// Stationary, planar, convex landing areas. Editor preview and gameplay share this test.
// Vertices must follow the perimeter, clockwise or counter-clockwise.
validate(points)
{
    if (points.size < 3 || points.size > 8)
        return "Select 3 to 8 corners around the perimeter";
    normal = planeNormal(points);
    if (normal[2] < 0.7)
        return "Select a walkable landing plane";
    winding = 0;
    for (i = 0; i < points.size; i++)
    {
        a = points[i];
        b = points[(i + 1) % points.size];
        if (abs(vectorDot(a - points[0], normal)) > 0.25)
            return "All corners must lie on the same plane";
        if (distanceSquared(a, b) < 1)
            return "Two corners are too close together";
        // Every other corner must lie strictly on the same side of every edge.
        // This also rejects crossed polygons and redundant collinear corners.
        for (j = 0; j < points.size; j++)
        {
            if (j == i || j == (i + 1) % points.size)
                continue;
            cross = _cross(a, b, points[j]);
            if (abs(cross) < 0.01)
                return "Corners must form a convex area without straight-line duplicates";
            sign = 1;
            if (cross < 0)
                sign = -1;
            if (winding != 0 && winding != sign)
                return "Corners cross or form a concave area; select them around the perimeter";
            winding = sign;
        }
    }
    return "";
}

contains(points, origin, grounded, requireGround)
{
    if (!isDefined(requireGround))
        requireGround = true;
    if ((requireGround && !grounded) || points.size < 3)
        return false;
    normal = planeNormal(points);
    if (normal[2] < 0.7)
        return false;
    height = vectorDot(origin - points[0], normal) / normal[2];
    if (height < -2 || height > 4 + supportOffset(points))
        return false;
    side = 0;
    for (i = 0; i < points.size; i++)
    {
        cross = _cross(points[i], points[(i + 1) % points.size], origin);
        if (abs(cross) < 0.01)
            continue;
        sign = 1;
        if (cross < 0)
            sign = -1;
        if (side != 0 && side != sign)
            return false;
        side = sign;
    }
    return true;
}

// A grounded player can stand with their center outside the landing perimeter.
// Keep geometric contains() strict for editor overlap/merge detection; only
// player contact tests use the 15-unit collision footprint.
touchesPlayer(points, origin, grounded, requireGround)
{
    if (!isDefined(requireGround))requireGround = true;
    if ((requireGround && !grounded) || points.size < 3)return false;
    if (contains(points, origin, grounded, requireGround))return true;
    normal = planeNormal(points);
    if (normal[2] < 0.7)return false;
    for (i = 0; i < points.size; i++)
    {
        a = points[i];b = points[(i + 1) % points.size];
        dx = b[0] - a[0];dy = b[1] - a[1];
        lengthSquared = dx * dx + dy * dy;
        if (lengthSquared < 0.0001)continue;
        t = ((origin[0] - a[0]) * dx + (origin[1] - a[1]) * dy) / lengthSquared;
        if (t < 0)t = 0;
        if (t > 1)t = 1;
        nearest = a + vectorScale(b - a, t);
        x = origin[0] - nearest[0];y = origin[1] - nearest[1];
        // Segment distance also rounds corners instead of extending each edge
        // independently, which would award checkpoints beyond the footprint.
        if (x * x + y * y > 225)continue;
        height = origin[2] - nearest[2];
        if (height >= -2 && height <= 4 + supportOffset(points))return true;
    }
    return false;
}

crossProduct(a, b)
{
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]);
}

planeNormal(points)
{
    normal = vectorNormalize(crossProduct(points[1] - points[0], points[2] - points[0]));
    if (normal[2] < 0)
        normal = (0,0,0) - normal;
    return normal;
}

// The player's 15-unit capsule rests above the plane at its center on a slope.
supportOffset(points)
{
    normal = planeNormal(points);
    return 15 * (1 / normal[2] - 1);
}

_cross(a, b, p)
{
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]);
}

encode(points)
{
    text = "";
    for (i = 0; i < points.size; i++)
    {
        if (i > 0)
            text += ";";
        text += points[i][0] + "," + points[i][1] + "," + points[i][2];
    }
    return text;
}

decode(text)
{
    points = [];
    parts = strTok(text, ";");
    if (parts.size > 8)
        return undefined;
    for (i = 0; i < parts.size; i++)
    {
        xyz = strTok(parts[i], ",");
        if (xyz.size != 3)
            return undefined;
        for (j = 0; j < 3; j++)
        {
            if (!isValidFloat(xyz[j]) || abs(float(xyz[j])) > 131072)
                return undefined;
        }
        points[i] = (float(xyz[0]), float(xyz[1]), float(xyz[2]));
    }
    return points;
}
