/*
 *  NSPropertyListSerialization+INI.m
 *  MulleObjCINIFoundation
 *
 *  Copyright (C) 2024 Nat!, Mulle kybernetiK
 *  All rights reserved.
 *
 *  Coded by Nat!
 */
#import "import-private.h"

#import "MulleINIParser.h"
#import "MulleObjCPropertyListPrinting+INI.h"
#import "MulleObjCINIFoundation.h"


@implementation NSPropertyListSerialization( INI)

@dependency MulleINIParser;

+ (void) load
{
   [self mulleAddParserClass:[MulleINIParser class]
                      method:@selector( parseData:)
       forPropertyListFormat:MullePropertyListINIFormat];

   [self mulleAddPrintMethod:@selector( mullePrintINIToStream:)
         forPropertyListFormat:MullePropertyListINIFormat];
}

@end
