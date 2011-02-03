/*
 *  GlobeMath.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/2/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */


#import "GlobeMath.h"

namespace WhirlyGlobe
{

Point3f PointFromGeo(GeoCoord geo) 
{ 
	float z = sinf(geo.lat());
	float rad = sqrtf(1.0-z*z);
	Point3f pt(rad*cosf(geo.lon()),rad*sinf(geo.lon()),z);
	return pt;
}
	
	
}
