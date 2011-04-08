//
//  TextureAtlas.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/28/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <vector>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "Identifiable.h"
#import "WhirlyVector.h"
#import "Texture.h"

/* TextureAtlas
    Used to build a texture atlas on the fly.
 */
@interface TextureAtlas : NSObject
{
    // Texture size
    unsigned int texSizeX,texSizeY;
    // Grid size (for sorting)
    unsigned int gridSizeX,gridSizeY;
    // Cell sieze
    unsigned int cellSizeX,cellSizeY;
    bool *layoutGrid;  // Used for sorting new images
    
    // Images we've rendered so far (for lookup)
    NSMutableArray *images;
}

// Construct with texture size (needs to be a power of 2)
// We sort images into buckets (sizeX/gridX,sizeY/gridY)
- (id)inithWithTexSizeX:(unsigned int)texSizeX texSizeY:(unsigned int)texSizeY cellSizeX:(unsigned int)cellSizeX cellSizeY:(unsigned int)cellSizeY;
    
// Add the image to this atlas and return texture coordinates
//  to map into.
// Returns false if there wasn't room
- (BOOL)addImage:(UIImage *)image texOrg:(WhirlyGlobe::TexCoord &)org texDest:(WhirlyGlobe::TexCoord &)dest;

// We cache the images and their coordinates.  Query the cache
- (BOOL)getImageLayout:(UIImage *)image texOrg:(WhirlyGlobe::TexCoord &)org texDest:(WhirlyGlobe::TexCoord &)dest;

// Generate a texture from the images
- (WhirlyGlobe::Texture *)createTexture;

@end
