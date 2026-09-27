#include openCJ\util;

// Rectangular and mildly skewed brush tops. Orientation comes from collision normals, never view yaw.
getRectangularPlatformOrgs()
{
    if (!self isOnGround())
    {
        self iprintln("Land on the platform before detecting it");
        return undefined;
    }
    points = detectLandingAt(self.origin);
    if (!isDefined(points))
        self iprintln("Could not identify a supported platform; use !cp corner for manual placement");
    else
        self iprintln("Detected platform edges from collision geometry");
    return points;
}

// Prefer the actual stationary collision brush. Objects above it cannot truncate
// its face, and selecting one convex brush cannot fill a hole between brushes.
// Traces remain the fallback for CoD2, patches and other non-brush geometry.
detectLandingAt(origin)
{
    top = bulletTrace(origin + (0,0,2), origin - (0,0,24), false, undefined);
    if (top["fraction"] < 1 && top["normal"][2] >= 0.7)
    {
        points = platformBrushFace(top["position"], top["normal"]);
        if (isDefined(points) && openCJ\checkpointArea::validate(points) == "" &&
            openCJ\checkpointArea::contains(points, origin, true))
            return points;
    }
    return detectAt(origin);
}

detectAt(origin)
{
    top = bulletTrace(origin + (0, 0, 2), origin - (0, 0, 24), false, undefined);
    if (top["fraction"] == 1 || top["normal"][2] < 0.7)
        return undefined;
    normal = top["normal"];
    start = top["position"] - normal;
    face = _side(start, vectorNormalize((normal[2], 0, 0 - normal[0])), normal);
    if (!isDefined(face))
        face = _side(start, vectorNormalize((0, normal[2], 0 - normal[1])), normal);
    if (!isDefined(face))
        return undefined;
    axis = face["normal"];
    side = openCJ\checkpointArea::crossProduct(normal, axis);
    // On a skewed slope, follow the adjacent edge instead of assuming a
    // right angle: a perpendicular scan can cross that same edge twice.
    // Allow up to about 18 degrees of skew; all corner/edge support checks remain.
    adjacent = _side(start, side, normal);
    if (!isDefined(adjacent) || vectorDot(adjacent["normal"], side) < 0.95)
        return undefined;
    along = openCJ\checkpointArea::crossProduct(adjacent["normal"], normal);
    directions = [];
    directions[0] = along;
    directions[1] = side;
    directions[2] = vectorScale(along, -1);
    directions[3] = vectorScale(side, -1);
    distances = [];
    faces = [];
    for (i = 0; i < 4; i++)
    {
        hit = _side(start, directions[i], normal);
        if (!isDefined(hit) || vectorDot(hit["normal"], directions[i]) < 0.95)
            return undefined;
        faces[i] = hit["normal"];
        distances[i] = vectorDot(hit["position"] - top["position"], faces[i]);
        if (distances[i] <= 0 || distances[i] >= 4096)
            return undefined;
    }
    // A wall can overlap only part of an edge. Tighten to that wall's face,
    // then verify again; never accept a corner merely because it is obstructed.
    for (attempt = 0; attempt <= 4; attempt++)
    {
        points = _corners(top["position"], axis, side, faces, distances);
        center = vectorScale(points[0] + points[1] + points[2] + points[3], 0.25);
        trimmed = false;
        for (i = 0; i < 4 && !trimmed; i++)
        {
            along = vectorNormalize(points[(i + 1) % 4] - points[i]);
            across = vectorNormalize(points[(i + 3) % 4] - points[i]);
            probes = [];
            probes[0] = points[i] + vectorScale(along + across, 0.5);
            midpoint = vectorScale(points[i] + points[(i + 1) % 4], 0.5);
            probes[1] = midpoint + vectorScale(vectorNormalize(center - midpoint), 0.5);
            for (j = 0; j < probes.size; j++)
            {
                if (_sameTop(probes[j], normal))
                    continue;
                above = top["position"] + normal;
                wall = bulletTrace(above, probes[j] + normal, false, undefined);
                // A missing corner is an exposed edge, not necessarily a wall.
                // Clip to that edge so the cutout never becomes checkpoint area.
                if (wall["fraction"] == 1)
                {
                    wall = bulletTrace(probes[j] - normal, start, false, undefined);
                    wall["normal"] = vectorScale(wall["normal"], -1);
                }
                if (wall["fraction"] == 1 || abs(vectorDot(wall["normal"], normal)) > 0.99)
                    return undefined;
                for (k = 0; k < 4; k++)
                {
                    faceNormal = _tangent(wall["normal"], normal);
                    denominator = vectorDot(wall["normal"], directions[k]);
                    if (abs(denominator) < 0.001)
                        continue;
                    limit = vectorDot(wall["position"] - top["position"], wall["normal"]) / denominator;
                    if (vectorDot(faceNormal, faces[k]) < -0.95 && limit > 0 && limit < distances[k] - 0.01)
                    {
                        boundary = _boundary(wall, top["position"], directions[k], normal);
                        faces[k] = vectorScale(boundary["normal"], -1);
                        distances[k] = vectorDot(boundary["position"] - top["position"], faces[k]);
                        trimmed = true;
                        break;
                    }
                }
                // An oblique raised brush may cover a probe without being a
                // boundary of the landing. Keep the original checkpoint plane;
                // standing on top of the obstruction does not pass this area.
                if (!trimmed && _solidAt(probes[j], normal))
                    continue;
                if (!trimmed)
                    return undefined;
                break;
            }
        }
        if (!trimmed)
            return points;
    }
    return undefined;
}

