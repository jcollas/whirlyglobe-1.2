//
//  LoftLayer.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 7/16/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobe/WhirlyGlobe.h>

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
@interface LoftedPolyDesc : NSObject
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
@interface LoftLayer : NSObject<WhirlyGlobeLayer>
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
- (WhirlyGlobe::SimpleIdentity) addLoftedPolys:(WhirlyGlobe::ShapeSet *)shape desc:(LoftedPolyDesc *)desc;

// Remove a lofted poly
- (void) removeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID;

// Change a lofted poly
- (void) changeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID desc:(LoftedPolyDesc *)desc;

@property (nonatomic,assign) float gridSize;
@property (nonatomic,assign) BOOL useCache;

@end
