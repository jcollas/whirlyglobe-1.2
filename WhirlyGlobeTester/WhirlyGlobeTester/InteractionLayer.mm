//
//  InteractionLayer.m
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import "InteractionLayer.h"
#import "OptionsViewController.h"

using namespace WhirlyGlobe;

@interface InteractionLayer()
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property (nonatomic,retain) WhirlyGlobeView *globeView;
@property (nonatomic,retain) NSDictionary *options;

- (void)displayCountries:(int)how;
- (void)displayMarkers:(int)how;
- (void)displayParticles:(bool)how;
- (void)displayLoftedPolys:(int)how;
- (void)displayGrid:(bool)how;
@end

@implementation InteractionLayer

@synthesize layerThread;
@synthesize globeView;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize particleSystemLayer;
@synthesize markerLayer;
@synthesize selectionLayer;
@synthesize options;

// Initialize with a globe view.  All the rest is optional.
- (id)initWithGlobeView:(WhirlyGlobeView *)inGlobeView
{
    self = [super init];
    if (self)
    {
        self.globeView = inGlobeView;
        self.options = [OptionsViewController fetchValuesDict];
        countryDb = NULL;
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
    self.particleSystemLayer = nil;
    self.markerLayer = nil;
    self.selectionLayer = nil;
    self.options = nil;
    
    if (countryDb)
        delete countryDb;
    countryDb = NULL;
    
    [super dealloc];
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
    self.layerThread = inThread;
    scene = inScene;

    // Set up the country DB
    // We want a cache, so read it or build it
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *bundleDir = [[NSBundle mainBundle] resourcePath];
    NSString *countryShape = [[NSBundle mainBundle] pathForResource:@"10m_admin_0_map_subunits" ofType:@"shp"];
    countryDb = new VectorDatabase(bundleDir,docDir,@"countries",new ShapeReader(countryShape),NULL,true);

    // When the user taps the globe
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSelector:) name:WhirlyGlobeTapMsg object:nil];
    
    // Notifications from the options controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionsChange:) name:kWGControlChange object:nil];
}

// Utility routine to add a texture to the scene
- (SimpleIdentity)makeTexture:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    if (!image)
        return EmptyIdentity;
    Texture *theTexture = new Texture(image);
    scene->addChangeRequest(new AddTextureReq(theTexture));

    return theTexture->getId();
}

// User tapped somewhere
// Let's see what the selection layer has to say
// In the main thread here
- (void)tapSelector:(NSNotification *)note
{
    TapMessage *msg = note.object;
	[self performSelector:@selector(tapSelectorLayerThread:) onThread:layerThread withObject:msg waitUntilDone:NO];
}

// Process the tap on the layer thread
// We're in the layer thread here
- (void)tapSelectorLayerThread:(TapMessage *)msg
{
    // Tap within 10 pixels (or points?)
    Point2f touchPt;  touchPt.x() = msg.touchLoc.x;  touchPt.y() = msg.touchLoc.y;
    SimpleIdentity objectId = [self.selectionLayer pickObject:touchPt maxDist:10.0];
    
    NSLog(@"User touched = %d",(int)objectId);    
}

#pragma mark -
#pragma mark Options Change Notification

// This method is called in the main loop

- (void)optionsChange:(NSNotification *)note
{
    [self performSelector:@selector(optionsChangeLayer:) onThread:self.layerThread withObject:note.object waitUntilDone:NO];
}

// This versions is called in the layer thread, so they can do work

// Add a few markers
- (void)optionsChangeLayer:(NSDictionary *)newOptions
{
    // Figure out what changed
    for (NSString *key in [options allKeys])
    {
        NSNumber *option = [options objectForKey:key];
        NSNumber *newOption = [newOptions objectForKey:key];
        // Option changed
        if ([option compare:newOption])
        {
            if (![key compare:kWGCountryControl])
            {
                [self displayCountries:[newOption intValue]];
            } else
                if (![key compare:kWGMarkerControl])
                {
                    [self displayMarkers:[newOption intValue]];
                } else 
                    if (![key compare:kWGParticleControl])
                    {
                        [self displayParticles:[newOption boolValue]];
                    } else
                        if (![key compare:kWGLoftedControl])
                        {
                            [self displayLoftedPolys:[newOption intValue]];
                        } else
                            if (![key compare:kWGGridControl])
                            {
                                [self displayGrid:[newOption boolValue]];
                            } else
                                NSLog(@"InteractionLayer: Unrecognized option %@.  Update code.",key);
        }
    }
    
    self.options = [NSDictionary dictionaryWithDictionary:newOptions];
}