_side(start, direction, normal)
{
    if (!isDefined(normal))
        normal = (0, 0, 1);
    // Walk outward on this top first. Tracing back from a distant wall can hit
    // a different brush behind the platform, even when its normal looks correct.
    top = start + normal;
    // Above the landing, a wall is a boundary too. Below it, the platform and
    // adjoining wall can be one continuous solid, so a reverse trace cannot exit.
    wallStart = top + normal;
    wall = bulletTrace(wallStart, wallStart + vectorScale(direction, 4096), false, undefined);
    wallDistance = 4097;
    if (wall["fraction"] < 1 && abs(vectorDot(wall["normal"], normal)) < 0.99)
    {
        // For an inclined wall, its intersection with the landing differs from
        // the hit one unit above it. Check support just inside the actual seam.
        denominator = vectorDot(wall["normal"], direction);
        if (abs(denominator) > 0.001)
            wallDistance = vectorDot(wall["position"] - top, wall["normal"]) / denominator;
    }
    near = 0;
    far = 4;
    while (far <= 4096)
    {
        if (far >= wallDistance)
        {
            // The four-unit scan may step across a narrow gap before a wall.
            // Only use that wall if the landing actually reaches its near face.
            wallNear = wallDistance - 0.5;
            if (wallNear > near && !_sameTop(top + vectorScale(direction, wallNear), normal))
            {
                far = wallNear;
                break;
            }
            // Use an outward normal consistently for walls and exposed edges.
            wall["normal"] = vectorScale(wall["normal"], -1);
            return _boundary(wall, top, direction, normal);
        }
        if (!_sameTop(top + vectorScale(direction, far), normal))
            break;
        near = far;
        far += 4;
    }
    if (far > 4096)
        return undefined;
    for (i = 0; i < 8; i++)
    {
        mid = (near + far) * 0.5;
        if (_sameTop(top + vectorScale(direction, mid), normal))
            near = mid;
        else
            far = mid;
    }
    outside = start + vectorScale(direction, far + 0.25);
    hit = bulletTrace(outside, start, false, undefined);
    // Near a steep end face, lowering the probe can move it back inside
    // the brush. Retry just below the landing plane to recover the edge normal.
    if (hit["fraction"] == 0 && vectorDot(hit["normal"], hit["normal"]) < 0.001)
    {
        shallow = top - vectorScale(normal, 0.125);
        hit = bulletTrace(shallow + vectorScale(direction, far + 0.25), shallow, false, undefined);
    }
    if (hit["fraction"] == 1 || abs(vectorDot(hit["normal"], normal)) > 0.99)
        return undefined;
    boundary = _boundary(hit, top, direction, normal);
    if (!isDefined(boundary))
        return undefined;
    // At a thin tapered edge, collision padding on the underside is amplified
    // when intersected with the top plane. Never extrapolate past the measured
    // surface edge; retain the face orientation but use the last supported point.
    if (vectorDot(boundary["position"] - top, direction) > far + 0.25)
        boundary["position"] = top + vectorScale(direction, near);
    return boundary;
}

