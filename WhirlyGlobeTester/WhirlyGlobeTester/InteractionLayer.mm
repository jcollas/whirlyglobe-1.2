//
//  InteractionLayer.m
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import "InteractionLayer.h"

using namespace WhirlyGlobe;

@interface InteractionLayer()
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property (nonatomic,retain) WhirlyGlobeView *globeView;

@end

@implementation InteractionLayer

@synthesize layerThread;
@synthesize globeView;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize particleSystemLayer;
@synthesize markerLayer;
@synthesize selectionLayer;


// Initialize with a globe view.  All the rest is optional.
- (id)initWithGlobeView:(WhirlyGlobeView *)inGlobeView
{
    self = [super init];
    if (self)
    {
        self.globeView = inGlobeView;
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
    
    [super dealloc];
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
    self.layerThread = inThread;
    scene = inScene;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapSelector:) name:WhirlyGlobeTapMsg object:nil];
    
    // Notifications from the options controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markerSwitch:) name:kWGMarkerSwitch object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(particleSwitch:) name:kWGParticleSwitch object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(labelSwitch:) name:kWGLabelSwitch object:nil];
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
#pragma mark Notifications

// These methods are called in the main loop

- (void)markerSwitch:(NSNotification *)note
{
    [self performSelector:@selector(markerSwitchLayer:) onThread:self.layerThread withObject:note.object waitUntilDone:NO];
}

- (void)particleSwitch:(NSNotification *)note
{
    [self performSelector:@selector(particleSwitchLayer:) onThread:self.layerThread withObject:note.object waitUntilDone:NO];
}

- (void)labelSwitch:(NSNotification *)note
{
    [self performSelector:@selector(labelSwitchLayer:) onThread:self.layerThread withObject:note.object waitUntilDone:NO];
}

// These versions are called in the layer thread, so they can do work

// Add a few markers
- (void)markerSwitchLayer:(NSNumber *)num
{
    // Add the markers
    if ([num boolValue])
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
    } else {
        // Remove the markers
        for (SimpleIDSet::iterator it = markerIDs.begin();
             it != markerIDs.end(); ++it)
            [self.markerLayer removeMarkers:*it];
        markerIDs.clear();
    }
}

// Add or remove the labels
- (void)labelSwitchLayer:(NSNumber *)num
{
    // Throw on some labels
    if ([num boolValue])
    {
        // This describes how our labels will look
        NSDictionary *labelDesc = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithBool:YES],@"enable",
         [UIColor clearColor],@"backgroundColor",
         [UIColor whiteColor],@"textColor",
         [UIFont boldSystemFontOfSize:32.0],@"font",
         [NSNumber numberWithInt:4],@"drawOffset",
         [NSNumber numberWithFloat:0.05],@"height",
         [NSNumber numberWithFloat:0.0],@"width",
         nil];
        
        // Build up a list of individual labels
        NSMutableArray *labels = [[[NSMutableArray alloc] init] autorelease];
        
        SingleLabel *sfLabel = [[[SingleLabel alloc] init] autorelease];
        sfLabel.text = @"San Francisco";
        [sfLabel setLoc:GeoCoord::CoordFromDegrees(-122.283,37.7166)];
        [labels addObject:sfLabel];
        
        SingleLabel *nyLabel = [[[SingleLabel alloc] init] autorelease];
        nyLabel.text = @"New York";
        [nyLabel setLoc:GeoCoord::CoordFromDegrees(-74,40.716667)];
        [labels addObject:nyLabel];
        
        SingleLabel *romeLabel = [[[SingleLabel alloc] init] autorelease];
        romeLabel.text = @"Rome";
        [romeLabel setLoc:GeoCoord::CoordFromDegrees(12.5, 41.9)];
        [labels addObject:romeLabel];
        
        // Add all the labels at once
        labelIDs.insert([self.labelLayer addLabels:labels desc:labelDesc]);        
    } else {
        // Remove the labels
        for (SimpleIDSet::iterator it = labelIDs.begin();
             it != labelIDs.end(); ++it)
            [self.labelLayer removeLabel:*it];
        labelIDs.clear();
    }
}

- (void)particleSwitchLayer:(NSNumber *)num
{
    // Add some new particle systems
    if ([num boolValue])
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

@end
