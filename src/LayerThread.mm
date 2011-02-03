//
//  LayerThread.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 2/2/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "LayerThread.h"

@interface WhirlyGlobeLayerThread()
@end

@implementation WhirlyGlobeLayerThread

- (id)initWithScene:(WhirlyGlobe::GlobeScene *)inScene
{
	if (self = [super init])
	{
		scene = inScene;
		layers = new std::vector<WhirlyGlobe::DataLayer *>();
	}
	
	return self;
}

- (void)dealloc
{
	delete layers;
	
	[super dealloc];
}

- (void)addLayer:(WhirlyGlobe::DataLayer *)layer
{
	layers->push_back(layer);
}

// Called to start the thread
// We'll just spend our time in here
- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Run through the inits
	for (unsigned int ii=0;ii<layers->size();ii++)
		(*layers)[ii]->init();
	
	// We're checking, obviously, but everyone else needs to as well
	while (![self isCancelled])
	{
		// Run through the layers
		// Note: Could stand to do some timing here
		for (unsigned int ii=0;ii<layers->size();ii++)
		{
			WhirlyGlobe::DataLayer *layer = (*layers)[ii];
			layer->process(scene);
		}
	}

	// Tear it down and head out
	for (unsigned int ii=0;ii<layers->size();ii++)
		delete (*layers)[ii];
	delete layers;
	
	[pool release];
}

@end
