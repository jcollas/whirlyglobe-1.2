//
//  PanDelegateFixed.m
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 4/28/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "PanDelegateFixed.h"
#import "AnimateViewMomentum.h"

@interface PanDelegateFixed()
@property (nonatomic,retain) NSDate *spinDate;
@end

@implementation PanDelegateFixed

@synthesize spinDate;

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if ((self = [super init]))
	{
		view = inView;
        rotType = RotNone;
	}
	
	return self;
}

- (void)dealloc
{
    self.spinDate = nil;
    [super dealloc];
}

+ (PanDelegateFixed *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	PanDelegateFixed *panDelegate = [[[PanDelegateFixed alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:panDelegate action:@selector(panAction:)] autorelease]];
	return panDelegate;
}

// Called for pan actions
- (void)panAction:(id)sender
{
	UIPanGestureRecognizer *pan = sender;
	EAGLView *glView = (EAGLView *)pan.view;
	SceneRendererES1 *sceneRender = glView.renderer;
	
	if (pan.numberOfTouches > 1)
	{
        rotType = RotNone;
		return;
	}
    
	switch (pan.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			[view cancelAnimation];
            
			// Save the first place we touched
			startTransform = [view calcModelMatrix];
			startQuat = view.rotQuat;
            spinQuat = view.rotQuat;
            startPoint = [pan locationOfTouch:0 inView:glView];
            self.spinDate = [NSDate date];
            lastTouch = [pan locationOfTouch:0 inView:glView];
			if ([view pointOnSphereFromScreen:startPoint transform:&startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&startOnSphere])
                // We'll start out letting them play with box axes
				rotType = RotFree;                
            else
                rotType = RotNone;
		}
			break;
		case UIGestureRecognizerStateChanged:
		{
			if (rotType != RotNone)
			{
				[view cancelAnimation];
                
				// Figure out where we are now
				Point3f hit;
                CGPoint touchPt = [pan locationOfTouch:0 inView:glView];
                lastTouch = touchPt;
				[view pointOnSphereFromScreen:touchPt transform:&startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit ];                
                                
				// This gives us a direction to rotate around
				// And how far to rotate
				Eigen::Quaternion<float> endRot;
				endRot.setFromTwoVectors(startOnSphere,hit);
                Eigen::Quaternion<float> newRotQuat = startQuat * endRot;

                // We'd like to keep the north pole pointed up
                // So we look at where the north pole is going
                Vector3f northPole = (newRotQuat * Vector3f(0,0,1)).normalized();
                if (northPole.y() != 0.0)
                {
                    // We need to know where up (facing the user) will be
                    //  so we can rotate around that
                    Vector3f newUp = [WhirlyGlobeView prospectiveUp:newRotQuat];
                    
                    // Then rotate it back on to the YZ axis
                    // This will keep it upward
                    float ang = atanf(northPole.x()/northPole.y());
                    // However, the pole might be down now
                    // If so, rotate it back up
                    if (northPole.y() < 0.0)
                        ang += M_PI;
                    Eigen::AngleAxisf upRot(ang,newUp);
                    newRotQuat = newRotQuat * upRot;
                }
 
                // Keep track of the last rotation
                [view setRotQuat:(newRotQuat)];

                // If our spin sample is too old, grab a new one
                self.spinDate = [NSDate date];
                spinQuat = view.rotQuat;
			}
		}
			break;
		case UIGestureRecognizerStateEnded:
        {
            // We'll use this to get two points in model space
            CGPoint vel = [pan velocityInView:glView];
            CGPoint touch0 = lastTouch;
            
            NSLog(@"touch0 = (%f,%f)  vel = (%f,%f)",touch0.x,touch0.y,vel.x,vel.y);
            Point3f p0 = [view pointUnproject:Point2f(touch0.x,touch0.y) width:sceneRender.framebufferWidth height:sceneRender.framebufferHeight clip:false];
            Point2f touch1(touch0.x+vel.x,touch0.y+vel.y);
            Point3f p1 = [view pointUnproject:touch1 width:sceneRender.framebufferWidth height:sceneRender.framebufferHeight clip:false];
            
            NSLog(@"p0 = (%f,%f,%f)  p1 = (%f,%f,%f)",p0.x(),p0.y(),p0.z(),p1.x(),p1.y(),p1.z());
            
            // Now unproject them back to the canonical model
            Eigen::Matrix4f modelMat = [view calcModelMatrix].inverse();
            Vector4f model_p0 = modelMat * Vector4f(p0.x(),p0.y(),p0.z(),1.0);
            Vector4f model_p1 = modelMat * Vector4f(p1.x(),p1.y(),p1.z(),1.0);

            model_p0.x() /= model_p0.w();  model_p0.y() /= model_p0.w();  model_p0.z() /= model_p0.w();
            model_p1.x() /= model_p1.w();  model_p1.y() /= model_p1.w();  model_p1.z() /= model_p1.w();
            NSLog(@"mp0 = (%f,%f,%f)  mp1 = (%f,%f,%f)",model_p0.x(),model_p0.y(),model_p0.z(),model_p1.x(),model_p1.y(),model_p1.z());

            // The angle between them, ignoring z, is what we're after
            model_p0.z() = 0;  model_p0.w() = 0;
            model_p1.z() = 0;  model_p1.w() = 0;
            model_p0.normalize();
            model_p1.normalize();

            float dot = model_p0.dot(model_p1);
            float ang = 80.0*acosf(dot);
            
            // The acceleration (to slow it down)
            float drag = -1;

            // Now for the direction
            Vector3f cross = Vector3f(model_p0.x(),model_p0.y(),0.0).cross(Vector3f(model_p1.x(),model_p1.y(),0.0));
            if (cross.z() < 0)
            {
                ang *= -1;
                drag *= -1;
            }
            
            NSLog(@"dot = %f  ang = %f",dot,ang);
              
            // Keep going in that direction for a while
            float angVel = ang;  
           view.delegate = [[[AnimateViewMomentum alloc] initWithView:view velocity:angVel accel:drag] autorelease];
        }
			break;
        default:
            break;
	}
}

@end
