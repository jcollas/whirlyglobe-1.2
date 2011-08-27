/*
 *  PanDelegate.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/18/11.
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

@interface WhirlyGlobePanDelegate : NSObject<UIGestureRecognizerDelegate> 
{
	WhirlyGlobeView *view;
	BOOL panning;
	// The view transform when we started
	Eigen::Affine3f startTransform;
	// Where we first touched the sphere
	Point3f startOnSphere;
	// Rotation when we started
	Eigen::Quaternionf startQuat;
}

+ (WhirlyGlobePanDelegate *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
