/*
 *  WhirlyGeometry.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/18/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "WhirlyVector.h"

namespace WhirlyGlobe
{

// Intersect a unit sphere with the given origin/vector
// Return true if we found one
// Returns the intersection in hit or the closest pass
bool IntersectUnitSphere(Point3f org,Vector3f dir,Point3f &hit);
	
// Point in polygon test
bool PointInPolygon(Point2f pt,const std::vector<Point2f> &ring);

}
