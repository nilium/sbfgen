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

#ifndef __SBFGEN_NSARRAY_FILTERS_HH__
#define __SBFGEN_NSARRAY_FILTERS_HH__

#import <Foundation/Foundation.h>

typedef id (^SPMapBlock)(id obj);
typedef BOOL (^SPFilterBlock)(id obj);
typedef id (^SPReduceBlock)(id memo, id obj);

@interface NSArray (SPImmutableFilters)

// map
- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block;
// reject
- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block;
// select
- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;
// reduce (memo is first value)
- (id)reduceUsingBlock:(SPReduceBlock)block;

@end

@interface NSMutableArray (SPMutableFilters)

// map
- (void)mapUsingBlock:(SPMapBlock)block;
// reject
- (void)rejectUsingBlock:(SPFilterBlock)block;
// select
- (void)selectUsingBlock:(SPFilterBlock)block;

@end

#endif /* end __SBFGEN_NSARRAY_FILTERS_HH__ include guard */

