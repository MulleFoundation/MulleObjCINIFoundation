/*
 *  MulleINIParser.m
 *  MulleObjCINIFoundation
 *
 *  Copyright (C) 2024 Nat!, Mulle kybernetiK
 *  All rights reserved.
 *
 *  Coded by Nat!
 */
#import "MulleINIParser.h"

#import "import-private.h"

#include <ctype.h>
#include <string.h>
#include <stdlib.h>


@implementation MulleINIParser


- (void) reset
{
   [_userInfo autorelease];
   _userInfo = nil;
   [_object autorelease];
   _object = nil;
}


/*
 * Trim leading whitespace; return pointer to first non-space char.
 */
static char *   trim_left( char *s, char *end)
{
   while( s < end && (*s == ' ' || *s == '\t' || *s == '\r'))
      s++;
   return( s);
}


/*
 * Trim trailing whitespace in-place; return pointer past last non-space char.
 */
static char *   trim_right( char *s, char *end)
{
   while( end > s && (end[-1] == ' ' || end[-1] == '\t' || end[-1] == '\r'))
      end--;
   return( end);
}


/*
 * Scan a double-quoted C string starting just after the opening '"'.
 * Processes \" -> " and \\ -> \.
 * Returns a newly malloc'd buffer (caller must free) with the unescaped
 * content, and sets *out_len.
 * Returns NULL on malformed input (unclosed quote).
 * p advances past the closing '"'.
 */
static char *   scan_double_quoted( char **p, char *end, size_t *out_len)
{
   char   *src;
   char   *dst;
   char   *buf;
   size_t  cap;

   src = *p;
   cap = (size_t)(end - src) + 1;
   buf = (char *) malloc( cap);
   if( ! buf)
      return( NULL);

   dst = buf;
   while( src < end && *src != '"')
   {
      if( *src == '\\' && src + 1 < end)
      {
         src++;
         switch( *src)
         {
         case '"'  : *dst++ = '"';  break;
         case '\'' : *dst++ = '\''; break;
         case '\\' : *dst++ = '\\'; break;
         case 'n'  : *dst++ = '\n'; break;
         case 'r'  : *dst++ = '\r'; break;
         case 't'  : *dst++ = '\t'; break;
         default   : *dst++ = '\\'; *dst++ = *src; break;
         }
         src++;
         continue;
      }
      *dst++ = *src++;
   }

   *dst = '\0';  /* buffer has room for cap bytes, dst is at most cap - 1 */

   if( src >= end)  /* unclosed quote — keep what we have */
   {
      *out_len = (size_t)(dst - buf);
      *p = src;
      return( buf);
   }

   src++;  /* skip closing '"' */
   *out_len = (size_t)(dst - buf);
   *p = src;
   return( buf);
}


/*
 * Scan a single-quoted string starting just after the opening '\''.
 * No escape processing.
 * Returns a malloc'd buffer; sets *out_len.
 */
static char *   scan_single_quoted( char **p, char *end, size_t *out_len)
{
   char   *src;
   char   *start;
   char   *buf;

   src   = *p;
   start = src;
   while( src < end && *src != '\'')
      src++;

   *out_len = (size_t)(src - start);
   buf = (char *) malloc( *out_len + 1);
   if( ! buf)
      return( NULL);
   memcpy( buf, start, *out_len);
   buf[ *out_len] = '\0';

   if( src < end)  /* skip closing '\'' */
      src++;

   *p = src;
   return( buf);
}


/*
 * Given a raw value region [vs, ve), strip inline comment (unquoted # or ;),
 * handle optional surrounding quotes, and return an NSString.
 * Falls through to returning the trimmed raw content if not quoted.
 */
static NSString *   make_value_string( char *vs, char *ve)
{
   NSString *result;
   char     *p;
   char     *buf;
   size_t    len;

   vs = trim_left( vs, ve);

   if( vs >= ve)
      return( @"");

   /* Double-quoted value */
   if( *vs == '"')
   {
      p   = vs + 1;
      buf = scan_double_quoted( &p, ve, &len);
      if( ! buf)
         return( @"");
      result = [NSString stringWithUTF8String:buf];  /* or use bytes/length */
      if( ! result)
         result = [[[NSString alloc] initWithBytes:buf
                                            length:len
                                          encoding:NSUTF8StringEncoding] autorelease];
      free( buf);
      return( result ? result : @"");
   }

   /* Single-quoted value */
   if( *vs == '\'')
   {
      p   = vs + 1;
      buf = scan_single_quoted( &p, ve, &len);
      if( ! buf)
         return( @"");
      result = [[[NSString alloc] initWithBytes:buf
                                         length:len
                                       encoding:NSUTF8StringEncoding] autorelease];
      free( buf);
      return( result ? result : @"");
   }

   /* Unquoted: strip inline comment and trailing whitespace */
   p = vs;
   while( p < ve)
   {
      if( *p == '"')
      {
         /* skip quoted sub-string so we don't strip # inside it */
         p++;
         while( p < ve && *p != '"')
         {
            if( *p == '\\' && p + 1 < ve)
               p++;
            p++;
         }
         if( p < ve)
            p++;
         continue;
      }
      if( *p == '#' || *p == ';')
      {
         ve = p;  /* truncate at inline comment */
         break;
      }
      p++;
   }
   ve = trim_right( vs, ve);

   if( vs >= ve)
      return( @"");

   return( [[[NSString alloc] initWithBytes:vs
                                     length:(NSUInteger)(ve - vs)
                                   encoding:NSUTF8StringEncoding] autorelease]);
}


