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

// Draw labels after everything else because of the transparency
static const int LabelDrawPriority=1000;

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

	// Keep track of labels by ID so we can delete them
	WhirlyGlobe::LabelMap *labelMap;
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Create a label at the given coordinates, with the font and color as specified
// You get an ID for the label back so you can delete it later
- (WhirlyGlobe::SimpleIdentity) addLabel:(NSString *)str loc:(WhirlyGlobe::GeoCoord)loc desc:(NSDictionary *)desc;

// Remove the given label
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId;

@end
