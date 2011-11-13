//
//  GlobeViewController.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WhirlyGlobe/WhirlyGlobe.h>
#import "InteractionLayer.h"
#import "OptionsViewController.h"
#import "PanDelegateFixed.h"

/** Globe View Controller
    This class pops up a a view controller with specific
    demo functionality for all the various data layers in WhirlyGlobe.
 */
@interface GlobeViewController : UIViewController <OptionsControllerDelegate>
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
    ParticleSystemLayer *particleSystemLayer;
    WGMarkerLayer *markerLayer;
    WGSelectionLayer *selectionLayer;
    InteractionLayer *interactLayer;
    
    // Gesture recognizer delegates
    WhirlyGlobePinchDelegate *pinchDelegate;
    PanDelegateFixed *panDelegate;
    WhirlyGlobeTapDelegate *tapDelegate;
    WhirlyGlobeLongPressDelegate *longPressDelegate;
    WhirlyGlobeRotateDelegate *rotateDelegate;    
    
    UIPopoverController *popoverController;
    OptionsViewController *optionsViewC;
}

/// Use this to create one of these
+ (GlobeViewController *)loadFromNib;

@end
