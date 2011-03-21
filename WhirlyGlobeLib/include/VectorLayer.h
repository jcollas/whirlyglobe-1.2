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
#import "VectorData.h"
#import "GlobeMath.h"
#import "LayerThread.h"

namespace WhirlyGlobe
{
	// Used to map identities to shapes
	// Note: This is presumably mapping from drawable IDs, so we could technically do a set here
	typedef std::map<SimpleIdentity,VectorShape *> ShapeMap;
}

/* Vector description dictionary
    enable      <NSNumber bool>
    drawOffset  <NSNumber int>
    color       <UIColor>
    priority    <NSNumber int>
 */

/* Vector display layer
    Displays vector data as requested by a caller.
 */
@interface VectorLayer : NSObject<WhirlyGlobeLayer>
{
    WhirlyGlobe::GlobeScene *scene;
    WhirlyGlobeLayerThread *layerThread;
    
    // Vector data loaded in so far
    WhirlyGlobe::ShapeMap shapes;
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Look for a hit by geographic coordinate
// Note: Should accomodate multiple hits, distance and so forth
- (WhirlyGlobe::VectorShape *)findHitAtGeoCoord:(WhirlyGlobe::GeoCoord)geoCoord;

// Create geometry from the given vector
// The dictionary controls how the vector will appear
- (void)addVector:(WhirlyGlobe::VectorShape *)shape desc:(NSDictionary *)dict;

// Change an object representation according to the given attributes
- (void)changeVector:(WhirlyGlobe::SimpleIdentity)vecID desc:(NSDictionary *)dict;

// Remove the given vector by ID
- (void)removeVector:(WhirlyGlobe::SimpleIdentity)vecID;

@end
