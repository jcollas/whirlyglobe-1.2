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
	
// Set up the texture from a filename
Texture::Texture(NSString *baseName,NSString *ext)
{
	glId = 0;
	texData = nil;
	
	if (![ext compare:@"pvrtc"])
	{
		isPVRTC = true;
		NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:ext];
		if (!path)
			return;
		texData = [[NSData alloc] initWithContentsOfFile:path];
		if (!texData)
			return;
		
		// Note: This needs to be configurable
		width = height = 1024;
	} else {
		isPVRTC = false;
		// Otherwise load it the normal way
		UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.%@",baseName,ext]];
		if (!image)
			return;
		texData = [[image rawDataRetWidth:&width height:&height] retain];
	}
}
	
Texture::~Texture()
{
	if (texData)
		[texData release];
	texData = nil;
}
	
// Define the texture in OpenGL
// Note: Should load the texture from disk elsewhere
bool Texture::createInGL(bool releaseData)
{
	if (!texData)
		return false;
	
	if (glId)
		destroyInGL();
	
	// Allocate a texture and set up the various params
	glGenTextures(1, &glId);
	glBindTexture(GL_TEXTURE_2D, glId);
	
	// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	// Configure textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// If it's in an optimized form, we can use that more efficiently
	if (isPVRTC)
	{
		// Will always be 4 bits per pixel and RGB
		glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, width, height, 0, [texData length], [texData bytes]);
	} else {
		// Specify a 2D texture image, providing the a pointer to the image data in memory
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [texData bytes]);
	}	
	
	if (releaseData)
	{
		[texData release];
		texData = nil;
	}
	
	return true;
}
	
// Release the OpenGL texture
void Texture::destroyInGL()
{
	if (glId)
		glDeleteTextures(1, &glId);
}
	
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
}
	
BasicDrawable::~BasicDrawable()
{
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