- (void)displayCountries:(int)how
{
    // Remove the vectors
    for (SimpleIDSet::iterator it = vectorIDs.begin();
         it != vectorIDs.end(); ++it)
        [self.vectorLayer removeVector:*it];
    vectorIDs.clear();
    
    // Remove the labels
    for (SimpleIDSet::iterator it = labelIDs.begin();
         it != labelIDs.end(); ++it)
        [self.labelLayer removeLabel:*it];
    labelIDs.clear();

    // Visual description of the vectors and labels
    NSDictionary *shapeDesc = 
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithBool:YES],@"enable",
      [NSNumber numberWithInt:3],@"drawOffset",
      [UIColor whiteColor],@"color",
      nil];
    NSDictionary *labelDesc =
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithBool:YES],@"enable",
      [UIColor clearColor],@"backgroundColor",
      [UIColor whiteColor],@"textColor",
      [UIFont boldSystemFontOfSize:32.0],@"font",
      [NSNumber numberWithInt:4],@"drawOffset",
      [NSNumber numberWithFloat:0.05],@"width",
      nil];
    
    // Draw all the countries in the admin 0 shape file
    if (how)
    {        
        NSString *vecCacheName = (how == OnCached) ? @"country_vec" : nil;
        NSString *labelCacheName = (how == OnCached) ? @"country_label": nil;
        
        // If the caches are there we can just use them
        if (vecCacheName && RenderCacheExists(vecCacheName) && 
            labelCacheName && RenderCacheExists(labelCacheName))
        {
            vectorIDs.insert([self.vectorLayer addVectorsFromCache:vecCacheName]);
            labelIDs.insert([self.labelLayer addLabelsFromCache:labelCacheName]);
        } else {
            // No caches and we have to do it the hard way
            NSMutableArray *labels = [NSMutableArray array];
            
            // Work through the vectors.  This will get big, so don't do this normally.
            ShapeSet shapes;
            for (unsigned int ii=0;ii<countryDb->numVectors();ii++)
            {
                VectorShapeRef shape = countryDb->getVector(ii,true);
                NSString *name = [shape->getAttrDict() objectForKey:@"ADMIN"];
                VectorArealRef ar = boost::dynamic_pointer_cast<VectorAreal>(shape);
                if (ar.get() && name)
                {
                    // This frees the attribute memory, which we don't really need
                    shape->setAttrDict(nil);
                    shapes.insert(shape);
                    
                    // And build a label.  We'll add these as a group below
                    SingleLabel *label = [[[SingleLabel alloc] init] autorelease];
                    label.text = name;
                    [label setLoc:ar->calcGeoMbr().mid()];
                    [labels addObject:label];
                }
            }
            
            // Toss the vectors on top of the globe
            vectorIDs.insert([self.vectorLayer addVectors:&shapes desc:shapeDesc cacheName:vecCacheName]);
            
            // And the labels
            labelIDs.insert([self.labelLayer addLabels:labels desc:labelDesc cacheName:labelCacheName]);
        }
    }
}


- (void)displayMarkers:(int)how
{
    // Remove the markers
    for (SimpleIDSet::iterator it = markerIDs.begin();
         it != markerIDs.end(); ++it)
        [self.markerLayer removeMarkers:*it];
    markerIDs.clear();

    // Add the markers
    if (how)
    {
        // Description of the marker
        NSDictionary *markerDesc =
        [NSDictionary dictionaryWithObjectsAndKeys:
         [UIColor whiteColor],@"color",
         nil];
        
        // Set up a texture for the marker
        SimpleIdentity parisArmsTexId = [self makeTexture:@"200px-Grandes_Armes_de_Paris"];
        SimpleIdentity parisFlagTexID = [self makeTexture:@"200px-Flag_of_Paris"];
        SimpleIdentity frenchArmsTexID = [self makeTexture:@"175px-Armoiries_republique_francaise"];
        SimpleIdentity frenchFlagTexID = [self makeTexture:@"320px-Flag_of_France"];
        
        // Set up the marker
        WGMarker *parisMarker = [[[WGMarker alloc] init] autorelease];
        
        // Stick it right on top of Paris
        GeoCoord paris = GeoCoord::CoordFromDegrees(2.350833, 48.856667);
        [parisMarker setLoc:paris];
        
        // We're going to give it four different textures that rotate over a period of 10s
        [parisMarker addTexID:parisArmsTexId];
        [parisMarker addTexID:parisFlagTexID];
        [parisMarker addTexID:frenchArmsTexID];
        [parisMarker addTexID:frenchFlagTexID];
        parisMarker.period = 10.0;
        
        // These values are relative to the globe, which has a radius of 1.0
        parisMarker.width = 0.01;    parisMarker.height = 0.01;
        
        // Now we'll set this up for selection.  If we turn selection on
        //  and give the marker a unique ID as below, we'll get it back later
        // Note: Store this off somewhere to keep track of it
        parisMarker.isSelectable = true;
        parisMarker.selectID = Identifiable::genId();
        
        // And add the marker
        SimpleIdentity id1 = [self.markerLayer addMarker:parisMarker desc:markerDesc];
        markerIDs.insert(id1);
    }
}

- (void)displayParticles:(bool)how
{
    // Add some new particle systems
    if (how)
    {
        NSDictionary *partDesc =
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithFloat:0.02],@"minLength",
         [NSNumber numberWithFloat:0.03],@"maxLength",
         [NSNumber numberWithInt:500],@"minNumPerSec",
         [NSNumber numberWithInt:600],@"maxNumPerSec",
         [NSNumber numberWithFloat:1.0],@"minLifetime",
         [NSNumber numberWithFloat:5.0],@"maxLifetime",
         nil];
        
        // Add a single particle system
        ParticleSystem *particleSystem = [[[ParticleSystem alloc] init] autorelease];
        GeoCoord washDc = GeoCoord::CoordFromDegrees(-77.036667,38.895111);
        [particleSystem setLoc:washDc];
        [particleSystem setNorm:PointFromGeo(washDc)];
        
        partSysIDs.insert([self.particleSystemLayer addParticleSystem:particleSystem desc:partDesc]);    
    } else {
        // Remove the particle systems
        //        for (SimpleIDSet::iterator it = partSysIDs.begin();
        //             it != partSysIDs.end(); ++it)
        //            [self.particleSystemLayer remove];
        //        partSysIDs.clear();        
    }
}

- (void)displayLoftedPolys:(int)how
{
    
}

- (void)displayGrid:(bool)how
{
    
}

@end
