/*
 *  Cullable.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "Drawable.h"

namespace WhirlyGlobe
{	

/* Cullable unit
 This is a representation of cullable geometry.  It has
 geometry/direction info and a list of associated
 Drawables.
 Cullables are always rectangles in lon/lat.
 */
class Cullable : public Identifiable
{
public:
	Cullable() { }
	
	// Add the given drawable to our set
	void addDrawable(Drawable *drawable) { drawables.insert(drawable); }
	
	const std::set<Drawable *> &getDrawables() const { return drawables; }

	GeoMbr getGeoMbr() const { return geoMbr; }
	void setGeoMbr(const GeoMbr &inMbr);
	
public:	
	// 3D locations (in model space) of the corners
	Point3f cornerPoints[4];
	// Normal vectors (in model space) for the corners
	Vector3f cornerNorms[4];
	// Geographic coordinates of our bounding box
	GeoMbr geoMbr;
	
	std::set<Drawable *> drawables;
};

}
