/*
 *  LabelLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/7/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import <set>
#import "Identifiable.h"
#import "Drawable.h"
#import "DataLayer.h"
#import "LayerThread.h"

namespace WhirlyGlobe 
{

/* Whirly Globe Label
	Represents a label.  This is just a stub so we can reference a
     label for removal.
 */
class Label : public Identifiable
{
public:
	Label() { drawableId = EmptyIdentity; textureId = EmptyIdentity; }
	Label(SimpleIdentity drawableId,SimpleIdentity textureId) : drawableId(drawableId), textureId(textureId) { }
	
	SimpleIdentity getDrawableId() const { return drawableId; }
	void setDrawableId(SimpleIdentity inId) { drawableId = inId; }
	SimpleIdentity getTextureId() const { return textureId; }
	void setTextureId(SimpleIdentity inId) { textureId = inId; }
	
protected:
	// IDs for drawable and texture
	SimpleIdentity drawableId;
	SimpleIdentity textureId;
};
	
typedef std::map<WhirlyGlobe::SimpleIdentity,Label> LabelMap;
	
}

// Set up information related to a label
@interface LabelInfo : NSObject
{
	NSString *str;
	UIFont *font;
	UIColor *textColor;
	UIColor *backgroundColor;
	// Label center in lon/lat
	WhirlyGlobe::GeoCoord loc;
	// Set either width or height.  We'll scale the other one.
	// This is in model coordinates.  Yes, different from the location.
	float width,height;
	// For internal use only
	WhirlyGlobe::SimpleIdentity labelId;
}

@property (nonatomic,retain) NSString *str;
@property (nonatomic,retain) UIFont *font;
@property (nonatomic,retain) UIColor *textColor,*backgroundColor;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,assign) float width,height;

@end

// Vertical offset
// Note: Calculate this
static const float LabelOffset = 0.001;

@interface LabelLayer : NSObject<WhirlyGlobeLayer>
{
	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobeLayerThread *layerThread;
	// Keep track of labels by ID so we can delete them
	WhirlyGlobe::LabelMap *labelMap;
}

// Init empty
- (id)init;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Create a label at the given coordinates, with the font and color as specified
// You get an ID for the label back, with which you can delete it later
- (WhirlyGlobe::SimpleIdentity) addLabel:(LabelInfo *)labelInfo;

// Remove the given label
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId;

@end
