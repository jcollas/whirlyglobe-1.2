/*
 *  LabelLayer.mm
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

#import "LabelLayer.h"
#import "WhirlyGeometry.h"
#import "GlobeMath.h"
#import "NSDictionary+Stuff.h"
#import "RenderCache.h"

namespace WhirlyGlobe
{
LabelSceneRep::LabelSceneRep() 
{ 
    selectID = EmptyIdentity; 
}

}

// How a label is justified for display
typedef enum {Middle,Left,Right} LabelJustify;

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
    LabelJustify            justify;
    int                     drawPriority;
    WhirlyGlobe::SimpleIdentity labelId;
    float                   fade;
    NSString                *cacheName;
}

@property (nonatomic,retain) NSArray *strs;
@property (nonatomic,retain) UIColor *textColor,*backColor;
@property (nonatomic,retain) UIFont *font;
@property (nonatomic,assign) float width,height;
@property (nonatomic,assign) int drawOffset;
@property (nonatomic,assign) float minVis,maxVis;
@property (nonatomic,assign) LabelJustify justify;
@property (nonatomic,assign) int drawPriority;
@property (nonatomic,readonly) WhirlyGlobe::SimpleIdentity labelId;
@property (nonatomic,assign) float fade;
@property (nonatomic,retain) NSString *cacheName;

- (id)initWithStrs:(NSArray *)inStrs desc:(NSDictionary *)desc;

@end

using namespace WhirlyGlobe;

@implementation SingleLabel
@synthesize text;
@synthesize loc;
@synthesize desc;
@synthesize iconTexture;
@synthesize isSelectable;
@synthesize selectID;

- (void)dealloc
{
    self.text = nil;
    self.desc = nil;
    
    [super dealloc];
}

- (bool)calcWidth:(float *)width height:(float *)height defaultFont:(UIFont *)font
{
    CGSize textSize = [text sizeWithFont:font];
    if (textSize.width == 0 || textSize.height == 0)
        return false;
    
    if (*width != 0.0)
        *height = *width * textSize.height / ((float)textSize.width);
    else
        *width = *height * textSize.width / ((float)textSize.height);
    
    return true;
}

// Calculate the corners in this order:  (ll,lr,ur,ul)
- (void)calcExtents2:(float)width2 height2:(float)height2 iconSize:(float)iconSize justify:(LabelJustify)justify corners:(Point3f *)pts norm:(Point3f *)norm iconCorners:(Point3f *)iconPts
{
    *norm = PointFromGeo(loc);
    Point3f center = *norm;
    Point3f up(0,0,1);
    Point3f horiz = up.cross(*norm).normalized();
    Point3f vert = norm->cross(horiz).normalized();;
    Point3f ll;
    
    switch (justify)
    {
        case Left:
            ll = center + iconSize * horiz - height2 * vert;
            break;
        case Middle:
            ll = center - (width2 + iconSize/2) * horiz - height2 * vert;
            break;
        case Right:
            ll = center - 2*width2 * horiz - height2 * vert;
            break;
    }
    pts[0] = ll;
    pts[1] = ll + 2*width2 * horiz;
    pts[2] = ll + 2*width2 * horiz + 2 * height2 * vert;
    pts[3] = ll + 2 * height2 * vert;

    // Now add the quad for the icon
    switch (justify)
    {
        case Left:
            ll = center - height2*vert;
            break;
        case Middle:
            ll = center - (width2 + iconSize) * horiz - height2*vert;
            break;
        case Right:
            ll = center - (2*width2 + iconSize) * horiz - height2*vert;
            break;
    }
    iconPts[0] = ll;
    iconPts[1] = ll + iconSize*horiz;
    iconPts[2] = ll + iconSize*horiz + iconSize*vert;
    iconPts[3] = ll + iconSize*vert;
}

- (void)calcExtents:(NSDictionary *)topDesc corners:(Point3f *)pts norm:(Point3f *)norm
{
    LabelInfo *labelInfo = [[[LabelInfo alloc] initWithStrs:[NSArray arrayWithObject:self.text] desc:topDesc] autorelease];
    
    // Width and height can be overriden per label
    float theWidth = labelInfo.width;
    float theHeight = labelInfo.height;
    if (desc)
    {
        theWidth = [desc floatForKey:@"width" default:theWidth];
        theHeight = [desc floatForKey:@"height" default:theHeight];
    }
    
    CGSize textSize = [text sizeWithFont:labelInfo.font];
    
    float width2,height2;
    if (theWidth != 0.0)
    {
        height2 = theWidth * textSize.height / ((float)2.0 * textSize.width);
        width2 = theWidth/2.0;
    } else {
        width2 = theHeight * textSize.width / ((float)2.0 * textSize.height);
        height2 = theHeight/2.0;
    }
    
    // If there's an icon, we need to offset the label
    float iconSize = (iconTexture==EmptyIdentity ? 0.f : 2*height2);

    Point3f corners[4],iconCorners[4];
    [self calcExtents2:width2 height2:height2 iconSize:iconSize justify:labelInfo.justify corners:corners norm:norm iconCorners:iconCorners];
    
    // If we have an icon, we need slightly different corners
    if (iconTexture)
    {
        pts[0] = iconCorners[0];
        pts[1] = corners[1];
        pts[2] = corners[2];
        pts[3] = iconCorners[3];
    } else {
        pts[0] = corners[0];
        pts[1] = corners[1];
        pts[2] = corners[2];
        pts[3] = corners[3];
    }
}



@end

@implementation LabelInfo

@synthesize strs;
@synthesize textColor,backColor;
@synthesize font;
@synthesize width,height;
@synthesize drawOffset;
@synthesize minVis,maxVis;
@synthesize justify;
@synthesize drawPriority;
@synthesize labelId;
@synthesize fade;
@synthesize cacheName;

// Parse label info out of a description
- (void)parseDesc:(NSDictionary *)desc
{
    self.textColor = [desc objectForKey:@"textColor" checkType:[UIColor class] default:[UIColor whiteColor]];
    self.backColor = [desc objectForKey:@"backgroundColor" checkType:[UIColor class] default:[UIColor clearColor]];
    self.font = [desc objectForKey:@"font" checkType:[UIFont class] default:[UIFont systemFontOfSize:32.0]];
    width = [desc floatForKey:@"width" default:0.001];
    height = [desc floatForKey:@"height" default:0.001];
    drawOffset = [desc intForKey:@"drawOffset" default:0];
    minVis = [desc floatForKey:@"minVis" default:DrawVisibleInvalid];
    maxVis = [desc floatForKey:@"maxVis" default:DrawVisibleInvalid];
    NSString *justifyStr = [desc stringForKey:@"justify" default:@"middle"];
    fade = [desc floatForKey:@"fade" default:0.0];
    if (![justifyStr compare:@"middle"])
        justify = Middle;
    else {
        if (![justifyStr compare:@"left"])
            justify = Left;
        else {
            if (![justifyStr compare:@"right"])
                justify = Right;
        }
    }
    drawPriority = [desc intForKey:@"drawPriority" default:LabelDrawPriority];
}

// Initialize a label info with data from the description dictionary
- (id)initWithStrs:(NSArray *)inStrs desc:(NSDictionary *)desc
{
    if ((self = [super init]))
    {
        self.strs = inStrs;
        [self parseDesc:desc];
        
        labelId = WhirlyGlobe::Identifiable::genId();
    }
    
    return self;
}

// Initialize a label with data from the description dictionary
- (id)initWithSceneRepId:(SimpleIdentity)inLabelId desc:(NSDictionary *)desc
{
    if ((self = [super init]))
    {
        [self parseDesc:desc];
        labelId = inLabelId;
    }
    
    return self;
}

- (void)dealloc
{
    self.strs = nil;
    self.textColor = nil;
    self.backColor = nil;
    self.font = nil;
    self.cacheName = nil;
    
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
@property (nonatomic,assign) WhirlyGlobeLayerThread *layerThread;
@end

@implementation LabelLayer

@synthesize layerThread;
@synthesize selectLayer;

- (id)init
{
    if ((self = [super init]))
    {
        textureAtlasSize = LabelTextureAtlasSizeDefault;
    }
    
    return self;
}

- (id)initWithTexAtlasSize:(unsigned int)inTextureAtlasSize
{
    if ((self = [super init]))
    {
        textureAtlasSize = inTextureAtlasSize;
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

// We use these for labels that have icons
// Don't want to give them their own separate drawable, obviously
typedef std::map<SimpleIdentity,BasicDrawable *> IconDrawables;

// Create the label and keep track of it
// We're in the layer thread here
// Note: Badly optimized for single label case
- (void)runAddLabels:(LabelInfo *)labelInfo
{
    LabelSceneRep *labelRep = new LabelSceneRep();
    labelRep->fade = labelInfo.fade;
    labelRep->setId(labelInfo.labelId);

    // Texture atlases we're building up for the labels
    std::vector<TextureAtlas *> texAtlases;
    std::vector<BasicDrawable *> drawables;
    
    // If we're writing out to a cache, set that up as well
    RenderCacheWriter *renderCacheWriter=NULL;
    if (labelInfo.cacheName)
        renderCacheWriter = new RenderCacheWriter(labelInfo.cacheName);    
    
    // Drawables used for the icons
    IconDrawables iconDrawables;
    
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
        
        if (texAtlasOn && textSize.width <= textureAtlasSize && 
                          textSize.height <= textureAtlasSize)
        {
            for (unsigned int ii=0;ii<texAtlases.size();ii++)
            {
                if ([texAtlases[ii] addImage:textImage texOrg:texOrg texDest:texDest])
                    foundii = ii;
            }
            if (foundii < 0)
            {
                // If we didn't find one, add a new one
                texAtlas = [[TextureAtlas alloc] inithWithTexSizeX:textureAtlasSize texSizeY:textureAtlasSize cellSizeX:8 cellSizeY:8];
                foundii = texAtlases.size();
                texAtlases.push_back(texAtlas);
                [texAtlas addImage:textImage texOrg:texOrg texDest:texDest];
                
                // And a corresponding drawable
                BasicDrawable *drawable = new BasicDrawable();
                drawable->setDrawOffset(labelInfo.drawOffset);
                drawable->setType(GL_TRIANGLES);
                drawable->setColor(RGBAColor(255,255,255,255));
                drawable->setDrawPriority(labelInfo.drawPriority);
                drawable->setVisibleRange(labelInfo.minVis,labelInfo.maxVis);
                drawable->setAlpha(true);
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
            drawable->setDrawPriority(labelInfo.drawPriority);
            drawable->setVisibleRange(labelInfo.minVis,labelInfo.maxVis);            
            drawable->setAlpha(true);
        } 
        
        // Figure out the extents in 3-space
        // Note: Probably won't work at the poles
        
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
        
        // If there's an icon, we need to offset the label
        float iconSize = (label.iconTexture==EmptyIdentity ? 0.f : 2*height2);

        Point3f norm;
        Point3f pts[4],iconPts[4];
        {
            Point3f ll;
            
            [label calcExtents2:width2 height2:height2 iconSize:iconSize justify:labelInfo.justify corners:pts norm:&norm iconCorners:iconPts];
                        
            // Texture coordinates are a little odd because text might not take up the whole texture
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
                
                // Add these to the cache first, before the renderer messes with them
                if (renderCacheWriter)
                {
                    renderCacheWriter->addTexture(tex->getId(),textImage);
                    renderCacheWriter->addDrawable(drawable);
                }

                if (labelInfo.fade > 0.0)
                {
                    NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
                    drawable->setFade(curTime,curTime+labelInfo.fade);
                }

                // Pass over to the renderer
                scene->addChangeRequest(new AddTextureReq(tex));
                scene->addChangeRequest(new AddDrawableReq(drawable));
                
                labelRep->texIDs.insert(tex->getId());
                labelRep->drawIDs.insert(drawable->getId());
            }
        }
        
        // Register the main label as selectable
        if (selectLayer && label.isSelectable)
        {
            // If the marker doesn't already have an ID, it needs one
            if (!label.selectID)
                label.selectID = Identifiable::genId();
            
            [selectLayer addSelectableRect:label.selectID rect:pts];
            labelRep->selectID = label.selectID;
        }
        
        // If there's an icon, let's add that
        if (label.iconTexture != EmptyIdentity)
        {
            if (renderCacheWriter)
                NSLog(@"LabelLayer: icon textures will not be cached properly.");
            
            SubTexture subTex = scene->getSubTexture(label.iconTexture);
            
            // Try to add this to an existing drawable
            IconDrawables::iterator it = iconDrawables.find(subTex.texId);
            BasicDrawable *iconDrawable = NULL;
            if (it == iconDrawables.end())
            {
                // Create one
                iconDrawable = new BasicDrawable();
                iconDrawable->setDrawOffset(labelInfo.drawOffset);
                iconDrawable->setType(GL_TRIANGLES);
                iconDrawable->setColor(RGBAColor(255,255,255,255));
                iconDrawable->setDrawPriority(labelInfo.drawPriority);
                iconDrawable->setVisibleRange(labelInfo.minVis,labelInfo.maxVis);
                iconDrawable->setAlpha(true);  // Note: Don't know this
                iconDrawable->setTexId(subTex.texId);
                iconDrawables[subTex.texId] = iconDrawable;
            } else
                iconDrawable = it->second;
                        
            // Texture coordinates are a little odd because text might not take up the whole texture
            std::vector<TexCoord> texCoord;
            texCoord.resize(4);
            texCoord[0].u() = 0.0;  texCoord[0].v() = 0.0;
            texCoord[1].u() = 1.0;  texCoord[1].v() = 0.0;
            texCoord[2].u() = 1.0;  texCoord[2].v() = 1.0;
            texCoord[3].u() = 0.0;  texCoord[3].v() = 1.0;
            subTex.processTexCoords(texCoord);
            
            // Add to the drawable we found (corresponding to a texture atlas)
            int vOff = iconDrawable->getNumPoints();
            for (unsigned int ii=0;ii<4;ii++)
            {
                Point3f &pt = iconPts[ii];
                iconDrawable->addPoint(pt);
                iconDrawable->addNormal(norm);
                iconDrawable->addTexCoord(texCoord[ii]);
                GeoMbr geoMbr = iconDrawable->getGeoMbr();
                geoMbr.addGeoCoord(label.loc);
                iconDrawable->setGeoMbr(geoMbr);
            }
            iconDrawable->addTriangle(BasicDrawable::Triangle(0+vOff,1+vOff,2+vOff));
            iconDrawable->addTriangle(BasicDrawable::Triangle(2+vOff,3+vOff,0+vOff));

            // Register the icon separately
            // Note: This won't work.  One rectangle per ID.
            if (selectLayer && label.isSelectable)
            {
                // If the marker doesn't already have an ID, it needs one
//                if (!label.selectID)
//                    label.selectID = Identifiable::genId();
//                
//                [selectLayer addSelectableRect:label.selectID rect:pts];
            }            
        }
    }

    // Generate textures from the atlases, point the drawables at them
    //  and hand both over to the rendering thread
    // Keep track of all of this stuff for the label representation (for deletion later)
    for (unsigned int ii=0;ii<texAtlases.size();ii++)
    {
        UIImage *theImage = nil;
        Texture *tex = [texAtlases[ii] createTexture:&theImage];
        BasicDrawable *drawable = drawables[ii];
        drawable->setTexId(tex->getId());

        // And save out to the cache if need be
        if (renderCacheWriter)
        {
            renderCacheWriter->addTexture(tex->getId(),theImage);
            renderCacheWriter->addDrawable(drawable);
        }

        if (labelInfo.fade > 0.0)
        {
            NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
            drawable->setFade(curTime,curTime+labelInfo.fade);
        }

        scene->addChangeRequest(new AddTextureReq(tex));
        scene->addChangeRequest(new AddDrawableReq(drawable));
                
        labelRep->texIDs.insert(tex->getId());
        labelRep->drawIDs.insert(drawable->getId());
        
        [texAtlases[ii] release];
    }  
        
    // Flush out the icon drawables as well
    for (IconDrawables::iterator it = iconDrawables.begin();
         it != iconDrawables.end(); ++it)
    {
        BasicDrawable *iconDrawable = it->second;

        if (labelInfo.fade > 0.0)
        {
            NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
            iconDrawable->setFade(curTime,curTime+labelInfo.fade);
        }
        scene->addChangeRequest(new AddDrawableReq(iconDrawable));
        labelRep->drawIDs.insert(iconDrawable->getId());
    }
    
    labelReps[labelRep->getId()] = labelRep;
    
    if (renderCacheWriter)
        delete renderCacheWriter;
}

// Add a group of labels that was previously saved to a cache
- (void)runAddLabelsFromCache:(LabelInfo *)labelInfo
{
    RenderCacheReader *renderCacheReader = new RenderCacheReader(labelInfo.cacheName);
    
    // Load in the textures and drawables
    SimpleIDSet texIDs,drawIDs;
    if (!renderCacheReader->getDrawablesAndTexturesAddToScene(scene,texIDs,drawIDs,labelInfo.fade))
        NSLog(@"LabelLayer failed to load from cache: %@",labelInfo.cacheName);
    else
    {
        LabelSceneRep *labelRep = new LabelSceneRep();
        labelRep->setId(labelInfo.labelId);
        labelRep->texIDs = texIDs;
        labelRep->drawIDs = drawIDs;
        labelReps[labelRep->getId()] = labelRep;
    }
    
    delete renderCacheReader;
}

// Remove the given label
- (void)runRemoveLabel:(NSNumber *)num
{
    SimpleIdentity labelId = [num unsignedIntValue];
    
    LabelSceneRepMap::iterator it = labelReps.find(labelId);
    if (it != labelReps.end())
    {
        LabelSceneRep *labelRep = it->second;
        
        // We need to fade them out, then delete
        if (labelRep->fade > 0.0)
        {
            NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
            for (SimpleIDSet::iterator idIt = labelRep->drawIDs.begin();
                 idIt != labelRep->drawIDs.end(); ++idIt)
                scene->addChangeRequest(new FadeChangeRequest(*idIt,curTime,curTime+labelRep->fade));                
            
            // Reset the fade and try to delete again later
            [self performSelector:@selector(runRemoveLabel:) withObject:num afterDelay:labelRep->fade];
            labelRep->fade = 0.0;
        } else {
            for (SimpleIDSet::iterator idIt = labelRep->drawIDs.begin();
                 idIt != labelRep->drawIDs.end(); ++idIt)
                scene->addChangeRequest(new RemDrawableReq(*idIt));
            for (SimpleIDSet::iterator idIt = labelRep->texIDs.begin();
                 idIt != labelRep->texIDs.end(); ++idIt)        
                scene->addChangeRequest(new RemTextureReq(*idIt));
            
            if (labelRep->selectID != EmptyIdentity && selectLayer)
                [self.selectLayer removeSelectable:labelRep->selectID];
            
            labelReps.erase(it);
            delete labelRep;
        }
    }
}

// Pass off label creation to a routine in our own thread
- (SimpleIdentity) addLabel:(NSString *)str loc:(WhirlyGlobe::GeoCoord)loc desc:(NSDictionary *)desc
{
    SingleLabel *theLabel = [[[SingleLabel alloc] init] autorelease];
    theLabel.text = str;
    [theLabel setLoc:loc];
    LabelInfo *labelInfo = [[[LabelInfo alloc] initWithStrs:[NSArray arrayWithObject:theLabel] desc:desc] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddLabels:labelInfo];
    else
        [self performSelector:@selector(runAddLabels:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
    
    return labelInfo.labelId;
}

// Pass off creation of a whole bunch of labels
- (SimpleIdentity) addLabels:(NSArray *)labels desc:(NSDictionary *)desc
{
    return [self addLabels:labels desc:desc cacheName:nil];
}

- (SimpleIdentity) addLabel:(SingleLabel *)label
{
    return [self addLabels:[NSMutableArray arrayWithObject:label] desc:label.desc];
}

/// Add a group of labels and save them to a render cache
- (SimpleIdentity) addLabels:(NSArray *)labels desc:(NSDictionary *)desc cacheName:(NSString *)cacheName
{
    LabelInfo *labelInfo = [[[LabelInfo alloc] initWithStrs:labels desc:desc] autorelease];
    labelInfo.cacheName = cacheName;
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddLabels:labelInfo];
    else
        [self performSelector:@selector(runAddLabels:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
    
    return labelInfo.labelId;        
}

/// Add a previously cached group of labels all at once
- (WhirlyGlobe::SimpleIdentity) addLabelsFromCache:(NSString *)cacheName
{
    LabelInfo *labelInfo = [[[LabelInfo alloc] init] autorelease];
    labelInfo.cacheName = cacheName;
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddLabelsFromCache:labelInfo];
    else
        [self performSelector:@selector(runAddLabels:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
    
    return labelInfo.labelId;
}

// Change visual representation for a group of labels
// Only doing min/max vis for now
- (void) runChangeLabel:(LabelInfo *)labelInfo
{
    LabelSceneRepMap::iterator it = labelReps.find(labelInfo.labelId);
    
    if (it != labelReps.end())
    {    
        LabelSceneRep *sceneRep = it->second;
        
        for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
             idIt != sceneRep->drawIDs.end(); ++idIt)
        {
            // Changed visibility
            scene->addChangeRequest(new VisibilityChangeRequest(*idIt, labelInfo.minVis, labelInfo.maxVis));
        }
    }    
}

// Change how the label is displayed
- (void)changeLabel:(WhirlyGlobe::SimpleIdentity)labelID desc:(NSDictionary *)dict
{
    LabelInfo *labelInfo = [[[LabelInfo alloc] initWithSceneRepId:labelID desc:dict] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runChangeLabel:labelInfo];
    else
        [self performSelector:@selector(runChangeLabel:) onThread:layerThread withObject:labelInfo waitUntilDone:NO];
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

// Return the cost of the given label group
// Can only do this if the label(s) have been created, so only from the layer thread
- (DrawCost *)getCost:(WhirlyGlobe::SimpleIdentity)labelId
{
    DrawCost *cost = [[[DrawCost alloc] init] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
    {
        LabelSceneRepMap::iterator it = labelReps.find(labelId);
        
        if (it != labelReps.end())
        {    
            LabelSceneRep *sceneRep = it->second;        
            // These were all created for this group of labels
            cost.numDrawables = sceneRep->drawIDs.size();
            cost.numTextures = sceneRep->texIDs.size();
        }
    }
        
    return cost;
}

@end
