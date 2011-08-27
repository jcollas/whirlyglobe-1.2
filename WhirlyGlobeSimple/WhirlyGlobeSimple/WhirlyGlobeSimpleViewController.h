//
//  WhirlyGlobeSimpleViewController.h
//  WhirlyGlobeSimple
//
//  Created by Stephen Gifford on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WhirlyGlobe/WhirlyGlobe.h>


@interface WhirlyGlobeSimpleViewController : UIViewController 
{
	EAGLView *glView;
	SceneRendererES1 *sceneRenderer;
        
   	// Scene, view, and associated data created when controller is up
	WhirlyGlobe::GlobeScene *theScene;
	WhirlyGlobeView *theView;
	TextureGroup *texGroup;
 
	// Thread used to control Whirly Globe layers
	WhirlyGlobeLayerThread *layerThread;
	
	// Data layers, readers, and loaders
	SphericalEarthLayer *earthLayer;
	VectorLayer *vectorLayer;
	LabelLayer *labelLayer;

    // Gesture recognizer delegates
    WhirlyGlobePinchDelegate *pinchDelegate;
    WhirlyGlobePanDelegate *panDelegate;
    WhirlyGlobeTapDelegate *tapDelegate;
    WhirlyGlobeLongPressDelegate *longPressDelegate;
    WhirlyGlobeRotateDelegate *rotateDelegate;
}

@end
