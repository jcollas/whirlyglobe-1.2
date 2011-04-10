//
//  InteractionLayer.mm
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 2/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "InteractionLayer.h"

using namespace WhirlyGlobe;

@interface InteractionLayer()
@property(nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property(nonatomic,retain) VectorLayer *vectorLayer;
@property(nonatomic,retain) LabelLayer *labelLayer;
@property(nonatomic,retain) WhirlyGlobeView *globeView;
@end

@implementation InteractionLayer

@synthesize countryDesc;
@synthesize oceanDesc;
@synthesize regionDesc;

@synthesize layerThread;
@synthesize globeView;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize countryPool;
@synthesize oceanPool;
@synthesize regionPool;

- (id)initWithVectorLayer:(VectorLayer *)inVecLayer labelLayer:(LabelLayer *)inLabelLayer globeView:(WhirlyGlobeView *)inGlobeView
{
	if ((self = [super init]))
	{
		self.vectorLayer = inVecLayer;
		self.labelLayer = inLabelLayer;
		self.globeView = inGlobeView;
                
        // Visual representation for countries when they first appear
        self.countryDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"enable",
                             [NSNumber numberWithInt:2],@"drawOffset",
                             [NSNumber numberWithFloat:0.5],@"minVis",
                             [NSNumber numberWithFloat:10.0],@"maxVis",
                             [UIColor whiteColor],@"color",
                             nil],@"shape",
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"enable",
                             [NSNumber numberWithInt:101],@"drawOffset",
                             [NSNumber numberWithFloat:0.5],@"minVis",
                             [NSNumber numberWithFloat:10.0],@"maxVis",
                             [UIColor clearColor],@"backgroundColor",
                             [UIColor whiteColor],@"textColor",
                             nil],@"label",
                            nil];
        // Visual representation for oceans
        self.oceanDesc = [NSDictionary
                            dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"enable",
                             [NSNumber numberWithInt:1],@"drawOffset",
                             [UIColor whiteColor],@"color",
                             nil],@"shape",                          
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES],@"enable",
                           [NSNumber numberWithInt:100],@"drawOffset",
                           nil],@"label",
                            nil];
        // Visual representation of regions and their labels
        self.regionDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],@"enable",
                            [NSNumber numberWithInt:3],@"drawOffset",
                            [NSNumber numberWithFloat:0.0],@"minVis",
                            [NSNumber numberWithFloat:0.5],@"maxVis",
                            [UIColor grayColor],@"color",
                            nil],@"shape",
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithFloat:0.0],@"minVis",
                            [NSNumber numberWithFloat:0.5],@"maxVis",
                            [NSNumber numberWithBool:YES],@"enable",
                            [NSNumber numberWithInt:102],@"drawOffset",
                            nil],@"label",
                           nil];
        
        // Set up the various pools
        // The caller will toss files into those.  We'll just consume.
        countryPool = new VectorPool();
        oceanPool = new VectorPool();
        regionPool = new VectorPool();
        
        // We'll restrict the attributes we grab to cut down memory use
        // YOU MUST ADD ANY ATTRIBUTES YOU NEED TO THIS LIST
        std::vector<std::string> filterAttrs;
        filterAttrs.push_back("ADMIN");
        filterAttrs.push_back("ADM0_A3");
        filterAttrs.push_back("ISO");
        filterAttrs.push_back("NAME_1");
        filterAttrs.push_back("Name");
        countryPool->setAttrFilter(filterAttrs);
        oceanPool->setAttrFilter(filterAttrs);
        regionPool->setAttrFilter(filterAttrs);
        
		// Register for the tap and press events
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSelector:) name:WhirlyGlobeTapMsg object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pressSelector:) name:WhirlyGlobeLongPressMsg object:nil];
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
    self.countryDesc = nil;
    self.oceanDesc = nil;
    self.regionDesc = nil;
    if (countryPool)
        delete countryPool;
    if (oceanPool)
        delete oceanPool;
    if (regionPool)
        delete regionPool;
    for (FeatureRepList::iterator it = featureReps.begin();
         it != featureReps.end(); ++it)
        delete (*it);
    
	[super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	self.layerThread = inThread;
	scene = inScene;
    
    [self performSelector:@selector(process:) onThread:layerThread withObject:nil waitUntilDone:NO];
}

