/*
 *  VectorData.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 3/7/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "VectorData.h"
#include "ShapeReader.h"

namespace WhirlyGlobe
{
    
VectorShape::VectorShape()
{
    drawableId = EmptyIdentity;
    attrDict = nil;
}
   
VectorShape::~VectorShape()
{
    if (attrDict) 
        [attrDict release];
}
    
SimpleIdentity VectorShape::getDrawableId() const
{ 
    return drawableId; 
}
    
void VectorShape::setDrawableId(SimpleIdentity inId)
{ 
    drawableId = inId; 
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
    
VectorAreal::~VectorAreal()
{
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
    
    
VectorPool::VectorPool()
{
    curReader = 0;
}
	
VectorPool::~VectorPool()
{
	for (unsigned int ii=0;ii<areals.size();ii++)
		delete areals[ii];
	for (unsigned int ii=0;ii<linears.size();ii++)
		delete linears[ii];
	for (unsigned int ii=0;ii<points.size();ii++)
		delete points[ii];
	areals.clear();
	linears.clear();
	points.clear();
    
    for (unsigned int ii=0;ii<readers.size();ii++)
        delete readers[ii];
    readers.clear();
}
    
void VectorPool::addReader(VectorReader *reader)
{
    readers.push_back(reader);
}
    
void VectorPool::addShapeFile(NSString *fileName)
{
    VectorReader *reader = new ShapeReader(fileName);
    if (reader)
        readers.push_back(reader);
}
    
bool VectorPool::isDone()
{
    return (curReader >= readers.size());
}
	
void VectorPool::update()
{
	if (curReader >= readers.size())
		return;
	
	// Grab the next vector
	VectorShape *shp = readers[curReader]->getNextObject();
	if (!shp)
	{
        curReader++;
        return;
	}
    
	// Sort into the appropriate spot
	VectorAreal *ar = dynamic_cast<VectorAreal *> (shp);
	if (ar)
		areals.push_back(ar);
	else {
		VectorLinear *lin = dynamic_cast<VectorLinear *> (shp);
		if (lin)
			linears.push_back(lin);
		else {
			VectorPoints *pts = dynamic_cast<VectorPoints *> (shp);
			if (pts)
				points.push_back(pts);
			else
				delete shp;
		}
	}
}
    
void VectorPool::findMatches(NSPredicate *pred,std::set<VectorShape *> &shapes)
{
    for (unsigned int ii=0;ii<areals.size();ii++)
    {
        VectorShape *shape = areals[ii];
        if ([pred evaluateWithObject:shape->getAttrDict()])
            shapes.insert(shape);
    }
    for (unsigned int ii=0;ii<linears.size();ii++)
    {
        VectorShape *shape = linears[ii];
        if ([pred evaluateWithObject:shape->getAttrDict()])
            shapes.insert(shape);
    }
    for (unsigned int ii=0;ii<points.size();ii++)
    {
        VectorShape *shape = points[ii];
        if ([pred evaluateWithObject:shape->getAttrDict()])
            shapes.insert(shape);
    }
}
    
void VectorPool::findArealsForPoint(GeoCoord geoCoord,ShapeSet &shapes)
{
    for (unsigned int ii=0;ii<areals.size();ii++)
	{
		VectorAreal *theAreal = areals[ii];
        if (theAreal->pointInside(geoCoord))
            shapes.insert(theAreal);
	}
}
	
}
