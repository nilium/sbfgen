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

#import <Cocoa/Cocoa.h>
#import <string>
#import <map>
#import <snow/types/types_2d.hh>
#import <vector>
#import "BitmapFont.hh"

// TODO: Add better handling of non-ASCII characters for working on the command-
// line, since right now it sucks.

static const snow::dimensi_t g_invalid_page_size = { -1, -1 };

static const CGFloat g_default_font_size = 15.0f;

static const std::string g_help_flag_long { "--help" };
static const std::string g_help_flag_short { "-h" };
static const std::string g_font_flag_long { "--font" };
static const std::string g_font_flag_short { "-f" };
static const std::string g_font_size_flag_long { "--font-size" };
static const std::string g_font_size_flag_short { "-s" };
static const std::string g_page_size_flag_long { "--page-size" };
static const std::string g_page_size_flag_short { "-p" };
static const std::string g_padding_flag_long { "--padding" };
static const std::string g_padding_flag_short { "-i" };
static const std::string g_prefix_flag_long { "--prefix" };
static const std::string g_prefix_flag_short { "-x" };
static const std::string g_chars_flag_long { "--chars" };
static const std::string g_chars_flag_short { "-c" };
static const std::string g_pretty_print_flag_long { "--pretty-print" };
static const std::string g_pretty_print_flag_short { "-t" };

enum argcheck_state_t {
  GET_OPTION,
  GET_FONT_NAME,
  GET_FONT_SIZE,
  GET_PAGE_SIZE,
  GET_PADDING,
  GET_PREFIX,
  GET_CHARS,
  SET_PRETTY_PRINT,
  GET_HELP_TEXT,
};

typedef std::string::size_type charloc_t;
typedef std::map<std::string, argcheck_state_t> option_map_t;

static const option_map_t g_option_map {
  std::make_pair(g_help_flag_short,         GET_HELP_TEXT),
  std::make_pair(g_help_flag_long,          GET_HELP_TEXT),
  std::make_pair(g_font_flag_short,         GET_FONT_NAME),
  std::make_pair(g_font_flag_long,          GET_FONT_NAME),
  std::make_pair(g_font_size_flag_short,    GET_FONT_SIZE),
  std::make_pair(g_font_size_flag_long,     GET_FONT_SIZE),
  std::make_pair(g_page_size_flag_short,    GET_PAGE_SIZE),
  std::make_pair(g_page_size_flag_long,     GET_PAGE_SIZE),
  std::make_pair(g_padding_flag_short,      GET_PADDING),
  std::make_pair(g_padding_flag_long,       GET_PADDING),
  std::make_pair(g_prefix_flag_short,       GET_PREFIX),
  std::make_pair(g_prefix_flag_long,        GET_PREFIX),
  std::make_pair(g_chars_flag_short,        GET_CHARS),
  std::make_pair(g_chars_flag_long,         GET_CHARS),
  std::make_pair(g_pretty_print_flag_short, SET_PRETTY_PRINT),
  std::make_pair(g_pretty_print_flag_long,  SET_PRETTY_PRINT),
};

static const std::string g_sbfgen_help_text {
  "sbfgen  --font|-f \"FontFamily[,bi##]\"\n"
  "        --chars|-c CHAR|CHAR_RANGE\n"
  "       [--font-size|-s SIZE]           (default: 15)\n"
  "       [--page-size|-p WIDTH[xHEIGHT]] (default: 256x256)\n"
  "       [--padding|-i PADDING]          (default: 4)\n"
  "       [--prefix|-x PREFIX]            (default: none)\n"
  "       [--pretty-print|-t]             (default: off)\n"
  "       [--help|-h]\n\n"
  "All fonts take on the last provided attributes. So, if you specify a\n"
  "font size of 12, all fonts specified thereafter will be sized 12. If you\n"
  "then specify a font of size 20, further fonts will be sized 20. The same\n"
  "applies to padding and page size as well.\n\n"
  "To specify a character to include in the font or a range of characters,\n"
  "use the --chars argument like so:\n\n"
  "   sbfgen --chars ASCII --chars 33-126 --chars 95\n\n"
  "This will tell it to include all characters within that range. These are\n"
  "not special character classes or ranges - they simply map to the decimal\n"
  "value of the characters. The only special case is when specifying\n"
  "the 'ASCII' range, which will include all printable ASCII characters in\n"
  "the range of 33-126 inclusive.\n\n"
  "By default, font sizes will be 15pt. You can override this by specifying\n"
  "the font size using --font-size or -s. Fonts 0 and under will revert\n"
  "to 15pt.\n\n"
  "Font flags include bold, italic, and weight. A font's flags follow the\n"
  "font family with a comma, such as 'FontName,ib15' specifies a bold and\n"
  "italic font with weight 15. Font weights must be in the range of\n"
  "0 to 15. The default weight is 5, which is the normal weight for fonts.\n\n"
  "sbfgen is licensed under the GPLv3. You should have received a copy of\n"
  "the GNU General Public License along with sbfgen. If not, see\n"
  "<http://www.gnu.org/licenses/>."
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
};

