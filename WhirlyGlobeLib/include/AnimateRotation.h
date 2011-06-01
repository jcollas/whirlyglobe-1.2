/*
 *  AnimateRotation.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 5/23/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

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
