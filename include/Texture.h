/*
 *  Texture.h
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

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "Identifiable.h"
#import "WhirlyVector.h"

namespace WhirlyGlobe
{

/** Your basic Texture representation.
    This is how you get an image sent over to the
    rendering engine.  Set up one of these and add it.
    If you want to remove it, you need to use its
    Identifiable ID.
 */
class Texture : public Identifiable
{
public:
    /// Construct emty
	Texture();
	/// Construct with raw texture data.  PVRTC is preferred.
	Texture(NSData *texData,bool isPVRTC);
	/// Construct with a file name and extension
	Texture(NSString *baseName,NSString *ext);
	/// Construct with a UIImage.  Expecting this to be a power of 2 on each side
	Texture(UIImage *inImage);
	
	~Texture();
	
	GLuint getGLId() const { return glId; }
	
	/// Render side only.  Don't call this.  Create the openGL version
	bool createInGL(bool releaseData=true);
	
	/// Render side only.  Don't call this.  Destroy the openGL version
	void destroyInGL();

    /// Set the texture width
    void setWidth(unsigned int newWidth) { width = newWidth; }
    /// Set the texture height
    void setHeight(unsigned int newHeight) { height = newHeight; }
    /// Set this to have a mipmap generated and used for minification
    void setUsesMipmaps(bool use) { usesMipmaps = use; }
	
protected:
	/// Raw texture data
	NSData *texData;
	/// Need to know how we're going to load it
	bool isPVRTC;
	
	unsigned int width,height;
    bool usesMipmaps;
	
	/// OpenGL ES ID
	/// Set to 0 if we haven't loaded yet
	GLuint glId;
};
	
}
