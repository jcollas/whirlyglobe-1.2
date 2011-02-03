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

namespace WhirlyGlobe
{

static const float ShapeOffset = 0.001;
	
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
	
/* Shape File Model
	Overlays a shape file on top of the globe.
 */
class VectorLayer : public DataLayer
{
public:
	// Supply a loader on construction
	// We'll pull data from that i
	VectorLayer(VectorLoader *);
	~VectorLayer();
	
	// Inherited from DataLayer
	virtual void init() { }

	// Generate drawables for the scene
	virtual void process(GlobeScene *scene);
	
protected:
	VectorLoader *loader;
};

}
