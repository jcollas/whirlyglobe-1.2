/*
 *  Cullable.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "GlobeScene.h"
#import "GlobeMath.h"

namespace WhirlyGlobe
{
	
void Cullable::setGeoMbr(const GeoMbr &inMbr)
{
	geoMbr = inMbr;
	
	// Turn the corner points in real world values
	cornerPoints[0] = PointFromGeo(geoMbr.ll());
	cornerPoints[1] = PointFromGeo(GeoCoord(geoMbr.ur().x(),geoMbr.ll().y()));
	cornerPoints[2] = PointFromGeo(geoMbr.ur());
	cornerPoints[3] = PointFromGeo(GeoCoord(geoMbr.ll().x(),geoMbr.ur().y()));
	
	// Normals happen to be the same
	for (unsigned int ii=0;ii<4;ii++)
		cornerNorms[ii] = cornerPoints[ii];
}

}
