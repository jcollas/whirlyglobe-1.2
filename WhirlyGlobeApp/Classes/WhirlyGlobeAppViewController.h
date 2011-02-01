//
//  WhirlyGlobeAppViewController.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyGlobe.h"

@interface WhirlyGlobeAppViewController : UIViewController 
{
	EAGLView *glView;
	SceneRendererES1 *sceneRenderer;
	WhirlyGlobePinchDelegate *pinchDelegate;
	WhirlyGlobeSwipeDelegate *swipeDelegate;
	WhirlyGlobePanDelegate *panDelegate;
}

@end

