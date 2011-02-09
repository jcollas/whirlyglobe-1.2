//
//  LabelLayer.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 2/7/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "LabelLayer.h"
#import "WhirlyGeometry.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;

@interface LabelInfo()
@property(nonatomic,assign) WhirlyGlobe::SimpleIdentity labelId;
@end

@implementation LabelInfo

@synthesize str;
@synthesize font;
@synthesize textColor,backgroundColor;
@synthesize loc;
@synthesize width;
@synthesize height;
@synthesize labelId;

- (id)init
{
	if (self = [super init])
	{
		width = height = 0.0;
	}
	
	return self;
}

- (void)dealloc
{
	self.str = nil;
	self.font = nil;
	self.textColor = nil;
	self.backgroundColor = nil;
	
	[super dealloc];
}

// Draw into an image of the appropriate size (but no bigger)
// Also returns the text size, for calculating texture coordinates
// Note: We don't need a full RGBA image here
- (UIImage *)renderToImage:(CGSize *)textSize
{
	// Figure out how big this needs to be
	*textSize = [self.str sizeWithFont:self.font];
	if (textSize->width == 0 || textSize->height == 0)
		return nil;
	
	// Next power of two up
	CGSize size;
	size.width = NextPowOf2(textSize->width);
	size.height = NextPowOf2(textSize->height);

	UIGraphicsBeginImageContext(size);
	
	// Draw into the image context
	[self.backgroundColor setFill];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextFillRect(ctx, CGRectMake(0,0,size.width,size.height));
	
	[self.textColor setFill];
	[self.str drawAtPoint:CGPointMake(0,0) withFont:self.font];
	
	// Grab the image and shut things down
	UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();
		
	return retImage;
}

@end


@interface LabelLayer()
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@end

@implementation LabelLayer

@synthesize layerThread;

- (id)init
{
	if (self = [super init])
	{
		labelMap = new LabelMap();
	}
	
	return self;
}

- (void)dealloc
{
	self.layerThread = nil;
	if (labelMap)
		delete labelMap;
	labelMap = NULL;
	
	[super dealloc];
}

// We only do things when called on, so nothing much to do here
- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene;
{
	self.layerThread = inLayerThread;
	scene = inScene;
}

// Create the label and keep track of it
// We're in the layer thread here
- (void)runAddLabel:(LabelInfo *)labelInfo
{
	// Render to an image, next size up and create a texture
	CGSize textSize;
	UIImage *textImage = [labelInfo renderToImage:&textSize];
	if (!textImage)
		return;	
	Texture *texture = new Texture(textImage);
	
	// Figure out the extents in 3-space
	// Note: Probably won't work at the poles
	Point3f norm = PointFromGeo(labelInfo.loc);
	Point3f center = (1.0 + LabelOffset) * norm;
	Point3f up(0,0,1);
	Point3f horiz = up.cross(norm).normalized();
	Point3f vert = norm.cross(horiz).normalized();;
	float width2,height2;
	if (labelInfo.width != 0.0)
	{
		height2 = labelInfo.width * textSize.height / ((float)2.0 * textSize.width);
		width2 = labelInfo.width/2.0;
	} else {
		width2 = labelInfo.height * textSize.width / ((float)2.0 * textSize.height);
		height2 = labelInfo.height/2.0;
	}
	
	Point3f pts[4];
	pts[0] = center - width2 * horiz - height2 * vert;
	pts[1] = center + width2 * horiz - height2 * vert;
	pts[2] = center + width2 * horiz + height2 * vert;
	pts[3] = center - width2 * horiz + height2 * vert;
	
	// Texture coordinates are a little odd because text might not take up the whole texture
	TexCoord texCoord[4];
	texCoord[0].u() = 0.0;										texCoord[0].v() = textSize.height / textImage.size.height;
	texCoord[1].u() = textSize.width / textImage.size.width;	texCoord[1].v() = texCoord[0].v();
	texCoord[2].u() = texCoord[1].u();							texCoord[2].v() = 0.0;
	texCoord[3].u() = 0.0;										texCoord[3].v() = 0.0;
	
	// Create a drawable for the text rectangle
	BasicDrawable *drawable = new BasicDrawable();
	for (unsigned int ii=0;ii<4;ii++)
	{
		drawable->addPoint(pts[ii]);
		drawable->addNormal(norm);
		drawable->addTexCoord(texCoord[ii]);
	}
	drawable->setDrawPriority(LabelDrawPriority);
	drawable->setType(GL_TRIANGLES);
	drawable->setTexId(texture->getId());
	drawable->setColor(RGBAColor(255,255,255,255));
	drawable->setGeoMbr(GeoMbr(labelInfo.loc,labelInfo.loc));
	drawable->addTriangle(BasicDrawable::Triangle(0,1,2));
	drawable->addTriangle(BasicDrawable::Triangle(2,3,0));
	
	// Hand the texture and drawable off to the rendering thead
	// Not our responsibility after this
	scene->addChangeRequest(ChangeRequest::AddTextureCR(texture));
	scene->addChangeRequest(ChangeRequest::AddDrawableCR(drawable));
	
	// Now keep track of the drawable we created
	// By implication, this tracks the texture too
	Label newLabel(drawable->getId(),texture->getId());
	newLabel.setId(labelInfo.labelId);
	(*labelMap)[labelInfo.labelId] = newLabel;
}

// Remove the given label
- (void)runRemoveLabel:(NSNumber *)num
{
	SimpleIdentity labelId = [num unsignedIntValue];
	
	LabelMap::iterator it = labelMap->find(labelId);
	if (it != labelMap->end())
	{
		// Ask the scene to get rid of the texture and drawable
		Label &label = it->second;
		scene->addChangeRequest(ChangeRequest::RemTextureCR(label.getTextureId()));
		scene->addChangeRequest(ChangeRequest::RemDrawableCR(label.getDrawableId()));
		
		labelMap->erase(it);
	}
}

// Pass off label creation to a routine in our own thread
- (SimpleIdentity) addLabel:(LabelInfo *)labelInfo;
{
	labelInfo.labelId = Identifiable::genId();
	[self performSelector:@selector(runAddLabel:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
	
	return labelInfo.labelId;
}

// Set up the label to be removed in the layer thread
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId
{
	NSNumber *num = [[NSNumber numberWithUnsignedInt:labelId] retain];
	[self performSelector:@selector(runRemoveLabel:) onThread:layerThread withObject:num waitUntilDone:NO];
}

@end
