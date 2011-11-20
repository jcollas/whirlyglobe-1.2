/*
 *  TextureAtlas.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 3/28/11.
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

#import "TextureAtlas.h"
#import "WhirlyGeometry.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;

// Set up the texture mapping matrix from the destination texture coords
void SubTexture::setFromTex(const TexCoord &texOrg,const TexCoord &texDest)
{
    trans = trans.Identity();
    trans.translate(texOrg);
    trans.scale(Point2f(texDest.x()-texOrg.x(),texDest.y()-texOrg.y()));
}

// Calculate a destination texture coordinate
TexCoord SubTexture::processTexCoord(const TexCoord &inCoord)
{
    Vector3f res = trans * Vector3f(inCoord.x(),inCoord.y(),1.0);
    return TexCoord(res.x(),res.y());
}

// Calculate destination texture coords for a while group
void SubTexture::processTexCoords(std::vector<TexCoord> &coords)
{
    for (unsigned int ii=0;ii<coords.size();ii++)
    {
        TexCoord &coord = coords[ii];
        Vector3f res = trans * Vector3f(coord.x(),coord.y(),1.0);
        coord.x() = res.x();  coord.y() = res.y();
    }
}

// Used to track images in the texture atlas
@interface ImageInstance : NSObject
{
@public
    unsigned int gridCellsX,gridCellsY;
    unsigned int gridCellX,gridCellY;
    TexCoord org,dest;
    UIImage *image;
}

@property(nonatomic,assign) unsigned int gridCellsX,gridCellsY;
@property(nonatomic,assign) unsigned int gridCellX,gridCellY;
@property(nonatomic,retain) UIImage *image;
@end

@implementation ImageInstance

@synthesize gridCellsX,gridCellsY;
@synthesize gridCellX,gridCellY;
@synthesize image;

- (void)dealloc
{
    self.image = nil;
    [super dealloc];
}

@end

@interface TextureAtlas()
@end

@implementation TextureAtlas

@synthesize texId;

- (id)inithWithTexSizeX:(unsigned int)inTexSizeX texSizeY:(unsigned int)inTexSizeY cellSizeX:(unsigned int)inCellSizeX cellSizeY:(unsigned int)inCellSizeY
{
    if ((self = [super init]))
    {
        texId = Identifiable::genId();
        texSizeX = inTexSizeX;
        texSizeY = inTexSizeY;
        cellSizeX = inCellSizeX;
        cellSizeY = inCellSizeY;
        gridSizeX = texSizeX/cellSizeX;
        gridSizeY = texSizeY/cellSizeY;
        layoutGrid = new bool[gridSizeX*gridSizeY]();
        for (unsigned int ii=0;ii<gridSizeX*gridSizeY;ii++)
            layoutGrid[ii] = true;
        images = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    delete [] layoutGrid;
    [images release];
    [super dealloc];
}

- (BOOL)addImage:(UIImage *)image texOrg:(WhirlyGlobe::TexCoord &)org texDest:(WhirlyGlobe::TexCoord &)dest
{
    // Number of grid cells we'll need
    unsigned int gridCellsX = std::ceil(image.size.width / cellSizeX);
    unsigned int gridCellsY = std::ceil(image.size.height / cellSizeY);
    
    // Look for a spot big enough
    bool found = false;
    int foundX,foundY;
    for (int iy=0;iy<gridSizeY-gridCellsY && !found;iy++)
        for (int ix=0;ix<gridSizeX-gridCellsX && !found;ix++)
        {
            bool clear = true;
            for (int testX=0;testX<gridCellsX && clear;testX++)
                for (int testY=0;testY<gridCellsY && clear;testY++)
                {
                    if (!layoutGrid[iy*gridSizeX+ix])
                        clear = false;
                }
            if (clear)
            {
                foundX = ix;
                foundY = iy;
                found = true;
            }
        }
    
    if (!found)
        return false;
    
    // Found a spot, so fill it in
    for (int gridX=0;gridX<gridCellsX;gridX++)
        for (int gridY=0;gridY<gridCellsY;gridY++)
            layoutGrid[(gridY+foundY)*gridSizeX+(gridX+foundX)] = false;
    
    ImageInstance *imageInst = [[[ImageInstance alloc] init] autorelease];
    imageInst.image = image;
    imageInst.gridCellsX = gridCellsX;
    imageInst.gridCellsY = gridCellsY;
    imageInst.gridCellX = foundX;
    imageInst.gridCellY = foundY;
    imageInst->org.u() = (float)(imageInst.gridCellX*cellSizeX) / (float)texSizeX;
    imageInst->org.v() = (float)(imageInst.gridCellY*cellSizeY) / (float)texSizeY;
    imageInst->dest.u() = (imageInst.gridCellX*cellSizeX + image.size.width)/(float)texSizeX;
    imageInst->dest.v() = (imageInst.gridCellY*cellSizeY + image.size.height)/(float)texSizeY;
    [images addObject:imageInst];
    
    org = imageInst->org;
    dest = imageInst->dest;
    
    return true;
}

- (BOOL)getImageLayout:(UIImage *)image texOrg:(WhirlyGlobe::TexCoord &)org texDest:(WhirlyGlobe::TexCoord &)dest
{
    for (ImageInstance *imageInst in images)
    {
        if (imageInst.image == image)
        {
            org = imageInst->org;
            dest = imageInst->dest;
            
            return true;
        }
    }
    
    return false;
}

- (WhirlyGlobe::Texture *)createTexture:(UIImage **)retImage
{
    UIGraphicsBeginImageContext(CGSizeMake(texSizeX,texSizeY));
    
    [[UIColor blackColor] setFill];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (ImageInstance *imageInst in images)
    {
        CGRect drawRect;
        drawRect.origin.x = cellSizeX*imageInst.gridCellX;
        drawRect.origin.y = cellSizeY*imageInst.gridCellY;
        drawRect.size.width = imageInst.image.size.width;
        drawRect.size.height = imageInst.image.size.height;
        CGContextDrawImage(ctx, drawRect, imageInst.image.CGImage);
    }
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    if (retImage)
        *retImage = resultImage;
    UIGraphicsEndImageContext();
    
    Texture *texture = new WhirlyGlobe::Texture(resultImage);
    texture->setId(texId);
    texture->setUsesMipmaps(true);
    return texture;
}


@end


@interface TextureAtlasBuilder()
@property (nonatomic,retain) NSMutableArray *atlases;
@end

@implementation TextureAtlasBuilder

@synthesize atlases;

- (id)initWithTexSizeX:(unsigned int)inTexSizeX texSizeY:(unsigned int)inTexSizeY
{
    self = [super init];
    if (self)
    {
        texSizeX = inTexSizeX;
        texSizeY = inTexSizeY;
        cellSizeX = cellSizeY = 8;
        self.atlases = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    self.atlases = nil;
    
    [super dealloc];
}

- (SimpleIdentity) addImage:(UIImage *)image
{
    if (!image)
        return EmptyIdentity;
    
    // Make sure the image size works
    if (image.size.width == 0 || image.size.width >= texSizeX ||
        image.size.height == 0 || image.size.height >= texSizeY)
    {
        return EmptyIdentity;
    }
    
    // Look for a texture atlas that can take the given image
    TexCoord org,dest;
    TextureAtlas *found = nil;
    for (TextureAtlas *atlas in atlases)
    {
        if ([atlas addImage:image texOrg:org texDest:dest])
        {
            found = atlas;
            break;
        }
    }    
    
    if (!found)
    {
        // Didn't find one, so make one
        TextureAtlas *atlas = [[[TextureAtlas alloc] inithWithTexSizeX:texSizeX texSizeY:texSizeY cellSizeX:cellSizeX cellSizeY:cellSizeY] autorelease];
        [atlas addImage:image texOrg:org texDest:dest];
        [atlases addObject:atlas];
        found = atlas;
    }
    
    SubTexture subTex;
    subTex.texId = found.texId;
    subTex.setFromTex(org, dest);
    mappings.push_back(subTex);
    
    return subTex.getId();
}

- (void)processIntoScene:(WhirlyGlobe::GlobeScene *)scene texIDs:(std::set<WhirlyGlobe::SimpleIdentity> *)texIDs
{
    // Create the textures, add them to the scene
    for (TextureAtlas *atlas in atlases)
    {
        Texture *tex = [atlas createTexture:nil];
        if (tex)
        {
            if (texIDs)
                texIDs->insert(tex->getId());
            scene->addChangeRequest(new AddTextureReq(tex));
        }
    }
    [atlases removeAllObjects];
    
    // Now add the mappings to the scene.  These are layer side.
    scene->addSubTextures(mappings);
    mappings.clear();
}

@end