// Do any book keeping work that doesn't involve interaction
// We're in the layer thread
- (void)process:(id)sender
{
    countryPool->update();
    oceanPool->update();
    regionPool->update();
    
    if (!countryPool->isDone() || !oceanPool->isDone() || !regionPool->isDone())
        [self performSelector:@selector(process:) onThread:layerThread withObject:nil waitUntilDone:NO];
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

// Someone tapped and held (pressed)
// We're in the main thread here
- (void)pressSelector:(NSNotification *)note
{
	TapMessage *msg = note.object;
    
	// If we were rotating from one point to another, stop
	[globeView cancelAnimation];

    // We need to switch over to the layer thread to search our active outlines
    [self performSelector:@selector(selectObject:) onThread:layerThread withObject:msg waitUntilDone:NO];
}

// Figure out where to put a label
//  and roughly how big.  Loc is already set.  We may tweak it.
- (void)calcLabelPlacement:(std::set<WhirlyGlobe::VectorShape *> *)shapes loc:(WhirlyGlobe::GeoCoord &)loc desc:(NSMutableDictionary *)desc
{
    double width=0.0,height=0.0;    
    WhirlyGlobe::VectorRing *largeLoop = NULL;
    float largeArea = 0.0;

    // Work through all the areals that make up the country
    // We get disconnected loops (think Alaska)
    for (std::set<VectorShape *>::iterator it = shapes->begin();
         it != shapes->end(); it++)
    {        
        WhirlyGlobe::VectorAreal *theAreal = dynamic_cast<WhirlyGlobe::VectorAreal *> (*it);
        if (theAreal && !theAreal->loops.empty())
        {
            // We need to find the largest loop.
            // It's there that we want to place the label
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
            
        }
    }

    // Now get a width in the direction we care about
    if (largeLoop)
    {
        WhirlyGlobe::GeoMbr ringMbr(*largeLoop);
        Point3f pt0 = PointFromGeo(ringMbr.ll());
        Point3f pt1 = PointFromGeo(ringMbr.lr());
        width = (pt1-pt0).norm() * 0.5;
        // Don't let the width get too crazy
        width = std::min(width,0.5);
        loc = ringMbr.mid();
    } else
        height = 0.02;
    
    // Fill in the appropriate dictionary fields
    [desc setObject:[NSNumber numberWithDouble:width] forKey:@"width"];
    [desc setObject:[NSNumber numberWithDouble:height] forKey:@"height"];
}

// Find an active feature that the given point falls within
// whichShape points to the overall or region outline we may have found
// We're in the layer thread
- (FeatureRep *)findFeatureRep:(const GeoCoord &)geoCoord height:(float)heightAboveGlobe whichShape:(VectorShape **)whichShape
{
    if (whichShape)
        *whichShape = NULL;
    
    for (FeatureRepList::iterator it = featureReps.begin();
         it != featureReps.end(); ++it)
    {
        FeatureRep *feat = *it;
        // Test the large outline
        if (heightAboveGlobe > feat->midPoint) {
            for (ShapeSet::iterator it = feat->outlines.begin();
                 it != feat->outlines.end(); ++it)
            {
                VectorAreal *ar = dynamic_cast<VectorAreal *>(*it);
                if (ar->pointInside(geoCoord))
                {
                    if (whichShape)
                        *whichShape = ar;
                    return feat;
                }
            }
        } else {
            // Test the small ones
            for (ShapeSet::iterator sit = feat->subOutlines.begin();
                 sit != feat->subOutlines.end(); ++sit)
            {
                VectorAreal *ar = dynamic_cast<VectorAreal *>(*sit);
                if (ar && ar->pointInside(geoCoord))
                {
                    if (whichShape)
                        *whichShape = ar;
                    return feat;
                }
            }
        }
    }
    
    return NULL;
}

// Add a new country
// We're in the layer thread
- (FeatureRep *)addCountryRep:(VectorAreal *)ar
{
    FeatureRep *feat = new FeatureRep();
    feat->featType = FeatRepCountry;
    
    // Look for all the feature that have the same ADMIN field
    // This finds us disjoint features
    NSString *name = [ar->getAttrDict() objectForKey:@"ADMIN"];
    NSPredicate *countryPred = [NSPredicate predicateWithFormat:@"ADMIN like %@",name];
    countryPool->findMatches(countryPred,feat->outlines);
    
    // Toss up the outline(s)
    feat->midPoint = 0.5;
    feat->outlineRep = [vectorLayer addVectors:&feat->outlines desc:[countryDesc objectForKey:@"shape"]];

    NSString *region_sel = [ar->getAttrDict() objectForKey:@"ADM0_A3"];
    if (name)
    {
        // Look for regions that correspond to the country
        std::set<VectorShape *> regionShapes;
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"ISO like %@",region_sel];
        regionPool->findMatches(pred,regionShapes);

        // Make up a label for the country
        // We'll have it appear when we're farther out
        NSMutableDictionary *labelDesc = [NSMutableDictionary dictionaryWithDictionary:[countryDesc objectForKey:@"label"]];
        [labelDesc setObject:[NSNumber numberWithFloat:feat->midPoint] forKey:@"minVis"];
        [labelDesc setObject:[NSNumber numberWithFloat:100.0] forKey:@"maxVis"];
        
        // Figure out where to place the label
        WhirlyGlobe::GeoCoord loc;
        [self calcLabelPlacement:&feat->outlines loc:loc desc:labelDesc];
        feat->labelId = [labelLayer addLabel:name loc:loc desc:labelDesc];
        
        // Add all the shapes at once
        // Toss up the region as a vector
        NSMutableDictionary *regionShapeDesc = [NSMutableDictionary dictionaryWithDictionary:[regionDesc objectForKey:@"shape"]];
        [regionShapeDesc setObject:[NSNumber numberWithFloat:0.0] forKey:@"minVis"];
        [regionShapeDesc setObject:[NSNumber numberWithFloat:feat->midPoint] forKey:@"maxVis"];
        feat->subOutlinesRep = [vectorLayer addVectors:&regionShapes desc:regionShapeDesc];
        feat->subOutlines = regionShapes;

        // Add all the labels in at once
        NSMutableDictionary *regionLabelDesc = [NSMutableDictionary dictionaryWithDictionary:[regionDesc objectForKey:@"label"]];
        [regionLabelDesc setObject:[NSNumber numberWithFloat:0.0] forKey:@"minVis"];
        [regionLabelDesc setObject:[NSNumber numberWithFloat:feat->midPoint] forKey:@"maxVis"];
        [regionLabelDesc setObject:[UIColor whiteColor] forKey:@"textColor"];
        [regionLabelDesc setObject:[UIColor clearColor] forKey:@"backgroundColor"];
        NSMutableArray *labels = [[[NSMutableArray alloc] init] autorelease];
        for (std::set<VectorShape *>::iterator it=regionShapes.begin();
             it != regionShapes.end(); ++it)
        {
            NSString *regionName = [(*it)->getAttrDict() objectForKey:@"NAME_1"];
            if (regionName)
            {
                WhirlyGlobe::GeoCoord regionLoc;
                SingleLabel *sLabel = [[[SingleLabel alloc] init] autorelease];
                NSMutableDictionary *thisDesc = [NSMutableDictionary dictionary];
                ShapeSet canShapes;
                canShapes.insert(*it);
                [self calcLabelPlacement:&canShapes loc:regionLoc desc:thisDesc];
                sLabel.loc = regionLoc;
                sLabel.text = regionName;
                sLabel.desc = thisDesc;
                [labels addObject:sLabel];
            }
        }
        if ([labels count] > 0)
            feat->subLabels = [labelLayer addLabels:labels desc:regionLabelDesc];
    }
    
    featureReps.push_back(feat);
    return feat;
}

