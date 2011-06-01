/*
 *  GridLines.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/25/11.
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
#import "DataLayer.h"
#import "GlobeScene.h"

static const float GlobeLineOffset = 0.01;
static const float GridCellSize = 3*(float)M_PI/180.0;

/* Grid Line Layer
	Sets up a set of grid lines
 */
@interface GridLayer : NSObject<WhirlyGlobeLayer>
{
	unsigned int numX,numY;
	unsigned int chunkX,chunkY;
	WhirlyGlobe::GlobeScene *scene;
}

// Initialize with the number of chunks of lines we want
- (id)initWithX:(unsigned int)numX Y:(unsigned int)numY;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end
