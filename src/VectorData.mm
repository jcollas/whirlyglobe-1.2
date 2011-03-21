/*
 *  VectorData.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 3/7/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "VectorData.h"

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
    
GeoMbr VectorAreal::calcGeoMbr() 
{ 
    return geoMbr; 
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
}
	
void VectorPool::update()
{
	if (done)
		return;
	
	// Grab the next vector
	VectorShape *shp = reader->getNextObject();
	if (!shp)
	{
		done = true;
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
	
}
