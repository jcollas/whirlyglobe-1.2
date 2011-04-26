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

// Representation of a large feature that has parts, such as a country or ocean
// This tracks all the various labels, region outlines and so forth
class FeatureRep
{
public:
    FeatureRep() { outlineRep = WhirlyGlobe::EmptyIdentity; labelId = WhirlyGlobe::EmptyIdentity; subOutlinesRep = WhirlyGlobe::EmptyIdentity;  subLabels = WhirlyGlobe::EmptyIdentity; midPoint = 100.0; }
    
    FeatureRepType featType;            // What this is
    std::set<WhirlyGlobe::VectorShape *> outlines;  // Areal feature outline (may be more than one)
    WhirlyGlobe::SimpleIdentity outlineRep;  // ID for the outline in the vector layer
    WhirlyGlobe::SimpleIdentity labelId;  // ID of label in label layer
    float midPoint;  // Distance where we switch from the low res to high res representation
    // Sub-features, such as states
    WhirlyGlobe::ShapeSet subOutlines;
    WhirlyGlobe::SimpleIdentity subOutlinesRep;  // Represented with a single entity in the vector layer
    WhirlyGlobe::SimpleIdentity subLabels;       // ID for all the sub outline labels together
};

typedef std::list<FeatureRep *> FeatureRepList;

// Maximum number of features we're willing to represent at once
static const unsigned int MaxFeatureReps = 8;

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
    
    FeatureRepList featureReps;   // Countries we're currently representing
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
