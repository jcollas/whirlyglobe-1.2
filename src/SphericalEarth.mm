/*
 *  SphericalEarth.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/11/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "SphericalEarth.h"
#import "UIImage+Stuff.h"

namespace WhirlyGlobe
{

Point3f PointFromGeo(GeoCoord geo) 
{ 
	float z = sinf(geo.lat());
	float rad = sqrtf(1.0-z*z);
	Point3f pt(rad*cosf(geo.lon()),rad*sinf(geo.lon()),z);
	return pt;
}
	
void SphericalEarthModel::clear()
{
	for (unsigned int ii=0;ii<cullables.size();ii++)
		delete cullables[ii];
	cullables.clear();
	for (unsigned int ii=0;ii<drawables.size();ii++)
		delete drawables[ii];
	drawables.clear();
}

SphericalEarthModel::~SphericalEarthModel()
{
	clear();
}

// Generate a list of drawables based on sphere, but broken
//  up to match the given texture group
void SphericalEarthModel::generate(TextureGroup *texGroup)
{
	clear();
	
	xDim = texGroup.numX;  yDim = texGroup.numY;
	cullables.resize(xDim*yDim,NULL);
	drawables.resize(xDim*yDim,NULL);
	
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
			
			// Set up the cullable and a drawable underneath that
			Cullable *cullable = cullables[chunkY*texGroup.numX+chunkX] = new Cullable(GeoMbr(geoLL,geoUR));
			Drawable *chunk = drawables[chunkY*texGroup.numX+chunkX] = new Drawable();
			cullable->addDrawable(chunk);
						
			chunk->points.reserve(3*(SphereTessX+1)*(SphereTessY+1));
			chunk->texCoords.reserve(2*(SphereTessX+1)*(SphereTessY+1));
			chunk->norms.reserve(3*(SphereTessX+1)*(SphereTessY+1));
			chunk->type = GL_TRIANGLES;
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
			chunk->tris.reserve(2*SphereTessX*SphereTessY);
			for (unsigned int iy=0;iy<SphereTessY;iy++)
			{
				for (unsigned int ix=0;ix<SphereTessX;ix++)
				{
					Drawable::Triangle triA,triB;
					triA.verts[0] = iy*(SphereTessX+1)+ix;
					triA.verts[1] = iy*(SphereTessX+1)+(ix+1);
					triA.verts[2] = (iy+1)*(SphereTessX+1)+(ix+1);
					triB.verts[0] = triA.verts[0];
					triB.verts[1] = triA.verts[2];
					triB.verts[2] = (iy+1)*(SphereTessX+1)+ix;
					chunk->tris.push_back(triA);
					chunk->tris.push_back(triB);
				}
			}
			
			if (!(chunk->textureId = [texGroup loadTextureX:chunkX y:chunkY]))
				throw (std::string)"Failed to load texture from group";

//			if (chunk->type == GL_POINTS)
//				chunk->textureId = 0;
		}
}
	
// Return cullables that overlap the given area
void SphericalEarthModel::overlapping(GeoMbr geoMbr,std::vector<Cullable *> &retCullables)
{
	// Note: We could do this more efficiently
	for (unsigned int ii=0;ii<cullables.size();ii++)
	{
		Cullable *cullable = cullables[ii];
		if (cullable->geoMbr.overlaps(geoMbr))
			retCullables.push_back(cullable);
	}
}

}