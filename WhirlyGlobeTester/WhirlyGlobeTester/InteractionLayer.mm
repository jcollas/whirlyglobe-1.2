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
@synthesize loftLayer;
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
        loftedPolys = false;
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
    self.loftLayer = nil;
    self.selectionLayer = nil;
    self.options = nil;
    
    if (countryDb)
        delete countryDb;
    countryDb = NULL;
    if (cityDb)
        delete cityDb;
    cityDb = NULL;
    
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
    NSString *cityShape = [[NSBundle mainBundle] pathForResource:@"50m_populated_places_simple" ofType:@"shp"];
    countryDb = new VectorDatabase(bundleDir,docDir,@"countries",new ShapeReader(countryShape),NULL,true);
    cityDb = new VectorDatabase(bundleDir,docDir,@"cities",new ShapeReader(cityShape),NULL,true);

    // When the user taps the globe
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSelector:) name:WhirlyGlobeTapMsg object:nil];
    
    // Notifications from the options controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionsChange:) name:kWGControlChange object:nil];
}

// User tapped somewhere
// Let's see what the selection layer has to say
// In the main thread here
- (void)tapSelector:(NSNotification *)note
{
    TapMessage *msg = note.object;
	[self performSelector:@selector(tapSelectorLayerThread:) onThread:layerThread withObject:msg waitUntilDone:NO];
}

// Send out a selection notification
// In the main thread here
- (void)selectionNote:(NSString *)what
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWGSelectionNotification object:what];
}

// Process the tap
// We're in the layer thread here
- (void)tapSelectorLayerThread:(TapMessage *)msg
{
    // Tap within 10 pixels (or points?)
    Point2f touchPt;  touchPt.x() = msg.touchLoc.x;  touchPt.y() = msg.touchLoc.y;
    SimpleIdentity objectId = [self.selectionLayer pickObject:touchPt maxDist:10.0];

    bool hit = false;
    if (labelSelectIDs.find(objectId) != labelSelectIDs.end())
    {
        [self performSelectorOnMainThread:@selector(selectionNote:) withObject:[NSString stringWithFormat:@"Label %d",objectId] waitUntilDone:NO];
        hit = true;
    }
    if (markerSelectIDs.find(objectId) != markerSelectIDs.end())
    {
        [self performSelectorOnMainThread:@selector(selectionNote:) withObject:[NSString stringWithFormat:@"Marker %d",objectId] waitUntilDone:NO];
        hit = true;
    }
    
    // If we didn't find anything to select, look for a country
    if (!hit)
    {
        ShapeSet shapes;
        countryDb->findArealsForPoint(msg.whereGeo,shapes);
    
        if (!shapes.empty())
        {
            if (loftedPolys)
            {
                // We found one or more, so add their loops
                for (ShapeSet::iterator it = shapes.begin();
                     it != shapes.end(); ++it)
                {
                    VectorShapeRef shape = *it;
                    WGLoftedPolyDesc *desc = [[[WGLoftedPolyDesc alloc] init] autorelease];
                    desc.color = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.5];
                    NSNumber *countryNum = [shape->getAttrDict() objectForKey:@"wgshapefileidx"];
                    if (countryNum)
                        desc.key = [NSString stringWithFormat:@"country_%d",[countryNum intValue]];
                    desc.height = 0.01;
                    SimpleIdentity loftId = [loftLayer addLoftedPoly:shape desc:desc];
                    if (loftId != EmptyIdentity)
                        loftedPolyIDs.insert(loftId);
                }
            }
            
            VectorShapeRef shape = *(shapes.begin());
            NSString *name = [shape->getAttrDict() objectForKey:@"ADMIN"];
            [self performSelectorOnMainThread:@selector(selectionNote:) withObject:[NSString stringWithFormat:@"Country: %@",name] waitUntilDone:NO];
            hit = true;
        }
    }
    
    if (!hit)
        [self performSelectorOnMainThread:@selector(selectionNote:) withObject:[NSString stringWithFormat:@"Nothing",objectId] waitUntilDone:NO];        
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
                                if (![key compare:kWGStatsControl])
                                {
                                    // Nothing to do here
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
    
    // Clear out the select IDs 
    labelSelectIDs.clear();

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
                    label.isSelectable = YES;
                    label.selectID = Identifiable::genId();
                    label.text = name;
                    [label setLoc:ar->calcGeoMbr().mid()];
                    [labels addObject:label];
                    labelSelectIDs.insert(label.selectID);
                }
            }
            
            // Toss the vectors on top of the globe
            vectorIDs.insert([self.vectorLayer addVectors:&shapes desc:shapeDesc cacheName:vecCacheName]);
            
            // And the labels
            labelIDs.insert([self.labelLayer addLabels:labels desc:labelDesc cacheName:labelCacheName]);
        }
    }
}

// Number of markers to throw out there
const int NumMarkers=250;

