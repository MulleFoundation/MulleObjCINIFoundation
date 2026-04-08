#import <MulleObjCIniFoundation/MulleObjCIniFoundation.h>


/* Test: semicolon and hash line comments, inline comments */
static char *ini =
   "; full-line semicolon comment\n"
   "# full-line hash comment\n"
   "[section]\n"
   "key1 = value1 ; inline semicolon comment\n"
   "key2 = value2 # inline hash comment\n"
   "key3 = value3\n"
   "; disabled = old\n"
   "# disabled2 = old2\n";


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
   mulle_printf( "disabled: %@\n", [section objectForKey:@"disabled"]);
   mulle_printf( "disabled2: %@\n", [section objectForKey:@"disabled2"]);

   return( 0);
}
