//
//  InteractionLayer.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobe/WhirlyGlobe.h>

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
