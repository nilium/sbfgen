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

// The minimum glyph size in pixels.
#define MIN_GLYPH_SIZE (5)

// Uncomment to use the nearest multiple of five when fitting glyphs into the
// texture packer. If commented, it uses the nearest power of two. In most cases
// it's better to use a multiple of five, though if the font fits well into a
// POT size then you may want to use the latter, as it will produce more uniform
// and usually better-packed glyphs.
#define USE_NEAREST_FIVE

// Uncomment to use square bins - that is, each glyph gets assigned a bin where
// its width and height are equal. Otherwise, width and height may differ
// according to nearestFunc (which defaults to the nearest multiple of five).
// #define USE_SQUARE_BINS

// Uncomment to enable drawing of colored rectangles around bins (both used and
// unused). This is only really useful for debugging and should otherwise be
// left alone.
// #define DEBUG_DRAW_BINS



#ifdef DEBUG_DRAW_BINS
static void drawBins(const binpack_t *bin) {
  [(bin->loaded() ? [NSColor blueColor] : [NSColor orangeColor]) setStroke];
  auto frame = bin->frame();
  NSRect stroke_rect = {
    { (CGFloat)frame.origin.x, (CGFloat)frame.origin.y },
    { (CGFloat)frame.size.width, (CGFloat)frame.size.height }
  };
  [NSBezierPath strokeRect:stroke_rect];
  if (bin->bottom())
    drawBins(bin->bottom());
  if (bin->right())
    drawBins(bin->right());
}
#endif

#ifdef USE_NEAREST_FIVE

static int nearestFunc(int x) {
  return (x / 5) * 5;
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
    _bins = new binpack_t(size);
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

  binpack_t *bin = _bins->find_unused_bin(glyph_size);
  // if (bin)
    // std::clog << bin->frame() << std::endl;
  if (bin) {
    NSRect glyph_rect;
    auto origin = bin->origin();

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
  delete _bins;
  CGContextRelease(_context);
  free(_storage);
}

- (BOOL)empty
{
  return [_glyphs count] > 0;
}

@end
