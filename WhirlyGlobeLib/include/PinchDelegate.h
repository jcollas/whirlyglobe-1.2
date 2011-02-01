/*
 *  PinchDelegate.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/17/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "GlobeView.h"

/* WhirlyGlobe Pinch Gesture Delegate
	Responds to pinches on a UIView and manipulates the globe view
	accordingly.
 */
@interface WhirlyGlobePinchDelegate : NSObject <UIGestureRecognizerDelegate>
{
	float startZ;  // If we're in the process of zooming in, where we started
	WhirlyGlobe::GlobeView *globeView;
}

// Create a pinch gesture and a delete and wire them up to the given UIView
// Also need the view parameters in GlobeView
+ (WhirlyGlobePinchDelegate *)pinchDelegateForView:(UIView *)view globeView:(WhirlyGlobe::GlobeView *)globeView;

@end
