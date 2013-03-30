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

#ifndef __SBFGEN_FONTPAGE_HH__
#define __SBFGEN_FONTPAGE_HH__

#import <Cocoa/Cocoa.h>
#import <snow/types/types_2d.hh>
#import <snow/math/vec2.hh>
#import <snow/types/slot_image.hh>

#define kSFontPageBitmapInfoFlags (kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst)

@class SBitmapFont;
@class SGlyphInfo;

@interface SFontPage : NSObject
{
  __weak SBitmapFont *_owner;
  NSMutableArray *_glyphs;
  NSMutableDictionary *_glyph_paths;
  snow::slot_image_t<> _bins;
  NSUInteger _padding;
  CGContextRef _context;
  void *_storage;
}

- (id)initWithPageSize:(snow::dimensi_t)dimens owner:(SBitmapFont *)owner;

// Returns true if glyph was successfully added or is already in the page, false
// if the page is full.
- (BOOL)addGlyph:(SGlyphInfo *)info;
- (void)finalizePage;

@property (readonly) BOOL empty;
@property (readonly) const void *bitmapData;
@property (copy) NSArray *glyphs;

@end

#endif /* end __SBFGEN_FONTPAGE_HH__ include guard */
