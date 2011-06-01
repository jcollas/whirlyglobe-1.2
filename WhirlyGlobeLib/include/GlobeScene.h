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
#import "GlobeView.h"

namespace WhirlyGlobe 
{
	
// Add the given texture 
// If we get deleted before doing that, delete the texture as well
class AddTextureReq : public ChangeRequest
{
public:
	AddTextureReq(Texture *tex) : tex(tex) { }
	~AddTextureReq() { if (tex) delete tex; tex = NULL; }
	
	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
protected:
	Texture *tex;
};
	
// Remove and delete the given texture
class RemTextureReq : public ChangeRequest
{
public:
	RemTextureReq(SimpleIdentity texId) : texture(texId) { }

	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
protected:
	SimpleIdentity texture;
};

// Add the given drawable.  We'll sort it into cullables
class AddDrawableReq : public ChangeRequest
{
public:
	AddDrawableReq(Drawable *drawable) : drawable(drawable) { }
	AddDrawableReq() { if (drawable) delete drawable; drawable = NULL; }
	
	void execute(GlobeScene *scene,WhirlyGlobeView *view);	
	
protected:
	Drawable *drawable;
};

// Remove the drawable from the scene and delete it
class RemDrawableReq : public ChangeRequest
{
public:
	RemDrawableReq(SimpleIdentity drawId) : drawable(drawId) { }

	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
protected:	
	SimpleIdentity drawable;
};	

/* GlobeScene
	The top level scene object.  Keeps track of drawables
     which are sorted into Cullables.
 */
class GlobeScene
{
	friend class ChangeRequest;
public:
	// Construct with the grid size of the cullables
	GlobeScene(unsigned int numX,unsigned int numY);
	~GlobeScene();

	// Get the cullable grid size
	void getCullableSize(unsigned int &numX,unsigned int &numY) { numX = this->numX;  numY = this->numY; }
	
	// Return a particular cullable
	const Cullable * getCullable(unsigned int x,unsigned int y) { return &cullables[y*numX+x]; }
	
	// Full list of cullables (for the renderer)
	const Cullable *getCullables() { return cullables; }
	
	// Put together your change requests and then hand them over all at once
	// If you do them one by one, there's too much locking
	// Call this in any thread
	void addChangeRequests(const std::vector<ChangeRequest *> &newchanges);
	void addChangeRequest(ChangeRequest *newChange);
	
	// Look for a valid texture
	GLuint getGLTexture(SimpleIdentity texIdent);
	
	// Process change requests
	// Only the renderer should call this in the rendering thread
	// Note: Should give this a time limit
	void processChanges(WhirlyGlobeView *view);
	
public:
	// Given a geo mbr, return all the overlapping cullables
	void overlapping(GeoMbr geoMbr,std::vector<Cullable *> &cullables);
	
	// Remove the given drawable from the cullables
	// Note: This could be optimized
	void removeFromCullables(Drawable *drawable);
	
	// Look for a Drawable by ID
	Drawable *getDrawable(SimpleIdentity drawId);
	
	// Look for a Texture by ID
	Texture *getTexture(SimpleIdentity texId);

	// Cullable grid dimensions
	unsigned int numX,numY;

	// Array of active cullables.  Static after construction for now
	Cullable *cullables;
	
	// All the drawables we've been handed, sorted by ID
	typedef std::set<Drawable *,IdentifiableSorter> DrawableSet;
	DrawableSet drawables;
	
	// Textures, sorted by ID
	typedef std::set<Texture *,IdentifiableSorter> TextureSet;
	TextureSet textures;
	
	// We keep a list of change requests to execute
	// This can be accessed in multiple threads, so we lock it
	pthread_mutex_t changeRequestLock;
	std::vector<ChangeRequest *> changeRequests;
};
	
}
