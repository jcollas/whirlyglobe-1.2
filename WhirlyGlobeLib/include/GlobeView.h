//
//  GlobeView.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/14/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WhirlyVector.h"

namespace WhirlyGlobe
{

/* Globe View
	Parameters associated with viewing the globe.
 */
class GlobeView
{
public:
	GlobeView();
	
	float fieldOfView;
	float imagePlaneSize;
	float nearPlane;
	float farPlane;
	
	// The globe has a radius of 1.0 so 1.0 + heightAboveGlobe is the offset from the middle of the globe
	float heightAboveGlobe;
	
	// Quaternion used for rotation from origin state
	Eigen::Quaternion<float> rotQuat;

	// Calculate the viewing frustum (which is also the image plane)
	// Need the framebuffer size in pixels as input
	void calcFrustum(unsigned int frameWidth,unsigned int frameHeight,Point2f &ll,Point2f &ur,float &near,float &far);
	
	// Return min/max valid heights above globe
	float minHeightAboveGlobe(),maxHeightAboveGlobe();
	
	// Set the height above globe, taking constraints into account
	void setHeightAboveGlobe(float newH);

	// Calculate the z offset to make the earth appear where we want it
	float calcEarthZOffset();
	
	// Generate the model view matrix for use by OpenGL
	//  Or calculation of our own
	Eigen::Transform3f calcModelMatrix();

	// From a screen point calculate the corresponding point in 3-space
	Point3f pointUnproject(Point2f screenPt,unsigned int frameWidth,unsigned int frameHeight);
};

}
