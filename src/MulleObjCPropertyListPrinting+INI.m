/*
 *  MulleObjCPropertyListPrinting+INI.m
 *  MulleObjCINIFoundation
 *
 *  Copyright (C) 2024 Nat!, Mulle kybernetiK
 *  All rights reserved.
 *
 *  Coded by Nat!
 */
#import "MulleObjCPropertyListPrinting+INI.h"

#import "import-private.h"

#include <string.h>


static void   write_utf8_string( id handle, NSString *s)
{
   NSData   *data;

   if( ! s || [s length] == 0)
      return;
   data = [s dataUsingEncoding:NSUTF8StringEncoding];
   [handle appendData:data];
}


static void   write_cstring( id handle, char *s)
{
   NSData   *data;

   data = [NSData dataWithBytesNoCopy:s
                               length:strlen( s)
                         freeWhenDone:NO];
   [handle appendData:data];
}


/*
 * Write one section's key-value pairs to handle.
 */
static void   write_section_pairs( id handle, NSDictionary *pairs)
{
   NSArray    *keys;
   NSString   *key;
   NSString   *value;
   NSUInteger  i;
   NSUInteger  n;

   keys = [pairs allKeys];
   // sort for deterministic output
   keys = [keys sortedArrayUsingSelector:@selector( compare:)];
   n    = [keys count];
   for( i = 0; i < n; i++)
   {
      key   = [keys objectAtIndex:i];
      value = [pairs objectForKey:key];

      write_utf8_string( handle, key);
      write_cstring( handle, "=");
      write_utf8_string( handle, value);
      write_cstring( handle, "\n");
   }
}


@implementation NSObject( MulleObjCPropertyListPrinting_INI)

- (void) mullePrintINIToStream:(id) handle
{
   NSDictionary   *dict;
   NSDictionary   *global_pairs;
   NSArray        *section_keys;
   NSString       *section;
   NSUInteger      i;
   NSUInteger      n;

   if( ! [self isKindOfClass:[NSDictionary class]])
      return;

   dict = (NSDictionary *) self;

   /* Write global section (@"") first, without a header */
   global_pairs = [dict objectForKey:@""];
   if( global_pairs && [global_pairs isKindOfClass:[NSDictionary class]]
       && [global_pairs count] > 0)
   {
      write_section_pairs( handle, global_pairs);
   }

   /* Sort section names for deterministic output; skip global */
   section_keys = [[dict allKeys] sortedArrayUsingSelector:@selector( compare:)];
   n = [section_keys count];
   for( i = 0; i < n; i++)
   {
      section = [section_keys objectAtIndex:i];
      if( [section length] == 0)
         continue;  /* already wrote global */

      write_cstring( handle, "[");
      write_utf8_string( handle, section);
      write_cstring( handle, "]\n");

      NSDictionary *pairs;

      pairs = [dict objectForKey:section];
      if( [pairs isKindOfClass:[NSDictionary class]])
         write_section_pairs( handle, pairs);
   }
}


- (NSString *) mulleINIDescription
{
   NSMutableData   *data;

   data = [NSMutableData dataWithCapacity:256];
   [self mullePrintINIToStream:data];
   return( [[[NSString alloc] initWithData:data
                                  encoding:NSUTF8StringEncoding] autorelease]);
}

@end
