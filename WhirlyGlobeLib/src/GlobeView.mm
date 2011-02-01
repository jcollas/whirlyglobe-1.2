//
//  GlobeView.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WhirlyVector.h"
#import "GlobeView.h"

namespace WhirlyGlobe
{

GlobeView::GlobeView()
{
	fieldOfView = 60.0 / 360.0 * 2 * (float)M_PI;  // 60 degree field of view
	imagePlaneSize = 0.01 * tanf(fieldOfView / 2.0);
	nearPlane = 0.01;
	farPlane = 4.0;
	heightAboveGlobe = 1.1;
	rotQuat = Eigen::AngleAxisf(0.0f,Vector3f(0.0f,0.0f,1.0f));
}

void GlobeView::calcFrustum(unsigned int frameWidth,unsigned int frameHeight,Point2f &ll,Point2f &ur,float &near,float &far)
{
	ll.x() = -imagePlaneSize;
	ur.x() = imagePlaneSize;
	float ratio =  ((float)frameHeight / (float)frameWidth);
	ll.y() = -imagePlaneSize * ratio;
	ur.y() = imagePlaneSize * ratio ;
	near = nearPlane;
	far = farPlane;
}
	
float GlobeView::minHeightAboveGlobe()
{
	return 2*nearPlane;
}
	
float GlobeView::maxHeightAboveGlobe()
{
	return (farPlane - 1.0);
}
	
float GlobeView::calcEarthZOffset()
{
	float minH = minHeightAboveGlobe();
	if (heightAboveGlobe < minH)
		return 1.0+minH;
	
	float maxH = maxHeightAboveGlobe();
	if (heightAboveGlobe > maxH)
		return 1.0+maxH;
	
	return 1.0 + heightAboveGlobe;
}

void GlobeView::setHeightAboveGlobe(float newH)
{
	float minH = minHeightAboveGlobe();
	heightAboveGlobe = std::max(newH,minH);

	float maxH = maxHeightAboveGlobe();
	heightAboveGlobe = std::min(newH,maxH);
}
	
Eigen::Transform3f GlobeView::calcModelMatrix()
{
	Eigen::Transform3f trans(Eigen::Translation3f(0,0,-calcEarthZOffset()));
	Eigen::Transform3f rot(rotQuat);
	
	return trans * rot;
}

Point3f GlobeView::pointUnproject(Point2f screenPt,unsigned int frameWidth,unsigned int frameHeight)
{
	Point2f ll,ur;
	float near,far;
	calcFrustum(frameWidth, frameHeight, ll, ur, near, far);
	
	// Calculate a parameteric value and flip the y/v
	float u = screenPt.x() / frameWidth;
	u = std::max(0.0f,u);	u = std::min(1.0f,u);
	float v = screenPt.y() / frameHeight;
	v = std::max(0.0f,v);	v = std::min(1.0f,v);
	v = 1.0 - v;
	
	// Now come up with a point in 3 space between ll and ur
	Point2f mid(u * (ur.x()-ll.x()) + ll.x(), v * (ur.y()-ll.y()) + ll.y());
	return Point3f(mid.x(),mid.y(),-near);
}
	
}
