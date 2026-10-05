# MulleObjCINIFoundation Library Documentation for AI
<!-- Keywords: ini, config, parser, writer, propertylist, foundation, objc -->
## 1. Introduction & Purpose

MulleObjCINIFoundation is an Objective-C (MulleObjC) library that parses and
writes INI / CFG configuration files. It converts INI text into a nested
`NSDictionary` of `NSDictionary` objects (section -> key -> value, all
`NSString`), and can serialize such a dictionary back into INI text.

Key features:

- A single-pass, in-memory INI parser (`MulleINIParser`) that accepts `=` and
  `:` separators, `;` and `#` comments, quoted keys/values, and duplicate keys
  (last one wins).
- A category on `NSString` (`-mulleINI`) for one-step parsing of a string.
- An INI printer (`-mullePrintINIToStream:` / `-mulleINIDescription`) for an
  `NSDictionary` shaped as section -> key -> value.
- Integration with `NSPropertyListSerialization` through the format constant
  `MullePropertyListINIFormat`, registered automatically in `+load`.

The library is a component of the MulleFoundation family. Its only direct
mulle-sde dependency is `MulleFoundationBase`, which supplies MulleObjC and
Foundation (`NSDictionary`, `NSString`, `NSData`, `NSPropertyListSerialization`).

## 2. Key Concepts & Design Philosophy

- **Dictionary-centric model.** INI content is always represented as
  `NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *`. Every
  section is itself a dictionary keyed by `NSString`; every value is an
  `NSString`. There is no type coercion, so `4` stays `@"4"`.
- **The global section.** Key/value pairs that appear before any `[section]`
  header are stored under the empty-string section key `@""`. If no global keys
  exist, the `@""` entry is removed from the result.
- **Reusable parser instance.** A `MulleINIParser` keeps the last parse result
  in its retained `object` property and the retained `userInfo` property. Call
  `-reset` to release both and reuse the instance. `+instance` factory is the
  preferred way to obtain one.
- **Last-one-wins.** Duplicate keys within a section overwrite earlier values.
- **Deterministic writing.** The printer sorts section names and the keys within
  each section (via `-compare:`) so output is stable.
