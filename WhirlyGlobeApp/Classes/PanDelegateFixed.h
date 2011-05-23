//
//  PanDelegateFixed.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 4/28/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobe.h>

// Kind of rotation we're in the middle of
typedef enum {RotNone,RotFree,RotVert,RotHoriz} RotationType;

// 
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
}

+ (PanDelegateFixed *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView;

@end
