/*
 *  Texture.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/7/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "GLUtils.h"
#import "Texture.h"
#import "UIImage+Stuff.h"

namespace WhirlyGlobe
{
	
Texture::Texture()
	: texData(NULL), isPVRTC(false), glId(0)
{
}
	
// Construct with raw texture data
Texture::Texture(NSData *texData,bool isPVRTC) 
	: texData(texData), isPVRTC(isPVRTC) 
{ 
	[texData retain]; 
	glId = 0; 
}

// Set up the texture from a filename
Texture::Texture(NSString *baseName,NSString *ext)
{
	glId = 0;
	texData = nil;
	
	if (![ext compare:@"pvrtc"])
	{
		isPVRTC = true;
		NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:ext];
		if (!path)
			return;
		texData = [[NSData alloc] initWithContentsOfFile:path];
		if (!texData)
			return;
	} else {
		isPVRTC = false;
		// Otherwise load it the normal way
		UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.%@",baseName,ext]];
		if (!image)
			return;
		texData = [[image rawDataRetWidth:&width height:&height] retain];
	}
}

// Construct with a UIImage
Texture::Texture(UIImage *inImage)
    : isPVRTC(false), glId(0)
{
	texData = [[inImage rawDataRetWidth:&width height:&height] retain];
}

Texture::~Texture()
{
	if (texData)
		[texData release];
	texData = nil;
}

// Define the texture in OpenGL
// Note: Should load the texture from disk elsewhere
bool Texture::createInGL(bool releaseData)
{
	if (!texData)
		return false;
	
	if (glId)
		destroyInGL();
	
	// Allocate a texture and set up the various params
	glGenTextures(1, &glId);
    CheckGLError("Texture::createInGL() glGenTextures()");

	glBindTexture(GL_TEXTURE_2D, glId);
    CheckGLError("Texture::createInGL() glBindTexture()");
	
	// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    CheckGLError("Texture::createInGL() glBlendFunc()");
	
	// Configure textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    CheckGLError("Texture::createInGL() glTexParameteri()");
	
	// If it's in an optimized form, we can use that more efficiently
	if (isPVRTC)
	{
		// Will always be 4 bits per pixel and RGB
		glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, width, height, 0, [texData length], [texData bytes]);
        CheckGLError("Texture::createInGL() glCompressedTexImage2D()");
	} else {
		// Specify a 2D texture image, providing the a pointer to the image data in memory
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [texData bytes]);
        CheckGLError("Texture::createInGL() glTexImage2D()");
	}	
	
	if (releaseData)
	{
		[texData release];
		texData = nil;
	}
	
	return true;
}

// Release the OpenGL texture
void Texture::destroyInGL()
{
	if (glId)
    {
		glDeleteTextures(1, &glId);
        CheckGLError("Texture::createInGL() glDeleteTextures()");
    }
}

}