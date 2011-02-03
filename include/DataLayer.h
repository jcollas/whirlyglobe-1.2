/*
 *  DataLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import <Foundation/Foundation.h>
#import "GlobeScene.h"

@class WhirlyGlobeLayerThread;

/* Layer (data or interaction)
   Used to overlay data on top of the globe and/or interact with data.
   Layers are run in their own thread and make use of that thread's run loop.
 */
@protocol WhirlyGlobeLayer

// This is called after the layer thread kicks off
// Open your files and such here and then insert yourself in the run loop
//  for further processing
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end
