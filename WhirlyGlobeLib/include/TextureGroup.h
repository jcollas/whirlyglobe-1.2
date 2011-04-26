//
//  TextureGroup.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "WhirlyVector.h"

/* Texture Group
	Used to represent a large image that's been broken
	into several pieces to get around the 1k X 1k limit in OpenGL.
	File name: <base>_XxY.<ext>
 */
@interface TextureGroup : NSObject 
{
	NSString *baseName;      // Base name (e.g. "worldTexture")
	NSString *ext;           // Extension (e.g. "png")
	unsigned int numX,numY;  // Number of chunks in each dimension
    unsigned int pixelsSquare;  // Number of pixels on each side
    unsigned int borderPixels;  // Number of pixels on each side devoted to border
}

@property (nonatomic,retain) NSString *baseName,*ext;
@property (nonatomic,readonly) unsigned int numX,numY;
@property (nonatomic,readonly) unsigned int pixelsSquare,borderPixels;

// Need to initialize with the the info plist file
// This will point us to everything else
- (id) initWithInfo:(NSString *)infoName;

// Generate the name of the given instance (without the extension)
- (NSString *) generateFileNameX:(unsigned int)x y:(unsigned int)y;

// Calculate the mapping that represents "full" coverage
// This takes border pixels into account
- (void)calcTexMappingOrg:(WhirlyGlobe::TexCoord *)org dest:(WhirlyGlobe::TexCoord *)dest;

@end
