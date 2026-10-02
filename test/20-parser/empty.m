#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>


/* Test: empty values, empty sections, global (pre-section) keys */
static char *ini =
   "global_key = global_value\n"
   "another_global = 42\n"
   "[section_with_content]\n"
   "key = value\n"
   "empty_value =\n"
   "[EmptySection]\n"
   "[LastSection]\n"
   "last = ok\n";


int   main( void)
{
   MulleINIParser   *parser;
   NSDictionary     *result;
   NSDictionary     *section;

   parser = [MulleINIParser new];
   result = [parser parseBytes:(void *) ini length:strlen( ini)];
   [parser release];

   /* global section stored under @"" */
   section = [result objectForKey:@""];
   mulle_printf( "global_key: '%@'\n",     [section objectForKey:@"global_key"]);
   mulle_printf( "another_global: '%@'\n", [section objectForKey:@"another_global"]);

   section = [result objectForKey:@"section_with_content"];
   mulle_printf( "key: '%@'\n",         [section objectForKey:@"key"]);
   mulle_printf( "empty_value: '%@'\n", [section objectForKey:@"empty_value"]);

   /* empty section should exist as an empty dict, not nil */
   section = [result objectForKey:@"EmptySection"];
   mulle_printf( "EmptySection exists: %d\n",  section ? 1 : 0);
   mulle_printf( "EmptySection count: %lu\n", (unsigned long) [section count]);

   section = [result objectForKey:@"LastSection"];
   mulle_printf( "last: '%@'\n", [section objectForKey:@"last"]);

   return( 0);
}
