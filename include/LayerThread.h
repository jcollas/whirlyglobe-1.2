/*
 *  LayerThread.h
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

#import <UIKit/UIKit.h>
#import <vector>
#import "GlobeScene.h"
#import "DataLayer.h"

/* Layer Thread
	Layers are maintained in a separate thread and run at regular intevals.
 */
@interface WhirlyGlobeLayerThread : NSThread
{
	// Scene we're messing with
	WhirlyGlobe::GlobeScene *scene;
	
	// The various data layers we'll display
	NSMutableArray<NSObject> *layers;
	
	// Run loop created within main
	NSRunLoop *runLoop;
}

@property (nonatomic,retain) NSRunLoop *runLoop;

// Set it up with a renderer (for context) and a scene
- (id)initWithScene:(WhirlyGlobe::GlobeScene *)scene;

// Add these before you kick off the thread
- (void)addLayer:(NSObject<WhirlyGlobeLayer> *)layer;

// We're overriding the main entry point
- (void)main;

@end
