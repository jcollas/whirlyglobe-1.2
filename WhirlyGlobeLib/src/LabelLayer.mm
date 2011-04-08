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
#import "NSDictionary+Stuff.h"

using namespace WhirlyGlobe;

@implementation SingleLabel
@synthesize text;
@synthesize loc;
@synthesize desc;

- (void)dealloc
{
    self.text = nil;
    self.desc = nil;
    
    [super dealloc];
}

@end

// Label spec passed around between threads
@interface LabelInfo : NSObject
{  
    NSArray                 *strs;  // SingleLabel objects
    UIColor                 *textColor;
    UIColor                 *backColor;
    UIFont                  *font;
    float                   width,height;
    int                     drawOffset;
    float                   minVis,maxVis;
    WhirlyGlobe::SimpleIdentity labelId;
}

@property (nonatomic,retain) NSArray *strs;
@property (nonatomic,retain) UIColor *textColor,*backColor;
@property (nonatomic,retain) UIFont *font;
@property (nonatomic,assign) float width,height;
@property (nonatomic,assign) int drawOffset;
@property (nonatomic,assign) float minVis,maxVis;
@property (nonatomic,readonly) WhirlyGlobe::SimpleIdentity labelId;

@end

@implementation LabelInfo

@synthesize strs;
@synthesize textColor,backColor;
@synthesize font;
@synthesize width,height;
@synthesize drawOffset;
@synthesize minVis,maxVis;
@synthesize labelId;

// Initialize a label info with data from the description dictionary
- (id)initWithStrs:(NSArray *)inStrs desc:(NSDictionary *)desc
{
    if ((self = [super init]))
    {
        self.strs = inStrs;
        
        self.textColor = [desc objectForKey:@"textColor" checkType:[UIColor class] default:[UIColor whiteColor]];
        self.backColor = [desc objectForKey:@"backgroundColor" checkType:[UIColor class] default:[UIColor clearColor]];
        self.font = [desc objectForKey:@"font" checkType:[UIFont class] default:[UIFont systemFontOfSize:32.0]];
        width = [desc floatForKey:@"width" default:0.001];
        height = [desc floatForKey:@"height" default:0.001];
        drawOffset = [desc intForKey:@"drawOffset" default:1];
        minVis = [desc floatForKey:@"minVis" default:DrawVisibleInvalid];
        maxVis = [desc floatForKey:@"maxVis" default:DrawVisibleInvalid];
        labelId = WhirlyGlobe::Identifiable::genId();
    }
    
    return self;
}

- (void)dealloc
{
    self.strs = nil;
    self.textColor = nil;
    self.backColor = nil;
    self.font = nil;
    
    [super dealloc];
}

// Draw into an image of the appropriate size (but no bigger)
// Also returns the text size, for calculating texture coordinates
// Note: We don't need a full RGBA image here
- (UIImage *)renderToImage:(SingleLabel *)label powOfTwo:(BOOL)usePowOfTwo retSize:(CGSize *)textSize texOrg:(TexCoord &)texOrg texDest:(TexCoord &)texDest
{
    // A single label can override a few of the label attributes
    UIColor *theTextColor = self.textColor;
    UIColor *theBackColor = self.backColor;
    UIFont *theFont = self.font;
    if (label.desc)
    {
        theTextColor = [label.desc objectForKey:@"textColor" checkType:[UIColor class] default:theTextColor];
        theBackColor = [label.desc objectForKey:@"backgroundColor" checkType:[UIColor class] default:theBackColor];
        theFont = [label.desc objectForKey:@"font" checkType:[UIFont class] default:theFont];
    }
    
    // Figure out how big this needs to be
    *textSize = [label.text sizeWithFont:font];
    if (textSize->width == 0 || textSize->height == 0)
        return nil;
    
    CGSize size;
    if (usePowOfTwo)
    {
        size.width = NextPowOf2(textSize->width);
        size.height = NextPowOf2(textSize->height);
    } else {
        size.width = textSize->width;
        size.height = textSize->height;
    }

	UIGraphicsBeginImageContext(size);
	
	// Draw into the image context
	[theBackColor setFill];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextFillRect(ctx, CGRectMake(0,0,size.width,size.height));
	
	[theTextColor setFill];
	[label.text drawAtPoint:CGPointMake(0,0) withFont:theFont];
	
	// Grab the image and shut things down
	UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();
    
    if (usePowOfTwo)
    {
        texOrg.u() = 0.0;  texOrg.v() = textSize->height / size.height;
        texDest.u() = textSize->width / size.width;  texDest.v() = 0.0;
    } else {
        texOrg.u() = 0.0;  texOrg.v() = 1.0;  
        texDest.u() = 1.0;  texDest.v() = 0.0;
    }

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
    if ((self = [super init]))
    {
    }
    
    return self;
}

