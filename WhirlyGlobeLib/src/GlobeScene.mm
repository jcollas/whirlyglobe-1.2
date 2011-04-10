//
//  GlobeScene.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "GlobeScene.h"
#import "GlobeView.h"
#import "GlobeMath.h"

namespace WhirlyGlobe 
{

GlobeScene::GlobeScene(unsigned int numX, unsigned int numY)
	: numX(numX), numY(numY)
{
	cullables = new Cullable [numX*numY];

	// Set up the various MBRs
	GeoCoord geoIncr(2*M_PI/numX,M_PI/numY);
	for (unsigned int iy=0;iy<numY;iy++)
	{
		for (unsigned int ix=0;ix<numX;ix++)
		{
			// Set up the extents for each cullable
			GeoCoord geoLL(-M_PI + ix*geoIncr.x(),-M_PI/2.0 + iy*geoIncr.y());
			GeoCoord geoUR(geoLL.x() + geoIncr.x(),geoLL.y() + geoIncr.y());
			Cullable &cullable = cullables[iy*numX+ix];
			cullable.setGeoMbr(GeoMbr(geoLL,geoUR));
		}
	}
	
	pthread_mutex_init(&changeRequestLock,NULL);
}

GlobeScene::~GlobeScene()
{
	delete [] cullables;
	for (DrawableSet::iterator it = drawables.begin(); it != drawables.end(); ++it)
		delete *it;
	for (TextureSet::iterator it = textures.begin(); it != textures.end(); ++it)
		delete *it;
	
	pthread_mutex_destroy(&changeRequestLock);
	
	for (unsigned int ii=0;ii<changeRequests.size();ii++)
		delete changeRequests[ii];
	changeRequests.clear();
}

// Return a list of overlapping cullables, given the geo MBR
// Note: This could be a lot smarter
void GlobeScene::overlapping(GeoMbr geoMbr,std::vector<Cullable *> &foundCullables)
{
	foundCullables.clear();
	for (unsigned int ii=0;ii<numX*numY;ii++)
	{
		Cullable *cullable = &cullables[ii];
		if (geoMbr.overlaps(cullable->geoMbr))
			foundCullables.push_back(cullable);
	}
}

// Remove the given drawable from all the cullables
// Note: Optimize this
void GlobeScene::removeFromCullables(Drawable *drawable)
{
	for (unsigned int ii=0;ii<numX*numY;ii++)
	{
		Cullable &cullable = cullables[ii];
		cullable.remDrawable(drawable);
	}
}
	
// Add change requests to our list
void GlobeScene::addChangeRequests(const std::vector<ChangeRequest *> &newChanges)
{
	pthread_mutex_lock(&changeRequestLock);
	
	changeRequests.insert(changeRequests.end(),newChanges.begin(),newChanges.end());
	
	pthread_mutex_unlock(&changeRequestLock);
}
	
// Add a single change request
void GlobeScene::addChangeRequest(ChangeRequest *newChange)
{
	pthread_mutex_lock(&changeRequestLock);

	changeRequests.push_back(newChange);

	pthread_mutex_unlock(&changeRequestLock);
}
	
GLuint GlobeScene::getGLTexture(SimpleIdentity texIdent)
{
	Texture dumbTex;
	dumbTex.setId(texIdent);
	TextureSet::iterator it = textures.find(&dumbTex);
	if (it != textures.end())
		return (*it)->getGLId();
	
	return 0;
}
	
Drawable *GlobeScene::getDrawable(SimpleIdentity drawId)
{
	BasicDrawable dumbDraw;
	dumbDraw.setId(drawId);
	GlobeScene::DrawableSet::iterator it = drawables.find(&dumbDraw);
	if (it != drawables.end())
		return *it;
	
	return NULL;
}
	
Texture *GlobeScene::getTexture(SimpleIdentity texId)
{
	Texture dumbTex;
	dumbTex.setId(texId);
	GlobeScene::TextureSet::iterator it = textures.find(&dumbTex);
	if (it != textures.end())
		return *it;
	
	return NULL;
}

// Process outstanding changes.
// We'll grab the lock and we're only expecting to be called in the rendering thread
void GlobeScene::processChanges(WhirlyGlobeView *view)
{
	std::vector<Cullable *> foundCullables;
	
	// We're not willing to wait in the rendering thread
	if (!pthread_mutex_trylock(&changeRequestLock))
	{
		for (unsigned int ii=0;ii<changeRequests.size();ii++)
		{
			ChangeRequest *req = changeRequests[ii];
			req->execute(this,view);
			delete req;
		}
		changeRequests.clear();
		
		pthread_mutex_unlock(&changeRequestLock);
	}
}
	
void AddTextureReq::execute(GlobeScene *scene,WhirlyGlobeView *view)
{
	tex->createInGL(true);
	scene->textures.insert(tex);
	tex = NULL;
}
	
void RemTextureReq::execute(GlobeScene *scene,WhirlyGlobeView *view)
{
	Texture dumbTex;
	dumbTex.setId(texture);
	GlobeScene::TextureSet::iterator it = scene->textures.find(&dumbTex);
	if (it != scene->textures.end())
	{
		Texture *tex = *it;
		tex->destroyInGL();
		scene->textures.erase(it);
		delete tex;
	}
}

void AddDrawableReq::execute(GlobeScene *scene,WhirlyGlobeView *view)
{
	// Add the drawable
	scene->drawables.insert(drawable);
	
	// Sort into cullables
	// Note: Need a more selective MBR check.  We're going to catch edge overlaps
	std::vector<Cullable *> foundCullables;
	scene->overlapping(drawable->getGeoMbr(),foundCullables);
	for (unsigned int ci=0;ci<foundCullables.size();ci++)
		foundCullables[ci]->addDrawable(drawable);
		
	// Initialize any OpenGL foo
	// Note: Make the Z offset a parameter
	drawable->setupGL([view calcZbufferRes]);
	
	drawable = NULL;
}
	
void RemDrawableReq::execute(GlobeScene *scene,WhirlyGlobeView *view)
{
	BasicDrawable dumbDraw;
	dumbDraw.setId(drawable);
	GlobeScene::DrawableSet::iterator it = scene->drawables.find(&dumbDraw);
	if (it != scene->drawables.end())
	{
		Drawable *theDrawable = *it;
		scene->removeFromCullables(theDrawable);
		
		scene->drawables.erase(it);
		// Teardown OpenGL foo
		theDrawable->teardownGL();
		// And delete
		delete theDrawable;
	}
}

}