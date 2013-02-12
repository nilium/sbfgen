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

#import "GlyphInfo.hh"

@implementation SGlyphInfo {
  CGFontRef _cgfont;
  CGRect _bbox;
  CGSize _advance;
}

@synthesize font = _font;
@synthesize character = _character;
@synthesize glyph = _glyph;
@synthesize path = _path;

- (id)initWithFont:(NSFont *)font character:(UniChar)character
{
  self = [super init];
  if (self) {
    _font = font;
    _character = character;
    if (!CTFontGetGlyphsForCharacters((__bridge CTFontRef)font, &character, &_glyph, 1))
      return nil;

    _path = [NSBezierPath bezierPath];
    [_path moveToPoint:NSMakePoint(0, 0)];
    [_path appendBezierPathWithGlyph:_glyph inFont:font];
    _cgfont = CTFontCopyGraphicsFont((__bridge CTFontRef)font, nullptr);
    CTFontGetAdvancesForGlyphs((__bridge CTFontRef)_font, kCTFontHorizontalOrientation, &_glyph, &_advance, 1);
    CTFontGetBoundingRectsForGlyphs((__bridge CTFontRef)_font, kCTFontHorizontalOrientation, &_glyph, &_bbox, 1);

  }
  return self;
}

- (void)dealloc
{
  CGFontRelease(_cgfont);
}

- (NSDictionary *)infoDictionary
{
  return @{
    @"code": @((NSUInteger)_character),
    @"page": @(_pageIndex),
    @"frame": @{
      @"x":      @((float)_glyphFrame.origin.x),
      @"y":      @((float)_glyphFrame.origin.y),
      @"width":  @((float)_glyphFrame.size.width),
      @"height": @((float)_glyphFrame.size.height)
    },
    @"advances": @{
      @"x": @((float)_advance.width),
      @"y": @((float)_advance.height)
    },
    @"offsets": @{
      @"x": @((float)_bbox.origin.x),
      @"y": @((float)_bbox.origin.y)
    }
  };
}

@end
