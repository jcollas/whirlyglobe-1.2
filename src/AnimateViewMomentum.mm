//
//  AnimateViewMomentum.m
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 5/23/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <algorithm>
#import "AnimateViewMomentum.h"

@interface AnimateViewMomentum()
@property (nonatomic,retain) NSDate *startDate;
@end

@implementation AnimateViewMomentum

@synthesize startDate;

- (id)initWithView:(WhirlyGlobeView *)globeView velocity:(float)inVel accel:(float)inAcc;
{
    if ((self = [super init]))
    {
        velocity = inVel;
        acceleration = inAcc;
        startQuat = [globeView rotQuat];
        
        self.startDate = [NSDate date];
        
        // Let's calculate the maximum time, so we know when to stop
        maxTime = 0.0;
        if (acceleration != 0.0)
            maxTime = -velocity / acceleration;
        maxTime = std::max(0.f,maxTime);
        
        if (maxTime == 0.0)
            self.startDate = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.startDate = nil;
    
    [super dealloc];
}

// Called by the view when it's time to update
- (void)updateView:(WhirlyGlobeView *)globeView
{
    if (!self.startDate)
        return;
    
	float sinceStart = -(float)[startDate timeIntervalSinceDate:[NSDate date]];
    
    if (sinceStart > maxTime)
    {
        // This will snap us to the end and then we stop
        sinceStart = maxTime;
        self.startDate = nil;
    }
    
    // Calculate the offset based on angle
    float totalAng = (velocity + 0.5 * acceleration * sinceStart) * sinceStart;
    Eigen::Quaternion<float> diffRot(Eigen::AngleAxisf(totalAng,Vector3f(0,0,1)));
    Eigen::Quaternion<float> newQuat;
    newQuat = startQuat * diffRot;    
    [globeView setRotQuat:newQuat];
}

@end