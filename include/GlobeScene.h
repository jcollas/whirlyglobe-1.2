//
//  GlobeScene.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

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

namespace WhirlyGlobe 
{
	
/* Change Requests
	These are change requests made to the scene.
	The renderer has to do these to avoid thread conflicts
	 and manage OpenGL resources.
 */

// Add the given texture 
// Scene is responsible for deleting texture
typedef struct 
{
	Texture *tex;
} ChangeReq_AddTexture;
	
// Remove the given texture.  Will also delete
typedef struct
{
	SimpleIdentity texture;
} ChangeReq_RemTexture;

// Add the given drawable.  We'll sort it into cullables
typedef struct 
{
	Drawable *drawable;
} ChangeReq_AddDrawable;

// Remove the given drawable
// This will eventually delete it
typedef struct 
{
	SimpleIdentity drawable;
} ChangeReq_RemDrawable;
	
// Change a given drawable's color
typedef struct
{
	SimpleIdentity drawable;
	unsigned char color[4];
} ChangeReq_ColorDrawable;
	
// Turn a given drawable on/off
typedef struct
{
	SimpleIdentity drawable;
	bool newOnOff;
} ChangeReq_OnOffDrawable;

typedef enum {CR_AddTexture,CR_RemTexture,CR_AddDrawable,CR_RemDrawable,CR_ColorDrawable,CR_OnOffDrawable} ChangeRequestType;
	
// Single change request
class ChangeRequest
{
public:
	ChangeRequestType type;
	union {
		ChangeReq_AddTexture addTexture;
		ChangeReq_RemTexture remTexture;
		ChangeReq_AddDrawable addDrawable;
		ChangeReq_RemDrawable remDrawable;
		ChangeReq_ColorDrawable colorDrawable;
		ChangeReq_OnOffDrawable onOffDrawable;
	} info;
	
	// Convenience routines for generating the various requests
	static ChangeRequest AddTextureCR(Texture *tex);
	static ChangeRequest RemTextureCR(SimpleIdentity);
	static ChangeRequest AddDrawableCR(Drawable *drawable);
	static ChangeRequest RemDrawableCR(SimpleIdentity);
	static ChangeRequest ColorDrawableCR(SimpleIdentity, RGBAColor);
	static ChangeRequest OnOffDrawable(SimpleIdentity, bool);
};

/* GlobeScene
	The top level scene object.  Keeps track of drawables
     which are sorted into Cullables.
 */
class GlobeScene
{
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
	void addChangeRequests(const std::vector<ChangeRequest> &newchanges);
	void addChangeRequest(const ChangeRequest &newChange);
	
	// Look for a valid texture
	GLuint getGLTexture(SimpleIdentity texIdent);
	
	// Process change requests
	// Only the renderer should call this in the rendering thread
	// Note: Should give this a time limit
	void processChanges();
	
protected:
	// Given a geo mbr, return all the overlapping cullables
	void overlapping(GeoMbr geoMbr,std::vector<Cullable *> &cullables);
	
	// Remove the given drawable from the cullables
	// Note: This could be optimized
	void removeFromCullables(Drawable *drawable);

	// Cullable grid dimensions
	unsigned int numX,numY;

	// Array of active cullables.  Static after construction for now
	Cullable *cullables;
	
	// All the drawables we've been handed
	typedef std::map<SimpleIdentity,Drawable *> DrawableMap;
	DrawableMap drawables;
	
	// We refer to textures this way
	typedef std::map<SimpleIdentity,Texture *> TextureMap;
	TextureMap textures;
	
	// We keep a list of change requests to execute
	// This can be accessed in multiple threads, so we lock it
	pthread_mutex_t changeRequestLock;
	std::vector<ChangeRequest> changeRequests;
};
	
}
