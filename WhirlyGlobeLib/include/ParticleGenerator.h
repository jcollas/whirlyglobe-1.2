/*
 *  ParticleGenerator.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 10/12/11.
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
#import "Generator.h"

namespace WhirlyGlobe
{
    
class ParticleGenerator : public Generator
{
public:
    ParticleGenerator(int maxNumParticles);
    virtual ~ParticleGenerator();
    
    /// Generate the list of drawables per frame
    void generateDrawables(RendererFrameInfo *frameInfo,std::vector<Drawable *> &drawables);
    
    // Representation of single particle
    class Particle
    {
    public:
        Point3f loc;
        Vector3f dir;    // Normalized
        RGBAColor color;
        float velocity;  // Distance per second
        CFTimeInterval expiration;
    };
    
    // Low level representation of a particle system
    class ParticleSystem : public Identifiable
    {
    public:
        ParticleSystem() : Identifiable() { }
        ~ParticleSystem() { }
        
        // Return a reasonable set of defaults
        static ParticleSystem makeDefault();

        // Make a new randomized paticle
        Particle generateParticle();
        
        // Location and direction
        Point3f loc;
        Vector3f dirN,dirE,dirUp;
        // Randomized length over the hemisphere
        float minLength,maxLength;
        // Randomized lifetime and generation
        int numPerSecMin,numPerSecMax;
        float minLifetime,maxLifetime;
        // Range of the angle from the normal out to -normal
        float minPhi,maxPhi;
        // Colors, random selection
        std::vector<RGBAColor> colors;
        // These are visibility parameters, not randomized
        float minVis,maxVis;
    };
    
    // Add a particle system to the mix
    void addParticleSystem(ParticleSystem *particleSystem);

    // Remove a particle system by ID
    void removeParticleSystem(SimpleIdentity systemId);
    
protected:
    // All times are offset from here
    CFTimeInterval startTime;
    // When we last updated
    CFTimeInterval lastUpdateTime;

    int maxNumParticles;  // All the particles we can have at once.  Ever.
    std::vector<Particle> particles;
    typedef std::set<ParticleSystem *,IdentifiableSorter> ParticleSystemSet;
    ParticleSystemSet particleSystems;
};
    

class ParticleGeneratorAddSystemRequest : public GeneratorChangeRequest
{
public:
    ParticleGeneratorAddSystemRequest(SimpleIdentity generatorID,ParticleGenerator::ParticleSystem *partSystem);
    ~ParticleGeneratorAddSystemRequest();

    virtual void execute2(GlobeScene *scene,Generator *gen);
    
protected:
    ParticleGenerator::ParticleSystem *system;
};

    
class ParticleGeneratorRemSystemRequest : public GeneratorChangeRequest
{
public:
    ParticleGeneratorRemSystemRequest(SimpleIdentity generatorID,SimpleIdentity systemId);
    ~ParticleGeneratorRemSystemRequest() { }
    
    virtual void execute2(GlobeScene *scene,Generator *gen);
    
protected:
    SimpleIdentity systemId;
};
    
}