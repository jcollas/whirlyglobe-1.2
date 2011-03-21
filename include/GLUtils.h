//
//  GLUtils.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// Check for a GL error and print (NSLog) a message
bool CheckGLError(const char *msg);
