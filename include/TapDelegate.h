/*
 *  TapDelegate.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/3/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "GlobeView.h"
#import "TapMessage.h"

/* Whirly Globe Tap Gesture Delegate
	Responds to taps by blasting out a notification.
 */
@interface WhirlyGlobeTapDelegate : NSObject <UIGestureRecognizerDelegate>
{
	WhirlyGlobeView *globeView;
}

// Create a tap gesture recognizer and a delegate and wire them up to the given UIView
+ (WhirlyGlobeTapDelegate *)tapDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
