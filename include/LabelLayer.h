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

/// Default for label draw priority
static const int LabelDrawPriority=1000;

/** The Label Scene Representation is used to encapsulate a set of
    labels that are being added or have been added to the scene and
    their associated textures and drawable IDs.
  */
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

/** The Single Label represents one label with its text, location,
    and an NSDictionary that can be used to override some attributes.
    In general we don't want to create just one label, we want to
    create a large number of labels at once.  We use an array of
    these single labels to do that.
  */
@interface SingleLabel : NSObject
{
    /// The text we want to see
    NSString *text;
    /// A geolocation for the middle, left or right of the label
    ///  depending on the justification
    WhirlyGlobe::GeoCoord loc;
    /// This dictionary contains overrides for certain attributes
    ///  for just this label.  Only width, height, and icon supported
    NSDictionary *desc;
    /// If non-zero, this is the texture to use as an icon
    WhirlyGlobe::SimpleIdentity iconTexture;  
}

@property (nonatomic,retain) NSString *text;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,retain) NSDictionary *desc;
@property (nonatomic,assign) WhirlyGlobe::SimpleIdentity iconTexture;

/// This is used to sort out width and height from the defaults.  Pass
///  in the value of one and zero for the other and it will fill in the
///  missing one.
- (bool)calcWidth:(float *)width height:(float *)height defaultFont:(UIFont *)font;

/// This will calculate the real extents in 3D over the globe.
/// Pass in an array of 3 point3f structures for the points and
///  normals.  The corners are returned in counter-clockwise order.
/// This is used for label selection
- (void)calcExtents:(NSDictionary *)topDesc corners:(Point3f *)pts norm:(Point3f *)norm;

@end

/// Size of one side of the texture atlases built for labels
static const unsigned int LabelTextureAtlasSize = 512;

/** The Label Layer will represent and manage groups of labels.  You
    can hand it a list of labels to display and it will group those
    in to associated drawables.  You want to give it a group for speed.
    Labels are currently drawn in Quartz, compiled into texture atlases
    and drawn together.  This will change in the future to use font
    textures.
 
    When you add a group of labels you will get back a unique ID
    which can be used to modify or delete all those labels at once.
 
    The label display can be controlled via the individual SingleLabel
    objects as well as overall look and feel with the label description
    dictionary.  That dictionary can contain the following:
 
    <list type="bullet">
    <item>enable          [NSNumber bool]
    <item>drawOffset      [NSNumber int]
    <item>drawPriority    [NSNumber int]
    <item>label           [NSString]
    <item>textColor       [UIColor]
    <item>backgroundColor [UIColor]
    <item>font            [UIFont]
    <item>width           [NSNumber float]  [In display coordinates, not geo]
    <item>height          [NSNumber float]
    <item>minVis          [NSNumber float]
    <item>maxVis          [NSNumber float]
    <item>justify         [NSString>] middle, left, right
  */
@interface LabelLayer : NSObject<WhirlyGlobeLayer>
{
	WhirlyGlobeLayerThread *layerThread;
	WhirlyGlobe::GlobeScene *scene;

    /// Keep track of labels (or groups of labels) by ID for deletion
    WhirlyGlobe::LabelSceneRepMap labelReps;
}

/// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

/// Create a label at the given coordinates, with the given look and feel.
/// You get an ID for the label back so you can delete or modify it later.
/// If you have more than one label, call addLabels instead.
- (WhirlyGlobe::SimpleIdentity) addLabel:(NSString *)str loc:(WhirlyGlobe::GeoCoord)loc desc:(NSDictionary *)desc;

/// Add a whole list of labels (represented by SingleLabel objects) with the given
///  look and feel.
/// You get the ID identifying the whole group for modification or deletion
- (WhirlyGlobe::SimpleIdentity) addLabels:(NSArray *)labels desc:(NSDictionary *)desc;
/// Add a single label with the SingleLabel object.  The desc dictionary in that
///  object will specify the look
- (WhirlyGlobe::SimpleIdentity) addLabel:(SingleLabel *)label;

/// Change the display of a given label accordingly to the desc dictionary.
/// Only minVis and maxVis are supported
- (void)changeLabel:(WhirlyGlobe::SimpleIdentity)labelID desc:(NSDictionary *)dict;

/// Return the cost of a given label group (number of drawables and textures).
/// Only call this in the layer thread
- (DrawCost *)getCost:(WhirlyGlobe::SimpleIdentity)labelID;

/// Remove the given label group by ID
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId;

@end
