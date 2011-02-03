//
//  GlobeScene.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "GlobeScene.h"
#import "GlobeMath.h"

namespace WhirlyGlobe 
{
	
ChangeRequest ChangeRequest::AddTextureCR(Texture *tex)
{
	ChangeRequest req;
	req.type = CR_AddTexture;
	req.info.addTexture.tex = tex;
	
	return req;
}
	
ChangeRequest ChangeRequest::AddDrawableCR(Drawable *drawable)
{
	ChangeRequest req;
	req.type = CR_AddDrawable;
	req.info.addDrawable.drawable = drawable;
	
	return req;
}
	
ChangeRequest ChangeRequest::RemDrawableCR(SimpleIdentity drawable)
{
	ChangeRequest req;
	req.type = CR_RemDrawable;
	req.info.remDrawable.drawable = drawable;
	
	return req;
}

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
	for (DrawableMap::iterator it = drawables.begin(); it != drawables.end(); ++it)
		delete it->second;
	for (TextureMap::iterator it = textures.begin(); it != textures.end(); ++it)
		delete it->second;
	
	pthread_mutex_destroy(&changeRequestLock);
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
	
// Add change requests to our list
void GlobeScene::addChangeRequests(const std::vector<ChangeRequest> &newChanges)
{
	pthread_mutex_lock(&changeRequestLock);
	
	changeRequests.insert(changeRequests.end(),newChanges.begin(),newChanges.end());
	
	pthread_mutex_unlock(&changeRequestLock);
}
	
// Add a single change request
void GlobeScene::addChangeRequest(const ChangeRequest &newChange)
{
	changeRequests.push_back(newChange);
}
	
GLuint GlobeScene::getGLTexture(SimpleIdentity texIdent)
{
	TextureMap::iterator it = textures.find(texIdent);
	if (it != textures.end())
		return it->second->getGLId();
	
	return 0;
}

// Process outstanding changes.
// We'll grab the lock and we're only expecting to be called in the rendering thread
void GlobeScene::processChanges()
{
	std::vector<Cullable *> foundCullables;
	
	// We're not willing to wait in the rendering thread
	if (!pthread_mutex_trylock(&changeRequestLock))
	{
		for (unsigned int ii=0;ii<changeRequests.size();ii++)
		{
			ChangeRequest &req = changeRequests[ii];
			switch (req.type)
			{
				case CR_AddTexture:
				{
					Texture *theTex = req.info.addTexture.tex;
					theTex->createInGL();
					textures[theTex->getId()] = theTex;
				}
					break;
				case CR_AddDrawable:
				{
					// Add the drawable
					Drawable *theDrawable = req.info.addDrawable.drawable;
					drawables[theDrawable->getId()] = theDrawable;
					
					// Sort into cullables
					// Note: Need a more selective MBR check.  We're going to catch edge overlaps
					foundCullables.clear();
					overlapping(theDrawable->getGeoMbr(),foundCullables);
					for (unsigned int ci=0;ci<foundCullables.size();ci++)
						foundCullables[ci]->addDrawable(theDrawable);
				}
					break;
				case CR_RemDrawable:
				{
					DrawableMap::iterator it = drawables.find(req.info.remDrawable.drawable);
					if (it != drawables.end())
					{
						Drawable *drawable = it->second;
						drawables.erase(it);
						delete drawable;
					}
				}
					break;
			}
		}
		changeRequests.clear();
		
		pthread_mutex_unlock(&changeRequestLock);
	}
}

}
