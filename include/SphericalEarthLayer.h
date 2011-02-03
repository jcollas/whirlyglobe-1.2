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
#import "DataLayer.h"

namespace WhirlyGlobe
{

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
class SphericalEarthLayer : public DataLayer
{
public:
	SphericalEarthLayer(TextureGroup *texGroup);
	~SphericalEarthLayer();

	// Inherited from DataLayer
	virtual void init() { };

	// Generate geometry for scene
	virtual void process(GlobeScene *scene);
	
protected:	
	bool done;
	TextureGroup *texGroup;
	unsigned int xDim,yDim;
	
//	float radius;  // 1.0 by default

};

}
