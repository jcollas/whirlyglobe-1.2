/*
 *  GlobeMath.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/2/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "WhirlyVector.h"

namespace WhirlyGlobe
{

// Generate an (x,y,z) from geodetic values (lon,lat) in radians
Point3f PointFromGeo(GeoCoord geo);

// Degree to radians conversion
template<typename T>
T DegToRad(T deg) { return deg / 180.0 * (T)M_PI; }

// Radians to degress
template<typename T>
T RadToDeg(T rad) { return rad / (T)M_PI * 180.0; }

}
