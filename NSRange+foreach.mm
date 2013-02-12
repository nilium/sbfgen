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

#import "NSRange+foreach.hh"

void NSRangeInclEach(NSRange range, range_each_block_t block)
{
  BOOL stop = NO;
  NSUInteger location = range.location;
  const NSUInteger sentinel = location + range.length;
  for (; !stop && location <= sentinel; ++location)
    block(location, &stop);
}

void NSRangeExclEach(NSRange range, range_each_block_t block)
{
  BOOL stop = NO;
  NSUInteger location = range.location;
  const NSUInteger sentinel = location + range.length;
  for (; !stop && location < sentinel; ++location)
    block(location, &stop);
}
