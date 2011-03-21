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

@synthesize regionShapeFiles;
@synthesize regionInteriorFiles;
@synthesize countryDesc;
@synthesize oceanDesc;
@synthesize disableDesc;

@synthesize layerThread;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize globeView;

- (id)initWithVectorLayer:(VectorLayer *)inVecLayer labelLayer:(LabelLayer *)inLabelLayer globeView:(WhirlyGlobeView *)inGlobeView
{
	if ((self = [super init]))
	{
		self.vectorLayer = inVecLayer;
		self.labelLayer = inLabelLayer;
		self.globeView = inGlobeView;
        
        self.regionShapeFiles = [[[NSMutableArray alloc] init] autorelease];
        self.regionInteriorFiles = [[[NSMutableArray alloc] init] autorelease];
        
        // Visual representation for countries when they first appear
        self.countryDesc = [NSDictionary 
                            dictionaryWithObject:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"enable",
                             [NSNumber numberWithInt:1],@"drawOffset",
                             [UIColor whiteColor],@"color",
                             nil]
                            forKey:@"shape"
                            ];
        // Visual representation for oceans (off, initially)
        self.countryDesc = [NSDictionary
                            dictionaryWithObject:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"enable",
                             [NSNumber numberWithInt:2],@"drawOffset",
                             [UIColor whiteColor],@"color",
                             nil]
                            forKey:@"shape"
                            ];
        // Used to disable a visual representation
        self.disableDesc = [NSDictionary
                            dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:NO],@"enable",
                            nil];
        
		// Register for the tap events
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSelector:) name:WhirlyGlobeTapMsg object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	self.layerThread = nil;
    self.globeView = nil;
    self.vectorLayer = nil;
    self.labelLayer = nil;
    self.regionShapeFiles = nil;
    self.regionInteriorFiles = nil;
    self.countryDesc = nil;
    self.oceanDesc = nil;
    self.disableDesc = nil;
    
	[super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	self.layerThread = inThread;
	scene = inScene;
}

// Called by the vector loader when a country is loaded in
// We're in the layer thread
- (void)countryShape:(VectorLoaderInfo *)info
{
    // Let's keep track of the ID for later use
    countryIDs.insert(info.shape->getId());
}

// Called by the vector loader when an ocean is loaded in
// We're in the layer thread
- (void)oceanShape:(VectorLoaderInfo *)info
{
}

// Somebody tapped the globe
// We're in the main thread here
- (void)tapSelector:(NSNotification *)note
{
	TapMessage *msg = note.object;

	// If we were rotating from one point to another, stop
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

// Figure out where to put a label
//  and roughly how big.  Loc is already set.  We may tweak it.
- (void)calcLabelPlacement:(WhirlyGlobe::VectorShape *)shape loc:(WhirlyGlobe::GeoCoord &)loc desc:(NSMutableDictionary *)desc
{
    double width=0.0,height=0.0;
    
    // We'll try to fit this label in to the MBR of the first loop
    WhirlyGlobe::VectorAreal *theAreal = dynamic_cast<WhirlyGlobe::VectorAreal *> (shape);
    if (theAreal && !theAreal->loops.empty())
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
        width = (pt1-pt0).norm() * 0.5;
        // Don't let the width get too crazy
        if (width > 0.5)
        {
            width = 0.5;
        }
        loc = ringMbr.mid();
    } else {
        // This is just a uniform height if we picked something non-areal
        height = 0.05;
    }
    
    // Fill in the appropriate dictionary fields
    [desc setObject:[NSNumber numberWithDouble:width] forKey:@"width"];
    [desc setObject:[NSNumber numberWithDouble:height] forKey:@"height"];
}

// Unselect everything we've currently got up
// We're in the layer thread
- (void)unselectAll
{
    // Turn off the shapes
    for (SimpleIDSet::iterator it=countryIDs.begin();it!=countryIDs.end();++it)
        [vectorLayer changeVector:*it desc:disableDesc];
    // Remove the labels
    for (SimpleIDSet::iterator it=labelIDs.begin();it!=labelIDs.end();++it)
        [labelLayer removeLabel:*it];
    labelIDs.clear();
}

// Select a single country
// We're in the layer thread
- (void)selectCountry:(WhirlyGlobe::VectorShape *)shape
{
    [vectorLayer changeVector:shape->getId() desc:countryDesc];

    // Make a label for this country
    NSDictionary *shapeAttrs = shape->getAttrDict();
    NSString *name = [shapeAttrs objectForKey:@"ADMIN"];
    if (name)
    {
        NSMutableDictionary *labelDesc = [[[NSMutableDictionary alloc] init] autorelease];
        [labelDesc setObject:[NSNumber numberWithInt:4] forKey:@"drawOffset"];
        WhirlyGlobe::GeoCoord loc;
        [self calcLabelPlacement:shape loc:loc desc:labelDesc];
        WhirlyGlobe::SimpleIdentity labelId = [labelLayer addLabel:name loc:loc desc:labelDesc];
        labelIDs.insert(labelId);
    }
}

// Try to pick an object
// We're in the layer thread
- (void)pickObject:(TapMessage *)msg
{
	// Look for a vector feature
	WhirlyGlobe::VectorShape *shape = [vectorLayer findHitAtGeoCoord:msg.whereGeo];

    if (shape)
    {
        // Unselect everything, then reselect the country
        [self unselectAll];
        [self selectCountry:shape];
    } else {
        // If we selected nothing, turn our countries back on
        for (SimpleIDSet::iterator it=countryIDs.begin();it!=countryIDs.end();++it)
            [vectorLayer changeVector:*it desc:countryDesc];
    }
}

@end
