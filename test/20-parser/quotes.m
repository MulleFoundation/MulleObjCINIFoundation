#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>


/* Test: quoted keys and values, escape sequences */
static char *ini =
   "[section]\n"
   "quoted_string = \"Hello World\"\n"
   "single_quoted = 'Single quotes'\n"
   "escaped_quotes = \"He said \\\"Hello\\\"\"\n"
   "escaped_backslash = \"C:\\\\Windows\"\n"
   "\"key with spaces\" = value\n"
   "plain = unquoted value\n";


int   main( void)
{
   MulleINIParser   *parser;
   NSDictionary     *result;
   NSDictionary     *section;

   parser = [MulleINIParser new];
   result = [parser parseBytes:(void *) ini length:strlen( ini)];
   [parser release];

   section = [result objectForKey:@"section"];
   mulle_printf( "quoted_string: '%@'\n",    [section objectForKey:@"quoted_string"]);
   mulle_printf( "single_quoted: '%@'\n",    [section objectForKey:@"single_quoted"]);
   mulle_printf( "escaped_quotes: '%@'\n",   [section objectForKey:@"escaped_quotes"]);
   mulle_printf( "escaped_backslash: '%@'\n",[section objectForKey:@"escaped_backslash"]);
   mulle_printf( "key with spaces: '%@'\n",  [section objectForKey:@"key with spaces"]);
   mulle_printf( "plain: '%@'\n",            [section objectForKey:@"plain"]);

   return( 0);
}