_sameTop(point, normal)
{
    if (!isDefined(normal))
        normal = (0, 0, 1);
    hit = bulletTrace(point + vectorScale(normal, 2), point - vectorScale(normal, 2), false, undefined);
    // A tall probe can start inside an adjoining inclined wall even though the
    // landing itself is clear. Retry close to the surface before rejecting it.
    if (hit["fraction"] < 1 && vectorDot(hit["normal"], normal) < 0.999)
        hit = bulletTrace(point + vectorScale(normal, 0.25), point - vectorScale(normal, 2), false, undefined);
    return hit["fraction"] < 1 && vectorDot(hit["normal"], normal) > 0.999 && distanceSquared(hit["position"], point) < 0.0625;
}

_tangent(vector, normal)
{
    return vectorNormalize(vector - vectorScale(normal, vectorDot(vector, normal)));
}

// Intersect the side face with the landing plane, removing the trace's height offset.
_boundary(hit, top, direction, normal)
{
    denominator = vectorDot(hit["normal"], direction);
    if (abs(denominator) < 0.001)
        return undefined;
    distance = vectorDot(hit["position"] - top, hit["normal"]) / denominator;
    hit["position"] = top + vectorScale(direction, distance);
    hit["normal"] = _tangent(hit["normal"], normal);
    return hit;
}
rectangle(origin, axis, side, distances)
{
    points = [];
    points[0] = origin + vectorScale(axis, distances[0]) + vectorScale(side, distances[1]);
    points[1] = origin - vectorScale(axis, distances[2]) + vectorScale(side, distances[1]);
    points[2] = origin - vectorScale(axis, distances[2]) - vectorScale(side, distances[3]);
    points[3] = origin + vectorScale(axis, distances[0]) - vectorScale(side, distances[3]);
    return points;
}

// Brush compilation can leave nominally rectangular sides slightly nonparallel.
// Intersect their measured planes rather than extending a small angular error
// across a long platform and placing a corner outside the actual landing.
_corners(origin, axis, side, faces, distances)
{
    points = [];
    for (i = 0; i < 4; i++)
    {
        j = (i + 1) % 4;
        a = vectorDot(faces[i], axis);
        b = vectorDot(faces[i], side);
        c = vectorDot(faces[j], axis);
        d = vectorDot(faces[j], side);
        determinant = a*d - b*c;
        x = (distances[i]*d - b*distances[j]) / determinant;
        y = (a*distances[j] - distances[i]*c) / determinant;
        points[i] = origin + vectorScale(axis,x) + vectorScale(side,y);
    }
    return points;
}

// A zero-length normal at fraction zero means the short trace starts in solid.
// Do not treat a missing surface (fraction one) as an obstruction.
_solidAt(point, normal)
{
    hit = bulletTrace(point + vectorScale(normal, 0.125), point - vectorScale(normal, 0.125), false, undefined);
    return hit["fraction"] == 0 && vectorDot(hit["normal"], hit["normal"]) < 0.001;
}
