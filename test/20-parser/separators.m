#import <MulleObjCIniFoundation/MulleObjCIniFoundation.h>


/* Test: both = and : as key-value separators */
static char *ini =
   "[section]\n"
   "key1 = equals separator\n"
   "key2 : colon separator\n"
   "key3=nospaces\n"
   "key4:nospaces_colon\n";


int   main( void)
{
   MulleINIParser   *parser;
   NSDictionary     *result;
   NSDictionary     *section;

   parser = [MulleINIParser new];
   result = [parser parseBytes:(void *) ini length:strlen( ini)];
   [parser release];

   section = [result objectForKey:@"section"];
   mulle_printf( "key1: '%@'\n", [section objectForKey:@"key1"]);
   mulle_printf( "key2: '%@'\n", [section objectForKey:@"key2"]);
   mulle_printf( "key3: '%@'\n", [section objectForKey:@"key3"]);
   mulle_printf( "key4: '%@'\n", [section objectForKey:@"key4"]);

   return( 0);
}
