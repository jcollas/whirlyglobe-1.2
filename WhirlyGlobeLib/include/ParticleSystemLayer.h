/*
 *  ParticleSystemLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 10/10/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
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

#import <math.h>
#import <set>
#import <map>
#import "Identifiable.h"
#import "Drawable.h"
#import "DataLayer.h"
#import "LayerThread.h"
#import "TextureAtlas.h"
#import "DrawCost.h"
#import "ParticleGenerator.h"

/** Particle System
    Representation of a single particle system.
    We give it a geographic location and a normal (in 3-space).
    The rest of the info is in the dictionary.
 */
@interface ParticleSystem : NSObject
{
    WhirlyGlobe::GeoCoord loc;
    Vector3f norm;
}

@property (nonatomic,assign) WhirlyGlobe::GeoCoord loc;
@property (nonatomic,assign) Vector3f norm;

@end

namespace WhirlyGlobe
{
    
class ParticleSysSceneRep : public Identifiable
{
public:
    ParticleSysSceneRep() { }
    
    SimpleIDSet partSysIDs;    // The particle systems we created
};
typedef std::set<ParticleSysSceneRep *,IdentifiableSorter> ParticleSysSceneRepSet;    
    
}

/** Particle System Layer
    This layer creates and controls particle systems defined by locations
    and a collection attributes in a dictionary.
  */
@interface ParticleSystemLayer : NSObject<WhirlyGlobeLayer> 
{
    WhirlyGlobeLayerThread *layerThread;
    WhirlyGlobe::GlobeScene *scene;
    
    WhirlyGlobe::SimpleIdentity generatorId;
    
    WhirlyGlobe::ParticleSysSceneRepSet sceneReps;
}

/// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)scene;

/// Add a single particle system to the layer
- (WhirlyGlobe::SimpleIdentity) addParticleSystem:(ParticleSystem *)partSystem desc:(NSDictionary *)desc;

/// Add a group of particle systems
- (WhirlyGlobe::SimpleIdentity) addParticleSystems:(NSArray *)partSystems desc:(NSDictionary *)desc;

/// Remove one or more particle systems
- (void) removeParticleSystems:(WhirlyGlobe::SimpleIdentity)partSysId;

@end