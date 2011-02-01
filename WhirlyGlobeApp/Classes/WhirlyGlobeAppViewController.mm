//
//  WhirlyGlobeAppViewController.m
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WhirlyGlobeAppViewController.h"

@interface WhirlyGlobeAppViewController()
@property (nonatomic,retain) EAGLView *glView;
@property (nonatomic,retain) SceneRendererES1 *sceneRenderer;
@property (nonatomic,retain) WhirlyGlobePinchDelegate *pinchDelegate;
@property (nonatomic,retain) WhirlyGlobeSwipeDelegate *swipeDelegate;
@property (nonatomic,retain) WhirlyGlobePanDelegate *panDelegate;
@end

@implementation WhirlyGlobeAppViewController

@synthesize glView;
@synthesize sceneRenderer;
@synthesize pinchDelegate;
@synthesize swipeDelegate;
@synthesize panDelegate;

- (void)dealloc 
{
	self.glView = nil;
	self.sceneRenderer = nil;
	self.pinchDelegate = nil;
	self.swipeDelegate = nil;
	self.panDelegate = nil;
	
    [super dealloc];
}

// Global scene and view
// Note: Put these somewhere else
WhirlyGlobe::GlobeScene scene;
WhirlyGlobe::GlobeView view;
WhirlyGlobe::SphericalEarthModel earth;
WhirlyGlobe::GridLineModel gridLines;
WhirlyGlobe::ShapeFileModel *shapeModel;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
// Toss a whirly globe view on top
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	// Set up an OpenGL ES view and renderer
	self.glView = [[[EAGLView alloc] init] autorelease];
	self.sceneRenderer = [[[SceneRendererES1 alloc] init] autorelease];
	glView.renderer = sceneRenderer;
	[self.view addSubview:glView];
	glView.frame = self.view.bounds;

	// Create the textures and geometry, but in the right GL context
	[sceneRenderer useContext];

	// Set up a texture group for the world texture
	TextureGroup *texGroup = [[[TextureGroup alloc] initWithBase:@"wtb" ext:@"pvrtc" numX:5 numY:2] autorelease];
	
	// Create sphere drawables and hand those over
	earth.generate(texGroup);
	std::vector<WhirlyGlobe::Cullable *> &cullables = earth.getCullables();
	for (unsigned int ii=0;ii<cullables.size();ii++)
		scene.addCullable(cullables[ii]);

	// Grid lines next
	// This adds to the existing cullables
//	gridLines.generate(&earth);
	
	// Shapefile overlay
	// Adds to existing cullables
//	NSString *shapeFileName = [[NSBundle mainBundle] pathForResource:@"world" ofType:@"shp"];
	NSString *shapeFileName = [[NSBundle mainBundle] pathForResource:@"boundaries polygon" ofType:@"shp"];
	shapeModel = new WhirlyGlobe::ShapeFileModel(shapeFileName);
	shapeModel->generate(&earth);
	
	// Give the renderer what it needs
	sceneRenderer.scene = &scene;
	sceneRenderer.view = &view;
	
	// Wire up a guesture recognizer to catch pinch
	self.pinchDelegate = [WhirlyGlobePinchDelegate pinchDelegateForView:glView globeView:&view];
	self.swipeDelegate = [WhirlyGlobeSwipeDelegate swipeDelegateForView:glView globeView:&view];
	self.panDelegate = [WhirlyGlobePanDelegate panDelegateForView:glView globeView:&view];
}

- (void)viewDidUnload 
{
	self.glView = nil;
	self.sceneRenderer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.glView startAnimation];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.glView stopAnimation];
	
	[super viewWillDisappear:animated];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
