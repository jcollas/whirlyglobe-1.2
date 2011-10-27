//
//  GlobeViewController.m
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import "GlobeViewController.h"

using namespace WhirlyGlobe;

@interface GlobeViewController()
@property (nonatomic,retain) EAGLView *glView;
@property (nonatomic,retain) SceneRendererES1 *sceneRenderer;
@property (nonatomic,retain) WhirlyGlobeView *theView;
@property (nonatomic,retain) TextureGroup *texGroup;
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property (nonatomic,retain) SphericalEarthLayer *earthLayer;
@property (nonatomic,retain) VectorLayer *vectorLayer;
@property (nonatomic,retain) LabelLayer *labelLayer;
@property (nonatomic,retain) ParticleSystemLayer *particleSystemLayer;
@property (nonatomic,retain) WGMarkerLayer *markerLayer;
@property (nonatomic,retain) WGSelectionLayer *selectionLayer;
@property (nonatomic,retain) InteractionLayer *interactLayer;
@property (nonatomic,retain) WhirlyGlobePinchDelegate *pinchDelegate;
@property (nonatomic,retain) WhirlyGlobePanDelegate *panDelegate;
@property (nonatomic,retain) WhirlyGlobeTapDelegate *tapDelegate;
@property (nonatomic,retain) WhirlyGlobeLongPressDelegate *longPressDelegate;
@property (nonatomic,retain) WhirlyGlobeRotateDelegate *rotateDelegate;

@end


@implementation GlobeViewController

@synthesize glView;
@synthesize sceneRenderer;
@synthesize theView;
@synthesize texGroup;
@synthesize layerThread;
@synthesize earthLayer;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize particleSystemLayer;
@synthesize markerLayer;
@synthesize selectionLayer;
@synthesize interactLayer;
@synthesize pinchDelegate;
@synthesize panDelegate;
@synthesize tapDelegate;
@synthesize longPressDelegate;
@synthesize rotateDelegate;

+ (GlobeViewController *)loadFromNib
{
    GlobeViewController *viewC = [[[GlobeViewController alloc] initWithNibName:@"GlobeViewController" bundle:nil] autorelease];
    
    return viewC;
}

- (void)clear
{
    if (self.layerThread)
    {
        [self.layerThread cancel];
        while (!self.layerThread.isFinished)
            [NSThread sleepForTimeInterval:0.001];
    }
    
    self.glView = nil;
    self.sceneRenderer = nil;
    
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
    self.particleSystemLayer = nil;
    self.markerLayer = nil;
    self.selectionLayer = nil;
    self.interactLayer = nil;
    
    self.pinchDelegate = nil;
    self.panDelegate = nil;
    self.tapDelegate = nil;
    self.longPressDelegate = nil;
    self.rotateDelegate = nil;
}

- (void)dealloc
{
    [self clear];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Set up an OpenGL ES view and renderer
	self.glView = [[[EAGLView alloc] init] autorelease];
	self.sceneRenderer = [[[SceneRendererES1 alloc] init] autorelease];
	glView.renderer = sceneRenderer;
	glView.frameInterval = 2;  // 60 fps
	[self.view addSubview:glView];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.opaque = YES;
	self.view.autoresizesSubviews = YES;
	glView.frame = self.view.bounds;
    glView.backgroundColor = [UIColor blackColor];
    
	// Create the textures and geometry, but in the right GL context
	[sceneRenderer useContext];
	
	// Set up a texture group for the world texture
	self.texGroup = [[[TextureGroup alloc] initWithInfo:[[NSBundle mainBundle] pathForResource:@"big_wtb_info" ofType:@"plist"]] autorelease];
    
	// Need an empty scene and view
	theScene = new WhirlyGlobe::GlobeScene(4*texGroup.numX,4*texGroup.numY);
	self.theView = [[[WhirlyGlobeView alloc] init] autorelease];
	
	// Need a layer thread to manage the layers
	self.layerThread = [[[WhirlyGlobeLayerThread alloc] initWithScene:theScene] autorelease];
	
	// Earth layer on the bottom
	self.earthLayer = [[[SphericalEarthLayer alloc] initWithTexGroup:texGroup cacheName:nil] autorelease];
	[self.layerThread addLayer:earthLayer];
    
    // Selection feedback
    self.selectionLayer = [[[WGSelectionLayer alloc] initWithGlobeView:self.theView renderer:self.sceneRenderer] autorelease];
    [self.layerThread addLayer:selectionLayer];

	// Set up the vector layer where all our outlines will go
	self.vectorLayer = [[[VectorLayer alloc] init] autorelease];
	[self.layerThread addLayer:vectorLayer];
    
	// General purpose label layer.
	self.labelLayer = [[[LabelLayer alloc] init] autorelease];
	[self.layerThread addLayer:labelLayer];
    
    // Particle System layer
    self.particleSystemLayer = [[[ParticleSystemLayer alloc] init] autorelease];
    [self.layerThread addLayer:particleSystemLayer];
    
    // Marker layer
    self.markerLayer = [[[WGMarkerLayer alloc] init] autorelease];
    self.markerLayer.selectLayer = self.selectionLayer;
    [self.layerThread addLayer:markerLayer];
    
    // Lastly, an interaction layer of our own
    self.interactLayer = [[[InteractionLayer alloc] init] autorelease];
    interactLayer.vectorLayer = vectorLayer;
    interactLayer.labelLayer = labelLayer;
    interactLayer.particleSystemLayer = particleSystemLayer;
    interactLayer.markerLayer = markerLayer;
    interactLayer.selectionLayer = selectionLayer;
    [self.layerThread addLayer:interactLayer];
        
	// Give the renderer what it needs
	sceneRenderer.scene = theScene;
	sceneRenderer.view = theView;
	
	// Wire up the gesture recognizers
	self.pinchDelegate = [WhirlyGlobePinchDelegate pinchDelegateForView:glView globeView:theView];
	self.panDelegate = [WhirlyGlobePanDelegate panDelegateForView:glView globeView:theView];
	self.tapDelegate = [WhirlyGlobeTapDelegate tapDelegateForView:glView globeView:theView];
    self.longPressDelegate = [WhirlyGlobeLongPressDelegate longPressDelegateForView:glView globeView:theView];
    self.rotateDelegate = [WhirlyGlobeRotateDelegate rotateDelegateForView:glView globeView:theView];
	
	// Kick off the layer thread
	// This will start loading things
	[self.layerThread start];
}

- (void)viewDidUnload
{	
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
