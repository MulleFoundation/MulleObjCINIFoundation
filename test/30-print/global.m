#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>


/* Test: global section (@"") is written without a [header] and first */
int   main( void)
{
   NSMutableDictionary   *root;
   NSMutableDictionary   *global;
   NSMutableDictionary   *section;
   NSString              *output;

   global = [NSMutableDictionary dictionary];
   [global setObject:@"global_value" forKey:@"global_key"];

   section = [NSMutableDictionary dictionary];
   [section setObject:@"sectval" forKey:@"sectkey"];

   root = [NSMutableDictionary dictionary];
   [root setObject:global  forKey:@""];
   [root setObject:section forKey:@"mysection"];

   output = [root mulleINIDescription];
   mulle_printf( "%@", output);

   return( 0);
}
