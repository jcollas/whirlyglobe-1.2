//
//  EAGLView.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <ESRenderer.h>

/* OpenGL View
	A base class for implementing an open GL rendering view.
	This is modeled off of the example.  We subclass this for
    our own purposes.
 */
@interface EAGLView : UIView 
{
	id <ESRenderer> renderer;

	NSInteger frameInterval;
    BOOL animating;
    CADisplayLink *displayLink;
}

// We're only expecting this to be set once
@property (nonatomic, retain) id<ESRenderer> renderer;

// This is in units of 60/frameRate.  Set it to 4 to get 15 frames/sec (at most)
@property (nonatomic) NSInteger frameInterval;

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;

// Used to stop/start animation
- (void) startAnimation;
- (void) stopAnimation;

// Draw into the actual view
- (void) drawView:(id)sender;

@end