void display_help_exit(int code = 0)
{
  std::cout << g_sbfgen_help_text << std::endl;
  exit(code);
}

NSString *stoNSString(const std::string &string)
{
  return [NSString stringWithCString:string.c_str() encoding:NSUTF8StringEncoding];
}

NSFont *getFontSized(const std::string &fontName, const CGFloat size)
{
  // Read font family and flags, if specified
  std::string fontFamily = fontName;
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  charloc_t flagLoc = fontName.find(',');
  NSFontTraitMask traits = 0;
  NSUInteger weight = 5;

  if (flagLoc != std::string::npos) {
    fontFamily.resize(flagLoc);

    charloc_t lastNumIndex = std::string::npos;
    for (charloc_t flagIndex = flagLoc + 1; flagIndex < fontName.length(); ++flagIndex) {
      const char flagChar = fontName[flagIndex];

      switch (flagChar) {
        case 'b': case 'B': traits |= NSBoldFontMask; break;
        case 'i': case 'I': traits |= NSItalicFontMask; break;
        default: // weight and unknown flags
          if (isdigit(flagChar)) {
            if (lastNumIndex == std::string::npos || lastNumIndex + 1 != flagIndex) {
              weight = flagChar - '0';
              lastNumIndex = flagIndex;
            } else if (lastNumIndex + 1 == flagIndex) {
              weight = weight * 10 + (flagChar - '0');
              lastNumIndex = flagIndex;
            } else {
              goto font_weight_error;
            }
          } else {
            std::clog << "Unrecognized font flag '" << fontName[flagIndex] << "'" << std::endl;
          }
        break;
      }
    }
  }

  if (weight > 15) {
    font_weight_error:
    std::clog << "Invalid weight '" << weight << "' specified for font '" << fontName << "'. Exiting." << std::endl;
    return nil;
  }

  // Get the NSFont
  NSString *familyNameNS = nil;
  NSFont *fontNS = nil;

  familyNameNS = stoNSString(fontFamily);
  fontNS = [fontManager fontWithFamily:familyNameNS traits:traits weight:weight size:size];

  if (fontNS == nil) {
    std::clog << "No font found for family '" << fontName << "' with the given flags. Exiting." << std::endl;
  }

  return fontNS;
}

snow::dimensi_t readPageSizeArg(const std::string &argStr)
{
  snow::dimensi_t pageSize;

  charloc_t xLocation = argStr.find('x');
  if (xLocation == std::string::npos)
    xLocation = argStr.find('X');

  try {
    if (xLocation != std::string::npos) {
      // Height specified
      pageSize.width = std::stoi(argStr.substr(0, xLocation));
      pageSize.height = std::stoi(argStr.substr(xLocation + 1));
    } else {
      // Height = Width
      pageSize.width = pageSize.height = std::stoi(argStr);
    }
  } catch (std::invalid_argument invalidArgEx) {
    std::clog << "Exception (invalid_argument) converting size to integer: "
              << invalidArgEx.what() << std::endl;
    pageSize = g_invalid_page_size;
  } catch (std::out_of_range rangeEx) {
    std::clog << "Exception (out_of_range) converting size to integer: "
              << rangeEx.what() << std::endl;
    pageSize = g_invalid_page_size;
  }

  return pageSize;
}

