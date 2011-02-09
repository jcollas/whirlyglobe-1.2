//
//  InteractionLayer.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 2/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WhirlyGlobe.h"

/* (Whirly Globe) Interaction Layer
	This looks for tap messages and tweaks the vector layer
     accordingly.
    It needs to be a layer so it can run in the same thread as the layers.
 */
@interface InteractionLayer : NSObject <WhirlyGlobeLayer>
{
	WhirlyGlobeLayerThread *layerThread;
	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobeView *globeView;
	VectorLayer *vectorLayer;
	LabelLayer *labelLayer;
	WhirlyGlobe::SimpleIdentity curSelect;
	WhirlyGlobe::SimpleIdentity curLabel;
}

// Need a pointer to the vector layer to start with
- (id)initWithVectorLayer:(VectorLayer *)layer labelLayer:(LabelLayer *)labelLayer globeView:(WhirlyGlobeView *)globeView;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end
