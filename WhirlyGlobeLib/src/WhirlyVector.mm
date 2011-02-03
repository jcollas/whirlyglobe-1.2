/*
 *  WhirlyVector.cpp
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/25/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "WhirlyVector.h"

namespace WhirlyGlobe
{
	
Mbr::Mbr(const std::vector<Point2f> &pts)
{
	for (unsigned int ii=0;ii<pts.size();ii++)
		addPoint(pts[ii]);
}
	
void Mbr::addPoint(Point2f pt)
{
	if (!valid())
	{
		pt_ll = pt_ur = pt;  
		return;
	}
	
	pt_ll.x() = std::min(pt_ll.x(),pt.x());  
	pt_ll.y() = std::min(pt_ll.y(),pt.y());
	pt_ur.x() = std::max(pt_ur.x(),pt.x());
	pt_ur.y() = std::max(pt_ur.y(),pt.y());
}

// Calculate MBR overlap.  All the various kinds.
bool Mbr::overlaps(const Mbr &that) const
{
	Point2f ul(),lr();
	
	// Basic inclusion cases
	if ((that.inside(pt_ll) || that.inside(pt_ur) || that.inside(Point2f(pt_ll.x(),pt_ur.y())) || that.inside(Point2f(pt_ur.x(),pt_ll.y()))) ||
		(inside(that.pt_ll) || inside(that.pt_ur) || inside(Point2f(that.pt_ll.x(),that.pt_ur.y())) || inside(Point2f(that.pt_ur.x(),that.pt_ll.y()))))
		return true;
	
	// How for the skinny overlap cases
	if ((that.pt_ll.x() <= pt_ll.x() && pt_ur.x() <= that.pt_ur.x() &&
		 pt_ll.y() <= that.pt_ll.y() && that.pt_ur.y() <= pt_ur.y()) ||
		(pt_ll.x() <= that.pt_ll.x() && that.pt_ur.x() <= pt_ur.x() &&
		 that.pt_ll.y() <= pt_ll.y() && pt_ur.y() <= that.pt_ur.y()))
		return true;
	if ((pt_ll.x() <= that.pt_ll.x() && that.pt_ur.x() <= pt_ur.x() &&
		 that.pt_ll.y() <= pt_ll.y() && pt_ur.y() <= that.pt_ur.y()) ||
		(that.pt_ll.x() <= pt_ll.x() && pt_ur.x() <= that.pt_ur.x() &&
		 pt_ll.y() <= that.pt_ll.y() && that.pt_ur.y() <= pt_ur.y()))
		return true;
	
	return false;
}

// Expand the MBR by this coordinate
void GeoMbr::addGeoCoord(GeoCoord coord)
{
	if (!valid())
	{
		pt_ll = pt_ur = coord;
		return;
	}
	
	pt_ll.x() = std::min(pt_ll.x(),coord.x());
	pt_ll.y() = std::min(pt_ll.y(),coord.y());
	pt_ur.x() = std::max(pt_ur.x(),coord.x());
	pt_ur.y() = std::max(pt_ur.y(),coord.y());
}
	
bool GeoMbr::overlaps(const GeoMbr &that) const
{
	std::vector<Mbr> mbrsA,mbrsB;

	splitIntoMbrs(mbrsA);
	that.splitIntoMbrs(mbrsB);
	
	for (unsigned int aa=0;aa<mbrsA.size();aa++)
		for (unsigned int bb=0;bb<mbrsB.size();bb++)
			if (mbrsA[aa].overlaps(mbrsB[bb]))
				return true;
	
	return false;
}
	
bool GeoMbr::inside(GeoCoord coord) const
{
	std::vector<Mbr> mbrs;
	splitIntoMbrs(mbrs);
	
	for (unsigned int ii=0;ii<mbrs.size();ii++)
		if (mbrs[ii].inside(coord))
			return true;
	
	return false;
}
	
// Break a a geoMbr into one or two pieces
// If we overlap -180/+180 then we need two mbrs
void GeoMbr::splitIntoMbrs(std::vector<Mbr> &mbrs) const
{
	// Simple case
	if (pt_ll.x() <= pt_ur.x())
		mbrs.push_back(Mbr(pt_ll,pt_ur));
	else {
		mbrs.push_back(Mbr(pt_ll,Point2f((float)M_PI,pt_ur.y())));
		mbrs.push_back(Mbr(Point2f(((float)-M_PI,pt_ll.y())),pt_ur));
	}
}

}
