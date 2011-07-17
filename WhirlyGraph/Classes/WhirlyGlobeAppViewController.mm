/*
 *  WhirlyGlobeAppViewController.m
 *  WhirlyGlobeApp
 *
 *  Created by Stephen Gifford on 1/12/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "WhirlyGlobeAppViewController.h"
#import "PanDelegateFixed.h"
#import "WebViewController.h"

#define CENTER_COORD1 512.0
#define CENTER_COORD2 384.0


// WebViewController *webViewController;



using namespace WhirlyGlobe;

@interface WhirlyGlobeAppViewController()
@property (nonatomic,retain) EAGLView *glView;
@property (nonatomic,retain) SceneRendererES1 *sceneRenderer;
@property (nonatomic,retain) UILabel *fpsLabel,*drawLabel;
@property (nonatomic,retain) WhirlyGlobePinchDelegate *pinchDelegate;
@property (nonatomic,retain) WhirlyGlobeSwipeDelegate *swipeDelegate;
@property (nonatomic,retain) WhirlyGlobeRotateDelegate *rotateDelegate;
@property (nonatomic,retain) PanDelegateFixed *panDelegate;
@property (nonatomic,retain) WhirlyGlobeTapDelegate *tapDelegate;
@property (nonatomic,retain) WhirlyGlobeLongPressDelegate *pressDelegate;
@property (nonatomic,retain) WhirlyGlobeView *theView;
@property (nonatomic,retain) TextureGroup *texGroup;
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@property (nonatomic,retain) SphericalEarthLayer *earthLayer;
@property (nonatomic,retain) VectorLayer *vectorLayer;
@property (nonatomic,retain) LabelLayer *labelLayer;
@property (nonatomic,retain) LoftLayer *loftLayer;
@property (nonatomic,retain) InteractionLayer *interactLayer;

- (void)labelUpdate:(NSObject *)sender;
@end

@implementation WhirlyGlobeAppViewController

@synthesize glView;
@synthesize sceneRenderer;
@synthesize fpsLabel,drawLabel;
@synthesize pinchDelegate;
@synthesize swipeDelegate;
@synthesize rotateDelegate;
@synthesize panDelegate;
@synthesize tapDelegate;
@synthesize pressDelegate;
@synthesize theView;
@synthesize texGroup;
@synthesize layerThread;
@synthesize earthLayer;
@synthesize vectorLayer;
@synthesize labelLayer;
@synthesize loftLayer;
@synthesize interactLayer;


//for wikipedia
@synthesize tmpURLString, tmpTitleString;

//for popover options button to open tableview
@synthesize popOverController;
@synthesize optionsViewController;
@synthesize label;
@synthesize buttonOpenPopOver;


- (void)clear
{
    self.glView = nil;
    self.sceneRenderer = nil;
    self.fpsLabel = nil;
    self.drawLabel = nil;
    self.pinchDelegate = nil;
    self.swipeDelegate = nil;
    self.rotateDelegate = nil;
    self.panDelegate = nil;
    self.tapDelegate = nil;
    self.pressDelegate = nil;
    
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
    self.loftLayer = nil;
    self.interactLayer = nil;
}

- (void)dealloc 
{
    [self clear];
    
    [optionsViewController release];
    
    [super dealloc];
}

// Get the structures together for a 
- (void)viewDidLoad 
{
    
    // Define the popover for the options button
    optionsViewController = [[OptionsViewController alloc] init];
    optionsViewController.delegate = self;
    popOverController = [[UIPopoverController alloc] initWithContentViewController:optionsViewController];
    popOverController.popoverContentSize = CGSizeMake(400, 300);
    
    [super viewDidLoad];
	
	// Set up an OpenGL ES view and renderer
	self.glView = [[[EAGLView alloc] init] autorelease];
	self.sceneRenderer = [[[SceneRendererES1 alloc] init] autorelease];
	glView.renderer = sceneRenderer;
	glView.frameInterval = 2;  // 60 fps
	//[self.view addSubview:glView];
    [self.view insertSubview:glView atIndex:0];

    self.view.backgroundColor = [UIColor blackColor];
    self.view.opaque = YES;
	self.view.autoresizesSubviews = YES;
	glView.frame = self.view.bounds;
    glView.backgroundColor = [UIColor blackColor];
	
	// Stick a FPS label in the upper left
	self.fpsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,20)] autorelease];
	self.fpsLabel.backgroundColor = [UIColor clearColor];
	self.fpsLabel.textColor = [UIColor whiteColor];
    // Note: Turned off for now
//	[self.view addSubview:self.fpsLabel];
	[self labelUpdate:self];
	
	// And a drawable label right below that
	self.drawLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0,20,100,20)] autorelease];
	self.drawLabel.backgroundColor = [UIColor clearColor];
	self.drawLabel.textColor = [UIColor whiteColor];
    // Note: Also turned off
//	[self.view addSubview:self.drawLabel];

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
	self.earthLayer = [[[SphericalEarthLayer alloc] initWithTexGroup:texGroup] autorelease];
	[self.layerThread addLayer:earthLayer];

	// Set up the vector layer where all our outlines will go
	self.vectorLayer = [[[VectorLayer alloc] init] autorelease];
	[self.layerThread addLayer:vectorLayer];

	// General purpose label layer.
	self.labelLayer = [[[LabelLayer alloc] init] autorelease];
	[self.layerThread addLayer:labelLayer];
    
    // Lofted polygon layer
    self.loftLayer = [[[LoftLayer alloc] init] autorelease];
    self.loftLayer.gridSize = [self.earthLayer smallestTesselation];
    [self.layerThread addLayer:loftLayer];

	// The interaction layer will handle label and geometry creation when something is tapped
    // Data is divided by countries, oceans, and regions (e.g. states/provinces)
	self.interactLayer = [[[InteractionLayer alloc] initWithVectorLayer:self.vectorLayer labelLayer:labelLayer loftLayer:loftLayer
                                                              globeView:self.theView
                                                           countryShape:[[NSBundle mainBundle] pathForResource:@"50m_admin_0_map_subunits" ofType:@"shp"]
                                                             oceanShape:[[NSBundle mainBundle] pathForResource:@"10m_geography_marine_polys" ofType:@"shp"]
                                                            regionShape:nil]
                          autorelease]; 
    self.interactLayer.maxEdgeLen = [self.earthLayer smallestTesselation]/10.0;
	[self.layerThread addLayer:interactLayer];
			
	// Give the renderer what it needs
	sceneRenderer.scene = theScene;
	sceneRenderer.view = theView;
	
	// Wire up the gesture recognizers
	self.pinchDelegate = [WhirlyGlobePinchDelegate pinchDelegateForView:glView globeView:theView];
//	self.swipeDelegate = [WhirlyGlobeSwipeDelegate swipeDelegateForView:glView globeView:theView];
	self.panDelegate = [PanDelegateFixed panDelegateForView:glView globeView:theView];
	self.tapDelegate = [WhirlyGlobeTapDelegate tapDelegateForView:glView globeView:theView];
    self.pressDelegate = [WhirlyGlobeLongPressDelegate longPressDelegateForView:glView globeView:theView];
    self.rotateDelegate = [WhirlyGlobeRotateDelegate rotateDelegateForView:glView globeView:theView];
	
	// Kick off the layer thread
	// This will start loading things
	[self.layerThread start];

    // Find out when the user's selected a country (pressed)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCountrySelector:) name:WhirlyGlobeCountrySelectMsg object:nil];
}

// User selected a country
// Probably in the layer thread
- (void)selectCountrySelector:(NSNotification *)note
{
    CountrySelectMsg *selectMsg = note.object;
    [self performSelectorOnMainThread:@selector(webControllerPage:) withObject:selectMsg waitUntilDone:NO];
}

// Pop up a web view for the country in question
// In the main thread
- (void)webControllerPage:(CountrySelectMsg *)selectMsg
{
    NSLog(@"User selected country %@",selectMsg.country);

    //    NSString *HTMLString = [[NSString alloc] initWithFormat:@"data%d",dataTag];	
    NSString *HTMLString = [NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@",selectMsg.country];
    self.tmpURLString = HTMLString;
    
    //Prepare WebViewController for popover
    
    WebViewController  *webViewControllerForPopover = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil ];    
    webViewControllerForPopover.passStringURL = self.tmpURLString;
    webViewControllerForPopover.passStringTitle = self.tmpTitleString;
    
    [webViewControllerForPopover setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    webViewControllerForPopover.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    webViewControllerForPopover.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentModalViewController:webViewControllerForPopover animated:YES];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

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
//	return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return true;
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


// tab to dismiss popover
-(void)didTap:(NSNumber *)which {
    
    NSLog(@"User tapped: %@",which);
    
    [popOverController dismissPopoverAnimated:YES];    
    
    // Note: Fill this in
    [self.interactLayer setDisplayField:@"foo"];
}

// Somebody tapped in the space outside the globe
// We're in the main thread here
- (void)tapOutsideSelector:(NSNotification *)note
{
    NSLog(@"Tap outside selector called");
}

-(IBAction)togglePopOverController:(id)sender;
{
    UIButton* myButton = (UIButton*)sender;
    
    float x = myButton.center.x;  // center it a bit horizontally
    float y = myButton.center.y; // y position of the button
    CGSize size = {10,10}; // rectange size of the button
    [popOverController setPopoverContentSize:CGSizeMake(500.0,400.0)];  // required to size the popover box - easy to forget this!



    if ([popOverController isPopoverVisible]) {
        [popOverController dismissPopoverAnimated:YES];
    } else {
		[popOverController presentPopoverFromRect:CGRectMake(x, y, size.width, size.height) 
                                            inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }    
}

@end
