//
//  SwipeDelegate.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobeView.h"

/* Whirly Globe Swipe Delegate
	Responds to swipes and rotates the globe accordingly.
 */
@interface WhirlyGlobeSwipeDelegate : NSObject<UIGestureRecognizerDelegate>
{
	WhirlyGlobe::GlobeView *view;
}

+ (WhirlyGlobeSwipeDelegate *)swipeDelegateForView:(UIView *)view globeView:(WhirlyGlobe::GlobeView *)globeView;

@end