- (void)dealloc
{
    self.layerThread = nil;
    for (LabelSceneRepMap::iterator it=labelReps.begin();
         it!=labelReps.end(); ++it)
        delete it->second;
    labelReps.clear();
    
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
// Note: Badly optimized for single label case
- (void)runAddLabels:(LabelInfo *)labelInfo
{
    LabelSceneRep *labelRep = new LabelSceneRep();
    labelRep->setId(labelInfo.labelId);

    // Texture atlases we're building up for the labels
    std::vector<TextureAtlas *> texAtlases;
    std::vector<BasicDrawable *> drawables;
    
    // Let's only bother for more than one label
    bool texAtlasOn = [labelInfo.strs count] > 1;

    // Work through the labels
    for (SingleLabel *label in labelInfo.strs)
    {    
        TexCoord texOrg,texDest;
        CGSize textSize;
        UIImage *textImage = [labelInfo renderToImage:label powOfTwo:!texAtlasOn retSize:&textSize texOrg:texOrg texDest:texDest];
        if (!textImage)
            return;
        
        // Look for a spot in an existing texture atlas
        int foundii = -1;
        BasicDrawable *drawable = NULL;
        TextureAtlas *texAtlas = nil;
        
        if (texAtlasOn && textSize.width <= LabelTextureAtlasSize && 
                          textSize.height <= LabelTextureAtlasSize)
        {
            for (unsigned int ii=0;ii<texAtlases.size();ii++)
            {
                if ([texAtlases[ii] addImage:textImage texOrg:texOrg texDest:texDest])
                    foundii = ii;
            }
            if (foundii < 0)
            {
                // If we didn't find one, add a new one
                texAtlas = [[TextureAtlas alloc] inithWithTexSizeX:LabelTextureAtlasSize texSizeY:LabelTextureAtlasSize cellSizeX:8 cellSizeY:8];
                foundii = texAtlases.size();
                texAtlases.push_back(texAtlas);
                [texAtlas addImage:textImage texOrg:texOrg texDest:texDest];
                
                // And a corresponding drawable
                BasicDrawable *drawable = new BasicDrawable();
                drawable->setDrawOffset(labelInfo.drawOffset);
                drawable->setType(GL_TRIANGLES);
                drawable->setColor(RGBAColor(255,255,255,255));
                drawable->setDrawPriority(LabelDrawPriority);
                drawable->setVisibleRange(labelInfo.minVis,labelInfo.maxVis);
                drawables.push_back(drawable);
            }
            drawable = drawables[foundii];
            texAtlas = texAtlases[foundii];
        } else {
            // Add a drawable for just the one label because it's too big
            drawable = new BasicDrawable();
            drawable->setDrawOffset(labelInfo.drawOffset);
            drawable->setType(GL_TRIANGLES);
            drawable->setColor(RGBAColor(255,255,255,255));
            drawable->addTriangle(BasicDrawable::Triangle(0,1,2));
            drawable->addTriangle(BasicDrawable::Triangle(2,3,0));
            drawable->setDrawPriority(LabelDrawPriority);
            drawable->setVisibleRange(labelInfo.minVis,labelInfo.maxVis);            
        } 
        
        // Figure out the extents in 3-space
        // Note: Probably won't work at the poles
        Point3f norm = PointFromGeo(label.loc);
        Point3f center = norm;
        Point3f up(0,0,1);
        Point3f horiz = up.cross(norm).normalized();
        Point3f vert = norm.cross(horiz).normalized();;
        
        // Width and height can be overriden per label
        float theWidth = labelInfo.width;
        float theHeight = labelInfo.height;
        if (label.desc)
        {
            theWidth = [label.desc floatForKey:@"width" default:theWidth];
            theHeight = [label.desc floatForKey:@"height" default:theHeight];
        }
        
        float width2,height2;
        if (theWidth != 0.0)
        {
            height2 = theWidth * textSize.height / ((float)2.0 * textSize.width);
            width2 = theWidth/2.0;
        } else {
            width2 = theHeight * textSize.width / ((float)2.0 * textSize.height);
            height2 = theHeight/2.0;
        }
        
        Point3f pts[4];
        pts[0] = center - width2 * horiz - height2 * vert;
        pts[1] = center + width2 * horiz - height2 * vert;
        pts[2] = center + width2 * horiz + height2 * vert;
        pts[3] = center - width2 * horiz + height2 * vert;
        
        // Texture coordinates are a little odd because text might not take up the whole texture
        // Note: These are wrong for atlases
        TexCoord texCoord[4];
        texCoord[0].u() = texOrg.u();  texCoord[0].v() = texOrg.v();
        texCoord[1].u() = texDest.u();  texCoord[1].v() = texOrg.v();
        texCoord[2].u() = texDest.u();  texCoord[2].v() = texDest.v();
        texCoord[3].u() = texOrg.u();  texCoord[3].v() = texDest.v();

        // Add to the drawable we found (corresponding to a texture atlas)
        int vOff = drawable->getNumPoints();
        for (unsigned int ii=0;ii<4;ii++)
        {
            Point3f &pt = pts[ii];
            drawable->addPoint(pt);
            drawable->addNormal(norm);
            drawable->addTexCoord(texCoord[ii]);
            GeoMbr geoMbr = drawable->getGeoMbr();
            geoMbr.addGeoCoord(label.loc);
            drawable->setGeoMbr(geoMbr);
        }
        drawable->addTriangle(BasicDrawable::Triangle(0+vOff,1+vOff,2+vOff));
        drawable->addTriangle(BasicDrawable::Triangle(2+vOff,3+vOff,0+vOff));
        
        // If we don't have a texture atlas (didn't fit), just hand over
        //  the drawable and make a new texture
        if (!texAtlas)
        {
            Texture *tex = new Texture(textImage);
            drawable->setTexId(tex->getId());

            scene->addChangeRequest(new AddTextureReq(tex));
            scene->addChangeRequest(new AddDrawableReq(drawable));
            
            labelRep->texIDs.insert(tex->getId());
            labelRep->drawIDs.insert(drawable->getId());
        }
    }

    // Generate textures from the atlases, point the drawables at them
    //  and hand both over to the rendering thread
    // Keep track of all of this stuff for the label representation (for deletion later)
    for (unsigned int ii=0;ii<texAtlases.size();ii++)
    {
        Texture *tex = [texAtlases[ii] createTexture];
        BasicDrawable *drawable = drawables[ii];
        drawable->setTexId(tex->getId());

        scene->addChangeRequest(new AddTextureReq(tex));
        scene->addChangeRequest(new AddDrawableReq(drawable));
        
        labelRep->texIDs.insert(tex->getId());
        labelRep->drawIDs.insert(drawable->getId());
    }    
    
    labelReps[labelRep->getId()] = labelRep;
}

// Remove the given label
- (void)runRemoveLabel:(NSNumber *)num
{
    SimpleIdentity labelId = [num unsignedIntValue];
    
    LabelSceneRepMap::iterator it = labelReps.find(labelId);
    if (it != labelReps.end())
    {
        LabelSceneRep *labelRep = it->second;

        for (SimpleIDSet::iterator idIt = labelRep->drawIDs.begin();
             idIt != labelRep->drawIDs.end(); ++idIt)
            scene->addChangeRequest(new RemDrawableReq(*idIt));
        for (SimpleIDSet::iterator idIt = labelRep->texIDs.begin();
             idIt != labelRep->texIDs.end(); ++idIt)        
        scene->addChangeRequest(new RemTextureReq(*idIt));
        
        labelReps.erase(it);
        delete labelRep;
    }
}

// Pass off label creation to a routine in our own thread
- (SimpleIdentity) addLabel:(NSString *)str loc:(WhirlyGlobe::GeoCoord)loc desc:(NSDictionary *)desc
{
    SingleLabel *theLabel = [[[SingleLabel alloc] init] autorelease];
    theLabel.text = str;
    theLabel.loc = loc;
    LabelInfo *labelInfo = [[[LabelInfo alloc] initWithStrs:[NSArray arrayWithObject:theLabel] desc:desc] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddLabels:labelInfo];
    else
        [self performSelector:@selector(runAddLabels:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
    
    return labelInfo.labelId;
}

// Pass of creation of a whole bunch of labels
- (SimpleIdentity) addLabels:(NSArray *)labels desc:(NSDictionary *)desc
{
    LabelInfo *labelInfo = [[[LabelInfo alloc] initWithStrs:labels desc:desc] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddLabels:labelInfo];
    else
        [self performSelector:@selector(runAddLabels:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
    
    return labelInfo.labelId;    
}

// Set up the label to be removed in the layer thread
- (void) removeLabel:(WhirlyGlobe::SimpleIdentity)labelId
{
    NSNumber *num = [NSNumber numberWithUnsignedInt:labelId];
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runRemoveLabel:num];
    else
        [self performSelector:@selector(runRemoveLabel:) onThread:layerThread withObject:num waitUntilDone:NO];
}

@end
