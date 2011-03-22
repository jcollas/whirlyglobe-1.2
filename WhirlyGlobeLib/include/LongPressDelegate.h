//
//  LongPressDelegate.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/22/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobeView.h"
#import "TapMessage.h"

/* Whirly Globe Long Press Delegate
    Responds to a long press by blasting out a notification.
 */
@interface WhirlyGlobeLongPressDelegate : NSObject <UIGestureRecognizerDelegate>
{
    WhirlyGlobeView *globeView;
}

// Create a long press geture recognizer and a delegate and wire them up to the UIView
+ (WhirlyGlobeLongPressDelegate *)longPressDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
