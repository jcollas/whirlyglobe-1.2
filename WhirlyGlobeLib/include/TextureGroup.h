/*
 *  TextureGroup.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/3/11.
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
