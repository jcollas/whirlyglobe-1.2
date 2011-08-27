/*
 *  SceneRendererES1.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/13/11.
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

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "GlobeView.h"
#import "GlobeScene.h"

@class SceneRendererES1;

// This would be the protocol for the scene render delegate if
//  we were using an explicit protocol
// The methods are all optional, though
@protocol SceneRendererDelegate

// This overrides the setup view, including lights and modes
// Be sure to do *all* the setup if you do this
- (void)lightingSetup:(SceneRendererES1 *)sceneRenderer;

// Called right before a frame is rendered
- (void)preFrame:(SceneRendererES1 *)sceneRenderer;

// Called right after a frame is rendered
- (void)postFrame:(SceneRendererES1 *)sceneRenderer;
@end

// Number of frames to use for counting frames/sec
static const unsigned int RenderFrameCount = 25;

/* Scene Renderer for OpenGL ES1
	This implements rendering 
 */
@interface SceneRendererES1 : NSObject <ESRenderer>
{
	EAGLContext *context;

	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobeView *view;

    // The pixel dimensions of the CAEAGLLayer.
    GLint framebufferWidth;
    GLint framebufferHeight;
    
    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
    GLuint defaultFramebuffer, colorRenderbuffer, depthRenderbuffer;	
	
	// Frames per second
	float framesPerSec;
	unsigned int frameCount;
	NSDate *frameCountStart;
	
	// Number of drawables drawn in last frame
	unsigned int numDrawables;
    
    // Delegate called at specific points
    id delegate;

        // Clear color, defaults to black
    WhirlyGlobe::RGBAColor clearColor;
}

// Assign the scene from outside.  Caller responsible for storage
@property (nonatomic,assign) WhirlyGlobe::GlobeScene *scene;
@property (nonatomic,assign) WhirlyGlobeView *view;

@property (nonatomic,readonly) GLint framebufferWidth,framebufferHeight;

@property (nonatomic,readonly) float framesPerSec;
@property (nonatomic,readonly) unsigned int numDrawables;

@property (nonatomic,assign) id delegate;

- (void) render:(CFTimeInterval)duration;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (void) setClearColor:(UIColor *)color;

// Call this before defining things within the OpenGL context
- (void)useContext;

@end
