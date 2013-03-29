#!/usr/bin/env ruby -w
require 'sqlite3'
require 'json'

STMT_CREATE_INFO_TABLE = "CREATE TABLE IF NOT EXISTS font_info(
  font_id INTEGER PRIMARY KEY,
  pages INTEGER,
  num_glyphs INTEGER,
  num_kernings INTEGER,
  line_height REAL,
  leading REAL,
  ascent REAL,
  descent REAL,
  page_width INTEGER,
  page_height INTEGER,
  bbox_min_x REAL,
  bbox_max_x REAL,
  bbox_min_y REAL,
  bbox_max_y REAL,
  name TEXT
)"
STMT_CREATE_GLYPH_TABLE = "CREATE TABLE IF NOT EXISTS font_glyphs(
  font_id INTEGER,
  code INTEGER,
  page INTEGER,
  frame_x INTEGER,
  frame_y INTEGER,
  frame_width INTEGER,
  frame_height INTEGER,
  advance_x REAL,
  advance_y REAL,
  offset_x REAL,
  offset_y REAL
)"
STMT_CREATE_KERN_TABLE = "CREATE TABLE IF NOT EXISTS font_kernings(
  font_id INTEGER,
  first_code INTEGER,
  second_code INTEGER,
  amount REAL
)"

STMT_INSERT_INFO = "INSERT INTO font_info(
  pages,
  num_glyphs,
  num_kernings,
  line_height,
  leading,
  ascent,
  descent,
  page_width,
  page_height,
  bbox_min_x,
  bbox_max_x,
  bbox_min_y,
  bbox_max_y,
  name
) VALUES(
  :pages ,
  :num_glyphs ,
  :num_kernings ,
  :line_height ,
  :leading ,
  :ascent ,
  :descent ,
  :page_width ,
  :page_height ,
  :bbox_min_x ,
  :bbox_max_x ,
  :bbox_min_y ,
  :bbox_max_y ,
  :name
)"
STMT_INSERT_GLYPH = "INSERT INTO font_glyphs VALUES(
  :font_id ,
  :code ,
  :page ,
  :frame_x ,
  :frame_y ,
  :frame_width ,
  :frame_height ,
  :advance_x ,
  :advance_y ,
  :offset_x ,
  :offset_y
)"
STMT_INSERT_KERN = "INSERT INTO font_kernings VALUES(
  :font_id ,
  :first_code ,
  :second_code ,
  :amount
)"

KNAME        = "name"
KGLYPHS      = "glyphs"
KKERNINGS    = "kernings"
KNUM_PAGES   = "pages"
KLINE_HEIGHT = "line_height"
KLEADING     = "leading"
KASCENT      = "ascent"
KDESCENT     = "descent"
KPAGE_SIZE   = "page_size"
KBBOX        = "bbox"
KX_MIN       = "x_min"
KY_MIN       = "y_min"
KX_MAX       = "x_max"
KY_MAX       = "y_max"
KCODE        = "code"
KPAGE        = "page"
KFRAME       = "frame"
KX           = "x"
KY           = "y"
KWIDTH       = "width"
KHEIGHT      = "height"
KADVANCES    = "advances"
KOFFSETS     = "offsets"
KFIRST       = "first"
KSECOND      = "second"
KAMOUNT      = "amount"

def convert_to_db(json_filepath, db = nil)

  json_input = nil
  File.open(json_filepath, 'r') {
    |io|
    json_input = JSON[io.read]
  }

  # Get necessary arrays
  glyphs = (json_input[KGLYPHS] || [])
  kerns = (json_input[KKERNINGS] || [])

  # compensate for the name key not being inserted by sbfgen (ergo being a key
  # inserted by someone using the font)
  name = json_input[KNAME] || File.basename(json_filepath, File.extname(json_filepath))

  close_db = false

  if db.nil?
    dbname = "#{json_filepath.chomp(File.extname(json_filepath))}.db"
    db = SQLite3::Database.new(dbname)
    close_db = true
  end

  db.execute(STMT_CREATE_INFO_TABLE)
  db.execute(STMT_CREATE_GLYPH_TABLE)
  db.execute(STMT_CREATE_KERN_TABLE)

  font_id = nil

  db.execute(STMT_INSERT_INFO,
    "pages"        => json_input[KNUM_PAGES],
    "num_glyphs"   => glyphs.length,
    "num_kernings" => kerns.length,
    "line_height"  => json_input[KLINE_HEIGHT],
    "leading"      => json_input[KLEADING],
    "ascent"       => json_input[KASCENT],
    "descent"      => json_input[KDESCENT],
    "page_width"   => json_input[KPAGE_SIZE][KWIDTH],
    "page_height"  => json_input[KPAGE_SIZE][KHEIGHT],
    "bbox_min_x"   => json_input[KBBOX][KX_MIN],
    "bbox_max_x"   => json_input[KBBOX][KX_MAX],
    "bbox_min_y"   => json_input[KBBOX][KY_MIN],
    "bbox_max_y"   => json_input[KBBOX][KY_MAX],
    "name"         => name)

  font_id = db.last_insert_row_id()

  unless glyphs.empty?
    new_glyph_stmt = db.prepare(STMT_INSERT_GLYPH)
    new_glyph_stmt.bind_param("font_id", font_id)
    r = nil
    glyphs.each {
      |glyph|

      r = new_glyph_stmt.execute(
        "code"         => glyph[KCODE],
        "page"         => glyph[KPAGE],
        "frame_x"      => glyph[KFRAME][KX],
        "frame_y"      => glyph[KFRAME][KY],
        "frame_width"  => glyph[KFRAME][KWIDTH],
        "frame_height" => glyph[KFRAME][KHEIGHT],
        "advance_x"    => glyph[KADVANCES][KX],
        "advance_y"    => glyph[KADVANCES][KY],
        "offset_x"     => glyph[KOFFSETS][KX],
        "offset_y"     => glyph[KOFFSETS][KY]
        )
    }
    r.close() unless r.nil?
  end

  unless kerns.empty?
    new_kern_stmt = db.prepare(STMT_INSERT_KERN)
    new_kern_stmt.bind_param("font_id", font_id)
    r = nil
    kerns.each {
      |kern|
      r = new_kern_stmt.execute(
        "first_code"  => kern[KFIRST],
        "second_code" => kern[KSECOND],
        "amount"      => kern[KAMOUNT]
        )
    }
    r.close() unless r.nil?
  end

  db.close() if close_db

end

if __FILE__ == $0
  dbname = ARGV.shift
  db = SQLite3::Database.new(dbname)
  if db.nil?
    raise "Couldn't open database #{dbname}"
  end

  ARGV.each {
    |filepath|
    puts "Converting #{filepath} -> #{dbname}"
    convert_to_db(filepath, db)
  }
  db.close unless db.nil?
end
