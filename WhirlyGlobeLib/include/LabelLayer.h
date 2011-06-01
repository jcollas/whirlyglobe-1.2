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
#import "Identifiable.h"
#import "Drawable.h"
#import "DataLayer.h"
#import "LayerThread.h"
#import "TextureAtlas.h"

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
}

@property (nonatomic,retain) NSString *text;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,retain) NSDictionary *desc;

// Pass in either width or height.  Will calculate the other one
- (bool)calcWidth:(float *)width height:(float *)height defaultFont:(UIFont *)font;

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

// Remove the given label
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId;

@end
