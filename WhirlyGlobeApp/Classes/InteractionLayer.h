//
//  InteractionLayer.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 2/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <list>
#import <Foundation/Foundation.h>
#import "WhirlyGlobe.h"

typedef std::set<WhirlyGlobe::SimpleIdentity> SimpleIDSet;

typedef enum {FeatRepCountry,FeatRepOcean} FeatureRepType;

// Representation of a large feature that has part, such as a country or ocean
// This tracks all the various labels, region outlines and so forth
class FeatureRep
{
public:
    FeatureRep() { outline = NULL; labelId = WhirlyGlobe::EmptyIdentity; midPoint = 100.0; }
    
    FeatureRepType featType;            // What this is
    WhirlyGlobe::VectorAreal *outline;  // Points in to a vector pool
    WhirlyGlobe::SimpleIdentity labelId;  // ID of label in label layer
    float midPoint;  // Distance where we switch from the low res to high res representation
    // Sub-features, such as states
    WhirlyGlobe::ShapeSet subOutlines;
    SimpleIDSet subLabels;
};

typedef std::set<FeatureRep *> FeatureRepSet;

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
    
    NSDictionary *countryDesc;  // Visual representation for countries and their labels
    NSDictionary *oceanDesc;    // Visual representation for oceans and their labels
    NSDictionary *regionDesc;   // Visual representation for regions (states/provinces) and labels

    WhirlyGlobe::VectorPool *countryPool;    // Used to incrementally load countries
    WhirlyGlobe::VectorPool *oceanPool;      // Used to incrementally load oceans
    WhirlyGlobe::VectorPool *regionPool;     // Used to incrementally load regions
    
    FeatureRepSet featureReps;   // Countries we're currently representing
}

@property (nonatomic,retain) NSDictionary *countryDesc;
@property (nonatomic,retain) NSDictionary *oceanDesc;
@property (nonatomic,retain) NSDictionary *regionDesc;
@property (nonatomic,readonly) WhirlyGlobe::VectorPool *countryPool;
@property (nonatomic,readonly) WhirlyGlobe::VectorPool *oceanPool;
@property (nonatomic,readonly) WhirlyGlobe::VectorPool *regionPool;

// Need a pointer to the vector layer to start with
- (id)initWithVectorLayer:(VectorLayer *)layer labelLayer:(LabelLayer *)labelLayer globeView:(WhirlyGlobeView *)globeView;

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inThread scene:(WhirlyGlobe::GlobeScene *)scene;

@end
