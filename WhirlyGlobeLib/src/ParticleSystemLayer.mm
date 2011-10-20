//
//  ParticleSystemLayer.mm
//  WhirlyGlobeLib
//
//  Created by Steve Gifford on 10/10/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "ParticleSystemLayer.h"
#import "NSDictionary+Stuff.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;


#pragma mark - Particle System

@implementation ParticleSystem

@synthesize loc;
@synthesize norm;

@end


#pragma mark - Particle System Info

@interface ParticleSystemInfo : NSObject 
{
    SimpleIdentity destId;
    NSArray *systems;
    NSDictionary *desc;
}

@property (nonatomic,assign) SimpleIdentity destId;
@property (nonatomic,retain) NSArray *systems;
@property (nonatomic,retain) NSDictionary *desc;

- (id)initWithSystems:(NSArray *)inSystems desc:(NSDictionary *)inDesc;

@end

@implementation ParticleSystemInfo

@synthesize destId;
@synthesize systems;
@synthesize desc;

- (id)initWithSystems:(NSArray *)inSystems desc:(NSDictionary *)inDesc
{
    self = [super init];
    if (self)
    {
        self.systems = inSystems;
        self.desc = inDesc;
    }
    
    return self;
}

- (void)dealloc
{
    self.systems = nil;
    self.desc = nil;
    
    [super dealloc];
}

@end


#pragma mark - Particle System Layer

@interface ParticleSystemLayer()

@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;

@end

@implementation ParticleSystemLayer

@synthesize layerThread;

- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
    self.layerThread = inLayerThread;
    scene = inScene;
    
    // Add the Particle Generator to the scene
    // This will create particles for us every frame
    ParticleGenerator *gen = new ParticleGenerator(16384);
    generatorId = gen->getId();
    scene->addChangeRequest(new AddGeneratorReq(gen));
}

// Parse the basic particle system parameters out of an NSDictionary
- (ParticleGenerator::ParticleSystem)parseParams:(NSDictionary *)desc defaultSystem:(ParticleGenerator::ParticleSystem *)defaultParams
{
    ParticleGenerator::ParticleSystem params;
    if (defaultParams)
        params = *defaultParams;
    
    params.minLength = [desc floatForKey:@"minLength" default:params.minLength];
    params.maxLength = [desc floatForKey:@"maxLength" default:params.maxLength];
    params.numPerSecMin = [desc intForKey:@"minNumPerSec" default:params.numPerSecMin];
    params.numPerSecMax = [desc intForKey:@"maxNumPerSec" default:params.numPerSecMax];
    params.minLifetime = [desc floatForKey:@"minLifetime" default:params.minLifetime];
    params.maxLifetime = [desc floatForKey:@"maxLifetime" default:params.maxLifetime];
    params.minVis = [desc floatForKey:@"minVis" default:DrawVisibleInvalid];
    params.maxVis = [desc floatForKey:@"maxVis" default:DrawVisibleInvalid];

    return params;
}

// Do the actual work off setting up and adding one or more particle systems
- (void)runAddSystems:(ParticleSystemInfo *)systemInfo
{
    // Parse out the general parameters
    ParticleGenerator::ParticleSystem defaultSystem = ParticleGenerator::ParticleSystem::makeDefault();
    ParticleGenerator::ParticleSystem baseParams = [self parseParams:systemInfo.desc defaultSystem:&defaultSystem];

    // Now run through the particle systems and kick them off
    for (ParticleSystem *partSys in systemInfo.systems)
    {
        // Set up the specifics of this one
        ParticleGenerator::ParticleSystem *newPartSys = new ParticleGenerator::ParticleSystem(baseParams);
        newPartSys->loc = PointFromGeo([partSys loc]);
        // Note: Won't work at the poles
        newPartSys->dirUp = [partSys norm];
        newPartSys->dirE = Vector3f(0,0,1).cross(newPartSys->dirUp);
        newPartSys->dirN = newPartSys->dirUp.cross(newPartSys->dirE);
        
        // Hand it off to the renderer
        newPartSys->setId(systemInfo.destId);
        scene->addChangeRequest(new ParticleGeneratorAddSystemRequest(generatorId,newPartSys));
    }
}

// Add a single particle system
- (SimpleIdentity) addParticleSystem:(ParticleSystem *)partSystem desc:(NSDictionary *)desc
{
    ParticleSystemInfo *systemInfo = [[[ParticleSystemInfo alloc] initWithSystems:[NSArray arrayWithObject:partSystem] desc:desc] autorelease];
    systemInfo.destId = Identifiable::genId();
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddSystems:systemInfo];
    else
        [self performSelector:@selector(runAddSystems:) onThread:layerThread withObject:systemInfo waitUntilDone:NO];
    
    return systemInfo.destId;
}


@end