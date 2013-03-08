# sbfgen is copyright (c) 2013 Noel R. Cower.
#
# This file is part of sbfgen.
#
# sbfgen is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# sbfgen is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with sbfgen.  If not, see <http://www.gnu.org/licenses/>.

PRODUCT=sbfgen

CFLAGS+= -Wall
CFLAGS+= -g -O0
CFLAGS+= -fobjc-arc -fblocks
CFLAGS+= -DTARGET_OS_MAC
CFLAGS+= $(shell pkg-config --cflags snow-common)

CXXFLAGS+= -ObjC++ -std=c++11 -stdlib=libc++

LDFLAGS+= -framework Cocoa
LDFLAGS+= -lc++
LDFLAGS+= $(shell pkg-config --libs snow-common)

SOURCES:=\
  BitmapFont.mm \
  FontPage.mm \
  GlyphInfo.mm \
  NSFilters.mm \
  NSRange+foreach.mm \
  sbfgen.mm

OBJECTS:=\
  BitmapFont.o \
  FontPage.o \
  GlyphInfo.o \
  NSFilters.o \
  NSRange+foreach.o \
  sbfgen.o

.PHONY: all clean

all: $(PRODUCT)

$(PRODUCT): $(OBJECTS)
	$(CXX) $(LDFLAGS) $^ -o $@

BitmapFont.o: BitmapFont.mm BitmapFont.hh GlyphInfo.hh FontPage.hh NSFilters.hh NSRange+foreach.hh
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

FontPage.o: FontPage.mm FontPage.hh GlyphInfo.hh BitmapFont.hh
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

GlyphInfo.o: GlyphInfo.mm GlyphInfo.hh
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

NSFilters.o: NSFilters.mm NSFilters.hh
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

NSRange+foreach.o: NSRange+foreach.mm NSRange+foreach.hh
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

sbfgen.o: sbfgen.mm BitmapFont.hh
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJECTS) $(PRODUCT)
