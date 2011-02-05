//
//  GlobeView.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WhirlyVector.h"
#import "GlobeView.h"

@interface WhirlyGlobeView()
@property (nonatomic,retain) NSDate *startDate,*endDate;
@end

@implementation WhirlyGlobeView

@synthesize fieldOfView,imagePlaneSize,nearPlane,farPlane,heightAboveGlobe;
@synthesize rotQuat;
@synthesize startDate,endDate;

- (id)init
{
	if (self = [super init])
	{
		fieldOfView = 60.0 / 360.0 * 2 * (float)M_PI;  // 60 degree field of view
		imagePlaneSize = 0.01 * tanf(fieldOfView / 2.0);
		nearPlane = 0.01;
		farPlane = 4.0;
		heightAboveGlobe = 1.1;
		rotQuat = Eigen::AngleAxisf(0.0f,Vector3f(0.0f,0.0f,1.0f));
	}
	
	return self;
}

- (void)dealloc
{
	self.startDate = nil;
	self.endDate = nil;
	[super dealloc];
}

- (void)calcFrustumWidth:(unsigned int)frameWidth height:(unsigned int)frameHeight ll:(Point2f &)ll ur:(Point2f &)ur near:(float &)near far:(float &)far
{
	ll.x() = -imagePlaneSize;
	ur.x() = imagePlaneSize;
	float ratio =  ((float)frameHeight / (float)frameWidth);
	ll.y() = -imagePlaneSize * ratio;
	ur.y() = imagePlaneSize * ratio ;
	near = nearPlane;
	far = farPlane;
}
	
- (float)minHeightAboveGlobe
{
	return 2*nearPlane;
}
	
- (float)maxHeightAboveGlobe
{
	return (farPlane - 1.0);
}
	
- (float)calcEarthZOffset
{
	float minH = [self minHeightAboveGlobe];
	if (heightAboveGlobe < minH)
		return 1.0+minH;
	
	float maxH = [self maxHeightAboveGlobe];
	if (heightAboveGlobe > maxH)
		return 1.0+maxH;
	
	return 1.0 + heightAboveGlobe;
}

- (void)setHeightAboveGlobe:(float)newH
{
	float minH = [self minHeightAboveGlobe];
	heightAboveGlobe = std::max(newH,minH);

	float maxH = [self maxHeightAboveGlobe];
	heightAboveGlobe = std::min(newH,maxH);
}
	
- (Eigen::Transform3f)calcModelMatrix
{
	Eigen::Transform3f trans(Eigen::Translation3f(0,0,-[self calcEarthZOffset]));
	Eigen::Transform3f rot(rotQuat);
	
	return trans * rot;
}

- (Vector3f)currentUp
{
	Eigen::Matrix4f modelMat = [self calcModelMatrix].inverse();
	
	Vector4f newUp = modelMat * Vector4f(0,0,1,0);
	return Vector3f(newUp.x(),newUp.y(),newUp.z());
}

- (Point3f)pointUnproject:(Point2f)screenPt width:(unsigned int)frameWidth height:(unsigned int)frameHeight
{
	Point2f ll,ur;
	float near,far;
	[self calcFrustumWidth:frameWidth height:frameHeight ll:ll ur:ur near:near far:far];
	
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
	
- (bool)pointOnSphereFromScreen:(CGPoint)pt transform:(const Eigen::Transform3f *)transform frameSize:(const Point2f &)frameSize hit:(Point3f *)hit
{
	// Back project the point from screen space into model space
	Point3f screenPt = [self pointUnproject:Point2f(pt.x,pt.y) width:frameSize.x() height:frameSize.y()];
	
	// Run the screen point and the eye point (origin) back through
	//  the model matrix to get a direction and origin in model space
	Eigen::Transform3f modelTrans = *transform;
	Matrix4f invModelMat = modelTrans.inverse();
	Point3f eyePt(0,0,0);
	Vector4f modelEye = invModelMat * Vector4f(eyePt.x(),eyePt.y(),eyePt.z(),1.0);
	Vector4f modelScreenPt = invModelMat * Vector4f(screenPt.x(),screenPt.y(),screenPt.z(),1.0);
	
	// Now intersect that with a unit sphere to see where we hit
	Vector4f dir4 = modelScreenPt - modelEye;
	Vector3f dir(dir4.x(),dir4.y(),dir4.z());
	if (WhirlyGlobe::IntersectUnitSphere(Vector3f(modelEye.x(),modelEye.y(),modelEye.z()), dir, *hit))
		return true;
	
	// We need the closest pass, if that didn't work out
	Vector3f orgDir(-modelEye.x(),-modelEye.y(),-modelEye.z());
	orgDir.normalize();
	dir.normalize();
	Vector3f tmpDir = orgDir.cross(dir);
	Vector3f resVec = dir.cross(tmpDir);
	*hit = -resVec.normalized();
	
	return false;
}

// Set up an animation from one to the other
- (void)animateToRotation:(Eigen::Quaternion<float> &)newRot howLong:(float)howLong
{
	self.startDate = [NSDate date];
	self.endDate = [self.startDate dateByAddingTimeInterval:howLong];
	startQuat = rotQuat;
	endQuat = newRot;
}

// Run the rotation animation
- (void)animate
{
	if (!self.startDate)
		return;
	
	NSDate *now = [NSDate date];
	float span = (float)[endDate timeIntervalSinceDate:startDate];
	float remain = (float)[endDate timeIntervalSinceDate:now];

	// All done.  Snap to the end
	if (remain < 0)
	{
		rotQuat = endQuat;
		self.startDate = nil;
		self.endDate = nil;
	} else {
		// Interpolate somewhere along the path
		float t = (1.0-remain)/span;
		rotQuat = startQuat.slerp(t,endQuat);
	}
}


@end
