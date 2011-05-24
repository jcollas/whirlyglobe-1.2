//
//  AnimateViewMomentum.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 5/23/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobe.h>

@interface AnimateViewMomentum : NSObject<WhirlyGlobeAnimationDelegate> 
{
    float velocity,acceleration;
    Eigen::Quaternion<float> startQuat;
    float maxTime;
    NSDate *startDate;
}

// Initialize with an angular velocity and a negative acceleration (to slow down)
- (id)initWithView:(WhirlyGlobeView *)globeView velocity:(float)velocity accel:(float)acceleration;

@end
