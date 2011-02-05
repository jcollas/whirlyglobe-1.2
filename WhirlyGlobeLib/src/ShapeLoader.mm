/*
 *  ShapeLoader.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/2/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "ShapeLoader.h"
#import "shapefil.h"

namespace WhirlyGlobe
{

ShapeLoader::ShapeLoader(NSString *fileName)
{
	shp = SHPOpen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "rb");
	if (!shp)
		return;
	where = 0;	
	SHPGetInfo((SHPInfo *)shp, &numEntity, &shapeType, minBound, maxBound);
}
	
ShapeLoader::~ShapeLoader()
{
	if (shp)
		SHPClose((SHPInfo *)shp);
}
	
bool ShapeLoader::isValid()
{
	return shp != NULL;
}

// Return the next shape
VectorShape *ShapeLoader::getNextObject()
{
	// Reached the end
	if (where >= numEntity)
		return NULL;
	
	// Only doing polygons at the moment
	if (!(shapeType == SHPT_POLYGON || shapeType == SHPT_POLYGONZ))
		return NULL;
	
	SHPObject *thisShape = SHPReadObject((SHPInfo *)shp, where++);
	
	// Copy over vertices (in 2d)
	bool startOne = true;
	VectorAreal *areal = new VectorAreal();
	VectorRing *ring = NULL;
	for (unsigned int jj = 0, iPart = 1; jj < thisShape->nVertices; jj++)
	{
		// Add rings to the given areal until we're done
		if ( iPart < thisShape->nParts && thisShape->panPartStart[iPart] == jj)
		{
			iPart++;
			startOne = true;
		}
		
		if (startOne)
		{
			areal->loops.resize(areal->loops.size()+1);
			ring = &areal->loops.back();
			startOne = false;
		}
		
		Point2f pt(DegToRad<float>(thisShape->padfX[jj]),DegToRad<float>(thisShape->padfY[jj]));
		ring->push_back(pt);
	}
	
	SHPDestroyObject(thisShape);
	
	return areal;
}
	
}