- **Not a full INI dialect.** Line continuation (`\`), `${var}` interpolation,
  and automatic quoting of special characters are intentionally not supported.

## 3. Core API & Data Structures

All signatures below are copied verbatim from the public headers.

### 3.1. `MulleObjCINIFoundation.h`

Umbrella header that imports `MulleINIParser.h`,
`MulleObjCPropertyListPrinting+INI.h`, and the dependency declaration header.
It also defines the library version and the property-list format constant.

#### Version

```c
#define MULLE_OBJC_INI_FOUNDATION_VERSION  ((0UL << 20) | (1 << 8) | 0)

static inline unsigned int   MulleObjCIniFoundation_get_version_major( void);
static inline unsigned int   MulleObjCIniFoundation_get_version_minor( void);
static inline unsigned int   MulleObjCIniFoundation_get_version_patch( void);

extern uint32_t   MulleObjCIniFoundation_get_version( void);
```

- The three inline functions extract the major, minor and patch components from
  `MULLE_OBJC_INI_FOUNDATION_VERSION`.
- `MulleObjCIniFoundation_get_version()` returns the full packed 32-bit value.

#### Property list format constant

```c
enum
{
   MullePropertyListINIFormat = 7
};
```

- Format tag registered with `NSPropertyListSerialization` by this library's
  `+load` method. Passing it makes serialization use `-parseData:` for parsing
  and `-mullePrintINIToStream:` for printing.

### 3.2. `MulleINIParser.h`

#### `@interface MulleINIParser : NSObject`

- **Purpose:** Parses INI/CFG text into an `NSDictionary` of `NSDictionary`
  objects. Retains the most recent result.
- **Key properties:**
  - `@property( retain) id   userInfo;` — free-form slot for caller data.
  - `@property( retain) id   object;` — most recent parsed result
    (or `nil`).
- **Lifecycle:**
  - `- (id) parseData:(NSData *) data;` — parse the bytes of `data` as UTF-8
    INI. Returns an `NSDictionary` or `nil` if `data` is `nil`.
  - `- (id) parseBytes:(void *) bytes length:(NSUInteger) length;` — parse a
    raw byte buffer of `length` bytes. Returns an `NSDictionary` or `nil` when
    `bytes` is `NULL` or `length` is `0`. Also stores the result in `object`.
  - `- (void) reset;` — release and clear `userInfo` and `object`.
- **Parsing rules (as documented in the header and confirmed by tests):**
  - `[section]` — section header, trimmed, optional surrounding quotes stripped.
  - `key = value` — `=` separator; whitespace trimmed around key and value.
  - `key : value` — `:` separator also accepted.
  - `; comment` / `# comment` — full-line comment, skipped.
  - `key = val ; inline` / `key = val # inline` — inline `;` or `#` truncates
    the value when outside quotes.
  - `key = "quoted"` — double quotes stripped; `\"` and `\\` (and `\n`, `\r`,
    `\t`) escapes processed.
  - `key = 'quoted'` — single quotes stripped; no escaping.
  - `"key with spaces" = v` — double-quoted key, quotes stripped.
  - `empty_key =` — empty value becomes `@""`.
  - Keys before any `[section]` are stored under section key `@""`.
  - Duplicate keys — last one wins.
  - NOT supported: line continuation, `${var}` interpolation, type coercion.

#### `@interface NSString( MulleINIParser)`

- `- (id) mulleINI;` — parse the receiver as INI text; returns a nested
  `NSDictionary` or `nil` on error. Convenience wrapper around a temporary
  `MulleINIParser`.

### 3.3. `MulleObjCPropertyListPrinting+INI.h`

#### `@interface NSObject( MulleObjCPropertyListPrinting_INI)`

- **Purpose:** Writes an `NSDictionary` shaped as section -> key -> value as
  INI text. Declared on `NSObject`, but only useful for `NSDictionary`
  receivers (other receivers are ignored).
- **Expected structure:** keys are `NSString` section names; values are
  `NSDictionary` objects whose keys and values are `NSString` objects.
- **Core operations:**
  - `- (void) mullePrintINIToStream:(id) handle;` — appends the INI text to
    `handle`, an `NSMutableData`-like object that responds to `-appendData:`.
    The global section (`@""`) is written first without a header; other sections
    are written as `[name]\n` followed by `key=value\n` lines. Section names
    and keys are sorted for deterministic output.
  - `- (NSString *) mulleINIDescription;` — returns the INI text as an
    `NSString`, using an internal `NSMutableData` sink.

## 4. Performance Characteristics

- **Parsing:** `-parseBytes:length:` is a single left-to-right pass over the
  input; overall O(n) in the number of input bytes. Each key/value insertion
  into a dictionary is amortized O(1).
- **Writing:** O(s + k log k) where `s` is the number of sections and `k` the
  number of keys per section, due to sorting sections and keys.
- **Memory:** Input bytes are not modified; temporary buffers are allocated per
  quoted token and returned as `NSString` objects. Parsed strings are
  autoreleased in the default autorelease pool.
- **Thread safety:** Not thread-safe. A `MulleINIParser` instance is stateful
  (`object`, `userInfo`) and must not be shared across threads without external
  locking. `+instance` returns a per-thread/per-universe instance as provided by
  MulleObjC, but concurrent use of the same instance is still unsafe.

## 5. AI Usage Recommendations & Patterns

- **Best practices:**
  - Obtain parsers with the factory method `[MulleINIParser instance]` rather
    than `-new` / `-alloc` / `-init`.
  - Reuse a parser via `-reset` between parses instead of creating new ones.
  - Use `-mulleINI` on `NSString` for a quick, one-off parse.
  - Treat the returned dictionary as immutable; if you need to mutate it, copy
    it into mutable containers yourself.
- **Common pitfalls:**
  - Values are always `NSString`; cast/convert to numbers explicitly.
  - A section always exists as a (possibly empty) `NSDictionary`; an empty
    section is present with `count == 0`, not `nil`.
  - The global section key is the empty string `@""`, not `nil` or `@"global"`.
  - The printer does not escape special characters. Keys or values containing
    `=`, `#`, `;`, or leading/trailing spaces will round-trip incorrectly;
    quote or sanitize them beforehand.
  - `-mulleINI` returns `nil` on error, unlike `parseBytes:` which may return an
    empty dictionary for whitespace-only input.
- **Idiomatic usage:**
  - Parse with `parseBytes:length:` when you already hold a C buffer; use
    `parseData:` when you hold `NSData`; use `-mulleINI` for literals.
  - Write with `-mulleINIDescription` for a complete string, or
    `-mullePrintINIToStream:` to append into a larger `NSMutableData`.

## 6. Integration Examples

### Example 1: Parsing an INI buffer

```objc
#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>

#include <string.h>

int   main( void)
{
   static char      *text =
      "[dosbox]\n"
      "machine = vgaonly ; inline comment\n"
      "memsize : 4\n";
   MulleINIParser   *parser;
   NSDictionary     *config;
   NSDictionary     *section;

   parser  = [MulleINIParser instance];
   config  = [parser parseBytes:(void *) text
                        length:strlen( text)];
   section = [config objectForKey:@"dosbox"];

   mulle_printf( "machine=%s\n",
                 [[section objectForKey:@"machine"] UTF8String]);
   return( 0);
}
```

### Example 2: Parsing an `NSString` and reading the global section

```objc
#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>

int   main( void)
{
   NSString       *text;
   NSDictionary   *config;

   text   = @"global_key = global_value\n[section]\nkey = value\n";
   config = [text mulleINI];

   // keys before any [section] live under the empty-string section
   mulle_printf( "global_key=%s\n",
                 [[[config objectForKey:@""] objectForKey:@"global_key"] UTF8String]);
   return( 0);
}
```

### Example 3: Writing a dictionary as INI

```objc
#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>

int   main( void)
{
   NSMutableDictionary   *root;
   NSMutableDictionary   *global;
   NSMutableDictionary   *cpu;
   NSString              *output;

   global = [NSMutableDictionary dictionary];
   [global setObject:@"42" forKey:@"port"];

   cpu = [NSMutableDictionary dictionary];
   [cpu setObject:@"386" forKey:@"cputype"];

   root = [NSMutableDictionary dictionary];
   [root setObject:global forKey:@""];
   [root setObject:cpu    forKey:@"cpu"];

   output = [root mulleINIDescription];
   mulle_printf( "%@", output);
   return( 0);
}
```

### Example 4: Round-tripping through a stream sink

```objc
#import <MulleObjCINIFoundation/MulleObjCINIFoundation.h>

int   main( void)
{
   NSMutableData     *data;
   NSDictionary      *config;
   MulleINIParser    *parser;

   config = [@"[s]\nk=v\n" mulleINI];

   data = [NSMutableData dataWithCapacity:64];
   [config mullePrintINIToStream:data];

   parser = [MulleINIParser instance];
   [parser reset];
   config = [parser parseBytes:(void *) [data bytes]
                       length:[data length]];
   mulle_printf( "s.k=%s\n",
                 [[[config objectForKey:@"s"] objectForKey:@"k"] UTF8String]);
   return( 0);
}
```

## 7. Dependencies

Direct mulle-sde library dependencies (from `.mulle/etc/sourcetree/config`):

- `MulleFoundationBase` — provides MulleObjC, the Foundation classes
  (`NSDictionary`, `NSString`, `NSData`, `NSPropertyListSerialization`), and
  the `+instance` factory used by this library.

Build-time tooling dependency (not linked):

- `mulle-objc-tools` — provides the MulleObjC compiler and the code that
  generates `src/reflect/objc-deps.inc`.
