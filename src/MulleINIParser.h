/*
 *  MulleINIParser.h
 *  MulleObjCIniFoundation
 *
 *  Copyright (C) 2024 Nat!, Mulle kybernetiK
 *  All rights reserved.
 *
 *  Coded by Nat!
 */
#import "import.h"


//
// MulleINIParser parses INI/CFG config files into an
// NSDictionary of NSDictionaries (section -> key -> value, all NSString).
//
// Supported syntax:
//   [section]              - section header (trimmed, optional quotes stripped)
//   key = value            - '=' separator, whitespace trimmed around key/value
//   key : value            - ':' separator also accepted
//   ; comment              - semicolon line comment (line skipped)
//   # comment              - hash line comment (line skipped)
//   key = val ; inline     - inline ';' or '#' trim value (outside quotes)
//   key = "quoted"         - double-quoted value: strips quotes, \" and \\ escape
//   key = 'quoted'         - single-quoted value: strips quotes (no escaping)
//   "key with spaces" = v  - double-quoted key: strips quotes
//   empty_key =            - empty value -> @""
//   (keys before [section])- stored under section key @""
//   duplicate keys         - last one wins
//
// NOT supported: backslash line continuation, ${var} interpolation,
//                type coercion (all values remain NSString).
//
@interface MulleINIParser : NSObject

@property( retain) id   userInfo;
@property( retain) id   object;

- (id) parseData:(NSData *) data;
- (id) parseBytes:(void *) bytes
           length:(NSUInteger) length;

- (void) reset;

@end


@interface NSString( MulleINIParser)

// Parse the receiver as INI text; returns NSDictionary or nil on error.
- (id) mulleINI;

@end
