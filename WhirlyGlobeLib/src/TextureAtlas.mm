//
//  TextureAtlas.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextureAtlas.h"
#import "WhirlyGeometry.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;

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

- (id)inithWithTexSizeX:(unsigned int)inTexSizeX texSizeY:(unsigned int)inTexSizeY cellSizeX:(unsigned int)inCellSizeX cellSizeY:(unsigned int)inCellSizeY
{
    if ((self = [super init]))
    {
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

- (WhirlyGlobe::Texture *)createTexture
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
    UIGraphicsEndImageContext();
    
    
    static unsigned int outTex = 0;
    NSString *outStr = [NSString stringWithFormat:@"texAtlas%d",outTex++];
    [UIImagePNGRepresentation(resultImage) writeToFile:outStr atomically:YES];
    
    return new WhirlyGlobe::Texture(resultImage);
}


@end