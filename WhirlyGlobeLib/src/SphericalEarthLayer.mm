/*
 *  SphericalEarth.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/11/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "SphericalEarthLayer.h"
#import "UIImage+Stuff.h"
#import "GlobeMath.h"

namespace WhirlyGlobe
{
	
SphericalEarthLayer::SphericalEarthLayer(TextureGroup *texGroup)
	: xDim(texGroup.numX), yDim(texGroup.numY), texGroup(texGroup), done(false)
{
}
	
SphericalEarthLayer::~SphericalEarthLayer()
{
}

// Generate a list of drawables based on sphere, but broken
//  up to match the given texture group
// Note: Need to break this up over time a bit
void SphericalEarthLayer::process(GlobeScene *scene)
{
	if (done)
		return;
	done = true;
	
	// Unit size of each tesselation, basically
	GeoCoord geoIncr(2*M_PI/(texGroup.numX*SphereTessX),M_PI/(texGroup.numY*SphereTessY));
	
	// Texture increment for each tesselation
	TexCoord texIncr(1.0/(float)SphereTessX,1.0/(float)SphereTessY);
	
	// We're viewing this as a parameterization from ([0->1.0],[0->1.0]) so we'll
	//  break up these coordinates accordingly
	Point2f paramSize(1.0/(texGroup.numX*SphereTessX),1.0/(texGroup.numY*SphereTessY));
	for (unsigned int chunkX=0;chunkX<texGroup.numX;chunkX++)
		for (unsigned int chunkY=0;chunkY<texGroup.numY;chunkY++)
		{
			// Need the four corners to set up the cullable
			GeoCoord geoLL(-M_PI + (chunkX*SphereTessX)*geoIncr.x(),-M_PI/2.0 + (chunkY*SphereTessY)*geoIncr.y());
			GeoCoord geoUR(geoLL.x()+SphereTessX*geoIncr.x(),geoLL.y()+SphereTessY*geoIncr.y());

			// We'll set up and fill in the drawable
			BasicDrawable *chunk = new BasicDrawable((SphereTessX+1)*(SphereTessY+1),2*SphereTessX*SphereTessY);
			chunk->setType(GL_TRIANGLES);
			chunk->setGeoMbr(GeoMbr(geoLL,geoUR));
//			chunk->type = GL_POINTS;
//			chunk->type = (chunkX & 0x1) ? GL_TRIANGLES : GL_POINTS;

			// Generate points, texture coords, and normals first
			for (unsigned int iy=0;iy<SphereTessY+1;iy++)
				for (unsigned int ix=0;ix<SphereTessX+1;ix++)
				{
					// Generate the geographic location and clamp for safety
					GeoCoord geoLoc(-M_PI + (chunkX*SphereTessX+ix)*geoIncr.x(),-M_PI/2.0 + (chunkY*SphereTessY+iy)*geoIncr.y());
					if (geoLoc.x() < -M_PI)  geoLoc.x() = -M_PI;
					if (geoLoc.x() > M_PI) geoLoc.x() = M_PI;
					if (geoLoc.y() < -M_PI/2.0)  geoLoc.y() = -M_PI/2.0;
					if (geoLoc.y() > M_PI/2.0) geoLoc.y() = M_PI/2.0;
					
					// Physical location from that
					Point3f loc = PointFromGeo(geoLoc);
					
					// Do the texture coordinate seperately
					TexCoord texCoord(ix*texIncr.x(),1.0f-iy*texIncr.y());
					if (texCoord.x() > 1.0)  texCoord.x() = 1.0;
					if (texCoord.y() > 1.0)  texCoord.y() = 1.0;
					
					chunk->addPoint(loc);
					chunk->addTexCoord(texCoord);
					chunk->addNormal(loc);
				}
			
			// Two triangles per cell
			for (unsigned int iy=0;iy<SphereTessY;iy++)
			{
				for (unsigned int ix=0;ix<SphereTessX;ix++)
				{
					BasicDrawable::Triangle triA,triB;
					triA.verts[0] = iy*(SphereTessX+1)+ix;
					triA.verts[1] = iy*(SphereTessX+1)+(ix+1);
					triA.verts[2] = (iy+1)*(SphereTessX+1)+(ix+1);
					triB.verts[0] = triA.verts[0];
					triB.verts[1] = triA.verts[2];
					triB.verts[2] = (iy+1)*(SphereTessX+1)+ix;
					chunk->addTriangle(triA);
					chunk->addTriangle(triB);
				}
			}

			// Now for the changes to the scenegraph
			std::vector<ChangeRequest> changeRequests;

			// Ask for a new texture and wire it to the drawable
			Texture *tex = new Texture([texGroup generateFileNameX:chunkX y:chunkY],texGroup.ext);
			changeRequests.push_back(ChangeRequest::AddTextureCR(tex));
			chunk->setTexId(tex->getId());
			changeRequests.push_back(ChangeRequest::AddDrawableCR(chunk));

			// This should make the changes appear
			scene->addChangeRequests(changeRequests);

//			if (chunk->type == GL_POINTS)
//				chunk->textureId = 0;
		}
}

}