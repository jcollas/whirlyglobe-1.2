/*
 *  GridLines.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/25/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import "DataLayer.h"
#import "GlobeScene.h"

static const float GlobeLineOffset = 0.01;
static const float GridCellSize = 3*(float)M_PI/180.0;

/* Grid Line Layer
	Sets up a set of grid lines
 */
@interface GridLayer : NSObject<WhirlyGlobeLayer>
{
	unsigned int numX,numY;
	unsigned int chunkX,chunkY;
	WhirlyGlobe::GlobeScene *scene;
}

// Initialize with the number of chunks of lines we want
- (id)initWithX:(unsigned int)numX Y:(unsigned int)numY;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end
