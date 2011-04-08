//
//  PanDelegate.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/18/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobeView.h"

@interface WhirlyGlobePanDelegate : NSObject<UIGestureRecognizerDelegate> 
{
	WhirlyGlobeView *view;
	BOOL panning;
	// The view transform when we started
	Eigen::Transform3f startTransform;
	// Where we first touched the sphere
	Point3f startOnSphere;
	// Rotation when we started
	Eigen::Quaternionf startQuat;
}

+ (WhirlyGlobePanDelegate *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
