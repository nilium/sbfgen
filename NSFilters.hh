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

#ifndef __SNOW_NSFILTERS_HH__
#define __SNOW_NSFILTERS_HH__

/*
All map/select/reject operations can be performed asynchronously (provided your
block is fine under those conditions). They will block execution of the calling
thread until complete - if you want to run them without blocking, use
dispatch_async to call them, though bear in mind that for mutable containers,
you should not modify them while the operation is running (this sounds obvious,
but obvious things often have to be said).

map blocks must return non-nil objects (because you can't store nil in any
Cocoa containers - if you must, use NSNull).

Async map/reject/select will allow you to use an arbitrary stride. By default,
if you exclude the stride, they will use the NSFiltersDefaultStride of 256.
*/

@interface NSArray (SPImmutableArrayFilters)

// map
- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block;
- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// reject
- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block;
- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// select
- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block;
- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;
// reduce (memo is nil)
- (id)reduceUsingBlock:(SPReduceBlock)block;

@end

@interface NSMutableArray (SPMutableArrayFilters)

// map
- (id)mapUsingBlock:(SPMapBlock)block;
- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// reject
- (id)rejectUsingBlock:(SPFilterBlock)block;
- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// select
- (id)selectUsingBlock:(SPFilterBlock)block;
- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;

@end

@interface NSSet (SPImmutableSetFilters)

// map
- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block;
- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// reject
- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block;
- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// select
- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block;
- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;
// reduce (memo is nil)
- (id)reduceUsingBlock:(SPReduceBlock)block;

// auxiliary getObjects:count: to place set objects in an unretained array
- (void)getUnsafeObjects:(__unsafe_unretained id *)objects count:(NSUInteger)count;

@end

@interface NSMutableSet (SPMutableSetFilters)

// map
- (id)mapUsingBlock:(SPMapBlock)block;
- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue;
- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// reject
- (id)rejectUsingBlock:(SPFilterBlock)block;
- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;
// select
- (id)selectUsingBlock:(SPFilterBlock)block;
- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue;
- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride;

@end

#endif /* end __SNOW_NSFILTERS_HH__ include guard */

