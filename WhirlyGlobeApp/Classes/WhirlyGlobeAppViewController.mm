//
//  WhirlyGlobeAppViewController.m
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WhirlyGlobeAppViewController.h"

using namespace WhirlyGlobe;

@interface WhirlyGlobeAppViewController()
@property (nonatomic,retain) EAGLView *glView;
@property (nonatomic,retain) SceneRendererES1 *sceneRenderer;
@property (nonatomic,retain) UILabel *fpsLabel,*drawLabel;
@property (nonatomic,retain) WhirlyGlobePinchDelegate *pinchDelegate;
@property (nonatomic,retain) WhirlyGlobeSwipeDelegate *swipeDelegate;
@property (nonatomic,retain) WhirlyGlobePanDelegate *panDelegate;
@property (nonatomic,retain) WhirlyGlobeTapDelegate *tapDelegate;
@property (nonatomic,retain) WhirlyGlobeView *theView;
@property (nonatomic,retain) TextureGroup *texGroup;
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property (nonatomic,retain) SphericalEarthLayer *earthLayer;
@property (nonatomic,retain) VectorLayer *vectorLayer;
@property (nonatomic,retain) LabelLayer *labelLayer;
@property (nonatomic,retain) VectorLoader *vectorLoader;
@property (nonatomic,retain) InteractionLayer *interactLayer;

- (void)labelUpdate:(NSObject *)sender;
@end

@implementation WhirlyGlobeAppViewController

@synthesize glView;
@synthesize sceneRenderer;
@synthesize fpsLabel,drawLabel;
@synthesize pinchDelegate;
@synthesize swipeDelegate;
@synthesize panDelegate;
@synthesize tapDelegate;
@synthesize theView;
@synthesize texGroup;
@synthesize layerThread;
@synthesize earthLayer;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize vectorLoader;
@synthesize interactLayer;

- (void)clear
{
    self.glView = nil;
    self.sceneRenderer = nil;
    self.fpsLabel = nil;
    self.drawLabel = nil;
    self.pinchDelegate = nil;
    self.swipeDelegate = nil;
    self.panDelegate = nil;
    self.tapDelegate = nil;
    
    if (theScene)
    {
        delete theScene;
        theScene = NULL;
    }
    self.theView = nil;
    self.texGroup = nil;
    
    self.layerThread = nil;
    self.earthLayer = nil;
    self.vectorLayer = nil;
    self.labelLayer = nil;
    self.vectorLoader = nil;
    self.interactLayer = nil;
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
	glView.frameInterval = 2;  // 60 fps
	[self.view addSubview:glView];
	self.view.autoresizesSubviews = YES;
	glView.frame = self.view.bounds;
	
	// Stick a FPS label in the upper left
	self.fpsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,20)] autorelease];
	self.fpsLabel.backgroundColor = [UIColor clearColor];
	self.fpsLabel.textColor = [UIColor whiteColor];
	[self.view addSubview:self.fpsLabel];
	[self labelUpdate:self];
	
	// And a drawable label right below that
	self.drawLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0,20,100,20)] autorelease];
	self.drawLabel.backgroundColor = [UIColor clearColor];
	self.drawLabel.textColor = [UIColor whiteColor];
	[self.view addSubview:self.drawLabel];

	// Create the textures and geometry, but in the right GL context
	[sceneRenderer useContext];
	
	// Set up a texture group for the world texture
	self.texGroup = [[[TextureGroup alloc] initWithBase:@"wtb" ext:@"pvrtc" numX:5 numY:2] autorelease];

	// Need an empty scene and view
	theScene = new WhirlyGlobe::GlobeScene(4*texGroup.numX,4*texGroup.numY);
	self.theView = [[[WhirlyGlobeView alloc] init] autorelease];
	
	// Need a layer thread to manage the layers
	self.layerThread = [[[WhirlyGlobeLayerThread alloc] initWithScene:theScene] autorelease];
	
	// Earth layer on the bottom
	self.earthLayer = [[[SphericalEarthLayer alloc] initWithTexGroup:texGroup] autorelease];
	[self.layerThread addLayer:earthLayer];

	// Set up the vector layer where all our outlines will go
	self.vectorLayer = [[[VectorLayer alloc] init] autorelease];
	[self.layerThread addLayer:vectorLayer];

	// General purpose label layer.
	self.labelLayer = [[[LabelLayer alloc] init] autorelease];
	[self.layerThread addLayer:labelLayer];

	// The interaction layer will handle label and geometry creation when something is tapped
	self.interactLayer = [[[InteractionLayer alloc] initWithVectorLayer:self.vectorLayer labelLayer:labelLayer globeView:self.theView] autorelease];
    
    // These are files indexable by country name
    // The interaction layer will pop up regions from these when you select a country
	[self.interactLayer.regionShapeFiles addObject:@"region"];
    
    // These are points of interest.
    // The interaction layer will display these when a country is selected
	[self.interactLayer.regionInteriorFiles addObject:@"mountains"];
	[self.interactLayer.regionInteriorFiles addObject:@"points of interest"];
	[self.interactLayer.regionInteriorFiles addObject:@"lakes"];
	
	[self.layerThread addLayer:interactLayer];
		
	// Set up a vector loader so we can stream in shape data
	self.vectorLoader = [[[VectorLoader alloc] initWithVectorLayer:self.vectorLayer labelLayer:self.labelLayer] autorelease];
    [self.layerThread addLayer:vectorLoader];
	
	// We want the country outlines loaded in first
    // They'll start out as white outlines
	if (![self.vectorLoader 
          addShapeFile:[[NSBundle mainBundle] pathForResource:@"50m_admin_0_countries" ofType:@"shp"]
          target:interactLayer selector:@selector(countryShape:) desc:interactLayer.countryDesc])
		NSLog(@"Failed to load country file.");
    
	// Oceans we'll load in, but turn off in oceanSetup
/*	if (![self.vectorLoader 
          addShapeFile:[[NSBundle mainBundle] pathForResource:@"ocean" ofType:@"shp"]
          target:interactLayer selector:@selector(oceanShape:) desc:interactLayer.oceanDesc])
		NSLog(@"Failed to load country file.");
*/
	// Give the renderer what it needs
	sceneRenderer.scene = theScene;
	sceneRenderer.view = theView;
	
	// Wire up the gesture recognizers
	self.pinchDelegate = [WhirlyGlobePinchDelegate pinchDelegateForView:glView globeView:theView];
	self.swipeDelegate = [WhirlyGlobeSwipeDelegate swipeDelegateForView:glView globeView:theView];
	self.panDelegate = [WhirlyGlobePanDelegate panDelegateForView:glView globeView:theView];
	self.tapDelegate = [WhirlyGlobeTapDelegate tapDelegateForView:glView globeView:theView];
	
	// Kick off the layer thread
	// This will start loading things
	[self.layerThread start];
}

// Called when the vector layer creates a new drawable
// This lets us mess with the visual representation right at the beginning
- (void)setupDrawable:(BasicDrawable *)drawable shape:(VectorShape *)shape
{
	drawable->setColor(RGBAColor(128,128,128,255));
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

- (void)labelUpdate:(NSObject *)sender
{
	self.fpsLabel.text = [NSString stringWithFormat:@"%.2f fps",sceneRenderer.framesPerSec];
	self.drawLabel.text = [NSString stringWithFormat:@"%d draws",sceneRenderer.numDrawables];
	[self performSelector:@selector(labelUpdate:) withObject:nil afterDelay:FPSUpdateInterval];
}

@end
