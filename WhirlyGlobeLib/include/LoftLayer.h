/*
 *  LoftLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 7/16/11.
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
#import "ShapeReader.h"
#import "DataLayer.h"

namespace WhirlyGlobe
{
    
// Representation of a single lofted polygon
// Used to keep track of the assets we create
class LoftedPolySceneRep : public Identifiable
{
public:
    LoftedPolySceneRep() { }
    ~LoftedPolySceneRep() { }
    
    // If we're keeping a cache of the meshes, read and write
    bool readFromCache(NSString *key);
    bool writeToCache(NSString *key);
        
    SimpleIDSet drawIDs;  // Drawables created for this
    ShapeSet shapes;    // The shapes for the outlines
    GeoMbr shapeMbr;       // Overall bounding box
    std::vector<VectorRing> triMesh;  // The post-clip triangle mesh, pre-loft
};
typedef std::map<SimpleIdentity,LoftedPolySceneRep *> LoftedPolySceneRepMap;
    
}

// Description of how we want the lofted poly to look
@interface WGLoftedPolyDesc : NSObject
{
    UIColor *color;
    NSString *key;  // If set, used for caching
    float height;  // Height above the globe
}

@property (nonatomic,retain) UIColor *color;
@property (nonatomic,retain) NSString *key;
@property (nonatomic,assign) float height;

@end

/* Loft Layer
    Represents a set of lofted polygons.
 */
@interface WGLoftLayer : NSObject<WhirlyGlobeLayer>
{
    WhirlyGlobeLayerThread *layerThread;
    WhirlyGlobe::GlobeScene *scene;
    
    // Keep track of the lofted polygons
    WhirlyGlobe::LoftedPolySceneRepMap polyReps;
    float gridSize;
    // If set, we'll write mesh geometry out to disk for caching
    BOOL useCache;
}

// Called in layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Create a lofted poly
- (WhirlyGlobe::SimpleIdentity) addLoftedPolys:(WhirlyGlobe::ShapeSet *)shape desc:(WGLoftedPolyDesc *)desc;

- (WhirlyGlobe::SimpleIdentity) addLoftedPoly:(WhirlyGlobe::VectorShapeRef)shape desc:(WGLoftedPolyDesc *)desc;

// Remove a lofted poly
- (void) removeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID;

// Change a lofted poly
- (void) changeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID desc:(WGLoftedPolyDesc *)desc;

@property (nonatomic,assign) float gridSize;
@property (nonatomic,assign) BOOL useCache;

@end
