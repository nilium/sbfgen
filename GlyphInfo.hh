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

#ifndef __SBFGEN_GLYPHINFO_HH__
#define __SBFGEN_GLYPHINFO_HH__

#import <Cocoa/Cocoa.h>

@interface SGlyphInfo : NSObject

@property (readonly) NSFont *font;
@property (readonly) UniChar character;
@property (readonly) CGGlyph glyph;
@property (readonly) NSBezierPath *path;
@property (readwrite) NSRect glyphFrame;
@property (readwrite) NSUInteger pageIndex;
@property (readonly) CGSize advance;
@property (readonly) CGRect bbox;

- (id)initWithFont:(NSFont *)font character:(UniChar)character;
- (NSDictionary *)infoDictionary;

@end

#endif /* end __SBFGEN_GLYPHINFO_HH__ include guard */
