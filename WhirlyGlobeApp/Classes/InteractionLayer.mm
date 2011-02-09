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
@property(nonatomic,retain) LabelLayer *labelLayer;
@property(nonatomic,retain) WhirlyGlobeView *globeView;
@end

@implementation InteractionLayer

@synthesize layerThread;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize globeView;

- (id)initWithVectorLayer:(VectorLayer *)inVecLayer labelLayer:(LabelLayer *)inLabelLayer globeView:(WhirlyGlobeView *)inGlobeView
{
	if (self = [super init])
	{
		self.vectorLayer = inVecLayer;
		self.labelLayer = inLabelLayer;
		self.globeView = inGlobeView;
		curSelect = WhirlyGlobe::EmptyIdentity;
		curLabel = WhirlyGlobe::EmptyIdentity;
		
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
	self.labelLayer = nil;
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

	// Let's rotate to where they tapped over a 1sec period
	Vector3f curUp = [globeView currentUp];
	Point3f worldLoc = msg.worldLoc;
	
	// The rotation from where we are to where we tapped
	Eigen::Quaternion<float> endRot;
	endRot.setFromTwoVectors(worldLoc,curUp);
	Eigen::Quaternion<float> curRotQuat = globeView.rotQuat;
	Eigen::Quaternion<float> newRotQuat = curRotQuat * endRot;

	// We'd like to keep the north pole pointed up
	// So we look at where the north pole is going
	Vector3f northPole = (newRotQuat * Vector3f(0,0,1)).normalized();
	if (northPole.y() != 0.0)
	{
		// Then rotate it back on to the YZ axis
		// This will keep it upward
		float ang = atanf(northPole.x()/northPole.y());
		// However, the pole might be down now
		// If so, rotate it back up
		if (northPole.y() < 0.0)
			ang += M_PI;
		Eigen::AngleAxisf upRot(ang,worldLoc);
		newRotQuat = newRotQuat * upRot;
	}
	
	[globeView animateToRotation:newRotQuat howLong:1.0];
	
	// Now we need to switch over to the layer thread for the rest of this
	[self performSelector:@selector(pickObject:) onThread:layerThread withObject:msg waitUntilDone:NO];
}

// Try to pick an object
// We're in the layer thread
- (void)pickObject:(TapMessage *)msg
{
	// Look for a vector feature
	WhirlyGlobe::VectorShape *shape = [vectorLayer findHitAtGeoCoord:msg.whereGeo];

	// Unselect old object
	if (curSelect != WhirlyGlobe::EmptyIdentity)
	{
		[vectorLayer unSelectObject:curSelect];
		[labelLayer removeLabel:curLabel];
	}

	// Select new object
	if (shape)
	{
		curSelect = shape->getId();
		[vectorLayer selectObject:curSelect];
		NSDictionary *attrDict = shape->getAttrDict();

		// Put together a label
		LabelInfo *labelInfo = [[[LabelInfo alloc] init] autorelease];
		// We happen to know that the ADMIN field is the country name
		labelInfo.str = [attrDict objectForKey:@"ADMIN"];
		labelInfo.font = [UIFont systemFontOfSize:32.0];
		labelInfo.textColor = [UIColor whiteColor];
		labelInfo.backgroundColor = [UIColor clearColor];

		// We'll try to fit this label in to the MBR of the first loop
		WhirlyGlobe::VectorAreal *theAreal = dynamic_cast<WhirlyGlobe::VectorAreal *> (shape);
		if (theAreal && theAreal->loops.size())
		{
			// We need to find the largest loop.
			// It's there that we want to place the label
			float largeArea = 0.0;
			WhirlyGlobe::VectorRing *largeLoop = NULL;
			for (unsigned int ii=0;ii<theAreal->loops.size();ii++)
			{
				WhirlyGlobe::VectorRing *thisLoop = &(theAreal->loops[ii]);
				float thisArea = WhirlyGlobe::GeoMbr(*thisLoop).area();
				if (!largeLoop || (thisArea > largeArea))
				{
					largeArea = thisArea;
					largeLoop = thisLoop;
				}
			}
			
			// Now get a width in the direction we care about
			WhirlyGlobe::GeoMbr ringMbr(*largeLoop);
			Point3f pt0 = PointFromGeo(ringMbr.ll());
			Point3f pt1 = PointFromGeo(ringMbr.lr());
			labelInfo.width = (pt1-pt0).norm() * 0.5;
			// Don't let the width get too crazy
			if (labelInfo.width > 0.1)
			{
				labelInfo.width = 0.0;
				labelInfo.height = 0.05;
			}
			[labelInfo setLoc:ringMbr.mid()];
		} else {
			[labelInfo setLoc:msg.whereGeo];
			// This is just a uniform height if we picked something non-areal
			labelInfo.height = 0.05;
		}
						   
		// Label layer will do the rest
		curLabel = [labelLayer addLabel:labelInfo];
	}
}

@end
