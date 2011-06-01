/*
 *  PanDelegateFixed.h
 *  WhirlyGlobeApp
 *
 *  Created by Stephen Gifford on 4/28/11.
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

#import <Foundation/Foundation.h>
#import <WhirlyGlobe.h>

// Kind of rotation we're in the middle of
typedef enum {RotNone,RotFree,RotVert,RotHoriz} RotationType;

// Scale factors for the angular velocity
// Used with height
#define MaxAngularVelocity 150.0
#define MinAngularVelocity 5.0

// Version of pan delegate specific to this app
// The pan delegate handles panning and rotates the globe accordingly
@interface PanDelegateFixed : NSObject<UIGestureRecognizerDelegate> 
{
    WhirlyGlobeView *view;
    CGPoint startPoint;
    // Used to keep track of what sort of rotation we're doing
    RotationType rotType;
	// The view transform when we started
	Eigen::Transform3f startTransform;
	// Where we first touched the sphere
	Point3f startOnSphere;
	// Rotation when we started
	Eigen::Quaternionf startQuat;

    // Last sample for spinning
    Eigen::Quaternionf spinQuat;
    NSDate *spinDate;
    CGPoint lastTouch;
}

+ (PanDelegateFixed *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
