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
	WhirlyGlobeView *view;
}

+ (WhirlyGlobeSwipeDelegate *)swipeDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
