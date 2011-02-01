//
//  GlobeScene.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "GlobeScene.h"
#import "SphericalEarth.h"

namespace WhirlyGlobe {
	
Cullable::Cullable(const GeoMbr &geoMbr) : geoMbr(geoMbr)
{
	// Turn the corner points in real world values
	cornerPoints[0] = PointFromGeo(geoMbr.ll());
	cornerPoints[1] = PointFromGeo(GeoCoord(geoMbr.ur().x(),geoMbr.ll().y()));
	cornerPoints[2] = PointFromGeo(geoMbr.ur());
	cornerPoints[3] = PointFromGeo(GeoCoord(geoMbr.ll().x(),geoMbr.ur().y()));
	
	// Normals happen to be the same
	for (unsigned int ii=0;ii<4;ii++)
		cornerNorms[ii] = cornerPoints[ii];
}
	
void Drawable::draw()
{
	if (textureId)
	{
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	}
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);

	glVertexPointer(3, GL_FLOAT, 0, &points[0]);
	glNormalPointer(GL_FLOAT, 0, &norms[0]);
	if (textureId)
	{
		glTexCoordPointer(2, GL_FLOAT, 0, &texCoords[0]);
		glBindTexture(GL_TEXTURE_2D, textureId);
	}

	switch (type)
	{
		case GL_TRIANGLES:
			glDrawElements(GL_TRIANGLES, tris.size()*3, GL_UNSIGNED_SHORT, (unsigned short *)&tris[0]);
			break;
		case GL_POINTS:
		case GL_LINES:
		case GL_LINE_STRIP:
		case GL_LINE_LOOP:
			glDrawArrays(type, 0, points.size());
			break;
	}

	if (textureId)
	{
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	}
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
}

}
