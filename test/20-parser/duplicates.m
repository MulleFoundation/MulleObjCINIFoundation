#import <MulleObjCIniFoundation/MulleObjCIniFoundation.h>


/* Test: duplicate keys — last one wins */
static char *ini =
   "[section]\n"
   "key = first value\n"
   "key = second value\n"
   "key = third value\n";


int   main( void)
{
   MulleINIParser   *parser;
   NSDictionary     *result;
   NSDictionary     *section;

   parser = [MulleINIParser new];
   result = [parser parseBytes:(void *) ini length:strlen( ini)];
   [parser release];

   section = [result objectForKey:@"section"];
   mulle_printf( "key: '%@'\n", [section objectForKey:@"key"]);

   return( 0);
}
