/*
 *  Drawable.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "Drawable.h"
#import "GlobeScene.h"
#import "UIImage+Stuff.h"

namespace WhirlyGlobe
{
		
Drawable::Drawable()
{
}
	
Drawable::~Drawable()
{
}
	
BasicDrawable::BasicDrawable()
{
	type = 0;
	texId = 0;
	color.r = color.g = color.b = color.a = 255;
}
	
BasicDrawable::BasicDrawable(unsigned int numVert,unsigned int numTri)
{
	points.reserve(numVert);
	texCoords.reserve(numVert);
	norms.reserve(numVert);
	tris.reserve(numTri);
	color.r = color.g = color.b = color.a = 255;
	drawPriority = DefaultDrawPriority;
}
	
BasicDrawable::~BasicDrawable()
{
}
	
// Widen a line and turn it into a rectangle of the given width
void BasicDrawable::addRect(const Point3f &l0, const Vector3f &nl0, const Point3f &l1, const Vector3f &nl1,float width)
{
	Vector3f dir = l1-l0;
	if (dir.isZero())
		return;
	dir.normalize();

	float width2 = width/2.0;
	Vector3f c0 = dir.cross(nl0);
	c0.normalize();
	
	Point3f pt[3];
	pt[0] = l0 + c0 * width2;
	pt[1] = l1 + c0 * width2;
	pt[2] = l1 - c0 * width2;
	pt[3] = l0 - c0 * width2;

	unsigned short ptIdx[4];
	for (unsigned int ii=0;ii<4;ii++)
	{
		ptIdx[ii] = addPoint(pt[ii]);
		addNormal(nl0);
	}
	
	addTriangle(Triangle(ptIdx[0],ptIdx[1],ptIdx[3]));
	addTriangle(Triangle(ptIdx[3],ptIdx[1],ptIdx[2]));
}


// Define VBOs to make this fast(er)
void BasicDrawable::setupGL()
{
	pointBuffer = texCoordBuffer = normBuffer = triBuffer = 0;
	if (points.size())
	{
		glGenBuffers(1,&pointBuffer);
		glBindBuffer(GL_ARRAY_BUFFER,pointBuffer);
		glBufferData(GL_ARRAY_BUFFER,points.size()*sizeof(Vector3f),&points[0],GL_STATIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER,0);
	}
	if (texCoords.size())
	{
		glGenBuffers(1,&texCoordBuffer);
		glBindBuffer(GL_ARRAY_BUFFER,texCoordBuffer);
		glBufferData(GL_ARRAY_BUFFER,texCoords.size()*sizeof(Vector2f),&texCoords[0],GL_STATIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER,0);		
	}
	if (norms.size())
	{
		glGenBuffers(1, &normBuffer);
		glBindBuffer(GL_ARRAY_BUFFER,normBuffer);
		glBufferData(GL_ARRAY_BUFFER,norms.size()*sizeof(Vector3f),&norms[0],GL_STATIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER,0);
	}
	if (tris.size())
	{
		glGenBuffers(1, &triBuffer);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,triBuffer);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER,tris.size()*sizeof(Triangle),&tris[0],GL_STATIC_DRAW);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
	}
}
	
// Tear down the VBOs we set up
void BasicDrawable::teardownGL()
{
	if (pointBuffer)
		glDeleteBuffers(1,&pointBuffer);
	if (texCoordBuffer)
		glDeleteBuffers(1,&texCoordBuffer);
	if (normBuffer)
		glDeleteBuffers(1,&normBuffer);
	if (triBuffer)
		glDeleteBuffers(1,&triBuffer);
}
	
void BasicDrawable::draw(GlobeScene *scene) const
{
	drawVBO(scene);
}

// VBO based drawing
void BasicDrawable::drawVBO(GlobeScene *scene) const
{
	GLuint textureId = scene->getGLTexture(texId);
	
	if (type == GL_TRIANGLES)
		glEnable(GL_LIGHTING);
	else
		glDisable(GL_LIGHTING);
	
	glColor4ub(color.r, color.g, color.b, color.a);

	glEnableClientState(GL_VERTEX_ARRAY);
	glBindBuffer(GL_ARRAY_BUFFER, pointBuffer);
	glVertexPointer(3, GL_FLOAT, 0, 0);

	glEnableClientState(GL_NORMAL_ARRAY);
	glBindBuffer(GL_ARRAY_BUFFER, normBuffer);
	glNormalPointer(GL_FLOAT, 0, 0);

	if (textureId)
	{
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, textureId);

		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
		glTexCoordPointer(2, GL_FLOAT, 0, 0);
	} else
		glDisable(GL_TEXTURE_2D);
	
	switch (type)
	{
		case GL_TRIANGLES:
		{
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triBuffer);
			glDrawElements(GL_TRIANGLES, tris.size()*3, GL_UNSIGNED_SHORT, 0);
		}
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

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	glDisable(GL_LIGHTING);
}

// Non-VBO based drawing
void BasicDrawable::drawReg(GlobeScene *scene) const
{
	GLuint textureId = scene->getGLTexture(texId);
	
	if (textureId)
	{
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	} else {
		glDisable(GL_TEXTURE_2D);
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
	glColor4ub(color.r, color.g, color.b, color.a);
	
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