- (void)displayMarkers:(int)how
{
    // Remove the markers
    for (SimpleIDSet::iterator it = markerIDs.begin();
         it != markerIDs.end(); ++it)
        [self.markerLayer removeMarkers:*it];
    markerIDs.clear();
    
    // And nuke the textures
    for (SimpleIDSet::iterator it = markerTexIDs.begin();
         it != markerTexIDs.end(); ++it)
        scene->addChangeRequest(new RemTextureReq(*it));
    markerTexIDs.clear();
    
    // Get rid of select IDs
    markerSelectIDs.clear();
    
    // Add the markers
    if (how)
    {
        // Description of the marker
        NSDictionary *markerDesc =
        [NSDictionary dictionaryWithObjectsAndKeys:
         [UIColor whiteColor],@"color",
         [NSNumber numberWithFloat:0.0],@"minVis",
         [NSNumber numberWithFloat:0.8],@"maxVis",
         [NSNumber numberWithInt:2],@"drawOffset",
         nil];
        
        // Set up a texture atlas builder and toss in images
        TextureAtlasBuilder *atlasBuilder = [[[TextureAtlasBuilder alloc] initWithTexSizeX:1024 texSizeY:1024] autorelease];

        // We'll use numbers for the animations
        std::vector<SimpleIdentity> num_textures;
        for (unsigned int ii=0;ii<10;ii++)
        {
            SimpleIdentity newTexId = [atlasBuilder addImage:[UIImage imageNamed:[NSString stringWithFormat:@"number_%d",ii]]];            
            num_textures.push_back(newTexId);
        }
        
        // Turn the texture atlases into real textures
        [atlasBuilder processIntoScene:scene texIDs:&markerTexIDs];

        // Set up the markers
        NSMutableArray *markers = [NSMutableArray array];
        for (unsigned int ii=0;ii<NumMarkers && ii < cityDb->numVectors();ii++)
        {
            VectorShapeRef shape = cityDb->getVector(ii,true);
            VectorPointsRef pt = boost::dynamic_pointer_cast<VectorPoints>(shape);
        
            // Set up the marker
            WGMarker *marker = [[[WGMarker alloc] init] autorelease];
            GeoCoord coord = GeoCoord(pt->pts[0].x(),pt->pts[0].y());
            [marker setLoc:coord];
            
            // Give it several textures in a row to display
            for (unsigned int jj=0;jj<num_textures.size();jj++)
                [marker addTexID:num_textures[jj]];
            marker.period = 10.0;
            marker.timeOffset = ii*1.0;

            // These values are relative to the globe, which has a radius of 1.0
            marker.width = 0.01;            marker.height = 0.01;

            // Now we'll set this up for selection.  If we turn selection on
            //  and give the marker a unique ID as below, we'll get it back later
            // Note: Store this off somewhere to keep track of it
            marker.isSelectable = true;
            marker.selectID = Identifiable::genId();
            markerSelectIDs.insert(marker.selectID);

            [markers addObject:marker];
        }
        
        // Add them all at once
        markerIDs.insert([self.markerLayer addMarkers:markers desc:markerDesc]);
    }
}

// Number of particle systems to throw out there
const int NumParticleSystems = 150;

- (void)displayParticles:(bool)how
{
    // Add some new particle systems
    if (how)
    {
        NSDictionary *partDesc =
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithFloat:0.02],@"minLength",
         [NSNumber numberWithFloat:0.04],@"maxLength",
         [NSNumber numberWithInt:100],@"minNumPerSec",
         [NSNumber numberWithInt:200],@"maxNumPerSec",
         [NSNumber numberWithFloat:1.0],@"minLifetime",
         [NSNumber numberWithFloat:5.0],@"maxLifetime",
         [NSNumber numberWithFloat:0.0],@"minPhi",
         [NSNumber numberWithFloat:M_PI/5],@"maxPhi",
         [NSArray arrayWithObjects:
          [UIColor colorWithRed:255/256.0 green:239/256.0 blue:31/256.0 alpha:1.0],
          [UIColor colorWithRed:245/256.0 green:200/256.0 blue:22/256.0 alpha:1.0],
          [UIColor colorWithRed:255/256.0 green:197/256.0 blue:97/256.0 alpha:1.0],
          [UIColor colorWithRed:255/256.0 green:191/256.0 blue:135/256.0 alpha:1.0],
          [UIColor colorWithRed:255/256.0 green:134/256.0 blue:82/256.0 alpha:1.0],
          [UIColor colorWithRed:250/256.0 green:103/256.0 blue:62/256.0 alpha:1.0],
          [UIColor colorWithRed:245/256.0 green:84/256.0 blue:39/256.0 alpha:1.0],
          [UIColor colorWithRed:255/256.0 green:32/256.0 blue:20/256.0 alpha:1.0],
          nil],@"colors",
         nil];
        
        // Put together a list of particle systems
        NSMutableArray *partSystems = [NSMutableArray array];
        for (unsigned int ii=0;ii<NumParticleSystems && ii < cityDb->numVectors();ii++)
        {
            VectorShapeRef shape = cityDb->getVector(ii,true);
            VectorPointsRef pt = boost::dynamic_pointer_cast<VectorPoints>(shape);

            ParticleSystem *particleSystem = [[[ParticleSystem alloc] init] autorelease];
            GeoCoord coord = GeoCoord(pt->pts[0].x(),pt->pts[0].y());
            [particleSystem setLoc:coord];
            [particleSystem setNorm:PointFromGeo(coord)];   
            [partSystems addObject:particleSystem];
        }
        
        partSysIDs.insert([self.particleSystemLayer addParticleSystems:partSystems desc:partDesc]);    
    } else {
        // Remove the particle systems
        for (SimpleIDSet::iterator it = partSysIDs.begin();
             it != partSysIDs.end(); ++it)
            [self.particleSystemLayer removeParticleSystems:*it];
        partSysIDs.clear();        
    }
}

- (void)displayLoftedPolys:(int)how
{
    if (how)
    {
        loftedPolys = YES;
        self.loftLayer.useCache = (how > 1);
    } else {
        for (SimpleIDSet::iterator it = loftedPolyIDs.begin();
             it != loftedPolyIDs.end(); ++it)
            [self.loftLayer removeLoftedPoly:*it];
        loftedPolyIDs.clear();
        loftedPolys = NO;
    }
}

- (void)displayGrid:(bool)how
{
    
}

@end
