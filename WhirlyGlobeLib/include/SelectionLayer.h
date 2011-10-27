/*
 *  SelectionLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 10/26/11.
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
#import "SceneRendererES1.h"

namespace WhirlyGlobe
{

/// Used to store a single selectable
typedef struct
{
    /// Used to identify this selectable
    SimpleIdentity selectID;
    Point3f pts[4];
    Vector3f norm;
    float minVis,maxVis;
} RectSelectable;

}

@interface WGSelectionLayer : NSObject<WhirlyGlobeLayer>
{
    WhirlyGlobeView *globeView;
    SceneRendererES1 *renderer;
    WhirlyGlobeLayerThread *layerThread;
    std::vector<WhirlyGlobe::RectSelectable> selectables;
}

/// Construct with a globe view.  Need that for screen space calculations
- (id)initWithGlobeView:(WhirlyGlobeView *)inGlobeView renderer:(SceneRendererES1 *)inRenderer;

/// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

/// Add a rectangle (in 3-space) always available for selection
- (void)addSelectableRect:(WhirlyGlobe::SimpleIdentity)selectId rect:(Point3f *)pts;

/// Add a rectangle (in 3-space) for selection, but only between the given visibilities
- (void)addSelectableRect:(WhirlyGlobe::SimpleIdentity)selectId rect:(Point3f *)pts minVis:(float)minVis maxVis:(float)maxVis;

/// Remove the given selectable from consideration
- (void)removeSelectable:(WhirlyGlobe::SimpleIdentity)selectId;

/// Pass in the screen point where the user touched.  This returns the closest hit within the given distance
- (WhirlyGlobe::SimpleIdentity)pickObject:(Point2f)touchPt maxDist:(float)maxDist;

/// Remove a whole group of selectables by ID
/// Use this one for speed
//- (void)removeSelectables:(SimpleIDSet *)selectIds;

@end
