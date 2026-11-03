#include openCJ\util;

above(cp)
{
    if (isDefined(cp.heightAbove)) return cp.heightAbove;
    return 0;
}
same(a,b)
{
    return above(a)==above(b);
}
valid(value)
{
    return value>=0 && value<=16384;
}

// A curved manual selection becomes a horizontal footprint at its lowest corner.
// Planar sloped selections retain their original plane.
flatten(cp)
{
    if(cp.points.size<4 || openCJ\checkpointArea::validate(cp.points)!="All corners must lie on the same plane")return false;
    low=cp.points[0][2];high=low;
    for(i=1;i<cp.points.size;i++){low=min(low,cp.points[i][2]);high=max(high,cp.points[i][2]);}
    for(i=0;i<cp.points.size;i++)cp.points[i]=(cp.points[i][0],cp.points[i][1],low);
    cp.heightAbove=max(above(cp),high-low);
    return true;
}

planeZ(points,p)
{
    n=openCJ\checkpointArea::planeNormal(points);
    return points[0][2]-(n[0]*(p[0]-points[0][0])+n[1]*(p[1]-points[0][1]))/n[2];
}
lower(points,cp,p){return planeZ(points,p)-2;}
upper(points,cp,p){return planeZ(points,p)+4+openCJ\checkpointArea::supportOffset(points)+above(cp);}

// Clip an XY polygon against a linear inequality evaluated at its vertices.
clipValues(points,values)
{
    out=[];
    for(i=0;i<points.size;i++)
    {
        j=(i+1)%points.size;a=values[i];b=values[j];
        if(a>=0)out[out.size]=points[i];
        if((a<0 && b>0)||(a>0 && b<0))out[out.size]=points[i]+vectorScale(points[j]-points[i],a/(a-b));
    }
    return out;
}
xyArea(points)
{
    sum=0;
    for(i=1;i<points.size-1;i++)sum+=openCJ\checkpointArea::_cross(points[0],points[i],points[i+1]);
    return abs(sum)*0.5;
}

// Intersection of two vertical prisms, including tilted upper/lower planes.
// Unlike centre sampling this also detects narrow crossing strips and containment.
overlap(a,ap,b,bp)
{
    if(ap.size<3 || bp.size<3)return false;
    // Cheap bounds discard unrelated platforms before polygon clipping.
    for(axis=0;axis<2;axis++)
    {
        amin=ap[0][axis];amax=amin;bmin=bp[0][axis];bmax=bmin;
        for(i=1;i<ap.size;i++){amin=min(amin,ap[i][axis]);amax=max(amax,ap[i][axis]);}
        for(i=1;i<bp.size;i++){bmin=min(bmin,bp[i][axis]);bmax=max(bmax,bp[i][axis]);}
        if(amax<=bmin || bmax<=amin)return false;
    }
    if(openCJ\checkpointArea::validate(ap)!="" || openCJ\checkpointArea::validate(bp)!="")return false;
    poly=ap;winding=1;
    if(openCJ\checkpointArea::_cross(bp[0],bp[1],bp[2])<0)winding=-1;
    for(e=0;e<bp.size && poly.size>=3;e++)
    {
        values=[];
        for(i=0;i<poly.size;i++)values[i]=winding*openCJ\checkpointArea::_cross(bp[e],bp[(e+1)%bp.size],poly[i]);
        poly=clipValues(poly,values);
    }
    for(side=0;side<2 && poly.size>=3;side++)
    {
        values=[];
        for(i=0;i<poly.size;i++)
        {
            if(side==0)values[i]=upper(ap,a,poly[i])-lower(bp,b,poly[i])-0.001;
            else values[i]=upper(bp,b,poly[i])-lower(ap,a,poly[i])-0.001;
        }
        poly=clipValues(poly,values);
    }
    return poly.size>=3 && xyArea(poly)>0.0001;
}
areas(cp)
{
    result=[];
    if(isDefined(cp.points))result[0]=cp.points;
    else if(isDefined(cp.area))result[0]=cp.area;
    if(isDefined(cp.alternatives))for(i=0;i<cp.alternatives.size;i++)result[result.size]=cp.alternatives[i];
    return result;
}
groupsOverlap(a,b)
{
    aa=areas(a);bb=areas(b);
    for(i=0;i<aa.size;i++)for(j=0;j<bb.size;j++)if(overlap(a,aa[i],b,bb[j]))return true;
    return false;
}
sameArea(a,b)
{
    if(a.size!=b.size)return false;
    for(i=0;i<a.size;i++)
    {
        found=false;
        for(j=0;j<b.size;j++)if(distanceSquared(a[i],b[j])<0.0001)found=true;
        if(!found)return false;
    }
    return true;
}
isSelectedCopy(cp,selected)
{
    if(!isDefined(selected))return false;
    a=areas(cp);b=areas(selected);
    for(i=0;i<a.size;i++)for(j=0;j<b.size;j++)if(sameArea(a[i],b[j]))return true;
    return false;
}

