/*
 *  SphericalEarth.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/11/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import "WhirlyVector.h"
#import "TextureGroup.h"
#import "GlobeScene.h"

namespace WhirlyGlobe
{

// Generate an (x,y,z) from geodetic values (lon,lat) in radians
Point3f PointFromGeo(GeoCoord geo);
	
// Degree to radians conversion
template<typename T>
	T DegToRad(T deg) { return deg / 180.0 * (T)M_PI; }
	
// Radians to degres
template<typename T>
	T RadToDeg(T rad) { return rad / (T)M_PI * 180.0; }

// Each chunk of the globe is broken into this many units
static const unsigned int SphereTessX = 10,SphereTessY = 25;
//static const unsigned int SphereTessX = 20,SphereTessY = 50;

/* Spherical Earth Model
	For now, a model of the earth as a sphere.
	Obviously, this needs to be an ellipse and so forth.
	It's used to generate the geometry (and cull info) for drawing
     and used to index the culling array it creates for other
     uses.
 */
class SphericalEarthModel
{
public:
	SphericalEarthModel() { }
	~SphericalEarthModel();

	// Build a set of drawables for the whole sphere
	// Pass in a texture group to match texture coordinates
	void generate(TextureGroup *texGroup);
	
	// List of displayable info
	std::vector<Cullable *> &getCullables() { return cullables; }
	
	// Given a geo mbr, return all the overlapping cullables
	void overlapping(GeoMbr geoMbr,std::vector<Cullable *> &cullables);

protected:
	void clear();
	
	unsigned int xDim,yDim;
	std::vector<Cullable *> cullables;
	std::vector<Drawable *> drawables;
	
//	float radius;  // 1.0 by default

};

}
