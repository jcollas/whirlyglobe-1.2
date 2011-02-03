/*
 *  ShapeDisplay.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import <vector>
#import <Foundation/Foundation.h>
#import "DataLayer.h"
#import "GlobeMath.h"

// Vertical offset.
// Note: Needs to be calculated
static const float ShapeOffset = 0.001;

namespace WhirlyGlobe
{
	
// Base class for vector shapes
// Basically here so we can dynamic cast
class VectorShape
{
public:
	VectorShape() { };
	virtual ~VectorShape() { };
};

typedef std::vector<Point2f> VectorRing;
	
// Simple shape representation
class VectorAreal : public VectorShape
{
public:
	std::vector<VectorRing> loops;
};
	
/* Vector Loader
	Base class for loading a vector data file.
	Fill this in to hand data over to the Vector Layer.
 */
class VectorLoader
{
public:
	VectorLoader() { }
	virtual ~VectorLoader() { };
	
	// Return false if we failed to load
	virtual bool isValid() = 0;

	// Return one of the vector types
	// Keep enough state to figure out what the next one is
	virtual VectorShape *getNextObject() = 0;
};
	
}

	
/* Vector display layer
	Overlays a shape file on top of the globe.
 */
@interface VectorLayer : NSObject<WhirlyGlobeLayer>
{
	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobe::VectorLoader *loader;
}

// Need a vector loader to pull data from
- (id)initWithLoader:(WhirlyGlobe::VectorLoader *)loader;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end