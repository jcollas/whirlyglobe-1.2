//
//  InteractionLayer.mm
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 2/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "InteractionLayer.h"

@interface InteractionLayer()
@property(nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property(nonatomic,retain) VectorLayer *vectorLayer;
@property(nonatomic,retain) WhirlyGlobeView *globeView;
@end

@implementation InteractionLayer

@synthesize layerThread;
@synthesize vectorLayer;
@synthesize globeView;

- (id)initWithVectorLayer:(VectorLayer *)layer globeView:(WhirlyGlobeView *)inGlobeView
{
	if (self = [super init])
	{
		self.vectorLayer = layer;
		self.globeView = inGlobeView;
		curSelect = WhirlyGlobe::EmptyIdentity;
		
		// Register for the tap events
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSelector:) name:WhirlyGlobeTapMsg object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.layerThread = nil;
	self.vectorLayer = nil;
	self.globeView = nil;
	[super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	self.layerThread = inThread;
	scene = inScene;
}

// Somebody tapped the globe
// We're in the main thread here
- (void)tapSelector:(NSNotification *)note
{
	TapMessage *msg = note.object;
	
	[globeView cancelAnimation];

	// Let's rotate to where they tapped over 1s
	Vector3f curUp = [globeView currentUp];
	Eigen::Quaternion<float> endRot;
	Point3f worldLoc = msg.worldLoc;
	endRot.setFromTwoVectors(worldLoc,curUp);
	Eigen::Quaternion<float> curRotQuat = globeView.rotQuat;
	Eigen::Quaternion<float> newRotQuat = (curRotQuat * endRot);
	[globeView animateToRotation:newRotQuat howLong:1.0];
	
	// Now we need to switch over to the layer thread for the rest of this
	[self performSelector:@selector(pickObject:) onThread:layerThread withObject:msg waitUntilDone:NO];
}

// Try to pick an object
// The TapMessage has been retain, so we need to release it
// We're in the layer thread
- (void)pickObject:(TapMessage *)msg
{
//	[msg autorelease];
	
	// Look for a vector feature
	WhirlyGlobe::SimpleIdentity foundId = [vectorLayer findHitAtGeoCoord:msg.whereGeo];

	// Unselect old object
	if (curSelect != WhirlyGlobe::EmptyIdentity)
		[vectorLayer unSelectObject:curSelect];

	// Select new object
	if (foundId != WhirlyGlobe::EmptyIdentity)
	{
		curSelect = foundId;
		[vectorLayer selectObject:foundId];
	}
}

@end
