/*
 *  GlobeView.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/14/11.
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

#import "WhirlyVector.h"
#import "GlobeView.h"
#import "WhirlyGeometry.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;
using namespace Eigen;

@interface WhirlyGlobeView()
@end

@implementation WhirlyGlobeView

@synthesize fieldOfView,imagePlaneSize,nearPlane,farPlane,heightAboveGlobe;
@synthesize rotQuat;
@synthesize lastChangedTime;
@synthesize delegate;

- (id)init
{
	if ((self = [super init]))
	{
		fieldOfView = 60.0 / 360.0 * 2 * (float)M_PI;  // 60 degree field of view
		nearPlane = 0.001;
		imagePlaneSize = nearPlane * tanf(fieldOfView / 2.0);
		farPlane = 2.6;
		heightAboveGlobe = 1.1;
		rotQuat = Eigen::AngleAxisf(0.0f,Vector3f(0.0f,0.0f,1.0f));
        self.lastChangedTime = [NSDate date];
	}
	
	return self;
}

- (void)dealloc
{
    self.delegate = nil;
    self.lastChangedTime = nil;
	[super dealloc];
}

// Set the new rotation, but also keep track of when we did it
- (void)setRotQuat:(Eigen::Quaternionf)newRotQuat
{
    self.lastChangedTime = [NSDate date];
    rotQuat = newRotQuat;
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
	return 1.3*nearPlane;
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

// Set the height above the globe, but constrain it
// Also keep track of when we did it
- (void)setHeightAboveGlobe:(float)newH
{
	float minH = [self minHeightAboveGlobe];
	heightAboveGlobe = std::max(newH,minH);

	float maxH = [self maxHeightAboveGlobe];
	heightAboveGlobe = std::min(heightAboveGlobe,maxH);

    self.lastChangedTime = [NSDate date];
}
	
- (Eigen::Affine3f)calcModelMatrix
{
	Eigen::Affine3f trans(Eigen::Translation3f(0,0,-[self calcEarthZOffset]));
	Eigen::Affine3f rot(rotQuat);
	
	return trans * rot;
}

- (Vector3f)currentUp
{
	Eigen::Matrix4f modelMat = [self calcModelMatrix].inverse().matrix();
	
	Vector4f newUp = modelMat * Vector4f(0,0,1,0);
	return Vector3f(newUp.x(),newUp.y(),newUp.z());
}

+ (Vector3f)prospectiveUp:(Eigen::Quaternion<float> &)prospectiveRot
{
    Eigen::Affine3f rot(prospectiveRot);
    Eigen::Matrix4f modelMat = rot.inverse().matrix();
    Vector4f newUp = modelMat *Vector4f(0,0,1,0);
    return Vector3f(newUp.x(),newUp.y(),newUp.z());
}

- (Point3f)pointUnproject:(Point2f)screenPt width:(unsigned int)frameWidth height:(unsigned int)frameHeight clip:(bool)clip
{
	Point2f ll,ur;
	float near,far;
	[self calcFrustumWidth:frameWidth height:frameHeight ll:ll ur:ur near:near far:far];
	
	// Calculate a parameteric value and flip the y/v
	float u = screenPt.x() / frameWidth;
    if (clip)
    {
        u = std::max(0.0f,u);	u = std::min(1.0f,u);
    }
	float v = screenPt.y() / frameHeight;
    if (clip)
    {
        v = std::max(0.0f,v);	v = std::min(1.0f,v);
    }
	v = 1.0 - v;
	
	// Now come up with a point in 3 space between ll and ur
	Point2f mid(u * (ur.x()-ll.x()) + ll.x(), v * (ur.y()-ll.y()) + ll.y());
	return Point3f(mid.x(),mid.y(),-near);
}
	
- (bool)pointOnSphereFromScreen:(CGPoint)pt transform:(const Eigen::Affine3f *)transform frameSize:(const Point2f &)frameSize hit:(Point3f *)hit
{
	// Back project the point from screen space into model space
	Point3f screenPt = [self pointUnproject:Point2f(pt.x,pt.y) width:frameSize.x() height:frameSize.y() clip:true];
	
	// Run the screen point and the eye point (origin) back through
	//  the model matrix to get a direction and origin in model space
	Eigen::Affine3f modelTrans = *transform;
	Matrix4f invModelMat = modelTrans.inverse().matrix();
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

- (CGPoint)pointOnScreenFromSphere:(const Point3f &)worldLoc transform:(const Eigen::Affine3f *)transform frameSize:(const Point2f &)frameSize
{
    // Run the model point through the model transform (presumably what they passed in)
    Eigen::Affine3f modelTrans = *transform;
    Matrix4f modelMat = modelTrans.matrix();
    Vector4f screenPt = modelMat * Vector4f(worldLoc.x(),worldLoc.y(),worldLoc.z(),1.0);
    screenPt.x() /= screenPt.w();  screenPt.y() /= screenPt.w();  screenPt.z() /= screenPt.w();

    // Intersection with near gives us the same plane as the screen 
    Point3f ray;  
    ray.x() = screenPt.x() / screenPt.w();  ray.y() = screenPt.y() / screenPt.w();  ray.z() = screenPt.z() / screenPt.w();
    ray *= -nearPlane/ray.z();

    // Now we need to scale that to the frame
    Point2f ll,ur;
    float near,far;
    [self calcFrustumWidth:frameSize.x() height:frameSize.y() ll:ll ur:ur near:near far:far];
    float u = (ray.x() - ll.x()) / (ur.x() - ll.x());
    float v = (ray.y() - ll.y()) / (ur.y() - ll.y());
    v = 1.0 - v;
    
    CGPoint retPt;
    retPt.x = u * frameSize.x();
    retPt.y = v * frameSize.y();
    
    return retPt;
}

- (void)cancelAnimation
{
    self.delegate = nil;
}

// Run the rotation animation
- (void)animate
{
    if (delegate)
        [delegate updateView:self];
}

// Calculate the Z buffer resolution
- (float)calcZbufferRes
{
    float delta;
//    int numBits = 16;
//    float testZ = 1.5;  // Should only need up to 1.0 away, actually
//    delta = testZ * testZ / ( nearPlane * (1<<numBits - 1));
    
    // Note: Not right
    delta = 0.0001;
    
    return delta;
}

// Construct a rotation to the given location
//  and return it.  Doesn't actually do anything yet.
- (Eigen::Quaternionf) makeRotationToGeoCoord:(const GeoCoord &)worldCoord keepNorthUp:(BOOL)northUp
{
    Point3f worldLoc = PointFromGeo(worldCoord);
    
    // Let's rotate to where they tapped over a 1sec period
    Vector3f curUp = [self currentUp];
    
    // The rotation from where we are to where we tapped
    Eigen::Quaternionf endRot;
    endRot = QuatFromTwoVectors(worldLoc,curUp);
    Eigen::Quaternionf curRotQuat = self.rotQuat;
    Eigen::Quaternionf newRotQuat = curRotQuat * endRot;
    
    if (northUp)
    {
        // We'd like to keep the north pole pointed up
        // So we look at where the north pole is going
        Vector3f northPole = (newRotQuat * Vector3f(0,0,1)).normalized();
        if (northPole.y() != 0.0)
        {
            // Then rotate it back on to the YZ axis
            // This will keep it upward
            float ang = atanf(northPole.x()/northPole.y());
            // However, the pole might be down now
            // If so, rotate it back up
            if (northPole.y() < 0.0)
                ang += M_PI;
            Eigen::AngleAxisf upRot(ang,worldLoc);
            newRotQuat = newRotQuat * upRot;
        }
    }
    
    return newRotQuat;
}

@end
