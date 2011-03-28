/*
 *  ShapeDisplay.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import <vector>
#import <set>
#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "DataLayer.h"
#import "VectorData.h"
#import "GlobeMath.h"
#import "LayerThread.h"

namespace WhirlyGlobe
{
// Representation of the vector(s) in the scene
// We track these so we can remove them later
class VectorSceneRep : public Identifiable
{
public:
    VectorSceneRep() { }
    VectorSceneRep(std::set<VectorShape *> *inShapes) : shapes(*inShapes) { };
    
    std::set<VectorShape *> shapes;  // Shapes associated with this
    SimpleIDSet drawIDs;    // The drawables we created
};
typedef std::map<SimpleIdentity,VectorSceneRep *> VectorSceneRepMap;

}

/* Vector description dictionary
    enable      <NSNumber bool>
    drawOffset  <NSNumber int>
    color       <UIColor>
    priority    <NSNumber int>
 */

/* Vector display layer
    Displays vector data as requested by a caller.
 */
@interface VectorLayer : NSObject<WhirlyGlobeLayer>
{
@private
    WhirlyGlobe::GlobeScene *scene;
    WhirlyGlobeLayerThread *layerThread;
    
    // Visual representations of vectors
    WhirlyGlobe::VectorSceneRepMap vectorReps;    
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Create geometry from the given vector
// The dictionary controls how the vector will appear
// We refer to that vector by the returned ID
- (WhirlyGlobe::SimpleIdentity)addVector:(WhirlyGlobe::VectorShape *)shape desc:(NSDictionary *)dict;

// Create geometry for the given group of vectors
- (WhirlyGlobe::SimpleIdentity)addVectors:(std::set<WhirlyGlobe::VectorShape *> *)shapes desc:(NSDictionary *)dict;

// Change an object representation according to the given attributes
- (void)changeVector:(WhirlyGlobe::SimpleIdentity)vecID desc:(NSDictionary *)dict;

// Remove the given vector by ID
- (void)removeVector:(WhirlyGlobe::SimpleIdentity)vecID;

@end
