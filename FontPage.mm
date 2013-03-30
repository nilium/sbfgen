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

#import "FontPage.hh"
#import "GlyphInfo.hh"
#import "BitmapFont.hh"
#import <cmath>

using namespace snow;

// The size of a cell in the font page's bins
#define CELL_SIZE (4)

// The minimum glyph size in pixels.
#define MIN_GLYPH_SIZE CELL_SIZE

// Uncomment to use the nearest multiple of five when fitting glyphs into the
// texture packer. If commented, it uses the nearest power of two. In most cases
// it's better to use a multiple of five, though if the font fits well into a
// POT size then you may want to use the latter, as it will produce more uniform
// and usually better-packed glyphs.
// #define USE_NEAREST_FIVE

// Uncomment to use square bins - that is, each glyph gets assigned a bin where
// its width and height are equal. Otherwise, width and height may differ
// according to nearestFunc (which defaults to the nearest multiple of five).
// #define USE_SQUARE_BINS


inline static snow::vec2_t<size_t> cells_for_size(const snow::dimensi_t &dims) {
  return {
    (size_t)dims.width / CELL_SIZE + 1,
    (size_t)dims.height / CELL_SIZE + 1,
  };
}

inline static snow::vec2f_t cells_to_pos(const snow::vec2_t<size_t> &cells) {
  return {
    (float)cells.x * CELL_SIZE,
    (float)cells.y * CELL_SIZE
  };
}

#define USE_NEAREST_SCALAR 1
#ifdef USE_NEAREST_SCALAR

static int nearestFunc(int x) {
  int nearest = 0;
  while (nearest < x) nearest += USE_NEAREST_SCALAR;
  return nearest;
}

#else

static int nearestFunc(int x) {
  int nearest = 1;
  while (nearest < x) nearest <<= 1;
  return nearest;
}

#endif

@implementation SFontPage

@synthesize glyphs = _glyphs;
@synthesize bitmapData = _storage;
@dynamic empty;

- (id)initWithPageSize:(dimensi_t)size owner:(SBitmapFont *)owner
{
  self = [super init];
  if (self) {
    CGColorSpaceRef color_space = NULL;

    _padding = owner.padding;
    _owner = owner;
    _glyph_paths = [NSMutableDictionary new];
    _glyphs = [NSMutableArray new];
    _bins.resize({(size_t)size.width / CELL_SIZE, (size_t)size.height / CELL_SIZE});
    _storage = calloc(4 * size.width, size.height);

    color_space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    _context = CGBitmapContextCreate(_storage, size.width, size.height,
      8, 4 * size.width, color_space, kSFontPageBitmapInfoFlags);
    CGColorSpaceRelease(color_space);
  }
  return self;
}

- (BOOL)addGlyph:(SGlyphInfo *)info
{
  NSNumber *glyph_key = @(info.glyph);
  NSBezierPath *path = info.path;
  if (_glyph_paths[glyph_key])
    return YES;

  NSRect glyph_bounds = path.bounds;
  int req_width = std::max(MIN_GLYPH_SIZE, nearestFunc((int)std::ceil(glyph_bounds.size.width) + _padding * 2));
  int req_height = std::max(MIN_GLYPH_SIZE, nearestFunc((int)std::ceil(glyph_bounds.size.height) + _padding * 2));
#ifdef USE_SQUARE_BINS
  int req_size = std::max(req_width, req_height);
#endif

  dimensi_t glyph_size = {
#ifdef USE_SQUARE_BINS
    req_size, req_size
#else
    req_width, req_height
#endif
  };

  auto cell_size = cells_for_size(glyph_size);
  auto pair = _bins.find_free_pos(cell_size);

  if (pair.first) {
    _bins.consume_subimage(pair.second, cell_size, info.character);
    NSRect glyph_rect;
    auto origin = cells_to_pos(pair.second);

    path = [path copy];
    glyph_rect = NSMakeRect(origin.x + _padding, origin.y + _padding,
                            glyph_bounds.size.width, glyph_bounds.size.height);

    NSAffineTransform *tform = [NSAffineTransform transform];
    [tform translateXBy:-glyph_bounds.origin.x yBy:-glyph_bounds.origin.y];
    [tform translateXBy:glyph_rect.origin.x yBy:glyph_rect.origin.y];
    [path transformUsingAffineTransform:tform];

    info.glyphFrame = path.bounds;
    _glyph_paths[glyph_key] = path;

    return YES;
  }

  return NO;
}

- (void)finalizePage
{
  NSGraphicsContext *ctx;

  ctx = [NSGraphicsContext graphicsContextWithGraphicsPort:_context flipped:NO];
  [NSGraphicsContext setCurrentContext:ctx];
  [[NSColor whiteColor] setFill];

  for (NSBezierPath *path in [_glyph_paths allValues])
    [path fill];

#ifdef DEBUG_DRAW_BINS
  drawBins(_bins);
#endif
}

- (void)dealloc
{
  CGContextRelease(_context);
  free(_storage);
}

- (BOOL)empty
{
  return [_glyphs count] > 0;
}

@end
