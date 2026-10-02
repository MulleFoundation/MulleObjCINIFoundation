#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>


static char *dosbox_ini =
   "[dosbox]\n"
   "machine=vgaonly\n"
   "memsize=4\n"
   "[cpu]\n"
   "cputype=386\n"
   "cycles=auto\n"
   "[midi]\n"
   "mpu401=uart\n"
   "mididevice=fluidsynth\n"
   "# use win32 on Windows, fluidsynth on Linux/macOS\n"
   "fluid.soundfont=\n"
   "[sblaster]\n"
   "sbtype=none\n"
   "[mixer]\n"
   "rate=44100\n";


int   main( void)
{
   MulleINIParser   *parser;
   NSDictionary     *result;
   NSDictionary     *section;

   parser = [MulleINIParser new];
   result = [parser parseBytes:(void *) dosbox_ini length:strlen( dosbox_ini)];
   [parser release];

   if( ! result)
   {
      fprintf( stderr, "parse failed\n");
      return( 1);
   }

   /* verify section count: dosbox, cpu, midi, sblaster, mixer */
   mulle_printf( "sections: %lu\n", (unsigned long) [result count]);

   section = [result objectForKey:@"dosbox"];
   mulle_printf( "dosbox machine: %@\n", [section objectForKey:@"machine"]);
   mulle_printf( "dosbox memsize: %@\n", [section objectForKey:@"memsize"]);

   section = [result objectForKey:@"cpu"];
   mulle_printf( "cpu cputype: %@\n", [section objectForKey:@"cputype"]);
   mulle_printf( "cpu cycles: %@\n", [section objectForKey:@"cycles"]);

   section = [result objectForKey:@"midi"];
   mulle_printf( "midi mpu401: %@\n", [section objectForKey:@"mpu401"]);
   mulle_printf( "midi mididevice: %@\n", [section objectForKey:@"mididevice"]);
   mulle_printf( "midi fluid.soundfont: '%@'\n", [section objectForKey:@"fluid.soundfont"]);

   section = [result objectForKey:@"sblaster"];
   mulle_printf( "sblaster sbtype: %@\n", [section objectForKey:@"sbtype"]);

   section = [result objectForKey:@"mixer"];
   mulle_printf( "mixer rate: %@\n", [section objectForKey:@"rate"]);

   return( 0);
}
