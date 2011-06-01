/*
 *  GlobeMath.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/2/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "WhirlyVector.h"

namespace WhirlyGlobe
{

// Generate an (x,y,z) from geodetic values (lon,lat) in radians
Point3f PointFromGeo(GeoCoord geo);
	
// Generate a (lon,lat) from a model XYZ
GeoCoord GeoFromPoint(Point3f pt);

// Degree to radians conversion
template<typename T>
T DegToRad(T deg) { return deg / 180.0 * (T)M_PI; }

// Radians to degress
template<typename T>
T RadToDeg(T rad) { return rad / (T)M_PI * 180.0; }

}
