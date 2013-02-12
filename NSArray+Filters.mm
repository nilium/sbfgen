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

#import "NSArray+Filters.hh"

static NSString *const SPNilObjectMappingException = @"SPNilObjectMappingException";
static NSString *const SPNilObjectMappingExceptionReason = @"Objects returned by map blocks must not be nil.";
static NSString *const SPNoMemoryException = @"SPNoMemoryException";
static NSString *const SPNoMemoryExceptionReason = @"Unable to allocate objects array.";

// Mutates the given mutable array, removing blocks that match checkFor (TRUE or FALSE)
static void SPFilterArrayUsingBlock(NSMutableArray *arr, SPFilterBlock block, BOOL checkFor);
// Returns a new array filtered by removing blocks that match checkFor (TRUE or FALSE)
static NSArray *SPArrayFilteredUsingBlock(NSArray *arr, SPFilterBlock block, BOOL checkFor);


static NSArray *SPArrayFilteredUsingBlock(NSArray *arr, SPFilterBlock block, BOOL checkFor)
{
  NSArray *result = nil;
  __unsafe_unretained id *objects = NULL;
  NSUInteger index_filtered = 0;
  NSUInteger index = 0;
  const NSUInteger self_len = [arr count];
  const NSRange range = NSMakeRange(0, self_len);

  if (self_len == 0)
    return [arr copy];

  objects = (__unsafe_unretained id *)malloc(sizeof(id) * self_len);

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return nil;
  }

  [arr getObjects:objects range:range];

  for (index = 0, index_filtered = 0; index < self_len; ++index) {
    BOOL filter = block(objects[index]);

    if (filter == checkFor) {
      objects[index] = NULL;
    } else {
      if (index != index_filtered)
        objects[index_filtered] = objects[index];

      ++index_filtered;
    }
  }

  result = [[arr class] arrayWithObjects:objects count:index_filtered];

  free(objects);

  return result;
}


static void SPFilterArrayUsingBlock(NSMutableArray *arr, SPFilterBlock block, BOOL checkFor)
{
  __unsafe_unretained id *objects = NULL;
  NSUInteger index = 0;
  NSMutableIndexSet *indices = nil;
  const NSUInteger self_len = [arr count];
  const NSRange range = NSMakeRange(0, self_len);

  if (self_len == 0)
    return;

  objects = (__unsafe_unretained id *)malloc(sizeof(id) * self_len);

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return;
  }

  indices = [NSMutableIndexSet indexSet];
  [arr getObjects:objects range:range];

  for (index = 0; index < self_len; ++index)
    if (block(objects[index]) == checkFor)
      [indices addIndex:index];

  [arr removeObjectsAtIndexes:indices];

  free(objects);
}



@implementation NSArray (SPImmutableFilters)

- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block
{
  NSArray *result = nil;
  __unsafe_unretained id *objects = NULL;
  NSUInteger index = 0;
  const NSUInteger self_len = [self count];
  const NSRange range = NSMakeRange(0, self_len);

  if (self_len == 0)
    return [self copy];

  objects = (__unsafe_unretained id *)malloc(sizeof(id) * self_len);

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return nil;
  }

  [self getObjects:objects range:range];

  for (index = 0; index < self_len; ++index)
    if ( ! (objects[index] = block(objects[index]))) {
      free(objects);
      @throw [NSException exceptionWithName:SPNilObjectMappingException
                                     reason:SPNilObjectMappingExceptionReason
                                   userInfo:nil];
      return nil;
    }

  result = [[self class] arrayWithObjects:objects count:self_len];

  free(objects);

  return result;
}

- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block
{
  return SPArrayFilteredUsingBlock(self, block, TRUE);
}

- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block
{
  return SPArrayFilteredUsingBlock(self, block, FALSE);
}

- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block
{
  __unsafe_unretained id *objects = NULL;
  NSUInteger index = 0;
  const NSUInteger self_len = [self count];
  const NSRange range = NSMakeRange(0, self_len);

  if (self_len == 0)
    return nil;

  objects = (__unsafe_unretained id *)malloc(sizeof(id) * self_len);

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return nil;
  }

  [self getObjects:objects range:range];

  if (memo == nil) {
    memo = objects[0];
    index = 1;
  }

  for (; index < self_len; ++index)
    memo = block(memo, objects[index]);

  free(objects);

  return memo;
}

- (id)reduceUsingBlock:(SPReduceBlock)block
{
  return [self reduceWithInitialValue:nil usingBlock:block];
}

@end

@implementation NSMutableArray (SPMutableFilters)

- (void)mapUsingBlock:(SPMapBlock)block
{
  __unsafe_unretained id *objects = NULL;
  NSUInteger index = 0;
  const NSUInteger self_len = [self count];
  const NSRange range = NSMakeRange(0, self_len);

  if (self_len == 0)
    return;

  objects = (__unsafe_unretained id *)malloc(sizeof(id) * self_len);

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return;
  }

  [self getObjects:objects range:range];

  for (index = 0; index < self_len; ++index)
    if ( ! (objects[index] = block(objects[index]))) {
      free(objects);
      @throw [NSException exceptionWithName:SPNilObjectMappingException
                                     reason:SPNilObjectMappingExceptionReason
                                   userInfo:nil];
      return;
    }

  for (index = 0; index < self_len; ++index)
    [self replaceObjectAtIndex:index withObject:objects[index]];

  free(objects);
}

- (void)rejectUsingBlock:(SPFilterBlock)block
{
  SPFilterArrayUsingBlock(self, block, TRUE);
}

- (void)selectUsingBlock:(SPFilterBlock)block
{
  SPFilterArrayUsingBlock(self, block, FALSE);
}

@end