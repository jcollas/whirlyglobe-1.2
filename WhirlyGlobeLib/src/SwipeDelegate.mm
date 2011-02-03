//
//  SwipeDelegate.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwipeDelegate.h"


@implementation WhirlyGlobeSwipeDelegate

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if (self = [super init])
	{
		view = inView;
	}
	
	return self;
}

+ (WhirlyGlobeSwipeDelegate *)swipeDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	WhirlyGlobeSwipeDelegate *swipeDelegate = [[[WhirlyGlobeSwipeDelegate alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UISwipeGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(swipeGesture:)] autorelease]];
	return swipeDelegate;
}

// Called for swipe actions
- (void)swipeGesture:(id)sender
{
//	UISwipeGestureRecognizer *swipe = sender;
	
	// Only one state, since this is not continuous
}	


@end
