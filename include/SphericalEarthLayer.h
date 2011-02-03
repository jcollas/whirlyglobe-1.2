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

// Each chunk of the globe is broken into this many units
static const unsigned int SphereTessX = 10,SphereTessY = 25;
//static const unsigned int SphereTessX = 20,SphereTessY = 50;

/* Spherical Earth Model
	For now, a model of the earth as a sphere.
	Eventually, this needs to be an ellipse and so forth.
	It's used to generate the geometry (and cull info) for drawing
     and used to index the culling array it creates for other
     uses.
 */
@interface SphericalEarthLayer : NSObject<WhirlyGlobeLayer>
{
	TextureGroup *texGroup;
	WhirlyGlobe::GlobeScene *scene;
	unsigned int xDim,yDim;
	unsigned int chunkX,chunkY;
//	float radius;  // 1.0 by default
}

// Init in the main thread
- (id)initWithTexGroup:(TextureGroup *)texGroup;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end
