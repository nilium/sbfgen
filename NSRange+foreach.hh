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

#ifndef __SBFGEN_NSRANGE_FOREACH_HH__
#define __SBFGEN_NSRANGE_FOREACH_HH__

#import <Foundation/NSRange.h>

typedef void (^range_each_block_t)(NSUInteger location, BOOL *stop);

// Executes a block for each location in a given exclusive range (so, 1 length
// results in a single iteration for the first location).
void NSRangeInclEach(NSRange range, range_each_block_t block);
// The exclusive equivalent of NSRangeInclEach.
void NSRangeExclEach(NSRange range, range_each_block_t block);

#endif /* end __SBFGEN_NSRANGE_FOREACH_HH__ include guard */
