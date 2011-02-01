/*
 *  SceneRendererES1.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/13/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "GlobeView.h"
#import "GlobeScene.h"

/* Scene Renderer for OpenGL ES1
	This implements rendering 
 */
@interface SceneRendererES1 : NSObject <ESRenderer>
{
	EAGLContext *context;

	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobe::GlobeView *view;

    // The pixel dimensions of the CAEAGLLayer.
    GLint framebufferWidth;
    GLint framebufferHeight;
    
    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
    GLuint defaultFramebuffer, colorRenderbuffer, depthRenderbuffer;	
}

// Assign the scene from outside.  Caller responsible for storage
@property (nonatomic,assign) WhirlyGlobe::GlobeScene *scene;
@property (nonatomic,assign) WhirlyGlobe::GlobeView *view;

@property (nonatomic,readonly) GLint framebufferWidth,framebufferHeight;

- (void) render;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;

// Call this before defining things within the OpenGL context
- (void)useContext;

@end
