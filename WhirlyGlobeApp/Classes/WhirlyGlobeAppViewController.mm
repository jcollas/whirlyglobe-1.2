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
@property (nonatomic,retain) UILabel *fpsLabel;
@property (nonatomic,retain) WhirlyGlobePinchDelegate *pinchDelegate;
@property (nonatomic,retain) WhirlyGlobeSwipeDelegate *swipeDelegate;
@property (nonatomic,retain) WhirlyGlobePanDelegate *panDelegate;
@property (nonatomic,retain) TextureGroup *texGroup;
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property (nonatomic,retain) SphericalEarthLayer *earthLayer;
@property (nonatomic,retain) VectorLayer *vectorLayer;

- (void)fpsLabelUpdate:(NSObject *)sender;
@end

@implementation WhirlyGlobeAppViewController

@synthesize glView;
@synthesize sceneRenderer;
@synthesize fpsLabel;
@synthesize pinchDelegate;
@synthesize swipeDelegate;
@synthesize panDelegate;
@synthesize texGroup;
@synthesize layerThread;
@synthesize earthLayer;
@synthesize vectorLayer;

- (void)clear
{
	self.glView = nil;
	self.sceneRenderer = nil;
	self.fpsLabel = nil;
	self.pinchDelegate = nil;
	self.swipeDelegate = nil;
	self.panDelegate = nil;
	
	if (theScene)
	{
		delete theScene;
		theScene = NULL;
	}
	if (theView)
	{
		delete theView;
		theView = NULL;
	}
	self.texGroup = nil;
	
	self.layerThread = nil;
	self.earthLayer = nil;
	if (shapeLoader)
	{
		delete shapeLoader;
		shapeLoader = NULL;
	}
	self.vectorLayer = nil;
}

- (void)dealloc 
{
	[self clear];
	
    [super dealloc];
}

// Get the structures together for a 
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	// Set up an OpenGL ES view and renderer
	self.glView = [[[EAGLView alloc] init] autorelease];
	self.sceneRenderer = [[[SceneRendererES1 alloc] init] autorelease];
	glView.renderer = sceneRenderer;
	[self.view addSubview:glView];
	self.view.autoresizesSubviews = YES;
	glView.frame = self.view.bounds;
	
	// Stick a FPS label in the upper left
	self.fpsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,30)] autorelease];
	self.fpsLabel.backgroundColor = [UIColor clearColor];
	self.fpsLabel.textColor = [UIColor whiteColor];
	[self.view addSubview:self.fpsLabel];
	[self fpsLabelUpdate:self];

	// Create the textures and geometry, but in the right GL context
	[sceneRenderer useContext];
	
	// Set up a texture group for the world texture
	self.texGroup = [[[TextureGroup alloc] initWithBase:@"wtb" ext:@"pvrtc" numX:5 numY:2] autorelease];

	// Need an empty scene and view
	theScene = new WhirlyGlobe::GlobeScene(texGroup.numX,texGroup.numY);
	theView = new WhirlyGlobe::GlobeView();
	
	// Need a layer thread to manage the layers
	self.layerThread = [[[WhirlyGlobeLayerThread alloc] initWithScene:theScene] autorelease];
	
	// Earth layer on the bottom
	self.earthLayer = [[[SphericalEarthLayer alloc] initWithTexGroup:texGroup] autorelease];
	[self.layerThread addLayer:earthLayer];
	
	// Set up a data loader for the shapefile
	NSString *shapeFileName = [[NSBundle mainBundle] pathForResource:@"boundaries polygon" ofType:@"shp"];
	shapeLoader = new WhirlyGlobe::ShapeLoader(shapeFileName);
	if (!shapeLoader->isValid())
	{
		NSLog(@"Failed to open shape file: %@",shapeFileName);
		delete shapeLoader;
		shapeLoader = NULL;
	} else {
		self.vectorLayer = [[[VectorLayer alloc] initWithLoader:shapeLoader] autorelease];
		[self.layerThread addLayer:vectorLayer];
	}
	
	// Give the renderer what it needs
	sceneRenderer.scene = theScene;
	sceneRenderer.view = theView;
	
	// Wire up a guesture recognizer to catch pinch
	self.pinchDelegate = [WhirlyGlobePinchDelegate pinchDelegateForView:glView globeView:theView];
	self.swipeDelegate = [WhirlyGlobeSwipeDelegate swipeDelegateForView:glView globeView:theView];
	self.panDelegate = [WhirlyGlobePanDelegate panDelegateForView:glView globeView:theView];
	
	// Kick off the layer thread
	// This will start loading things
	[self.layerThread start];
}

- (void)viewDidUnload
{
	[self.layerThread cancel];
	while (!self.layerThread.isFinished)
		[NSThread sleepForTimeInterval:0.001];
	
	[self clear];
	
	[super viewDidUnload];
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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
	
	// Note: Not clear what we can really do here
}

- (void)fpsLabelUpdate:(NSObject *)sender
{
	self.fpsLabel.text = [NSString stringWithFormat:@"%.2f fps",sceneRenderer.framesPerSec];
	[self performSelector:@selector(fpsLabelUpdate:) withObject:nil afterDelay:FPSUpdateInterval];
}

@end
