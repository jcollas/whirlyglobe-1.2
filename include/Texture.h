/*
 *  Texture.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/7/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "Identifiable.h"
#import "WhirlyVector.h"

namespace WhirlyGlobe
{

/* Texture
 Simple representation of texture.
 */
class Texture : public Identifiable
{
public:
	Texture();
	// Construct with raw texture data
	Texture(NSData *texData,bool isPVRTC);
	// Construct with a file name and extension
	Texture(NSString *baseName,NSString *ext);
	// Construct with a UIImage.  Expecting this to be a power of 2 on each side
	Texture(UIImage *inImage);
	
	~Texture();
	
	GLuint getGLId() const { return glId; }
	
	// Create the openGL version
	bool createInGL(bool releaseData=true);
	
	// Destroy the openGL version
	void destroyInGL();
	
protected:
	// Raw texture data
	NSData *texData;
	// Need to know how we're going to load it
	bool isPVRTC;
	
	unsigned int width,height;
	
	// OpenGL ES ID
	// Set to 0 if we haven't loaded yet
	GLuint glId;
};
	
}
