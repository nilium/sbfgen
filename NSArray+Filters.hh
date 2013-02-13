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

@interface NSArray (SPImmutableArrayFilters)

// map
- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block;
- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
// reject
- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block;
- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
// select
- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block;
- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;
// reduce (memo is first value)
- (id)reduceUsingBlock:(SPReduceBlock)block;

@end

@interface NSMutableArray (SPMutableArrayFilters)

// map
- (void)mapUsingBlock:(SPMapBlock)block;
- (void)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
// reject
- (void)rejectUsingBlock:(SPFilterBlock)block;
- (void)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
// select
- (void)selectUsingBlock:(SPFilterBlock)block;
- (void)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

@end

@interface NSSet (SPImmutableSetFilters)

// map
- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block;
- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
// reject
- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block;
- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
// select
- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block;
- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;
// reduce (memo is first value)
- (id)reduceUsingBlock:(SPReduceBlock)block;

@end

@interface NSMutableSet (SPMutableSetFilters)

// map
- (void)mapUsingBlock:(SPMapBlock)block;
- (void)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
// reject
- (void)rejectUsingBlock:(SPFilterBlock)block;
- (void)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
// select
- (void)selectUsingBlock:(SPFilterBlock)block;
- (void)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

@end

#endif /* end __SBFGEN_NSARRAY_FILTERS_HH__ include guard */

