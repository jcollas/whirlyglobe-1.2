//
//  GlobeView.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/14/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyVector.h"
#import "WhirlyGeometry.h"

@class WhirlyGlobeView;

// Animation callback
@protocol WhirlyGlobeAnimationDelegate
// Called every tick to update the globe position
- (void)updateView:(WhirlyGlobeView *)globeView;
@end

/* Globe View
	Parameters associated with viewing the globe.
 */
@interface WhirlyGlobeView : NSObject
{
	float fieldOfView;
	float imagePlaneSize;
	float nearPlane;
	float farPlane;
	
	// The globe has a radius of 1.0 so 1.0 + heightAboveGlobe is the offset from the middle of the globe
	float heightAboveGlobe;
	
	// Quaternion used for rotation from origin state
	Eigen::Quaternion<float> rotQuat;
    
    // Used to update position based on time (or whatever other factor you like)
    NSObject<WhirlyGlobeAnimationDelegate> *delegate;
}

@property (nonatomic,assign) float fieldOfView,imagePlaneSize,nearPlane,farPlane,heightAboveGlobe;
@property (nonatomic,assign) Eigen::Quaternion<float> rotQuat;
@property (nonatomic,retain) NSObject<WhirlyGlobeAnimationDelegate> *delegate;

// Calculate the viewing frustum (which is also the image plane)
// Need the framebuffer size in pixels as input
- (void)calcFrustumWidth:(unsigned int)frameWidth height:(unsigned int)frameHeight ll:(Point2f &)ll ur:(Point2f &)ur near:(float &)near far:(float &)far;

// Return min/max valid heights above globe
- (float)minHeightAboveGlobe;
- (float)maxHeightAboveGlobe;

// Set the height above globe, taking constraints into account
- (void)setHeightAboveGlobe:(float)newH;

// Cancel any outstanding animation
- (void)cancelAnimation;

// Renderer calls this every update
- (void)animate;

// Calculate the Z buffer resolution
- (float)calcZbufferRes;

// Calculate the z offset to make the earth appear where we want it
- (float)calcEarthZOffset;

// Generate the model view matrix for use by OpenGL
//  Or calculation of our own
- (Eigen::Transform3f)calcModelMatrix;

// Return where up (0,0,1) is after model rotation
- (Vector3f)currentUp;

// Given a rotation, where would (0,0,1) wind up
+ (Vector3f)prospectiveUp:(Eigen::Quaternion<float> &)prospectiveRot;

// From a screen point calculate the corresponding point in 3-space
- (Point3f)pointUnproject:(Point2f)screenPt width:(unsigned int)frameWidth height:(unsigned int)frameHeight;

// Given a location on the screen and the screen size, figure out where we touched the sphere
// Returns true if we hit and where
// Returns false if not and the closest point on the sphere
- (bool)pointOnSphereFromScreen:(CGPoint)pt transform:(const Eigen::Transform3f *)transform frameSize:(const Point2f &)frameSize hit:(Point3f *)hit;

@end
