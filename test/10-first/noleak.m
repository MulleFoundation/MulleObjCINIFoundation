#import <MulleObjCIniFoundation/MulleObjCIniFoundation.h>

#include <unistd.h>


int   main( void)
{
#ifdef __MULLE_OBJC__
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) !=
         mulle_objc_universe_is_ok)
      _exit( 1);
#endif

   [[MulleINIParser new] autorelease];
   return( 0);
}
