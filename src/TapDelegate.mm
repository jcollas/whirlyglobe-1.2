/*
 *  TapDelegate.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/3/11.
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

#import "TapDelegate.h"
#import "EAGLView.h"
#import "SceneRendererES1.h"
#import "GlobeMath.h"

@implementation WhirlyGlobeTapDelegate

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if ((self = [super init]))
	{
		globeView = inView;
	}
	
	return self;
}

+ (WhirlyGlobeTapDelegate *)tapDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	WhirlyGlobeTapDelegate *tapDelegate = [[[WhirlyGlobeTapDelegate alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:tapDelegate action:@selector(tapAction:)] autorelease]];
	return tapDelegate;
}

// We'll let other gestures run
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return TRUE;
}

// Called for a tap
- (void)tapAction:(id)sender
{
	UITapGestureRecognizer *tap = sender;
	EAGLView *glView = (EAGLView *)tap.view;
	SceneRendererES1 *sceneRender = glView.renderer;

	// Translate that to the sphere
	// If we hit, then we'll generate a message
	Point3f hit;
	Eigen::Affine3f theTransform = [globeView calcModelMatrix];
    CGPoint touchLoc = [tap locationOfTouch:0 inView:glView];
	if ([globeView pointOnSphereFromScreen:touchLoc transform:&theTransform frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit])
	{
		TapMessage *msg = [[[TapMessage alloc] init] autorelease];
        [msg setTouchLoc:touchLoc];
        [msg setView:glView];
		[msg setWorldLoc:hit];
		[msg setWhereGeo:WhirlyGlobe::GeoFromPoint(hit)];
        msg.heightAboveGlobe = globeView.heightAboveGlobe;
		
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WhirlyGlobeTapMsg object:msg]];
	} else
        // If we didn't hit, we generate a different message
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WhirlyGlobeTapOutsideMsg object:[NSNull null]]];
}

@end
