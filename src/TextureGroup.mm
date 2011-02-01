//
//  TextureGroup.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+Stuff.h"
#import "TextureGroup.h"

@implementation TextureGroup

@synthesize baseName,ext;
@synthesize numX,numY;

// Initialize with the full info we need
- (id) initWithBase:(NSString *)base ext:(NSString *)extName numX:(unsigned int)x numY:(unsigned int)y
{
	if (self = [super init])
	{
		self.baseName = base;
		self.ext = extName;
		numX = x;
		numY = y;
	}
	
	return self;
}

// Generate a file name for loading a given piece
- (NSString *) generateFileNameX:(unsigned int)x y:(unsigned int)y
{
	if (x >= numX || y >= numY)
		return nil;
	
	return [NSString stringWithFormat:@"%@_%dx%d.%@",baseName,x,y,ext];
}

- (GLuint) loadTextureX:(unsigned int)x y:(unsigned int)y;
{
	// Allocate a texture and set up the various params
	GLuint texId = 0;
	glGenTextures(1, &texId);
	glBindTexture(GL_TEXTURE_2D, texId);

	// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	// Configure textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	// If it's in an optimized form, we can use that more efficiently
	if (![ext compare:@"pvrtc"])
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@_%dx%d",baseName,x,y] ofType:ext];
		if (!path)
			return 0;
		NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
		if (!texData)
			return 0;
		
		// Will always be 4 bits per pixel and RGB and always 1k X 1k
		glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, 1024, 1024, 0, [texData length], [texData bytes]);
		[texData release];
	} else {
		// Otherwise load it the normal way
		NSString *imageName = [self generateFileNameX:x y:y];
		UIImage *image = [UIImage imageNamed:imageName];
		if (!image)
			return 0;
		unsigned int width,height;
		NSData *imgData = [[image rawDataRetWidth:&width height:&height] retain];
	
		// Specify a 2D texture image, providing the a pointer to the image data in memory
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [imgData bytes]);
		[imgData release];
	}
	
	return texId;
}

@end
