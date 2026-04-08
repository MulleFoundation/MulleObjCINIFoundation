#import <MulleObjCIniFoundation/MulleObjCIniFoundation.h>


int   main( void)
{
   NSMutableDictionary   *root;
   NSMutableDictionary   *dosbox;
   NSMutableDictionary   *cpu;
   NSString              *output;

   dosbox = [NSMutableDictionary dictionary];
   [dosbox setObject:@"vgaonly" forKey:@"machine"];
   [dosbox setObject:@"4"       forKey:@"memsize"];

   cpu = [NSMutableDictionary dictionary];
   [cpu setObject:@"386"  forKey:@"cputype"];
   [cpu setObject:@"auto" forKey:@"cycles"];

   root = [NSMutableDictionary dictionary];
   [root setObject:dosbox forKey:@"dosbox"];
   [root setObject:cpu    forKey:@"cpu"];

   output = [root mulleINIDescription];
   mulle_printf( "%@", output);

   return( 0);
}
