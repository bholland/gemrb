/* GemRB - Infinity Engine Emulator
 * Copyright (C) 2003 The GemRB Project
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 *
 */

// GemRB.cpp : Defines the entry point for the application.


#include <cstdio>
#include "includes/win32def.h"
#include "plugins/Core/Interface.h"

#ifndef WIN32
#include <ctype.h>
#include <sys/time.h>
#include <dirent.h>
#else
#include <windows.h>
#endif

//this supposed to convince SDL to work on OS/X
#ifdef __APPLE_CC__ // we need startup SDL here
#include "SDL/SDL.h"
#endif

int main(int argc, char* argv[])
{
	core = new Interface( argc, argv );
	if (core->Init() == GEM_ERROR) {
		delete( core );
		printf("Press enter to continue...");
		getc(stdin);
		return -1;
	}
	core->Main();
	delete( core );
#ifndef WIN32
	//reinitialize the console colors.
	printf("\033[%sm","0") ;
#endif
	return 0;
}
