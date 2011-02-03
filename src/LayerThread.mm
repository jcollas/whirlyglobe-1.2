//
//  LayerThread.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 2/2/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "LayerThread.h"

@interface WhirlyGlobeLayerThread()
@property(nonatomic,retain) NSMutableArray<NSObject> *layers;
@end

@implementation WhirlyGlobeLayerThread

@synthesize layers;

- (id)initWithScene:(WhirlyGlobe::GlobeScene *)inScene
{
	if (self = [super init])
	{
		scene = inScene;
		self.layers = [[[NSMutableArray alloc] init] autorelease];
	}
	
	return self;
}

- (void)dealloc
{
	// This should release the layers
	self.layers = nil;
	
	[super dealloc];
}

- (void)addLayer:(NSObject<WhirlyGlobeLayer> *)layer
{
	[layers addObject:layer];
}

// Called to start the thread
// We'll just spend our time in here
- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	
	// Wake up our layers.  It's up to them to do the rest
	for (unsigned int ii=0;ii<[layers count];ii++)
	{
		NSObject<WhirlyGlobeLayer> *layer = [layers objectAtIndex:ii];
		[layer startWithThread:self scene:scene];
	}

	// Process the run loop until we're cancelled
	// We'll check every 10th of a second
	while (![self isCancelled])
	{
		[runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
	
	[pool release];
}

@end
