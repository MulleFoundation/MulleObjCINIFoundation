#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>


/*
 * Turnaround test:
 *   1. Parse a kitchensink INI string  -> dict1
 *   2. Write dict1 back to NSData via mullePrintINIToStream:
 *   3. Parse the written data          -> dict2
 *   4. Verify dict1 == dict2 (comments/ordering stripped, content preserved)
 */
static char *kitchensink =
   "; global section comment\n"
   "global_key = global_value\n"
   "# another comment\n"
   "another_global = 42\n"
   "\n"
   "[dosbox]\n"
   "machine=vgaonly ; inline comment\n"
   "memsize=4\n"
   "\n"
   "[cpu]\n"
   "cputype=386\n"
   "cycles = auto\n"
   "\n"
   "[strings]\n"
   "quoted = \"Hello World\"\n"
   "single = 'Single quotes'\n"
   "escaped = \"He said \\\"Hi\\\"\"\n"
   "backslash = \"C:\\\\Windows\"\n"
   "\"key with spaces\" = spaced value\n"
   "empty =\n"
   "\n"
   "[separators]\n"
   "equals = eq_value\n"
   "colon : colon_value\n";


static void   print_mismatch( NSString *section, NSString *key,
                               NSString *v1, NSString *v2)
{
   mulle_printf( "MISMATCH [%@] %@ : '%@' vs '%@'\n", section, key, v1, v2);
}


int   main( void)
{
   MulleINIParser    *parser;
   NSDictionary      *dict1;
   NSDictionary      *dict2;
   NSMutableData     *data;
   NSArray           *section_keys;
   NSArray           *keys;
   NSString          *section_name;
   NSString          *key;
   NSDictionary      *sect1;
   NSDictionary      *sect2;
   BOOL               ok;
   NSUInteger         i;
   NSUInteger         j;

   parser = [MulleINIParser new];

   /* Step 1: parse the kitchensink */
   dict1 = [parser parseBytes:(void *) kitchensink length:strlen( kitchensink)];
   if( ! dict1)
   {
      mulle_printf( "FAIL: first parse returned nil\n");
      [parser release];
      return( 1);
   }

   /* Step 2: write dict1 to NSData */
   data = [NSMutableData dataWithCapacity:512];
   [dict1 mullePrintINIToStream:data];
   if( [data length] == 0)
   {
      mulle_printf( "FAIL: printer produced empty output\n");
      [parser release];
      return( 1);
   }

   /* Step 3: parse the written data */
   [parser reset];
   dict2 = [parser parseBytes:(void *) [data bytes] length:[data length]];
   [parser release];

   if( ! dict2)
   {
      mulle_printf( "FAIL: second parse returned nil\n");
      return( 1);
   }

   /* Step 4: compare */
   ok = YES;

   /* Check dict1 sections are all present in dict2 with equal values */
   section_keys = [dict1 allKeys];
   for( i = 0; i < [section_keys count]; i++)
   {
      section_name = [section_keys objectAtIndex:i];
      sect1 = [dict1 objectForKey:section_name];
      sect2 = [dict2 objectForKey:section_name];

      if( ! sect2)
      {
         mulle_printf( "FAIL: section '%@' missing in round-trip\n", section_name);
         ok = NO;
         continue;
      }

      keys = [sect1 allKeys];
      for( j = 0; j < [keys count]; j++)
      {
         key = [keys objectAtIndex:j];
         NSString *v1 = [sect1 objectForKey:key];
         NSString *v2 = [sect2 objectForKey:key];
         if( ! [v1 isEqualToString:v2])
         {
            print_mismatch( section_name, key, v1, v2);
            ok = NO;
         }
      }

      /* Also check no extra keys appeared in dict2's section */
      if( [sect2 count] != [sect1 count])
      {
         mulle_printf( "FAIL: section '%@' key count %lu vs %lu\n",
                       section_name,
                       (unsigned long) [sect1 count],
                       (unsigned long) [sect2 count]);
         ok = NO;
      }
   }

   /* Check no extra sections in dict2 */
   if( [dict2 count] != [dict1 count])
   {
      mulle_printf( "FAIL: section count %lu vs %lu\n",
                    (unsigned long) [dict1 count],
                    (unsigned long) [dict2 count]);
      ok = NO;
   }

   mulle_printf( "%s\n", ok ? "PASS" : "FAIL");
   return( ok ? 0 : 1);
}
