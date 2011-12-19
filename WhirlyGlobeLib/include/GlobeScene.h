/*
 *  GlobeScene.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/3/11.
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


#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <vector>
#import <set>
#import "WhirlyVector.h"
#import "Texture.h"
#import "Cullable.h"
#import "Drawable.h"
#import "Generator.h"
#import "GlobeView.h"

namespace WhirlyGlobe 
{
    
class SubTexture;

/// Request that the renderer add the given texture.
/// This will make it available for use by its ID
class AddTextureReq : public ChangeRequest
{
public:
    /// Construct with a texture
    /// You are not responsible for deleteing the texture after this
	AddTextureReq(Texture *tex) : tex(tex) { }
    /// If the texture hasn't been added to the renderer, clean it up
	~AddTextureReq() { if (tex) delete tex; tex = NULL; }

	/// Add to the renderer.  Never call this.
	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
protected:
	Texture *tex;
};

/// Remove a texture referred to by ID
class RemTextureReq : public ChangeRequest
{
public:
    /// Construct with the ID
	RemTextureReq(SimpleIdentity texId) : texture(texId) { }

    /// Remove from the renderer.  Never call this.
	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
protected:
	SimpleIdentity texture;
};

/// Ask the renderer to add the drawable to the scene
class AddDrawableReq : public ChangeRequest
{
public:
    /// Construct with a drawable.  You're not responsible for deletion
	AddDrawableReq(Drawable *drawable) : drawable(drawable) { }
    /// If the drawable wasn't used, delete it
	~AddDrawableReq() { if (drawable) delete drawable; drawable = NULL; }

	/// Add to the renderer.  Never call this
	void execute(GlobeScene *scene,WhirlyGlobeView *view);	
	
protected:
	Drawable *drawable;
};

/// Ask the renderer to remove the drawable from the scene
class RemDrawableReq : public ChangeRequest
{
public:
    /// Construct with the drawable ID and an optional fade interval
	RemDrawableReq(SimpleIdentity drawId) : drawable(drawId) { }

    /// Remove the drawable.  Never call this
	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
protected:	
	SimpleIdentity drawable;
};	

/// Add a Drawable Generator to the scene
class AddGeneratorReq : public ChangeRequest
{
public:
    /// Construct with the generator ID
    AddGeneratorReq(Generator *generator) : generator(generator) { }

    /// Add to the renderer.  Never call this.
    void execute(GlobeScene *scene,WhirlyGlobeView *view);
    
protected:
    Generator *generator;
};
    
/// Remove the Drawable Generator from the scene
class RemGeneratorReq : public ChangeRequest
{
public:
    /// Construct with the generator ID
    RemGeneratorReq(SimpleIdentity genId) : genId(genId) { }
    
    /// Remove from the renderer.  Never call this.
    void execute(GlobeScene *scene,WhirlyGlobeView *view);
    
protected:
    SimpleIdentity genId;
};
    
/// Sorted set of generators
typedef std::set<Generator *,IdentifiableSorter> GeneratorSet;
    
/** GlobeScene is the top level scene object.
    It keeps track of the drawables by sorting them into
     cullables and it handles the change requests, which
     consist of pretty much everything that can happen.
 
    The developer never interacts with this.
 */
class GlobeScene
{
	friend class ChangeRequest;
public:
	/// Construct with the grid size of the cullables
    /// The earth will be divided up into these pieces
	GlobeScene(unsigned int numX,unsigned int numY);
	~GlobeScene();

	/// Get the cullable grid size
	void getCullableSize(unsigned int &numX,unsigned int &numY) { numX = this->numX;  numY = this->numY; }
	
	/// Return a particular cullable
	const Cullable * getCullable(unsigned int x,unsigned int y) { return &cullables[y*numX+x]; }
	
	/// Full list of cullables (for the renderer)
	const Cullable *getCullables() { return cullables; }
    
    /// Full set of Generators
    const GeneratorSet *getGenerators() { return &generators; }

	/// Add a single change request.  You can call this from any thread, it locks.
    /// If you have more than one, don't iterate, use the other version.
	void addChangeRequest(ChangeRequest *newChange);
    /// Add a list of change requets.  You can call this from any thread.
    /// This is the faster option if you have more than one change request
	void addChangeRequests(const std::vector<ChangeRequest *> &newchanges);
	
	/// Look for a valid texture
    /// If it's missing, we probably won't draw the associated geometry
	GLuint getGLTexture(SimpleIdentity texIdent);
	
	/// Process change requests
	/// Only the renderer should call this in the rendering thread
	// Note: Should give this a time limit
	void processChanges(WhirlyGlobeView *view);
    
    /// Add sub texture mappings.
    /// These are mappings from images to parts of texture atlases.
    /// They're here so we can use SimpleIdentity's to point into larger
    ///  textures.  Layer side only.  The rendering engine doesn't use them.
    void addSubTexture(const SubTexture &);
    void addSubTextures(const std::vector<SubTexture> &);
    
    /// Return a sub texture by ID.  The idea being we can use these
    ///  the same way we use full texture IDs.
    SubTexture getSubTexture(SimpleIdentity subTexId);
	
public:
	/// Given a geo mbr, return all the overlapping cullables
	void overlapping(GeoMbr geoMbr,std::vector<Cullable *> &cullables);
	
	/// Remove the given drawable from the cullables
	// Note: This could be optimized
	void removeFromCullables(Drawable *drawable);
    
    /// Look for a Draw Generator by ID
    Generator *getGenerator(SimpleIdentity genId);
	
	/// Look for a Drawable by ID
	Drawable *getDrawable(SimpleIdentity drawId);
	
	/// Look for a Texture by ID
	Texture *getTexture(SimpleIdentity texId);
    
    /// All the drawable generators we've been handed, sorted by ID
    GeneratorSet generators;

	/// Cullable grid dimensions
	unsigned int numX,numY;

	/// Array of active cullables.  Static after construction for now
	Cullable *cullables;
	
	typedef std::set<Drawable *,IdentifiableSorter> DrawableSet;
	/// All the drawables we've been handed, sorted by ID
	DrawableSet drawables;
	
	typedef std::set<Texture *,IdentifiableSorter> TextureSet;
	/// Textures, sorted by ID
	TextureSet textures;
	
	pthread_mutex_t changeRequestLock;
	/// We keep a list of change requests to execute
	/// This can be accessed in multiple threads, so we lock it
	std::vector<ChangeRequest *> changeRequests;
    
    typedef std::set<SubTexture> SubTextureSet;
    /// Mappings from images to parts of texture atlases
    SubTextureSet subTextureMap;
};
	
}
