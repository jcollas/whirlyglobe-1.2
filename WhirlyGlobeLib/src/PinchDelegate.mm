//
//  PinchDelegate.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PinchDelegate.h"

@implementation WhirlyGlobePinchDelegate

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if (self = [super init])
	{
		globeView = inView;
		startZ = 0.0;
	}
	
	return self;
}

+ (WhirlyGlobePinchDelegate *)pinchDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	WhirlyGlobePinchDelegate *pinchDelegate = [[[WhirlyGlobePinchDelegate alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UIPinchGestureRecognizer alloc] initWithTarget:pinchDelegate action:@selector(pinchGesture:)] autorelease]];
	return pinchDelegate;
}

// Called for pinch actions
- (void)pinchGesture:(id)sender
{
	UIPinchGestureRecognizer *pinch = sender;
	UIGestureRecognizerState theState = pinch.state;
	
	switch (theState)
	{
		case UIGestureRecognizerStateBegan:
			// Store the starting Z for comparison
			startZ = globeView.heightAboveGlobe;
			NSLog(@"Began: startZ = %f",startZ);
			break;
		case UIGestureRecognizerStateChanged:
			[globeView setHeightAboveGlobe:startZ/pinch.scale];
			NSLog(@"Change: scale = %f height = %f",pinch.scale,globeView.heightAboveGlobe);
			break;
	}
}

@end
