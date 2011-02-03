/*
 *  LayerThread.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import <vector>
#import "GlobeScene.h"
#import "DataLayer.h"

/* Layer Thread
	Layers are maintained in a separate thread and run at regular intevals.
 */
@interface WhirlyGlobeLayerThread : NSThread
{
	// Scene we're messing with
	WhirlyGlobe::GlobeScene *scene;
	
	// The various data layers we'll display
	std::vector<WhirlyGlobe::DataLayer *> *layers;
}

// Set it up with a renderer (for context) and a scene
- (id)initWithScene:(WhirlyGlobe::GlobeScene *)scene;

// Add these before you kick off the thread
- (void)addLayer:(WhirlyGlobe::DataLayer *)layer;

// We're overriding the main entry point
- (void)main;

@end
