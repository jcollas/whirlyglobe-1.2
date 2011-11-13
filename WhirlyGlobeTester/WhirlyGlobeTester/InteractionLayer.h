//
//  InteractionLayer.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobe/WhirlyGlobe.h>

// Notification names
#define kWGMarkerSwitch @"WGMarkerSwitch"
#define kWGParticleSwitch @"WGParticleSwitch"
#define kWGLabelSwitch @"WGLabelSwitch"

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
    
    WhirlyGlobe::SimpleIDSet partSysIDs;  // Particle systems added to globe
    WhirlyGlobe::SimpleIDSet labelIDs;   // Labels added to the globe
    WhirlyGlobe::SimpleIDSet markerIDs;  // Markers added to the globe
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
