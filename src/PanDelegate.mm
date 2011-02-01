//
//  PanDelegate.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PanDelegate.h"
#import "EAGLView.h"
#import "SceneRendererES1.h"
#import "WhirlyGeometry.h"

@implementation WhirlyGlobePanDelegate

- (id)initWithGlobeView:(WhirlyGlobe::GlobeView *)inView
{
	if (self = [super init])
	{
		view = inView;
	}
	
	return self;
}

+ (WhirlyGlobePanDelegate *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobe::GlobeView *)globeView
{
	WhirlyGlobePanDelegate *panDelegate = [[[WhirlyGlobePanDelegate alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:panDelegate action:@selector(panAction:)] autorelease]];
	return panDelegate;
}

// Calculate a point on the unit sphere, given the model transform
- (bool) pointOnSphereFromScreen:(CGPoint)pt modelTransform:(Eigen::Transform3f)transform frameSize:(Point2f)frameSize hit:(Point3f *)hit
{
	// Back project the point from screen space into model space
	Point3f screenPt = view->pointUnproject(Point2f(pt.x,pt.y),frameSize.x(),frameSize.y());
	
	// Run the screen point and the eye point (origin) back through
	//  the model matrix to get a direction and origin in model space
	Eigen::Transform3f modelTrans = transform;
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

// Called for pan actions
- (void)panAction:(id)sender
{
	UIPanGestureRecognizer *pan = sender;
	EAGLView *glView = (EAGLView *)pan.view;
	SceneRendererES1 *sceneRender = glView.renderer;
	
	if (pan.numberOfTouches > 1)
	{
		panning = NO;
		return;
	}
		
	switch (pan.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			// Save the first place we touched
			// Note: Is this really the first
			startTransform = view->calcModelMatrix();
			startQuat = view->rotQuat;
			panning = NO;
			if ([self pointOnSphereFromScreen:[pan locationOfTouch:0 inView:nil] modelTransform:startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&startOnSphere])
				panning = YES;

//			if (panning)
//				NSLog(@"Pan start: (%f,%f,%f)\n",startOnSphere.x(),startOnSphere.y(),startOnSphere.z());
		}
			break;
		case UIGestureRecognizerStateChanged:
		{
			if (panning)
			{
				// Figure out where we are now
				Point3f hit;
				[self pointOnSphereFromScreen:[pan locationOfTouch:0 inView:nil] modelTransform:startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit];
//				NSLog(@"Pan: (%f,%f,%f)\n",hit.x(),hit.y(),hit.z());

				// This gives us a direction to rotate around
				// And how far to rotate
				Eigen::Quaternion<float> thisRot;
				thisRot.setFromTwoVectors(startOnSphere,hit);
				view->rotQuat = startQuat * thisRot;
			}
		}
			break;
		case UIGestureRecognizerStateEnded:
			panning = NO;
			break;
	}
}

@end
