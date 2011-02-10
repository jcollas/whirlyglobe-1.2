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
	
ChangeRequest ChangeRequest::RemTextureCR(SimpleIdentity tex)
{
	ChangeRequest req;
	req.type = CR_RemTexture;
	req.info.remTexture.texture = tex;
	
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
	
ChangeRequest ChangeRequest::ColorDrawableCR(SimpleIdentity drawable, RGBAColor color)
{
	ChangeRequest req;
	req.type = CR_ColorDrawable;
	req.info.colorDrawable.drawable = drawable;
	req.info.colorDrawable.color[0] = color.r;
	req.info.colorDrawable.color[1] = color.g;
	req.info.colorDrawable.color[2] = color.b;
	req.info.colorDrawable.color[3] = color.a;
	
	return req;
}
	
ChangeRequest ChangeRequest::OnOffDrawable(SimpleIdentity drawable, bool newOnOff)
{
	ChangeRequest req;
	req.type = CR_OnOffDrawable;
	req.info.onOffDrawable.drawable = drawable;
	req.info.onOffDrawable.newOnOff = newOnOff;
	
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
void GlobeScene::addChangeRequests(const std::vector<ChangeRequest> &newChanges)
{
	pthread_mutex_lock(&changeRequestLock);
	
	changeRequests.insert(changeRequests.end(),newChanges.begin(),newChanges.end());
	
	pthread_mutex_unlock(&changeRequestLock);
}
	
// Add a single change request
void GlobeScene::addChangeRequest(const ChangeRequest &newChange)
{
	pthread_mutex_lock(&changeRequestLock);

	changeRequests.push_back(newChange);

	pthread_mutex_unlock(&changeRequestLock);
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
				case CR_RemTexture:
				{
					TextureMap::iterator it = textures.find(req.info.remTexture.texture);
					if (it != textures.end())
					{
						Texture *tex = it->second;
						tex->destroyInGL();
						textures.erase(it);
						delete tex;
					}
					break;
				}
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
					
					// Initialize any OpenGL foo
					theDrawable->setupGL();
				}
					break;
				case CR_RemDrawable:
				{
					DrawableMap::iterator it = drawables.find(req.info.remDrawable.drawable);
					if (it != drawables.end())
					{
						Drawable *drawable = it->second;
						removeFromCullables(drawable);
						
						drawables.erase(it);
						// Teardown OpenGL foo
						drawable->teardownGL();
						// And delete
						delete drawable;
					}
					break;
				}
					break;
				case CR_ColorDrawable:
				{
					DrawableMap::iterator it = drawables.find(req.info.colorDrawable.drawable);
					if (it != drawables.end())
					{
						Drawable *drawable = it->second;
						BasicDrawable *basicDrawable = dynamic_cast<BasicDrawable *> (drawable);
						if (basicDrawable)
							basicDrawable->setColor(req.info.colorDrawable.color);
					}
				}
				case CR_OnOffDrawable:
				{
					DrawableMap::iterator it = drawables.find(req.info.onOffDrawable.drawable);
					if (it != drawables.end())
					{
						Drawable *drawable = it->second;
						BasicDrawable *basicDrawable = dynamic_cast<BasicDrawable *> (drawable);
						if (basicDrawable)
							basicDrawable->setOnOff(req.info.onOffDrawable.newOnOff);
					}
				}
			}
		}
		changeRequests.clear();
		
		pthread_mutex_unlock(&changeRequestLock);
	}
}

}
