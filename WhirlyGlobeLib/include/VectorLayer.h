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
#import <set>
#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "DataLayer.h"
#import "GlobeMath.h"

// Vertical offset.
// Note: Needs to be calculated
static const float ShapeOffset = 0.001;

namespace WhirlyGlobe
{
	
// Base class for vector shapes
// Basically here so we can dynamic cast
class VectorShape : public Identifiable
{
public:
	VectorShape() { drawableId = EmptyIdentity; attrDict = nil; }
	virtual ~VectorShape() { if (attrDict) [attrDict release]; }
	
	SimpleIdentity getDrawableId() const { return drawableId; }
	void setDrawableId(SimpleIdentity inId) { drawableId = inId; }

	// Set the attribute dictionary
	void setAttrDict(NSMutableDictionary *newDict) { [attrDict release];  attrDict = newDict;  [attrDict retain]; }
	
	// Return the attr dict
	NSMutableDictionary *getAttrDict() { return attrDict; }
		
protected:
	// If set, points to drawable
	SimpleIdentity drawableId;
	// Attributes for this feature
	NSMutableDictionary *attrDict;
};

typedef std::vector<Point2f> VectorRing;

// Simple shape representation
class VectorAreal : public VectorShape
{
public:
	std::vector<VectorRing> loops;
	GeoMbr geoMbr;
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
	
typedef std::map<SimpleIdentity,VectorShape *> ShapeMap;

}
	
// This is invoked by the vector layer after it creates a drawable
// It gives you the opportunity to mess with that drawable before it's
//  handed over to the scene.
// You will be called in the layer thread.  Act accordingly.
// *DO NOT* keep a copy of these pointers.
@protocol LayerDrawableDelegate
// Mess with the drawable as it suits your task
- (void)setupDrawable:(WhirlyGlobe::BasicDrawable *)drawable shape:(WhirlyGlobe::VectorShape *)shape;
@end

/* Vector display layer
	Overlays a shape file on top of the globe.
 */
@interface VectorLayer : NSObject<WhirlyGlobeLayer>
{
	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobe::VectorLoader *loader;
	// Vector data loaded in so far
	WhirlyGlobe::ShapeMap shapes;
	NSObject<LayerDrawableDelegate> *drawableDelegate;
}

// Need a vector loader to pull data from
- (id)initWithLoader:(WhirlyGlobe::VectorLoader *)loader;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Look for a hit by geographic coordinate
// Note: Should accomodate multiple hits, distance and so forth
- (WhirlyGlobe::VectorShape *)findHitAtGeoCoord:(WhirlyGlobe::GeoCoord)geoCoord;

// Make an object visibly selected
- (void)selectObject:(WhirlyGlobe::SimpleIdentity)simpleId;

// Clear outstanding selection
- (void)unSelectObject:(WhirlyGlobe::SimpleIdentity)simpleId;

// Set this delegate to get called right after the layer has created and
//  set up a drawable.  You can then mess with the settings.
// You will be called in the layer thread.
- (void)setDrawableDelegate:(NSObject<LayerDrawableDelegate> *)delegate;

@end