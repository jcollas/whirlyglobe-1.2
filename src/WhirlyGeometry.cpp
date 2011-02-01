/*
 *  WhirlyGeometry.cpp
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/18/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "WhirlyGeometry.h"

namespace WhirlyGlobe
{

bool IntersectUnitSphere(Point3f org,Vector3f dir,Point3f &hit)
{
	float a = dir.dot(dir);
	float b = 2.0f * org.dot(dir);
	float c = org.dot(org) - 1.0;
	
	float sq = b*b - 4.0f * a * c;
	if (sq < 0.0)
		return false;
	
	float rt = sqrtf(sq);
	float ta = (-b + rt) / (2.0f * a);
	float tb = (-b - rt) / (2.0f * a);
	
	float t = std::min(ta,tb);
	
	hit = org + dir * t;
	return true;
}
	
}
