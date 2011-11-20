//
//  InteractionLayer.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobe/WhirlyGlobe.h>

// Notification for control dictionary changes
#define kWGControlChange @"WGControlChange"

// Key names in the control parameters dictionary
#define kWGCountryControl @"WGCountryControl"
#define kWGMarkerControl @"WGMarkerControl"
#define kWGParticleControl @"WGParticleControl"
#define kWGLoftedControl @"WGLoftedControl"
#define kWGGridControl @"WGGridControl"
#define kWGStatsControl @"WGStatsControl"

// Values for the various types
typedef enum {IsOff=0,OnNonCached,OnCached} WGSegmentEnum;

/** Interaction Layer
    Controls data display and interaction for the globe.
 */
@interface InteractionLayer : NSObject <WhirlyGlobeLayer>
{
	WhirlyGlobeLayerThread *layerThread;
	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobeView *globeView;

	VectorLayer *vectorLayer;
	LabelLayer *labelLayer;
    ParticleSystemLayer *particleSystemLayer;
    WGMarkerLayer *markerLayer;
    WGSelectionLayer *selectionLayer;
    
    WhirlyGlobe::VectorDatabase *countryDb;  // Country outlines
    WhirlyGlobe::VectorDatabase *cityDb;  // City points

    WhirlyGlobe::SimpleIDSet partSysIDs;  // Particle systems added to globe
    WhirlyGlobe::SimpleIDSet vectorIDs;   // Vectors added to globe
    WhirlyGlobe::SimpleIDSet labelIDs;   // Labels added to the globe
    WhirlyGlobe::SimpleIDSet markerTexIDs;  // Textures added to the globe for markers
    WhirlyGlobe::SimpleIDSet markerIDs;  // Markers added to the globe
    
    WhirlyGlobe::SimpleIDSet labelSelectIDs;  // Selection IDs used for labels
    WhirlyGlobe::SimpleIDSet markerSelectIDs;  // Selection IDs used for markers
    
    NSDictionary *options;  // Options for what to display and how
}

// Initialize with a globe view.  All the rest is optional.
- (id)initWithGlobeView:(WhirlyGlobeView *)globeView;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)scene;

@property (nonatomic,retain) VectorLayer *vectorLayer;
@property (nonatomic,retain) LabelLayer *labelLayer;
@property (nonatomic,retain) ParticleSystemLayer *particleSystemLayer;
@property (nonatomic,retain) WGMarkerLayer *markerLayer;
@property (nonatomic,retain) WGSelectionLayer *selectionLayer;

@end
