/*
 *  Drawable.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "GLUtils.h"
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
	
void DrawableChangeRequest::execute(GlobeScene *scene,WhirlyGlobeView *view)
{
	Drawable *theDrawable = scene->getDrawable(drawId);
	if (theDrawable)
		execute2(scene,theDrawable);
}
	
BasicDrawable::BasicDrawable()
{
	on = true;
	type = 0;
	texId = 0;
    drawPriority = 0;
    drawOffset = 0;
    minVisible = maxVisible = DrawVisibleInvalid;
    
	color.r = color.g = color.b = color.a = 255;
}
	
BasicDrawable::BasicDrawable(unsigned int numVert,unsigned int numTri)
{
	on = true;
    drawPriority = 0;
    drawOffset = 0;
	points.reserve(numVert);
	texCoords.reserve(numVert);
	norms.reserve(numVert);
	tris.reserve(numTri);
	color.r = color.g = color.b = color.a = 255;
	drawPriority = 0;
    minVisible = maxVisible = DrawVisibleInvalid;
}
	
BasicDrawable::~BasicDrawable()
{
}
    
bool BasicDrawable::isOn(WhirlyGlobeView *view) const
{
    if (minVisible == DrawVisibleInvalid || !on)
        return on;

    float visVal = view.heightAboveGlobe;
    
    return ((minVisible <= visVal && visVal <= maxVisible) ||
             (maxVisible <= visVal && visVal <= minVisible));
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
void BasicDrawable::setupGL(float minZres)
{
	// Offset the geometry upward by minZres units along the normals
	// Only do this once, obviously
	if (drawOffset != 0 && (points.size() == norms.size()))
	{
		// Note: This could be faster
		float scale = minZres*drawOffset;
		for (unsigned int ii=0;ii<points.size();ii++)
		{
			Vector3f pt = points[ii];
			points[ii] = norms[ii] * scale + pt;
		}
	}
	
	pointBuffer = texCoordBuffer = normBuffer = triBuffer = 0;
	if (points.size())
	{
		glGenBuffers(1,&pointBuffer);
        CheckGLError("BasicDrawable::setupGL() glGenBuffers()");
		glBindBuffer(GL_ARRAY_BUFFER,pointBuffer);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
		glBufferData(GL_ARRAY_BUFFER,points.size()*sizeof(Vector3f),&points[0],GL_STATIC_DRAW);
        CheckGLError("BasicDrawable::setupGL() glBufferData()");
		glBindBuffer(GL_ARRAY_BUFFER,0);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
	}
	if (texCoords.size())
	{
		glGenBuffers(1,&texCoordBuffer);
        CheckGLError("BasicDrawable::setupGL() glGenBuffers()");
		glBindBuffer(GL_ARRAY_BUFFER,texCoordBuffer);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
		glBufferData(GL_ARRAY_BUFFER,texCoords.size()*sizeof(Vector2f),&texCoords[0],GL_STATIC_DRAW);
        CheckGLError("BasicDrawable::setupGL() glBufferData()");
		glBindBuffer(GL_ARRAY_BUFFER,0);		
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
	}
	if (norms.size())
	{
		glGenBuffers(1, &normBuffer);
        CheckGLError("BasicDrawable::setupGL() glGenBuffers()");
		glBindBuffer(GL_ARRAY_BUFFER,normBuffer);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
		glBufferData(GL_ARRAY_BUFFER,norms.size()*sizeof(Vector3f),&norms[0],GL_STATIC_DRAW);
        CheckGLError("BasicDrawable::setupGL() glBufferData()");
		glBindBuffer(GL_ARRAY_BUFFER,0);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
	}
	if (tris.size())
	{
		glGenBuffers(1, &triBuffer);
        CheckGLError("BasicDrawable::setupGL() glGenBuffers()");
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,triBuffer);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
		glBufferData(GL_ELEMENT_ARRAY_BUFFER,tris.size()*sizeof(Triangle),&tris[0],GL_STATIC_DRAW);
        CheckGLError("BasicDrawable::setupGL() glBufferData()");
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
        CheckGLError("BasicDrawable::setupGL() glBindBuffer()");
	}
    
    // Clear out the arrays, since we won't need them again
    numPoints = points.size();
    points.clear();
    texCoords.clear();
    norms.clear();
    numTris = tris.size();
    tris.clear();
}
	
// Tear down the VBOs we set up
void BasicDrawable::teardownGL()
{
	if (pointBuffer)
    {
		glDeleteBuffers(1,&pointBuffer);
        CheckGLError("BasicDrawable::teardownGL() glDeleteBuffers()");
    }
	if (texCoordBuffer)
    {
		glDeleteBuffers(1,&texCoordBuffer);
        CheckGLError("BasicDrawable::teardownGL() glDeleteBuffers()");
    }
	if (normBuffer)
    {
		glDeleteBuffers(1,&normBuffer);
        CheckGLError("BasicDrawable::teardownGL() glDeleteBuffers()");
    }
	if (triBuffer)
    {
		glDeleteBuffers(1,&triBuffer);
        CheckGLError("BasicDrawable::teardownGL() glDeleteBuffers()");
    }
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
    CheckGLError("BasicDrawable::drawVBO() lighting");
	
	glColor4ub(color.r, color.g, color.b, color.a);
    CheckGLError("BasicDrawable::drawVBO() glColor4ub");

	glEnableClientState(GL_VERTEX_ARRAY);
    CheckGLError("BasicDrawable::drawVBO() glEnableClientState");
	glBindBuffer(GL_ARRAY_BUFFER, pointBuffer);
    CheckGLError("BasicDrawable::drawVBO() glBindBuffer");
	glVertexPointer(3, GL_FLOAT, 0, 0);
    CheckGLError("BasicDrawable::drawVBO() glVertexPointer");

	glEnableClientState(GL_NORMAL_ARRAY);
    CheckGLError("BasicDrawable::drawVBO() glEnableClientState");
	glBindBuffer(GL_ARRAY_BUFFER, normBuffer);
    CheckGLError("BasicDrawable::drawVBO() glBindBuffer");
	glNormalPointer(GL_FLOAT, 0, 0);
    CheckGLError("BasicDrawable::drawVBO() glNormalPointer");

	if (textureId)
	{
		glEnable(GL_TEXTURE_2D);
        CheckGLError("BasicDrawable::drawVBO() glEnable");
		glBindTexture(GL_TEXTURE_2D, textureId);
        CheckGLError("BasicDrawable::drawVBO() glBindTexture");

		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        CheckGLError("BasicDrawable::drawVBO() glEnableClientState");
		glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
        CheckGLError("BasicDrawable::drawVBO() glBindBuffer");
		glTexCoordPointer(2, GL_FLOAT, 0, 0);
        CheckGLError("BasicDrawable::drawVBO() glTexCoordPointer");
	}
    
    if (!textureId && (type == GL_TRIANGLES))
    {
        NSLog(@"No texture for: %lu",getId());
		glDisable(GL_TEXTURE_2D);
        CheckGLError("BasicDrawable::drawVBO() glDisable");
    }
	
	switch (type)
	{
		case GL_TRIANGLES:
		{
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triBuffer);
            CheckGLError("BasicDrawable::drawVBO() glBindBuffer");
			glDrawElements(GL_TRIANGLES, numTris*3, GL_UNSIGNED_SHORT, 0);
            CheckGLError("BasicDrawable::drawVBO() glDrawElements");
		}
			break;
		case GL_POINTS:
		case GL_LINES:
		case GL_LINE_STRIP:
		case GL_LINE_LOOP:
			glDrawArrays(type, 0, numPoints);
            CheckGLError("BasicDrawable::drawVBO() glDrawArrays");
			break;
	}
	
	if (textureId)
	{
		glDisable(GL_TEXTURE_2D);
        CheckGLError("BasicDrawable::drawVBO() glDisable");
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        CheckGLError("BasicDrawable::drawVBO() glDisableClientState");
	}
	glDisableClientState(GL_VERTEX_ARRAY);
    CheckGLError("BasicDrawable::drawVBO() glDisableClientState");
	glDisableClientState(GL_NORMAL_ARRAY);
    CheckGLError("BasicDrawable::drawVBO() glDisableClientState");

	glBindBuffer(GL_ARRAY_BUFFER, 0);
    CheckGLError("BasicDrawable::drawVBO() glBindBuffer");
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    CheckGLError("BasicDrawable::drawVBO() glBindBuffer");
	
	glDisable(GL_LIGHTING);
    CheckGLError("BasicDrawable::drawVBO() glDisable");
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

ColorChangeRequest::ColorChangeRequest(SimpleIdentity drawId,RGBAColor inColor)
	: DrawableChangeRequest(drawId)
{
	color[0] = inColor.r;
	color[1] = inColor.g;
	color[2] = inColor.b;
	color[3] = inColor.a;
}
	
void ColorChangeRequest::execute2(GlobeScene *scene,Drawable *draw)
{
	BasicDrawable *basicDrawable = dynamic_cast<BasicDrawable *> (draw);
	basicDrawable->setColor(color);
}
	
OnOffChangeRequest::OnOffChangeRequest(SimpleIdentity drawId,bool OnOff)
	: DrawableChangeRequest(drawId), newOnOff(OnOff)
{
	
}
	
void OnOffChangeRequest::execute2(GlobeScene *scene,Drawable *draw)
{
	BasicDrawable *basicDrawable = dynamic_cast<BasicDrawable *> (draw);
	basicDrawable->setOnOff(newOnOff);
}

}
