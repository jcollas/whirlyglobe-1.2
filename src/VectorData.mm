/*
 *  VectorData.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 3/7/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "VectorData.h"
#import "ShapeReader.h"

namespace WhirlyGlobe
{

// Break any edge longer than the given length
// Returns true if it broke anything.  If it didn't, doesn't fill in outPts
void SubdivideEdges(const VectorRing &inPts,VectorRing &outPts,bool closed,float maxLen)
{
    float maxLen2 = maxLen*maxLen;
    
    for (int ii=0;ii<(closed ? inPts.size() : inPts.size()-1);ii++)
    {
        const Point2f &p0 = inPts[ii];
        const Point2f &p1 = inPts[(ii+1)%inPts.size()];
        outPts.push_back(p0);
        Point2f dir = p1-p0;
        float dist2 = dir.squaredNorm();
        if (dist2 > maxLen2)
        {
            float dist = sqrtf(dist2);
            dir /= dist;
            for (float pos=maxLen;pos<dist;pos+=maxLen)
            {                
                Point2f divPt = p0+dir*pos;
                outPts.push_back(divPt);
            }
        }
    }
    if (!closed)
        outPts.push_back(inPts.back());
}

    
VectorShape::VectorShape()
{
    attrDict = nil;
}
   
VectorShape::~VectorShape()
{
    if (attrDict) 
        [attrDict release];
}
    
void VectorShape::setAttrDict(NSMutableDictionary *newDict)
{ 
    [attrDict release];  
    attrDict = newDict;  
    [attrDict retain]; 
}
    
NSMutableDictionary *VectorShape::getAttrDict()    
{
    return attrDict;
}
    
VectorAreal::VectorAreal()
{
}
    
VectorAreal::~VectorAreal()
{
}
    
VectorArealRef VectorAreal::createAreal()
{
    return VectorArealRef(new VectorAreal());
}

    
bool VectorAreal::pointInside(GeoCoord coord)
{
    if (geoMbr.inside(coord))
    {
        for (unsigned int ii=0;ii<loops.size();ii++)
            if (PointInPolygon(coord,loops[ii]))
                return true;
    }
    
    return false;
}
    
GeoMbr VectorAreal::calcGeoMbr() 
{ 
    return geoMbr; 
}
    
void VectorAreal::initGeoMbr()
{
    for (unsigned int ii=0;ii<loops.size();ii++)
        geoMbr.addGeoCoords(loops[ii]);
}
    
void VectorAreal::subdivide(float maxLen)
{
    for (unsigned int ii=0;ii<loops.size();ii++)
    {
        VectorRing newPts;
        SubdivideEdges(loops[ii], newPts, true, maxLen);
        loops[ii] = newPts;
    }
}

VectorLinear::VectorLinear()
{
}

VectorLinear::~VectorLinear()
{
}
    
VectorLinearRef VectorLinear::createLinear()
{
    return VectorLinearRef(new VectorLinear());
}
    
GeoMbr VectorLinear::calcGeoMbr() 
{ 
    return geoMbr; 
}

void VectorLinear::initGeoMbr()
{
    geoMbr.addGeoCoords(pts);
}
    
void VectorLinear::subdivide(float maxLen)
{
    VectorRing newPts;
    SubdivideEdges(pts, newPts, true, maxLen);
    pts = newPts;
}
    
VectorPoints::VectorPoints()
{
}
    
VectorPoints::~VectorPoints()
{
}
    
VectorPointsRef VectorPoints::createPoints()
{
    return VectorPointsRef(new VectorPoints());
}

GeoMbr VectorPoints::calcGeoMbr() 
{ 
    return geoMbr; 
}

void VectorPoints::initGeoMbr()
{
    geoMbr.addGeoCoords(pts);
}
    	
}