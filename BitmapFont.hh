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

#ifndef __SBFGEN_BITMAPFONT_HH__
#define __SBFGEN_BITMAPFONT_HH__

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>
#import <snow/types/types_2d.hh>

typedef void (^SBitmapEnumBlock)(const void *bitmap, snow::dimensi_t size, BOOL *stop);

@interface SBitmapFont : NSObject
{
  NSMutableSet *_glyphs;
  NSMutableArray *_pages;
  snow::dimensi_t _pageSize;
  dispatch_queue_t _workQueue;
}

@property (strong, readonly) NSFont *font;
@property (readwrite) NSUInteger padding;

- (id)initWithFont:(NSFont *)font pageSize:(snow::dimensi_t)size;
- (void)enumeratePageBitmapsUsingBlock:(SBitmapEnumBlock)block;
- (void)addGlyphsForCharactersInRange:(NSRange)chars;
- (BOOL)addGlyphForCharacter:(UniChar)character;
- (void)writePagesToFilesWithPrefix:(NSString *)prefix prettyPrint:(BOOL)pp;

@end

#endif /* end __SBFGEN_BITMAPFONT_HH__ include guard */
