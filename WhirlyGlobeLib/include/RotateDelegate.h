/*
 *  RotateDelegate.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 6/10/11.
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
#import "GlobeView.h"

// The state of our rotation
typedef enum {RotNone,RotFree} RotationType;

// Rotation delegate
// This is for two fingered rotation around the axis at the middle of the screen
@interface WhirlyGlobeRotateDelegate : NSObject <UIGestureRecognizerDelegate> 
{
    RotationType rotType;   // What sort of rotation state we're in
    WhirlyGlobeView *globeView;
    // Starting point for rotation
    Eigen::Quaternionf startQuat;
    Eigen::Vector3f axis;  // Axis to rotate around
}

// Create a rotation gesture and a delegate and write them up to the given UIView
+ (WhirlyGlobeRotateDelegate *)rotateDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
