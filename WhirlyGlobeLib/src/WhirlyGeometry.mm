/*
 *  WhirlyGeometry.cpp
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/18/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "WhirlyGeometry.h"

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
	
// Point in poly routine
// Courtesy: http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html

bool PointInPolygon(Point2f pt,const std::vector<Point2f> &ring)
{
	int ii, jj;
	bool c = false;
	for (ii = 0, jj = ring.size()-1; ii < ring.size(); jj = ii++) {
		if ( ((ring[ii].y()>pt.y()) != (ring[jj].y()>pt.y())) &&
			(pt.x() < (ring[jj].x()-ring[ii].x()) * (pt.y()-ring[ii].y()) / (ring[jj].y()-ring[ii].y()) + ring[ii].x()) )
			c = !c;
	}
	return c;
}

// Courtesy: http://acius2.blogspot.com/2007/11/calculating-next-power-of-2.html
unsigned int NextPowOf2(unsigned int val)
{
	val--;
	val = (val >> 1) | val;
	val = (val >> 2) | val;
	val = (val >> 4) | val;
	val = (val >> 8) | val;
	val = (val >> 16) | val;
	
	return (val + 1);
}
	
}