/*
 * Parse the key region [ks, ke).  Strip double quotes if present.
 */
static NSString *   make_key_string( char *ks, char *ke)
{
   NSString *result;
   char     *buf;
   size_t    len;
   char     *p;

   ks = trim_left( ks, ke);
   ke = trim_right( ks, ke);

   if( ks >= ke)
      return( nil);

   if( *ks == '"')
   {
      p   = ks + 1;
      buf = scan_double_quoted( &p, ke, &len);
      if( ! buf)
         return( nil);
      result = [[[NSString alloc] initWithBytes:buf
                                         length:len
                                       encoding:NSUTF8StringEncoding] autorelease];
      free( buf);
      return( result);
   }

   return( [[[NSString alloc] initWithBytes:ks
                                     length:(NSUInteger)(ke - ks)
                                   encoding:NSUTF8StringEncoding] autorelease]);
}


/*
 * Parse a section name from [ks, ke) (between '[' and ']').
 * Strip optional double quotes.
 */
static NSString *   make_section_string( char *ks, char *ke)
{
   NSString *result;
   char     *buf;
   size_t    len;
   char     *p;

   ks = trim_left( ks, ke);
   ke = trim_right( ks, ke);

   if( ks >= ke)
      return( @"");

   if( *ks == '"')
   {
      p   = ks + 1;
      buf = scan_double_quoted( &p, ke, &len);
      if( ! buf)
         return( @"");
      result = [[[NSString alloc] initWithBytes:buf
                                         length:len
                                       encoding:NSUTF8StringEncoding] autorelease];
      free( buf);
      return( result ? result : @"");
   }

   return( [[[NSString alloc] initWithBytes:ks
                                     length:(NSUInteger)(ke - ks)
                                   encoding:NSUTF8StringEncoding] autorelease]);
}


- (id) parseBytes:(void *) bytes
           length:(NSUInteger) length
{
   NSMutableDictionary   *result;
   NSMutableDictionary   *section_dict;
   NSString              *section_name;
   NSString              *key;
   NSString              *value;
   char                  *p;
   char                  *end;
   char                  *line_start;
   char                  *line_end;
   char                  *sep;
   char                  *scan;

   if( ! bytes || ! length)
      return( nil);

   result       = [NSMutableDictionary dictionary];
   section_name = @"";
   section_dict = [NSMutableDictionary dictionary];
   [result setObject:section_dict forKey:section_name];

   p   = (char *) bytes;
   end = p + length;

   while( p < end)
   {
      /* Find end of line (LF, or CR LF) */
      line_start = p;
      while( p < end && *p != '\n')
         p++;
      line_end = p;
      if( p < end)
         p++;  /* skip '\n' */

      /* Strip '\r' at line end */
      if( line_end > line_start && line_end[-1] == '\r')
         line_end--;

      /* Trim leading whitespace on line */
      line_start = trim_left( line_start, line_end);

      /* Empty line */
      if( line_start >= line_end)
         continue;

      /* Line comment */
      if( *line_start == ';' || *line_start == '#')
         continue;

      /* Section header: [name] */
      if( *line_start == '[')
      {
         char *bracket_end;

         bracket_end = line_start + 1;
         while( bracket_end < line_end && *bracket_end != ']')
            bracket_end++;

         section_name = make_section_string( line_start + 1, bracket_end);
         if( ! section_name)
            section_name = @"";

         section_dict = [result objectForKey:section_name];
         if( ! section_dict)
         {
            section_dict = [NSMutableDictionary dictionary];
            [result setObject:section_dict forKey:section_name];
         }
         continue;
      }

      /* Key-value line: scan for first '=' or ':' (outside quoted key) */
      sep  = NULL;
      scan = line_start;

      if( *scan == '"')
      {
         /* Quoted key: skip past closing '"' */
         scan++;
         while( scan < line_end && *scan != '"')
         {
            if( *scan == '\\' && scan + 1 < line_end)
               scan++;
            scan++;
         }
         if( scan < line_end)
            scan++;  /* skip closing '"' */
         /* Now look for separator after the quoted key */
         scan = trim_left( scan, line_end);
         if( scan < line_end && (*scan == '=' || *scan == ':'))
            sep = scan;
      }
      else
      {
         while( scan < line_end)
         {
            if( *scan == '=' || *scan == ':')
            {
               sep = scan;
               break;
            }
            scan++;
         }
      }

      if( ! sep)
         continue;  /* no separator found — skip line */

      key   = make_key_string( line_start, sep);
      value = make_value_string( sep + 1, line_end);

      if( ! key || [key length] == 0)
         continue;
      if( ! value)
         value = @"";

      [section_dict setObject:value forKey:key];
   }

   /* Remove the global section if it collected no keys */
   if( [[result objectForKey:@""] count] == 0)
      [result removeObjectForKey:@""];

   [_object autorelease];
   _object = [result retain];
   return( result);
}


- (id) parseData:(NSData *) data
{
   if( ! data)
      return( nil);
   return( [self parseBytes:(void *) [data bytes]
                    length:[data length]]);
}


@end


@implementation NSString( MulleINIParser)

- (id) mulleINI
{
   MulleINIParser   *parser;

   parser = [MulleINIParser instance];
   return( [parser parseData:[self dataUsingEncoding:NSUTF8StringEncoding]]);
}

@end