// Add a new ocean
// We're in the layer thread
- (FeatureRep *)addOceanRep:(VectorAreal *)ar
{
    FeatureRep *feat = new FeatureRep();
    feat->featType = FeatRepOcean;
    // Outline
    feat->outlines.insert(ar);
    feat->midPoint = 0.0;
    // Not making the outline visible.  Ugly
//    [vectorLayer addVector:ar desc:[oceanDesc objectForKey:@"shape"]];
    
    NSString *name = [ar->getAttrDict() objectForKey:@"Name"];
    if (name)
    {
        // Make up a label for the country
        // We'll have it appear when we're farther out
        NSMutableDictionary *labelDesc = [NSMutableDictionary dictionaryWithDictionary:[oceanDesc objectForKey:@"label"]];
        
        // Figure out where to place it
        WhirlyGlobe::GeoCoord loc;
        ShapeSet canShapes;
        canShapes.insert(ar);
        [self calcLabelPlacement:&canShapes loc:loc desc:labelDesc];
        feat->labelId = [labelLayer addLabel:name loc:loc desc:labelDesc];
    }
    
    featureReps.push_back(feat);
    return feat;
}

// Remove the given feature representation
// Including all its vectors and labels at various levels
- (void)removeFeatureRep:(FeatureRep *)feat
{
    FeatureRepList::iterator it = std::find(featureReps.begin(),featureReps.end(),feat);
    if (it != featureReps.end())
    {
        // Remove the vectors
        [vectorLayer removeVector:feat->outlineRep];
        [vectorLayer removeVector:feat->subOutlinesRep];

        // Remove labels
        if (feat->labelId)
            [labelLayer removeLabel:feat->labelId];
        [labelLayer removeLabel:feat->subLabels];
        
        featureReps.erase(it);
        delete feat;
    }
}

