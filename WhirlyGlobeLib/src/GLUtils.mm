//
//  GLUtils.cpp
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/21/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#include "GLUtils.h"

bool CheckGLError(const char *msg)
{
    GLenum theError = glGetError();
    if (theError != GL_NO_ERROR)
    {
        NSLog(@"GL Error: %d - %s",theError,msg);
        return false;
    }
    
    return true;
}
