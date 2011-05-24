//
//  AnimateRotation.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 5/23/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "AnimateRotation.h"

@implementation AnimateViewRotation

@synthesize startDate,endDate;
@synthesize startRot,endRot;

- (id)initWithView:(WhirlyGlobeView *)globeView rot:(Eigen::Quaternion<float> &)newRot howLong:(float)howLong
{
    if ((self = [super init]))
    {
        self.startDate = [NSDate date];
        self.endDate = [self.startDate dateByAddingTimeInterval:howLong];
        startRot = [globeView rotQuat];
        endRot = newRot;
    }
    
    return self;
}

- (void)dealloc
{
	self.startDate = nil;
	self.endDate = nil;
	[super dealloc];
}

// Called by the view when it's time to update
- (void)updateView:(WhirlyGlobeView *)globeView
{
	if (!self.startDate)
		return;
	
	NSDate *now = [NSDate date];
	float span = (float)[endDate timeIntervalSinceDate:startDate];
	float remain = (float)[endDate timeIntervalSinceDate:now];
    
	// All done.  Snap to the end
	if (remain < 0)
	{
		[globeView setRotQuat:endRot];
		self.startDate = nil;
		self.endDate = nil;
	} else {
		// Interpolate somewhere along the path
		float t = (span-remain)/span;
		[globeView setRotQuat:startRot.slerp(t,endRot)];
	}
}

@end