// Try to pick an object
// We're in the layer thread
- (void)pickObject:(TapMessage *)msg
{
    GeoCoord coord = msg.whereGeo;
    
    // Let's look for objects we're already representing
    FeatureRep *theFeat = [self findFeatureRep:coord height:msg.heightAboveGlobe whichShape:NULL];
    
    // We found a country or its regions
    if (theFeat)
    {
        // Turn the country/ocean off
        if (msg.heightAboveGlobe >= theFeat->midPoint)
            [self removeFeatureRep:theFeat];
        else {
            // Selected a region
            
        }
    } else {
        // Look for a country first
        ShapeSet foundShapes;
        countryPool->findArealsForPoint(coord,foundShapes);
        if (!foundShapes.empty())
        {
            // Toss in anything we found
            for (ShapeSet::iterator it = foundShapes.begin();
                 it != foundShapes.end(); ++it)
            {
                VectorAreal *ar = dynamic_cast<VectorAreal *>(*it);
                [self addCountryRep:ar];
            }
        } else {
            // Look for an ocean
            oceanPool->findArealsForPoint(coord,foundShapes);
            for (ShapeSet::iterator it = foundShapes.begin();
                 it != foundShapes.end(); ++it)
            {
                VectorAreal *ar = dynamic_cast<VectorAreal *>(*it);
                [self addOceanRep:ar];
            }
        }
    }
    
    // If we're over the maximum, remove a feature
    while (featureReps.size() > MaxFeatureReps)
        [self removeFeatureRep:*(featureReps.begin())];
}

// Look for an outline to select
// We're in the layer thread
- (void)selectObject:(TapMessage *)msg
{
    GeoCoord coord = msg.whereGeo;
    
    // Look for an object, taking LODs into account
    VectorShape *selectedShape = NULL;
    FeatureRep *theFeat = [self findFeatureRep:coord height:msg.heightAboveGlobe whichShape:&selectedShape];
    
    if (theFeat)
    {
        switch (theFeat->featType)
        {
            case FeatRepCountry:
                if (theFeat->outlines.find(selectedShape) != theFeat->outlines.end())
                    NSLog(@"User selected country:\n%@",[selectedShape->getAttrDict() description]);
                else
                    NSLog(@"User selected region within country:\n%@",[selectedShape->getAttrDict() description]);
                break;
            case FeatRepOcean:
                NSLog(@"User selected ocean:\n%@",[selectedShape->getAttrDict() description]);
                break;
        }
    }
    
    // Note: If you want to bring up a view at this point,
    //        don't forget to switch back to the main thread
}

@end