conflict(candidate)
{
    selected=undefined;
    if(self.cpc.selected<self.cpc.rows.size)selected=openCJ\checkpointCreation::_decode(self.cpc.rows[self.cpc.selected]);
    for(i=0;i<self.cpc.rows.size;i++)if(i!=self.cpc.selected)
    {
        other=openCJ\checkpointCreation::_decode(self.cpc.rows[i]);
        if(groupsOverlap(candidate,other))return "checkpoint "+(i+1)+" in "+self.cpc.route;
    }
    // Check this account's other saved drafts, including their pending selection.
    prefix=self openCJ\login::getPlayerID()+"_"+getCvar("mapname")+"_";
    files=opencjScanDir(getCvar("fs_homepath")+"/"+getCvar("fs_game")+"/checkpoints/drafts");names=[];
    if(isDefined(files))for(i=0;i<files.size;i++)
    {
        name=openCJ\checkpointList::draftName(files[i],prefix);
        if(isDefined(name) && name!=self.cpc.route)names[name]=true;
    }
    keys=getArrayKeys(names);
    for(k=0;k<keys.size;k++)
    {
        part=self openCJ\checkpointNetwork::readSection(keys[k]);if(!isDefined(part))continue;
        for(i=0;i<=part.rows.size;i++)
        {
            if(i<part.rows.size)other=openCJ\checkpointCreation::_decode(part.rows[i]);else other=part.draft;
            if(!isDefined(other)||isSelectedCopy(other,selected))continue;
            if(groupsOverlap(candidate,other))return "checkpoint "+(i+1)+" in draft "+keys[k];
        }
    }
    if(isDefined(level.checkpoints_checkpoints))for(i=0;i<level.checkpoints_checkpoints.size;i++)
    {
        other=level.checkpoints_checkpoints[i];
        if(!isDefined(other)||isSelectedCopy(other,selected))continue;
        if(groupsOverlap(candidate,other))return "published checkpoint #"+other.id;
        // Old radius checkpoints have no polygon; conservatively protect their bounds.
        if(!isDefined(other.area) && isDefined(other.radius))
        {
            legacy=openCJ\checkpointCreation::_empty();r=other.radius;p=other.origin;
            legacy.points[0]=p+(0-r,0-r,0);legacy.points[1]=p+(r,0-r,0);legacy.points[2]=p+(r,r,0);legacy.points[3]=p+(0-r,r,0);
            legacy.heightAbove=2*r;
            for(j=0;j<legacy.points.size;j++)legacy.points[j]-=(0,0,r);
            if(groupsOverlap(candidate,legacy))return "legacy checkpoint #"+other.id;
        }
    }
    return "";
}

edit(action)
{
    if(action=="height" && isDefined(self.cpc.heightTarget)){self.cpc.heightTarget=undefined;return;}
    cp=self.cpc.draft;
    if(openCJ\checkpointMoving::isMoving(cp)){self.cpc.status="Whole moving platforms do not use height offsets";return;}
    candidate=openCJ\checkpointCreation::_decode(openCJ\checkpointCreation::_encode(cp));
    if(flatten(candidate))
    {
        error=self conflict(candidate);
        if(error!=""){self.cpc.status="Height unchanged: overlaps "+error;self sendLocalChatMessage(self.cpc.status,true);return;}
        self.cpc.draft=candidate;cp=candidate;
        self sendLocalChatMessage("Using the lowest corner as the base; Upper covers the selected corner heights.");
    }
    if(openCJ\checkpointArea::validate(cp.points)!=""){self.cpc.status="Select at least three valid corners before editing height";return;}
    if(action=="height")
    {
        self.cpc.heightTarget="upper";
        return;
    }
    value=above(cp);
    if(action=="heightup")value+=4;
    else if(action=="heightdown")value=max(0,value-4);
    else value=self.cpc.heightRequestValue;
    if(!valid(value)){self.cpc.status="Height offset must be between 0 and 16384 units";return;}
    candidate=openCJ\checkpointCreation::_decode(openCJ\checkpointCreation::_encode(cp));
    candidate.heightAbove=value;
    if(value>above(cp))
    {
        error=self conflict(candidate);
        if(error!=""){self.cpc.status="Height unchanged: overlaps "+error;self sendLocalChatMessage(self.cpc.status,true);return;}
    }
    self.cpc.draft=candidate;
    self.cpc.status="";
}
