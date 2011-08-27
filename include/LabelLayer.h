/*
 *  LabelLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/7/11.
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
#import <set>
#import <map>
#import "Identifiable.h"
#import "Drawable.h"
#import "DataLayer.h"
#import "LayerThread.h"
#import "TextureAtlas.h"
#import "DrawCost.h"

namespace WhirlyGlobe 
{

// Draw labels after everything else because of the transparency
static const int LabelDrawPriority=1000;

// Representation of a group of labels in the scene
class LabelSceneRep : public Identifiable
{
public:
    LabelSceneRep() { }
    ~LabelSceneRep() { }
    
    SimpleIDSet texIDs;  // Textures we created for this
    SimpleIDSet drawIDs; // Drawables created for this
};
typedef std::map<SimpleIdentity,LabelSceneRep *> LabelSceneRepMap;
	
}

// A single label w/ location
// Used to pass a list of labels
@interface SingleLabel : NSObject
{
    NSString *text;
    WhirlyGlobe::GeoCoord loc;
    NSDictionary *desc;  // If set, this overrides the top level description
    WhirlyGlobe::SimpleIdentity iconTexture;  // If non-zero, this is the texture to use as an icon
}

@property (nonatomic,retain) NSString *text;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,retain) NSDictionary *desc;
@property (nonatomic,assign) WhirlyGlobe::SimpleIdentity iconTexture;

// Pass in either width or height.  Will calculate the other one
- (bool)calcWidth:(float *)width height:(float *)height defaultFont:(UIFont *)font;

// Calculate rectangle extents in 3D
// Pass in an array of 4 Point3f structures
// Returns the corners, in counter-clockwise order and the normal
- (void)calcExtents:(NSDictionary *)topDesc corners:(Point3f *)pts norm:(Point3f *)norm;

@end

// One side of the texture atlases built for labels
static const unsigned int LabelTextureAtlasSize = 512;

/* Label description dictionary
    enable          <NSNumber bool>
    drawOffset      <NSNumber int>
    label           <NSString >
    textColor       <UIColor>
    backgroundColor <UIColor>
    font            <UIFont>
    width           <NSNumber float>  [In display coordinates, not geo]
    height          <NSNumber float>
 */

/* Label Layer
    Represents a set of visual labels.
    At the moment these are rendered in Quartz, turned into textures
     and then displayed.  In the future, this may change.
 */
@interface LabelLayer : NSObject<WhirlyGlobeLayer>
{
	WhirlyGlobeLayerThread *layerThread;
	WhirlyGlobe::GlobeScene *scene;

    // Keep track of labels (or groups of labels) by ID for deletion
    WhirlyGlobe::LabelSceneRepMap labelReps;
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Create a label at the given coordinates, with the font and color as specified
// You get an ID for the label back so you can delete it later
- (WhirlyGlobe::SimpleIdentity) addLabel:(NSString *)str loc:(WhirlyGlobe::GeoCoord)loc desc:(NSDictionary *)desc;

// Add a whole list of labels (represented by SingleLabel)
// You get the ID identifying the whole group
- (WhirlyGlobe::SimpleIdentity) addLabels:(NSArray *)labels desc:(NSDictionary *)desc;
- (WhirlyGlobe::SimpleIdentity) addLabel:(SingleLabel *)label;

// Change the display of a given label
// What you can do here is restricted.  Just visibility for now
- (void)changeLabel:(WhirlyGlobe::SimpleIdentity)labelID desc:(NSDictionary *)dict;

// Return the cost of a given label group (number of drawables and textures)
// Only works in the layer thread
- (DrawCost *)getCost:(WhirlyGlobe::SimpleIdentity)labelID;

// Remove the given label
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId;

@end
