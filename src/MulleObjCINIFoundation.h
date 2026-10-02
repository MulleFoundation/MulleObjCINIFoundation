#import "import.h"

#include <stdint.h>

/*
 *  MulleObjCINIFoundation - INI/CFG config file parser and writer
 *
 *  Copyright (C) 2024 Nat!, Mulle kybernetiK
 *  All rights reserved.
 *
 *  version:  major, minor, patch
 */
#define MULLE_OBJC_INI_FOUNDATION_VERSION  ((0UL << 20) | (1 << 8) | 0)

static inline unsigned int   MulleObjCIniFoundation_get_version_major( void)
{
   return( MULLE_OBJC_INI_FOUNDATION_VERSION >> 20);
}

static inline unsigned int   MulleObjCIniFoundation_get_version_minor( void)
{
   return( (MULLE_OBJC_INI_FOUNDATION_VERSION >> 8) & 0xFFF);
}

static inline unsigned int   MulleObjCIniFoundation_get_version_patch( void)
{
   return( MULLE_OBJC_INI_FOUNDATION_VERSION & 0xFF);
}

extern uint32_t   MulleObjCIniFoundation_get_version( void);


//
// INI format constant for use with NSPropertyListSerialization.
// Registered by this library's +load method.
//
enum
{
   MullePropertyListINIFormat = 7
};


#import "MulleINIParser.h"
#import "MulleObjCPropertyListPrinting+INI.h"
#import "MulleObjCDeps+MulleObjCINIFoundation.h"


#ifdef __has_include
# if __has_include( "_MulleObjCINIFoundation-versioncheck.h")
#  include "_MulleObjCINIFoundation-versioncheck.h"
# endif
#endif