NSRange readCharRangeArg(const std::string &argStr)
{
  NSRange char_range = {0, 0};

  if (argStr == "ASCII")
    return NSMakeRange(' ', '~' - ' ');

  charloc_t range_sep = argStr.find('-');

  try {
    if (range_sep != std::string::npos) {
      // Height specified
      char_range.location = std::stoi(argStr.substr(0, range_sep));
      char_range.length = std::stoi(argStr.substr(range_sep + 1)) - char_range.location;
    } else {
      // Height = Width
      char_range.location = std::stoi(argStr);
    }
  } catch (std::invalid_argument invalidArgEx) {
    std::clog << "Exception (invalid_argument) converting size to integer: "
              << invalidArgEx.what() << std::endl;
    char_range = {0, 0};
  } catch (std::out_of_range rangeEx) {
    std::clog << "Exception (out_of_range) converting size to integer: "
              << rangeEx.what() << std::endl;
    char_range = {0, 0};
  }

  return char_range;
}

int main(int argc, const char *argv[])
{
  typedef std::vector<NSRange> range_vector_t;
  @autoreleasepool {
    NSMutableArray *fonts = [NSMutableArray array];
    argcheck_state_t state = GET_OPTION;
    snow::dimensi_t pageSize = {256, 256};
    CGFloat fontSize = g_default_font_size;
    NSUInteger padding = 4;
    NSString *prefix = nil;
    BOOL use_pretty_print = NO;
    range_vector_t char_ranges;

    if (argc <= 1) {
      display_help_exit();
    }

    for (int argIndex = 1; argIndex < argc; ++argIndex) {
      const std::string argStr{argv[argIndex]};

      switch (state) {
        case GET_OPTION: {
          option_map_t::const_iterator iter = g_option_map.find(argStr);
          if (iter != g_option_map.end()) {
            state = iter->second;
            if (state == SET_PRETTY_PRINT) {
              use_pretty_print = true;
              state = GET_OPTION;
              continue;
            }
          } else {
            std::clog << "Invalid argument to sbfgen: " << argStr << std::endl;
            return 1;
          }
        } break;

        case GET_HELP_TEXT:
          display_help_exit();
          break;

        case GET_FONT_NAME: {
          if (fontSize <= 0.0f) {
            std::clog << "Font size not set, defaulting to 15pt" << std::endl;
            fontSize = g_default_font_size;
          }

          NSFont *fontNS = getFontSized(argStr, fontSize);
          if (fontNS == nil) {
            return 1;
          }
          SBitmapFont *bmpf = [[SBitmapFont alloc] initWithFont:fontNS pageSize:pageSize];
          bmpf.padding = padding;
          [fonts addObject:bmpf];
          state = GET_OPTION;
        } break; // GET_FONT_NAME

        case GET_FONT_SIZE: {
          state = GET_OPTION;
          fontSize = stoi(argStr);
        }break;

        case GET_PAGE_SIZE: {
          pageSize = readPageSizeArg(argStr);
          if (pageSize == g_invalid_page_size) {
            return 1;
          }
          state = GET_OPTION;
        } break; // GET_PAGE_SIZE

        case GET_PADDING: {
          padding = (NSUInteger)stoi(argStr);
          state = GET_OPTION;
        } break; // GET_PADDING

        case GET_PREFIX: {
          if (prefix != nil) {
            std::clog << "Prefix specified twice, ignoring previous prefix." << std::endl;
          }
          prefix = stoNSString(argStr);
          state = GET_OPTION;
        } break;

        case GET_CHARS: {
          char_ranges.push_back(readCharRangeArg(argStr));
          state = GET_OPTION;
        } break;

        case SET_PRETTY_PRINT: break; // handled in GET_OPTION

      } // switch (state)

    } // for (args)

    if (state == GET_HELP_TEXT) {
      display_help_exit();
    }

    if (state != GET_OPTION || [fonts count] == 0) {
      std::clog << "Incomplete arguments to sbfgen" << std::endl;
    }

    for (SBitmapFont *bmpfont in fonts) {
      if (char_ranges.empty()) {
        [bmpfont addGlyphsForCharactersInRange:NSMakeRange(' ', '~' - ' ')];
      } else {
        for (auto range : char_ranges) {
          [bmpfont addGlyphsForCharactersInRange:range];
        }
      }
      [bmpfont writePagesToFilesWithPrefix:prefix prettyPrint:use_pretty_print];
    }

  } // @autoreleasepool
  return 0;
}
