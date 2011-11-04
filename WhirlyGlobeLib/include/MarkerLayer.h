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

namespace WhirlyGlobe
{

// Marker representation
// Used internally to track marker resources
class MarkerSceneRep : public Identifiable
{
public:
    MarkerSceneRep() { };
    ~MarkerSceneRep() { };
    
    SimpleIDSet texIDs;   // Textures created for this
    SimpleIDSet drawIDs;  // Drawables created for this
};
typedef std::set<MarkerSceneRep *,IdentifiableSorter> MarkerSceneRepSet;
    
}

/** WhirlyGlobe Marker
    A single marker object to be placed on the globe.  It will show
    up with the given width and height and be selectable if so desired.
 */
@interface WGMarker : NSObject
{
    /// If set, this marker should be made selectable
    ///  and it will be if the selection layer has been set
    bool isSelectable;
    /// If the marker is selectable, this is the unique identifier
    ///  for it.  You should set this ahead of time
    WhirlyGlobe::SimpleIdentity selectID;
    /// The location for the center of the marker.
    WhirlyGlobe::GeoCoord loc;
    /// The list of textures to use.  If there's just one
    ///  we show that.  If there's more than one, we switch
    ///  between them over the period.
    std::vector<WhirlyGlobe::SimpleIdentity> texIDs;
    /// The width in 3-space (remember the globe has radius = 1.0)
    float width;
    /// The height in 3-space (remember the globe has radius = 1.0)
    float height;
    /// The period over which we'll switch textures
    NSTimeInterval period;
}

@property (nonatomic,assign) bool isSelectable;
@property (nonatomic,assign) WhirlyGlobe::SimpleIdentity selectID;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,readonly) std::vector<WhirlyGlobe::SimpleIdentity> texIDs;
@property (nonatomic,assign) float width,height;
@property (nonatomic,assign) NSTimeInterval period;

/// Add a texture ID to be displayed
- (void)addTexID:(WhirlyGlobe::SimpleIdentity)texID;

@end

/** WhirlyGlobe Marker Layer
    Displays a set of markers on the globe.  Markers are simple 
 */
@interface WGMarkerLayer : NSObject<WhirlyGlobeLayer> 
{
    WhirlyGlobeLayerThread *layerThread;
    WhirlyGlobe::GlobeScene *scene;
    WGSelectionLayer *selectLayer;
    WhirlyGlobe::MarkerSceneRepSet markerReps;
}

/// Set this for selection layer support.  If this is set
///  and markers are designated selectable, then the outline
///  of each marker will be passed to the selection layer
///  and will show up in search results.
@property (nonatomic,assign) WGSelectionLayer *selectLayer;

/// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

/// Add a single marker.  The returned ID can be used to delete or modify it.
- (WhirlyGlobe::SimpleIdentity) addMarker:(WGMarker *)marker desc:(NSDictionary *)desc;

/// Add a whole array of SingleMarker objects.  These will all be identified by the returned ID.
/// To remove them, pass in that ID.  Selection will be based on individual IDs in
//   the SingleMarkers, if set.
//- (WhirlyGlobe::SimpleIdentity) addMarkers:(NSArray *)markers desc:(NSDictionary *)desc;

/// Remove one or more markers, designated by their ID
- (void) removeMarkers:(WhirlyGlobe::SimpleIdentity)markerID;

@end
