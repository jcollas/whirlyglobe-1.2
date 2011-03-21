//
//  InteractionLayer.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 2/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WhirlyGlobe.h"

typedef std::set<WhirlyGlobe::SimpleIdentity> SimpleIDSet;

/* (Whirly Globe) Interaction Layer
    This handles user interaction (taps) and manipulates data in the
    vector and label layers accordingly.
 */
@interface InteractionLayer : NSObject <WhirlyGlobeLayer>
{
	WhirlyGlobeLayerThread *layerThread;
	WhirlyGlobe::GlobeScene *scene;
	WhirlyGlobeView *globeView;
	VectorLayer *vectorLayer;
	LabelLayer *labelLayer;
    NSMutableArray *regionShapeFiles;     // States/provinces, indexed by country
    NSMutableArray *regionInteriorFiles;  // Points of interest within countries
    
    NSDictionary *countryDesc;  // Default visual representation for countries
    NSDictionary *oceanDesc;    // Default visual representation for oceans
    NSDictionary *disableDesc;  // Used to disable a visual representation
    
    SimpleIDSet countryIDs;
    SimpleIDSet labelIDs;
}

@property (nonatomic,retain) NSMutableArray *regionShapeFiles;
@property (nonatomic,retain) NSMutableArray *regionInteriorFiles;
@property (nonatomic,retain) NSDictionary *countryDesc;
@property (nonatomic,retain) NSDictionary *oceanDesc;
@property (nonatomic,retain) NSDictionary *disableDesc;

// Need a pointer to the vector layer to start with
- (id)initWithVectorLayer:(VectorLayer *)layer labelLayer:(LabelLayer *)labelLayer globeView:(WhirlyGlobeView *)globeView;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)scene;

// Called by the vector loader when a country is loaded in
- (void)countryShape:(VectorLoaderInfo *)info;

// Called by the vector loader when an ocean is loaded in
- (void)oceanShape:(VectorLoaderInfo *)info;

@end
