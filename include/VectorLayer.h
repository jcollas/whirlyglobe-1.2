/*
 *  ShapeDisplay.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/26/11.
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
#import <vector>
#import <set>
#import <map>
#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "DataLayer.h"
#import "VectorData.h"
#import "GlobeMath.h"
#import "LayerThread.h"
#import "DrawCost.h"

namespace WhirlyGlobe
{
// Representation of the vector(s) in the scene
// We track these so we can remove them later
class VectorSceneRep : public Identifiable
{
public:
    VectorSceneRep() { }
    VectorSceneRep(ShapeSet &inShapes) : shapes(inShapes) { };
    
    ShapeSet shapes;  // Shapes associated with this
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
- (WhirlyGlobe::SimpleIdentity)addVector:(WhirlyGlobe::VectorShapeRef)shape desc:(NSDictionary *)dict;

// Create geometry for the given group of vectors
- (WhirlyGlobe::SimpleIdentity)addVectors:(WhirlyGlobe::ShapeSet *)shapes desc:(NSDictionary *)dict;

// Change an object representation according to the given attributes
- (void)changeVector:(WhirlyGlobe::SimpleIdentity)vecID desc:(NSDictionary *)dict;

// Remove the given vector by ID
- (void)removeVector:(WhirlyGlobe::SimpleIdentity)vecID;

// Return the cost of the given vector scene representation
// This only works in the layer thread
- (DrawCost *)getCost:(WhirlyGlobe::SimpleIdentity)vecID;

@end
