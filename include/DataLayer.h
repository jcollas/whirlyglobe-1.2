/*
 *  DataLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
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
