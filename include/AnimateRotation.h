//
//  AnimateRotation.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 5/23/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyVector.h"
#import "WhirlyGeometry.h"
#import "GlobeView.h"

/* Animate View Rotation
    A delegate that animates rotation from one point to another
    over time.
 */
@interface AnimateViewRotation : NSObject<WhirlyGlobeAnimationDelegate>
{
    NSDate *startDate,*endDate;
    Eigen::Quaternion<float> startRot,endRot;
}

@property (nonatomic,retain) NSDate *startDate,*endDate;
@property (nonatomic,assign) Eigen::Quaternion<float> startRot,endRot;

// Kick off a rotate to the given position over the given time
// Assign this to the globe view's delegate and it'll do the rest
- (id)initWithView:(WhirlyGlobeView *)globeView rot:(Eigen::Quaternion<float> &)newRot howLong:(float)howLong;

@end
