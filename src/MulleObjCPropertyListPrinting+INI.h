/*
 *  MulleObjCPropertyListPrinting+INI.h
 *  MulleObjCINIFoundation
 *
 *  Copyright (C) 2024 Nat!, Mulle kybernetiK
 *  All rights reserved.
 *
 *  Coded by Nat!
 */
#import "import.h"


/*
 * INI writer for NSDictionary.
 *
 * The receiver must be a NSDictionary whose keys are NSStrings (section names)
 * and whose values are NSDictionary<NSString *, NSString *> (key-value pairs).
 *
 * Writing rules:
 *   - The global section (key @"") is written first, without a [header].
 *   - Each other section is written as [section_name]\n.
 *   - Each key-value pair is written as key=value\n.
 *   - Keys and values that contain '=', '#', ';', or leading/trailing spaces
 *     are not quoted automatically — the format stores them as-is.
 *   - An empty NSMutableData may be passed as a simple sink.
 */
@interface NSObject( MulleObjCPropertyListPrinting_INI)

- (void) mullePrintINIToStream:(id) handle;
- (NSString *) mulleINIDescription;

@end
