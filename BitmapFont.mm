/*
sbfgen is copyright (c) 2013 Noel R. Cower.

This file is part of sbfgen.

sbfgen is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

sbfgen is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with sbfgen.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "BitmapFont.hh"
#import "GlyphInfo.hh"
#import "FontPage.hh"
#import "NSRange+foreach.hh"
#import "NSFilters.hh"
#import <cmath>

using namespace snow;

// Uncomment to sort by longest edge, otherwise sorts by glyph height (this
// tends to be more optimal than sorting by longest edge).
// #define SORT_BY_LONGEST_EDGE


static NSComparisonResult (^g_glyph_size_comparator)(NSBezierPath *, NSBezierPath *) =
  ^(NSBezierPath *left, NSBezierPath *right) {
    NSSize left_size, right_size;
    double max_left, max_right;
    left_size = left.bounds.size;
    right_size = right.bounds.size;

  #ifdef SORT_BY_LONGEST_EDGE
    max_left = std::max(left_size.width, left_size.height);
    max_right = std::max(right_size.width, right_size.height);
    if (max_left == max_right) {
      max_left = std::min(left_size.width, left_size.height);
      max_right = std::min(right_size.width, right_size.height);
    }
  #else
    max_left = left_size.width;
    max_right = right_size.width;
    if (max_left == max_right) {
      max_left = left_size.height;
      max_right = right_size.height;
    }
  #endif
    if (max_left > max_right)
      return NSOrderedDescending;
    else if (max_left < max_right)
      return NSOrderedAscending;
    else
      return NSOrderedSame;
  };

static NSComparisonResult (^g_glyph_page_code_comparator)(SGlyphInfo *, SGlyphInfo *) =
  ^(SGlyphInfo *left, SGlyphInfo *right) {
    if (left.pageIndex < right.pageIndex) {
      return NSOrderedAscending;
    } else if (left.pageIndex > right.pageIndex) {
      return NSOrderedDescending;
    } else {
      if (left.character < right.character) {
        return NSOrderedAscending;
      } else if (left.character > right.character) {
        return NSOrderedDescending;
      }
    }
    return NSOrderedSame;
  };

@interface SBitmapFont ()

@property (strong, readwrite) NSFont *font;

- (void)addGlyphsToPages;

@end

@implementation SBitmapFont

@synthesize font = _font;

- (id)initWithFont:(NSFont *)font pageSize:(snow::dimensi_t)size
{
  self = [super init];
  if (self) {
    _glyphs = [NSMutableSet new];
    _pages = [NSMutableArray new];
    _pageSize = size;
    self.font = font;
    _workQueue = dispatch_queue_create("sbfgen.bmf.work_queue", DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (void)dealloc
{
}

- (void)enumeratePageBitmapsUsingBlock:(SBitmapEnumBlock)block
{
  BOOL stop = NO;
  for (SFontPage *page in _pages) {
    if (!page.empty) {
      [page finalizePage];
      block(page.bitmapData, _pageSize, &stop);

      if (stop) {
        return;
      }
    }
  }
}

#define ARBITRARILY_LARGE_BOUND (10000)

- (NSArray *)getKernings
{
  NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"character" ascending:YES];
  NSMutableArray *kerns = [NSMutableArray new];
  NSArray *sorted_glyphs = [_glyphs sortedArrayUsingDescriptors:@[desc]];
  NSDictionary *attrs = @{NSFontAttributeName: _font};
  NSSize container_size = { ARBITRARILY_LARGE_BOUND, ARBITRARILY_LARGE_BOUND };
  // Create a group so we can do the inner loop asynchronously.
  dispatch_group_t work_group = dispatch_group_create();
  for (SGlyphInfo *info in sorted_glyphs) {
    // This is basically the closest I'll get to making this any faster
    UniChar first_char = info.character;
    dispatch_group_async(work_group, _workQueue, ^{ @autoreleasepool {
      const NSRange char_range = {0, 2};
      UniChar chars[2] = {first_char, 'a'};
      NSTextStorage *storage;
      NSLayoutManager *layman;
      NSTextContainer *container;

      // And this is just plain evil, probably.
      layman = [[NSLayoutManager alloc] init];
      container = [[NSTextContainer alloc] initWithContainerSize:container_size];
      storage = [[NSTextStorage alloc] initWithString:@"xy" attributes:attrs];

      [layman addTextContainer:container];
      [storage addLayoutManager:layman];

      for (SGlyphInfo *next_info in sorted_glyphs) {
        NSRange glyph_range;
        NSPoint loc_first;
        NSPoint loc_second;
        float kern;
        NSString *gen_string;

        chars[1] = next_info.character;
        gen_string = [[NSString alloc] initWithCharactersNoCopy:chars length:2 freeWhenDone:NO];
        [storage replaceCharactersInRange:char_range withString:gen_string];

        glyph_range = [layman glyphRangeForTextContainer:container];
        loc_first = [layman locationForGlyphAtIndex:glyph_range.location];
        loc_second = [layman locationForGlyphAtIndex:glyph_range.location + 1];

        kern = (float)((loc_second.x - info.advance.width) - loc_first.x);

        if (std::fabs(kern) > 1e-4) {
          @synchronized(kerns) {
            [kerns addObject:@{
              @"first": @((NSUInteger)chars[0]),
              @"second": @((NSUInteger)chars[1]),
              @"amount": @(kern),
            }];
          }
        }
      }
    }});
  }
  dispatch_group_wait(work_group, DISPATCH_TIME_FOREVER);
  [kerns sortUsingDescriptors:@[
    [NSSortDescriptor sortDescriptorWithKey:@"first" ascending:YES],
    [NSSortDescriptor sortDescriptorWithKey:@"second" ascending:YES]
   ]];
  return [kerns copy];
}

- (void)writePagesToFilesWithPrefix:(NSString *)prefix prettyPrint:(BOOL)pp
{
  [_pages rejectUsingBlock:^(SFontPage *page) { return page.empty; }];

  __block int index = 1;
  NSString *basename = _font.fontName;

  [self addGlyphsToPages];

  [self enumeratePageBitmapsUsingBlock:^(const void *bmp, dimensi_t size, BOOL *stop) {
    NSString *filename = nil;
    NSBitmapImageRep *image_rep = nil;
    NSError *error = nil;
    CGDataProviderRef provider = nullptr;
    CGColorSpaceRef color_space = nullptr;
    CGImageRef image = nullptr;
    const size_t bmpSize = size.area() * 4;

    if (prefix)
      filename = [NSString stringWithFormat:@"%@%@_%d.png", prefix, basename, index, NULL];
    else
      filename = [NSString stringWithFormat:@"%@_%d.png", basename, index, NULL];

    color_space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    provider = CGDataProviderCreateWithData(nullptr, bmp, bmpSize, nullptr);
    image = CGImageCreate(size.width, size.height, 8, 32, size.width * 4,
                          color_space, kSFontPageBitmapInfoFlags, provider,
                          nullptr, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(color_space);

    image_rep = [[NSBitmapImageRep alloc]
                 initWithCGImage:image];
    [[image_rep representationUsingType:NSPNGFileType properties:@{}]
     writeToFile:filename options:0 error:&error];
    ++index;
  }];

  NSArray *sorted_glyphs = [[_glyphs allObjects]
                            sortedArrayUsingComparator:g_glyph_page_code_comparator];
  NSString *font_file;

  if (prefix)
    font_file = [NSString stringWithFormat:@"%@%@.json", prefix, basename, NULL];
  else
    font_file = [NSString stringWithFormat:@"%@.json", basename, NULL];

  CGRect bbox = CTFontGetBoundingBox((__bridge CTFontRef)_font);

  NSLayoutManager *layman = [[NSLayoutManager alloc] init];

  NSMutableDictionary *out = [NSMutableDictionary new];

  [out addEntriesFromDictionary: @{
    @"name": _font.fontName,
    @"pages": @([_pages count]),
    @"line_height": @([layman defaultLineHeightForFont:_font]),
    @"leading": @((float)CTFontGetLeading((__bridge CTFontRef)_font)),
    @"ascent": @((float)CTFontGetAscent((__bridge CTFontRef)_font)),
    @"descent": @((float)CTFontGetDescent((__bridge CTFontRef)_font)),
    @"bbox": @{
      // Basically, we're dropping precision here to avoid a lot of numbers that end in 00001
      @"x_min": @((float)bbox.origin.x),
      @"y_min": @((float)bbox.origin.y),
      @"x_max": @((float)bbox.size.width),
      @"y_max": @((float)bbox.size.height)
    },
    @"glyphs": [sorted_glyphs mappedArrayUsingBlock:^(SGlyphInfo *glyph) { return [glyph infoDictionary]; } queue:_workQueue]
  }];

  NSArray *kernings = [self getKernings];
  if ([kernings count] > 0)
    out[@"kernings"] = kernings;

  NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:font_file append:NO];
  [stream open];
  [NSJSONSerialization writeJSONObject:out
   toStream:stream
   options:(pp ? NSJSONWritingPrettyPrinted : 0) error:NULL];
  [stream close];
}

- (void)addGlyphsForCharactersInRange:(NSRange)chars
{
  NSSet *char_set = [_glyphs mappedSetUsingBlock:^(SGlyphInfo *info) { return @(info.character); } queue:_workQueue];
  NSRangeInclEach(chars, ^(NSUInteger char_loc, BOOL *stop) {
    // Basically, if the character is already in the font, skip it
    if ([char_set member:@((UniChar)char_loc)])
      return;

    SGlyphInfo *info = [[SGlyphInfo alloc] initWithFont:_font character:(UniChar)char_loc];
    if (info) {
      auto size = info.path.bounds.size;

      // Skip unusable glyphs
      if (size.width > _pageSize.width || size.height > _pageSize.height)
        return;

      [_glyphs addObject:info];
    }
  });
}

- (BOOL)addGlyphForCharacter:(UniChar)character
{
  SGlyphInfo *info = [[SGlyphInfo alloc] initWithFont:_font character:character];
  if (info) {
    [_glyphs addObject:info];
  }
  return NO;
}

- (void)addGlyphsToPages
{
  NSSortDescriptor *sort_desc;
  NSArray *sorted_glyphs;

  sort_desc = [[NSSortDescriptor alloc]
               initWithKey:@"path" ascending:NO comparator:g_glyph_size_comparator];
  sorted_glyphs = [_glyphs sortedArrayUsingDescriptors:@[sort_desc]];
  for (SGlyphInfo *info in sorted_glyphs) {
    NSUInteger pageIndex = 0;
    BOOL added_to_page = NO;

    for (SFontPage *page in _pages) {
      if ((added_to_page = [page addGlyph:info]))
        break;
      ++pageIndex;
    }

    if (!added_to_page) {
      SFontPage *new_page = [[SFontPage alloc] initWithPageSize:_pageSize owner:self];
      [_pages addObject:new_page];
      added_to_page = [new_page addGlyph:info];
    }

    if (!added_to_page)
      [_glyphs removeObject:info];
    else
      info.pageIndex = pageIndex;
  }
}

@end
