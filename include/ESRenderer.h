/*
 *  ESRenderer.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/13/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

// Borrowed from the GLES2 Example

// Base protocol for a renderer
@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

// Call this before defining things within the OpenGL context
- (void)useContext;

@end
