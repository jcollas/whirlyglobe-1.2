//
//  WhirlyGlobeAppViewController.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyGlobe.h"

// Update the frame rate display this much
static const float FPSUpdateInterval = 4.0;

/* Whirly Globe View Controller
	View controller that pops up a Whirly Globe view.
 */
@interface WhirlyGlobeAppViewController : UIViewController 
{
	EAGLView *glView;
	SceneRendererES1 *sceneRenderer;
	
	UILabel *fpsLabel;

	// Various interaction delegates when this view controller is up
	WhirlyGlobePinchDelegate *pinchDelegate;
	WhirlyGlobeSwipeDelegate *swipeDelegate;
	WhirlyGlobePanDelegate *panDelegate;

	// Scene, view, and associated data created when controller is up
	WhirlyGlobe::GlobeScene *theScene;
	WhirlyGlobeView *theView;
	TextureGroup *texGroup;
	
	// Thread used to control Whirly Globe layers
	WhirlyGlobeLayerThread *layerThread;
	
	// Data layers
	SphericalEarthLayer *earthLayer;
	WhirlyGlobe::ShapeLoader *shapeLoader;
	VectorLayer *vectorLayer;
}

@end

