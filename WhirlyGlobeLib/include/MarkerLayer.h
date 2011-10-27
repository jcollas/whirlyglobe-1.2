/*
 *  MarkerLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 10/21/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
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
#import <set>
#import <map>
#import "Identifiable.h"
#import "Drawable.h"
#import "DataLayer.h"
#import "LayerThread.h"
#import "TextureAtlas.h"
#import "DrawCost.h"
#import "SelectionLayer.h"

/// Default priority for markers
static const int MarkerDrawPriority=1005;

/// Maximum number of triangles we'll stick in a drawable
static const int MaxMarkerDrawableTris=1<<15/3;

@interface WGMarker : NSObject
{
    bool isSelectable;
    WhirlyGlobe::SimpleIdentity selectID;
    WhirlyGlobe::GeoCoord loc;
    std::vector<WhirlyGlobe::SimpleIdentity> texIDs;
    float width,height;
    /// The period over which we'll switch textures
    NSTimeInterval period;
}

@property (nonatomic,assign) bool isSelectable;
@property (nonatomic,assign) WhirlyGlobe::SimpleIdentity selectID;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,readonly) std::vector<WhirlyGlobe::SimpleIdentity> texIDs;
@property (nonatomic,assign) float width,height;
@property (nonatomic,assign) NSTimeInterval period;

// Convenience routine to set a single texture ID
- (void)addTexID:(WhirlyGlobe::SimpleIdentity)texID;

@end

@interface WGMarkerLayer : NSObject<WhirlyGlobeLayer> 
{
    WhirlyGlobeLayerThread *layerThread;
    WhirlyGlobe::GlobeScene *scene;
    WGSelectionLayer *selectLayer;
}

/// Set this for selection support
@property (nonatomic,assign) WGSelectionLayer *selectLayer;

/// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

/// Add a single marker 
- (WhirlyGlobe::SimpleIdentity) addMarker:(WGMarker *)marker desc:(NSDictionary *)desc;

@end
