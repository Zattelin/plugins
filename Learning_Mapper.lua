--[[

LEARNING MAPPER

Author: Nick Gammon
Date:   24th January 2020

 PERMISSION TO DISTRIBUTE

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 and associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.


 LIMITATION OF LIABILITY

 The software is provided "as is", without warranty of any kind, express or implied,
 including but not limited to the warranties of merchantability, fitness for a particular
 purpose and noninfringement. In no event shall the authors or copyright holders be liable
 for any claim, damages or other liability, whether in an action of contract,
 tort or otherwise, arising from, out of or in connection with the software
 or the use or other dealings in the software.

--]]

-- black is true (ham) and red is false (spam)
-- in other words, a marker assigned black IS the sort of line, and one assigned red IS NOT the sort of line

require "mapper"
require "serialize"
require "copytable"
require "commas"
require "tprint"
require "pairsbykeys"

function f_handle_description (saved_lines)
  local lines = { }
  for _, line_info in ipairs (saved_lines) do
    table.insert (lines, line_info.line) -- get text of line
  end -- for each line
  description = table.concat (lines, "\n")

  -- if the description follows the exits, then ignore descriptions that don't follow exits
  if config.ACTIVATE_DESCRIPTION_AFTER_EXITS then
    if not exits_str then
      return
    end -- if
  end -- if

  if config.WHEN_TO_DRAW_MAP == DRAW_MAP_ON_DESCRIPTION then
    process_new_room ()
  end -- if
end -- f_handle_description

function f_handle_exits ()
  local lines = { }
  for _, line_info in ipairs (saved_lines) do
    table.insert (lines, line_info.line) -- get text of line
  end -- for each line
  exits_str = table.concat (lines, " "):lower ()
  if config.WHEN_TO_DRAW_MAP == DRAW_MAP_ON_EXITS then
    process_new_room ()
  end -- if
end -- f_handle_exits

function f_handle_name ()
  local lines = { }
  for _, line_info in ipairs (saved_lines) do
    table.insert (lines, line_info.line) -- get text of line
  end -- for each line
  room_name = table.concat (lines, " ")
  if config.WHEN_TO_DRAW_MAP == DRAW_MAP_ON_ROOM_NAME then
    process_new_room ()
  end -- if
end -- f_handle_name

function f_handle_prompt ()
  local lines = { }
  for _, line_info in ipairs (saved_lines) do
    table.insert (lines, line_info.line) -- get text of line
  end -- for each line
  prompt = table.concat (lines, " ")
  if config.WHEN_TO_DRAW_MAP == DRAW_MAP_ON_PROMPT then
    process_new_room ()
  end -- if
end -- f_handle_prompt


-- these are the types of lines we are trying to classify as a certain line IS or IS NOT that type
line_types = {
  description = { short = "Description",  handler = f_handle_description },
  exits       = { short = "Exits",        handler = f_handle_exits },
  room_name   = { short = "Room name",    handler = f_handle_name },
  prompt      = { short = "Prompt",       handler = f_handle_prompt },
}  -- end of line_types table

function f_first_style_run_foreground (line)
  return { GetStyleInfo(line, 1, 14) or -1 }
end -- f_first_style_run_foreground

function f_show_colour (which, value)
  mapper.mapprint (string.format ("    %20s %5d %5d %7.2f", RGBColourToName (which), value.black, value.red, value.score))
end -- f_show_colour

function f_show_word (which, value)
  mapper.mapprint (string.format ("    %20s %5d %5d %7.2f", which, value.black, value.red, value.score))
end -- f_show_colour

function f_first_word (line)
  if not GetLineInfo(line, 1) then
    return {}
  end -- no line available
  return { (string.match (GetLineInfo(line, 1), "^%s*(%a+)") or ""):lower () }
end -- f_first_word

function f_all_words (line)
  if not GetLineInfo(line, 1) then
    return {}
  end -- no line available
  local words = { }
  for w in string.gmatch (GetLineInfo(line, 1), "%a+") do
    table.insert (words, w:lower ())
  end -- for
  return words
end -- f_all_words

function f_first_character (line)
  if not GetLineInfo(line, 1) then
    return {}
  end -- no line available
  return { string.match (GetLineInfo(line, 1), "^.") or "" }
end -- f_first_character

-- things we are looking for, like colour of first style run
markers = {

  {
  desc = "Foreground colour of first style run",
  func = f_first_style_run_foreground,
  marker = "m_first_style_run_foreground",
  show = f_show_colour,
  accessing_function = pairs,
  },

  {
  desc = "First word in the line",
  func = f_first_word,
  marker = "m_first_word",
  show = f_show_word,
  accessing_function = pairsByKeys,

  },

  {
  desc = "All words in the line",
  func = f_all_words,
  marker = "m_all_words",
  show = f_show_word,
  accessing_function = pairsByKeys,

  },

--[[

 {
  desc = "First character in the line",
  func = f_first_character,
  marker = "m_first_character",
  show = f_show_word,

  },

--]]

  } -- end of markers

-- this table has the counters
corpus = { }
-- stats
stats = { }

local MAX_NAME_LENGTH = 60

-- when to update the map
DRAW_MAP_ON_ROOM_NAME = 1
DRAW_MAP_ON_DESCRIPTION = 2
DRAW_MAP_ON_EXITS = 3
DRAW_MAP_ON_PROMPT = 4


default_config = {
  -- assorted colours
  BACKGROUND_COLOUR       = { name = "Background",        colour =  ColourNameToRGB "lightseagreen", },
  ROOM_COLOUR             = { name = "Room",              colour =  ColourNameToRGB "cyan", },
  EXIT_COLOUR             = { name = "Exit",              colour =  ColourNameToRGB "darkgreen", },
  EXIT_COLOUR_UP_DOWN     = { name = "Exit up/down",      colour =  ColourNameToRGB "darkmagenta", },
  EXIT_COLOUR_IN_OUT      = { name = "Exit in/out",       colour =  ColourNameToRGB "#3775E8", },
  OUR_ROOM_COLOUR         = { name = "Our room",          colour =  ColourNameToRGB "black", },
  UNKNOWN_ROOM_COLOUR     = { name = "Unknown room",      colour =  ColourNameToRGB "#00CACA", },
  DIFFERENT_AREA_COLOUR   = { name = "Another area",      colour =  ColourNameToRGB "#009393", },
  SHOP_FILL_COLOUR        = { name = "Shop",              colour =  ColourNameToRGB "darkolivegreen", },
  POSTOFFICE_FILL_COLOUR  = { name = "Post Office",       colour =  ColourNameToRGB "yellowgreen", },
  BANK_FILL_COLOUR        = { name = "Bank",              colour =  ColourNameToRGB "gold", },
  NEWSROOM_FILL_COLOUR    = { name = "Newsroom",          colour =  ColourNameToRGB "lightblue", },
  MAPPER_NOTE_COLOUR      = { name = "Messages",          colour =  ColourNameToRGB "lightgreen" },

  ROOM_NAME_TEXT          = { name = "Room name text",    colour = ColourNameToRGB "#BEF3F1", },
  ROOM_NAME_FILL          = { name = "Room name fill",    colour = ColourNameToRGB "#105653", },
  ROOM_NAME_BORDER        = { name = "Room name box",     colour = ColourNameToRGB "black", },

  AREA_NAME_TEXT          = { name = "Area name text",    colour = ColourNameToRGB "#BEF3F1",},
  AREA_NAME_FILL          = { name = "Area name fill",    colour = ColourNameToRGB "#105653", },
  AREA_NAME_BORDER        = { name = "Area name box",     colour = ColourNameToRGB "black", },

  FONT = { name =  get_preferred_font {"Dina",  "Lucida Console",  "Fixedsys", "Courier", "Sylfaen",} ,
           size = 8
         } ,

  -- size of map window
  WINDOW = { width = 400, height = 400 },

  -- how far from where we are standing to draw (rooms)
  SCAN = { depth = 30 },

  -- speedwalk delay
  DELAY = { time = 0.3 },

  -- how many seconds to show "recent visit" lines (default 3 minutes)
  LAST_VISIT_TIME = { time = 60 * 3 },

  -- config for learning mapper

  STATUS_BACKGROUND_COLOUR  = "black",       -- the background colour of the status window
  STATUS_FRAME_COLOUR       = "#1B1B1B",     -- the frame colour of the status window
  STATUS_TEXT_COLOUR        = "lightgreen",   -- palegreen is more visible

  UID_SIZE = 4,  -- how many characters of the UID to show

  -- learning configuration
  WHEN_TO_DRAW_MAP = DRAW_MAP_ON_EXITS,        -- we need to have name/description/exits to draw the map
  ACTIVATE_DESCRIPTION_AFTER_EXITS = false,    -- descriptions are activated *after* an exit line (used for MUDs with exits then descriptions)
  BLANK_LINE_TERMINATES_LINE_TYPE = false,     -- if true, a blank line terminates the previous line type
  ADD_NEWLINE_TO_PROMPT = false,               -- if true, attempts to add a newline to a prompt at the end of a packet
  SHOW_LEARNING_WINDOW = true,                 -- if true, show the learning status and training windows on startup
  }

rooms = {}

valid_direction = {
  n = "n",
  s = "s",
  e = "e",
  w = "w",
  u = "u",
  d = "d",
  ne = "ne",
  sw = "sw",
  nw = "nw",
  se = "se",
  north = "n",
  south = "s",
  east = "e",
  west = "w",
  up = "u",
  down = "d",
  northeast = "ne",
  northwest = "nw",
  southeast = "se",
  southwest = "sw",
  ['in'] = "in",
  out = "out",
  }  -- end of valid_direction

inverse_direction = {
  n = "s",
  s = "n",
  e = "w",
  w = "e",
  u = "d",
  d = "u",
  ne = "sw",
  sw = "ne",
  nw = "se",
  se = "nw",
  ['in'] = "out",
  out = "in",
  }  -- end of inverse_direction

-- -----------------------------------------------------------------
-- OnPluginDrawOutputWindow
--  Update our debugging info
-- -----------------------------------------------------------------
function OnPluginDrawOutputWindow (firstline, offset, notused)
  local background_colour = ColourNameToRGB (config.STATUS_BACKGROUND_COLOUR)
  local frame_colour = ColourNameToRGB (config.STATUS_FRAME_COLOUR)
  local text_colour = ColourNameToRGB (config.STATUS_TEXT_COLOUR)
  local main_height = GetInfo (263)
  local font_height = GetInfo (212)

  -- clear window
  WindowRectOp (win, miniwin.rect_fill, 0, 0, 0, 0, background_colour)

  -- frame it
  WindowRectOp(win, miniwin.rect_frame, 0, 0, 0, 0, frame_colour)

  -- allow for scrolling position
  local top =  (((firstline - 1) * font_height) - offset) - 2

  -- how many lines to draw

  local lastline = firstline + (main_height / font_height)

  for line = firstline, lastline do
    if line >= 1 and GetLineInfo (line, 1) then
      if GetLineInfo (line, 4) or GetLineInfo (line, 5) then
        -- note or input line, ignore it
      else
        local linetype, probability = analyse_line (line)
        if linetype then
          line_type_info = string.format ("<- %s (%0.0f%%)", linetype, probability * 100)
        else
          line_type_info = ""
        end -- if
        WindowText (win, font_id, line_type_info, 1, top,
                    0, 0, text_colour)
      end -- if
      top = top + font_height
    end -- if line exists
  end -- for each line

end -- OnPluginDrawOutputWindow

-- -----------------------------------------------------------------
-- OnPluginWorldOutputResized
--  On world window resize, remake the miniwindow to fit the size correctly
-- -----------------------------------------------------------------
function OnPluginWorldOutputResized ()

  font_name = GetInfo (20) -- output window font
  font_size = GetOption "output_font_height"

  local output_width  = GetInfo (240)  -- average width of pixels per character
  local wrap_column   = GetOption ('wrap_column')
  local pixel_offset  = GetOption ('pixel_offset')

  -- make window so I can grab the font info
  WindowCreate (win,
                (output_width * wrap_column) + pixel_offset + 10, -- left
                0,  -- top
                500, -- width
                GetInfo (263),   -- world window client height
                miniwin.pos_top_left,   -- position (irrelevant)
                miniwin.create_absolute_location,   -- flags
                ColourNameToRGB (config.STATUS_BACKGROUND_COLOUR))   -- background colour

  -- add font
  WindowFont (win, font_id, font_name, font_size,
              false, false, false, false,  -- normal
              miniwin.font_charset_ansi, miniwin.font_family_any)

  -- find height of font for future calculations
  font_height = WindowFontInfo (win, font_id, 1)  -- height

  WindowSetZOrder(win, -5)

   if WindowInfo (learn_window, 5) then
     WindowShow (win)
   end -- if

end -- OnPluginWorldOutputResized

-- -----------------------------------------------------------------
-- INFO helper function for debugging the plugin (information messages)
-- -----------------------------------------------------------------
function INFO (...)
   -- ColourNote ("orange", "", table.concat ( { ... }, " "))
end -- INFO

-- -----------------------------------------------------------------
-- WARNING helper function for debugging the plugin (warning/error messages)
-- -----------------------------------------------------------------
function WARNING (...)
  ColourNote ("red", "", table.concat ( { ... }, " "))
end -- WARNING

-- -----------------------------------------------------------------
-- DEBUG helper function for debugging the plugin to a notepad window
-- -----------------------------------------------------------------
function DEBUG (...)

  do return end  -- forget it for now

  if GetNotepadLength("Debug") > 5000 then
    return
  end -- if too big

  AppendToNotepad ("Debug", table.concat ( { ... }, " ") .. "\r\n")
end -- DEBUG

-- -----------------------------------------------------------------
-- corpus_reset - throw away the learned corpus
-- -----------------------------------------------------------------
function corpus_reset (empty)
  if empty then
    corpus = { }
    stats  = { }
  end -- if

  -- make sure each line type is in the corpus

  for k, v in pairs (line_types) do
    if not corpus [k] then
      corpus [k] = {}
    end -- not there yet

    if not stats [k] then
      stats [k] = { is = 0, isnot = 0 }
    end -- not there yet

    for k2, v2 in ipairs (markers) do
      if not corpus [k] [v2.marker] then  -- if that marker not there, add it
         corpus [k] [v2.marker] = { } -- table of values for this marker
      end -- marker not there yet

    end -- for each marker type
  end -- for each line type
end -- corpus_reset

LEARN_WINDOW_WIDTH = 300
LEARN_WINDOW_HEIGHT = 200
LEARN_BUTTON_WIDTH = 80
LEARN_BUTTON_HEIGHT = 30

hotspots = { }
button_down = false

-- -----------------------------------------------------------------
-- button_mouse_down - generic mouse-down handler
-- -----------------------------------------------------------------
function button_mouse_down (flags, hotspot_id)
  local hotspot_info = hotspots [hotspot_id]
  if not hotspot_info then
    WARNING ("No info found for hotspot", hotspot_id)
    return
  end

  -- no button state change if no selection
  if GetSelectionStartLine () == 0 then
    return
  end -- if

  button_down = true
  WindowRectOp (hotspot_info.window, miniwin.rect_draw_edge,
                hotspot_info.x1, hotspot_info.y1, hotspot_info.x2, hotspot_info.y2,
                miniwin.rect_edge_sunken,
                miniwin.rect_edge_at_all + miniwin.rect_option_fill_middle)  -- sunken, filled
  WindowText   (hotspot_info.window, hotspot_info.font, hotspot_info.text, hotspot_info.text_x + 1, hotspot_info.y1 + 8 + 1, 0, 0, ColourNameToRGB "black", true)
  Redraw ()

end -- button_mouse_down

-- -----------------------------------------------------------------
-- button_cancel_mouse_down - generic cancel-mouse-down handler
-- -----------------------------------------------------------------
function button_cancel_mouse_down (flags, hotspot_id)
  local hotspot_info = hotspots [hotspot_id]
  if not hotspot_info then
    WARNING ("No info found for hotspot", hotspot_id)
    return
  end

  button_down = false
  buttons_active = nil

  WindowRectOp (hotspot_info.window, miniwin.rect_draw_edge,
                hotspot_info.x1, hotspot_info.y1, hotspot_info.x2, hotspot_info.y2,
                miniwin.rect_edge_raised,
                miniwin.rect_edge_at_all + miniwin.rect_option_fill_middle)  -- raised, filled
  WindowText   (hotspot_info.window, hotspot_info.font, hotspot_info.text, hotspot_info.text_x, hotspot_info.y1 + 8, 0, 0, ColourNameToRGB "black", true)

  Redraw ()
end -- button_cancel_mouse_down

-- -----------------------------------------------------------------
-- button_mouse_up - generic mouse-up handler
-- -----------------------------------------------------------------
function button_mouse_up (flags, hotspot_id)
  local hotspot_info = hotspots [hotspot_id]
  if not hotspot_info then
    WARNING ("No info found for hotspot", hotspot_id)
    return
  end

  button_down = false
  buttons_active = nil

  -- call the handler
  hotspot_info.handler ()

  WindowRectOp (hotspot_info.window, miniwin.rect_draw_edge,
                hotspot_info.x1, hotspot_info.y1, hotspot_info.x2, hotspot_info.y2,
                miniwin.rect_edge_raised,
                miniwin.rect_edge_at_all + miniwin.rect_option_fill_middle)  -- raised, filled
  WindowText   (hotspot_info.window, hotspot_info.font, hotspot_info.text, hotspot_info.text_x, hotspot_info.y1 + 8, 0, 0, ColourNameToRGB "black", true)

  Redraw ()
end -- button_mouse_up

-- -----------------------------------------------------------------
-- make_button - make a button for the dialog window and remember its handler
-- -----------------------------------------------------------------
function make_button (window, font, x, y, text, tooltip, handler)

  WindowRectOp (window, miniwin.rect_draw_edge, x, y, x + LEARN_BUTTON_WIDTH, y + LEARN_BUTTON_HEIGHT,
            miniwin.rect_edge_raised,
            miniwin.rect_edge_at_all + miniwin.rect_option_fill_middle)  -- raised, filled

  local width = WindowTextWidth (window, font, text, true)
  local text_x = x + (LEARN_BUTTON_WIDTH - width) / 2

  WindowText   (window, font, text, text_x, y + 8, 0, 0, ColourNameToRGB "black", true)

  local hotspot_id = string.format ("HS_learn_%d,%d", x, y)
  -- remember handler function
  hotspots [hotspot_id] = { handler = handler,
                            window = window,
                            x1 = x, y1 = y,
                            x2 = x + LEARN_BUTTON_WIDTH, y2 = y + LEARN_BUTTON_HEIGHT,
                            font = font,
                            text = text,
                            text_x = text_x }

  WindowAddHotspot(window,
                  hotspot_id,
                   x, y, x + LEARN_BUTTON_WIDTH, y + LEARN_BUTTON_HEIGHT,
                   "",                          -- MouseOver
                   "",                          -- CancelMouseOver
                   "button_mouse_down",         -- MouseDown
                   "button_cancel_mouse_down",  -- CancelMouseDown
                   "button_mouse_up",           -- MouseUp
                   tooltip,                     -- tooltip text
                   miniwin.cursor_hand,         -- mouse cursor shape
                   0)                           -- flags


end -- make_button

-- -----------------------------------------------------------------
-- update_buttons - grey-out buttons if nothing selected
-- -----------------------------------------------------------------

buttons_active = nil

function update_buttons (name)

  -- do nothing if button pressed
  if button_down then
    return
  end -- if

  local have_selection = GetSelectionStartLine () ~= 0

  -- do nothing if the state hasn't changed
  if have_selection == buttons_active then
    return
  end -- if

  buttons_active = have_selection

  for hotspot_id, hotspot_info in pairs (hotspots) do
    if string.match (hotspot_id, "^HS_learn_") then
      local wanted_colour = ColourNameToRGB "black"
      if not buttons_active then
        wanted_colour = ColourNameToRGB "silver"
      end -- if
      WindowText   (hotspot_info.window, hotspot_info.font, hotspot_info.text, hotspot_info.text_x, hotspot_info.y1 + 8, 0, 0, wanted_colour, true)
    end -- if a learning button
  end -- for

  Redraw ()

end -- update_buttons

-- -----------------------------------------------------------------
-- mouseup_close_configure - they hit the close box in the learning window
-- -----------------------------------------------------------------
function mouseup_close_configure  (flags, hotspot_id)
  WindowShow (learn_window, false)
  WindowShow (win, false)
  mapper.mapprint ('Type: "mapper learn" to show the training window again')
  config.SHOW_LEARNING_WINDOW = false
end -- mouseup_close_configure

-- -----------------------------------------------------------------
-- toggle_learn_window - toggle the window: called from "mapper learn"
-- -----------------------------------------------------------------
function toggle_learn_window (name, line, wildcards)
  if WindowInfo (learn_window, 5) then
    WindowShow (win, false)
    WindowShow (learn_window, false)
    config.SHOW_LEARNING_WINDOW = false
  else
    WindowShow (win, true)
    WindowShow (learn_window, true)
    config.SHOW_LEARNING_WINDOW = true
  end -- if
end -- toggle_learn_window

-- -----------------------------------------------------------------
-- Plugin Install
-- -----------------------------------------------------------------
function OnPluginInstall ()

  win = "window_type_info_" .. GetPluginID ()
  learn_window = "learn_dialog_" .. GetPluginID ()
  font_id = "f"

  -- load corpus
  assert (loadstring (GetVariable ("corpus") or "")) ()
  -- load stats
  assert (loadstring (GetVariable ("stats") or "")) ()

  corpus_reset ()

  config = {}  -- in case not found

  -- get saved configuration
  assert (loadstring (GetVariable ("config") or "")) ()

  -- allow for additions to config
  for k, v in pairs (default_config) do
    config [k] = config [k] or v
  end -- for

  -- and rooms
  assert (loadstring (GetVariable ("rooms") or "")) ()

  -- initialize mapper

  mapper.init {
              config = config,            -- our configuration table
              get_room = get_room,        -- get info about a room
              show_other_areas = true,    -- show all areas
              show_help = OnHelp,         -- to show help
  }
  mapper.mapprint (string.format ("MUSHclient mapper installed, version %0.1f", mapper.VERSION))

  OnPluginWorldOutputResized ()

--[[

  -- clear debugging window
  if GetNotepadLength("Debug") > 0 then
    SendToNotepad ("Debug", "")
  end -- if

--]]

 -- find where window was last time

  windowinfo = movewindow.install (learn_window, miniwin.pos_center_right)

  learnFontName = get_preferred_font {"Dina",  "Lucida Console",  "Fixedsys", "Courier", "Sylfaen",}
  learnFontId = "f"
  learnFontSize = 9

  WindowCreate (learn_window,
                 windowinfo.window_left,
                 windowinfo.window_top,
                 LEARN_WINDOW_WIDTH,
                 LEARN_WINDOW_HEIGHT,
                 windowinfo.window_mode,   -- top right
                 windowinfo.window_flags,
                 ColourNameToRGB "lightcyan")

  WindowFont (learn_window, learnFontId, learnFontName, learnFontSize,
              true, false, false, false,  -- bold
              miniwin.font_charset_ansi, miniwin.font_family_any)

  -- find height of font for future calculations
  learn_font_height = WindowFontInfo (learn_window, font_id, 1)  -- height

  -- let them move it around
  movewindow.add_drag_handler (learn_window, 0, 0, 0, learn_font_height + 5)
  WindowRectOp (learn_window, miniwin.rect_fill, 0, 0, 0, learn_font_height + 5, ColourNameToRGB "darkblue", 0)
  draw_3d_box  (learn_window, 0, 0, LEARN_WINDOW_WIDTH, LEARN_WINDOW_HEIGHT)
  DIALOG_TITLE = "Learn line type"
  local width = WindowTextWidth (learn_window, learnFontId, DIALOG_TITLE, true)
  local x = (LEARN_WINDOW_WIDTH - width) / 2
  WindowText   (learn_window, learnFontId, DIALOG_TITLE, x, 3, 0, 0, ColourNameToRGB "white", true)

 -- close box
  local box_size = learn_font_height - 2
  local GAP = 5
  local y = 3
  local x = 1

  WindowRectOp (learn_window,
                miniwin.rect_frame,
                x + LEARN_WINDOW_WIDTH - box_size - GAP * 2,
                y + 1,
                x + LEARN_WINDOW_WIDTH - GAP * 2,
                y + 1 + box_size,
                0x808080)
  WindowLine (learn_window,
              x + LEARN_WINDOW_WIDTH - box_size - GAP * 2 + 3,
              y + 4,
              x + LEARN_WINDOW_WIDTH - GAP * 2 - 3,
              y - 2 + box_size,
              0x808080,
              miniwin.pen_solid, 1)
  WindowLine (learn_window,
              x - 4 + LEARN_WINDOW_WIDTH - GAP * 2,
              y + 4,
              x - 1 + LEARN_WINDOW_WIDTH - box_size - GAP * 2 + 3,
              y - 2 + box_size,
              0x808080,
              miniwin.pen_solid, 1)

  -- close configuration hotspot
  WindowAddHotspot(learn_window, "close_learn_dialog",
                   x + LEARN_WINDOW_WIDTH - box_size - GAP * 2,
                   y + 1,
                   x + LEARN_WINDOW_WIDTH - GAP * 2,
                   y + 1 + box_size,   -- rectangle
                   "", "", "", "", "mouseup_close_configure",  -- mouseup
                   "Click to close",
                   miniwin.cursor_hand, 0)  -- hand cursor


  -- the buttons for learning
  local LABEL_LEFT = 10
  local YES_BUTTON_LEFT = 100
  local NO_BUTTON_LEFT = YES_BUTTON_LEFT + LEARN_BUTTON_WIDTH + 20

  local y = learn_font_height + 10
  for type_name, type_info in pairs (line_types) do
    WindowText   (learn_window, learnFontId, type_info.short, LABEL_LEFT, y + 8, 0, 0, ColourNameToRGB "black", true)

    make_button (learn_window, learnFontId, YES_BUTTON_LEFT, y, "Yes", "Learn selection IS " .. type_info.short,
                  function () learn_line_type (type_name, true) end)
    make_button (learn_window, learnFontId, NO_BUTTON_LEFT,  y, "No",  "Learn selection is NOT " .. type_info.short,
                  function () learn_line_type (type_name, false) end)

    y = y + LEARN_BUTTON_HEIGHT + 10

  end -- for

  WindowShow (learn_window, config.SHOW_LEARNING_WINDOW)
  WindowShow (win, config.SHOW_LEARNING_WINDOW)

end -- OnPluginInstall

-- -----------------------------------------------------------------
-- Plugin Save State
-- -----------------------------------------------------------------
function OnPluginSaveState ()
  mapper.save_state ()
  SetVariable ("corpus", "corpus = " .. serialize.save_simple (corpus))
  SetVariable ("stats", "stats = " .. serialize.save_simple (stats))
  SetVariable ("config", "config = " .. serialize.save_simple (config))
  SetVariable ("rooms",  "rooms = "  .. serialize.save_simple (rooms))
  movewindow.save_state (learn_window)
end -- OnPluginSaveState

local C1 = 2   -- weightings
local C2 = 1
local weight = 1
local MAX_WEIGHT = 2.0

-- calculate the probability one word is red or black
function CalcProbability (red, black)
 local pResult = ( (black - red) * weight )
                 / (C1 * (black + red + C2) * MAX_WEIGHT)
  return 0.5 + pResult
end -- CalcProbability


-- -----------------------------------------------------------------
-- update_corpus
--  add one to red or black for a certain value, for a certain type of line, for a certain marker type
-- -----------------------------------------------------------------
function update_corpus (which, marker, value, black)
  local which_corpus = corpus [which] [marker]
  -- make new one for this value if necessary
  if not which_corpus [value] then
     which_corpus [value] = { red = 0, black = 0, score = 0 }
  end -- end of this value not there yet
  if black then
     which_corpus [value].black = which_corpus [value].black + 1
  else
     which_corpus [value].red = which_corpus [value].red + 1
  end -- if
  which_corpus [value].score = assert (CalcProbability (which_corpus [value].red, which_corpus [value].black))
end -- update_corpus


-- -----------------------------------------------------------------
-- learn_line_type
--  The user is training a line type. Update the corpus for each line type to show that this set of
--  markers is/isn't in it.
-- -----------------------------------------------------------------
function learn_line_type (which, black)

  start_line = GetSelectionStartLine ()
  end_line = GetSelectionEndLine ()

  if start_line == 0 then
     WARNING ("No line(s) selected - select one or more lines (or part lines)")
     return
  end -- if

  if black then
    stats [which].is = stats [which].is + 1
  else
    stats [which].isnot = stats [which].isnot + 1
  end -- if

  -- do all lines in the selection
  for line = start_line, end_line do
    -- process all the marker types, and add 1 to the red/black counter for that particular marker
    for k, v in ipairs (markers) do
      local values = v.func (line) -- call handler to get values
      for _, value in ipairs (values) do
        update_corpus (which, v.marker, value, black)
      end -- for each value

--[[
      -- other line types do NOT match this, if it was black
      if black then
        for linetype in pairs (line_types) do
          if linetype ~= which then -- don't do the one which it IS
            update_corpus (linetype, v.marker, value, red)
          end -- if not the learning type
        end -- each line type
      end -- black learning
--]]

    end -- for each type of marker
  end -- for each line

  -- INFO (string.format ("Selection is from %d to %d", start_line, end_line))

  local s = ":"
  if not black then
    s = ": NOT"
  end -- if

  -- INFO ("Selected lines " .. s .. " " .. which)

  -- tprint (corpus)

  Pause (false)

end -- learn_line_type

--   See:
--     http://www.paulgraham.com/naivebayes.html
--   For a good explanation of the background, see:
--     http://www.mathpages.com/home/kmath267.htm.

-- -----------------------------------------------------------------
-- SetProbability
-- calculate the probability a bunch of markers are ham (black)
--  using an array of probabilities, get an overall one
-- -----------------------------------------------------------------
function SetProbability (probs)
  local n, inv = 1, 1
  local i = 0
  for k, v in pairs (probs) do
    n = n * v
    inv = inv * (1 - v)
    i = i + 1
  end
  return  n / (n + inv)
end -- SetProbability

-- DO NOT DEBUG TO THE OUTPUT WINDOW IN THIS FUNCTION!
-- -----------------------------------------------------------------
-- analyse_line
-- work out type of line by comparing its markers to the corpus
-- -----------------------------------------------------------------
function analyse_line (line)
  local result = {}
  local line_type_probs = {}
  local marker_values = { }

  if Trim (GetLineInfo (line, 1)) == "" then
    return nil
  end -- if blank line

  -- get the values first, they will stay the same for all line types
  for _, m in ipairs (markers) do
    marker_values [m.marker] = m.func (line) -- call handler to get values
  end -- for each type of marker

  DEBUG ("Debugging line", line, ":", GetLineInfo (line, 1))
  for line_type, line_type_info in pairs (line_types) do
    DEBUG ("  Line type", line_type)
    local probs = { }
    for _, m in ipairs (markers) do
      DEBUG ("    Marker", m.marker)
      local values = marker_values [m.marker] -- get previously-retrieved values
      DEBUG ("      Value", value)
      for _, value in ipairs (values) do
        local corpus_value = corpus [line_type] [m.marker] [value]
        if corpus_value then
          assert (type (corpus_value) == 'table', 'corpus_value not a table')
          DEBUG ("        Score", tostring (corpus_value.score))
          table.insert (probs, corpus_value.score)
        end -- of having a value
      end -- for each value
    end -- for each type of marker
    local score = SetProbability (probs)
    table.insert (result, string.format ("%s: %3.2f", line_type_info.short, score))
    table.insert (line_type_probs, { line_type = line_type, score = score } )
  end -- for each line type
  table.sort (line_type_probs, function (a, b) return a.score > b.score end)
  if line_type_probs [1].score > 0.7 then
    return line_type_probs [1].line_type, line_type_probs [1].score
  else
    return nil
  end -- if
end -- analyse_line

-- -----------------------------------------------------------------
-- fixuid
-- shorten a UID for display purposes
-- -----------------------------------------------------------------
function fixuid (uid)
  if not uid then
    return "NO_UID"
  end -- if nil
  return uid:sub (1, config.UID_SIZE)
end -- fixuid

-- -----------------------------------------------------------------
-- process_new_room
-- we have an exit line - work out where we are and what the exits are
-- -----------------------------------------------------------------
function process_new_room ()

  if not description then
    WARNING "No description for this room"
    return
  end -- if no description

  if not exits_str then
    WARNING "No exits for this room"
    return
  end -- if no exits string

  if from_room and last_direction_moved then
    local last_desc = rooms [from_room].desc
    if last_desc == description then
      mapper.mapprint ("Warning: You have moved from a room to one with an identical description - the mapper may get confused.")
    end -- if

  end -- if moved from somewhere

  -- generate a "room ID" by hashing the room description and exits
  uid = utils.tohex (utils.md5 (description .. exits_str))
  uid = uid:sub (1, 25)

  -- break up exits into individual directions
  local exits = {}

  -- for each word in the exits line, which happens to be an exit name (eg. "north") add to the table
  for exit in string.gmatch (exits_str, "%w+") do
    local ex = valid_direction [exit]
    if ex then
      exits [ex] = "0"  -- don't know where it goes yet
    end -- if
  end -- for

  -- show what we found
  for k, v in pairs (exits) do
    -- INFO ("Exit:", k)
  end -- for

  -- add room to rooms table if not already known
  if not rooms [uid] then
    INFO ("Mapper adding room " .. fixuid (uid))
    rooms [uid] = { desc = description, exits = exits, area = WorldName (), name = room_name or fixuid (uid) }
  end -- if

  -- update room name if possible
  if room_name then
    rooms [uid].name = room_name
  end -- if

  INFO ("We are now in room " .. fixuid (uid))
  -- INFO ("Description: ", description)

  -- save so we know current room later on
  current_room = uid

  -- show what we believe the current exits to be
  for k, v in pairs (rooms [uid].exits) do
    INFO ("Exit: " .. k .. " -> " .. fixuid (v))
  end -- for

  -- try to work out where previous room's exit led
  if last_direction_moved and expected_exit ~= uid and from_room then
    fix_up_exit ()
  end -- exit was wrong

  -- call mapper to draw this room
  mapper.draw (uid)

  room_name = nil
  exits_str = nil
  description = nil
  last_direction_moved = nil

end -- process_new_room


-- -----------------------------------------------------------------
-- mapper 'get_room' callback - it wants to know about room uid
-- -----------------------------------------------------------------

function get_room (uid)

  if not rooms [uid] then
   return nil
  end -- if

  local room = copytable.deep (rooms [uid])

  local texits = {}
  for dir,dest in pairs (room.exits) do
    table.insert (texits, dir .. " -> " .. fixuid (dest))
  end -- for
  table.sort (texits)

  local desc = string.gsub (room.desc, "%. .*", ".")
  if room.name and not string.match (room.name, "^%x+$") then
    desc = room.name
  end -- if

  room.hovermessage = string.format (
       "%s\tExits: %s\nRoom: %s\n%s",
        room.name or "unknown",
        table.concat (texits, ", "),
        fixuid (uid),
        desc
      )

  if uid == current_room then
    room.bordercolour = config.OUR_ROOM_COLOUR.colour
    room.borderpenwidth = 2
  end -- not in this area

  return room

end -- get_room

-- -----------------------------------------------------------------
-- We have changed rooms - work out where the previous room led to
-- -----------------------------------------------------------------

function fix_up_exit ()

  -- where we were before
  local room = rooms [from_room]

  INFO ("Exit from " .. fixuid (from_room) .. " in the direction " .. last_direction_moved .. " was previously " .. (fixuid (room.exits [last_direction_moved]) or "nowhere"))
  -- leads to here

  if from_room == current_room then
    WARNING ("Declining to set the exit " .. last_direction_moved .. " from this room to be itself")
  else
    room.exits [last_direction_moved] = current_room
    INFO ("Exit from " .. fixuid (from_room) .. " in the direction " .. last_direction_moved .. " is now " .. fixuid (current_room))
  end -- if

  -- do inverse direction as a guess
  local inverse = inverse_direction [last_direction_moved]
  if inverse and current_room then
    if rooms [current_room].exits [inverse] == '0' then
      rooms [current_room].exits [inverse] = from_room
      INFO ("Added inverse direction from " .. fixuid (current_room) .. " in the direction " .. inverse .. " to be " .. fixuid (from_room))
    end -- if
  end -- of having an inverse


  -- clear for next time
  last_direction_moved = nil
  from_room = nil

end -- fix_up_exit

-- -----------------------------------------------------------------
-- try to detect when we send a movement command
-- -----------------------------------------------------------------

function OnPluginSent (sText)
  if valid_direction [sText] then
    last_direction_moved = valid_direction [sText]
    INFO ("current_room =", fixuid (current_room))
    INFO ("Just moving", last_direction_moved)
    if current_room and rooms [current_room] then
      expected_exit = rooms [current_room].exits [last_direction_moved]
      if expected_exit then
        from_room = current_room
      end -- if
    INFO ("Expected exit for this in direction " .. last_direction_moved .. " is to room", fixuid (expected_exit))
    end -- if
  end -- if
end -- function



-- -----------------------------------------------------------------
-- Plugin just connected to world
-- -----------------------------------------------------------------

function OnPluginConnect ()
  from_room = nil
  last_direction_moved = nil
  mapper.cancel_speedwalk ()
end -- OnPluginConnect

-- -----------------------------------------------------------------
-- Plugin just disconnected from world
-- -----------------------------------------------------------------

function OnPluginDisconnect ()
  mapper.cancel_speedwalk ()
end -- OnPluginDisconnect

-- -----------------------------------------------------------------
-- Callback to show part of the room description, used by map_find
-- -----------------------------------------------------------------

FIND_OFFSET = 33

function show_find_details (uid)
  local this_room = rooms [uid]
  local desc = this_room.desc:lower ()
  local st, en = string.find (desc, wanted, 1, true)
  if not st then
    return
  end -- can't find the description, odd

  desc = this_room.desc

  local first, last
  local first_dots = ""
  local last_dots = ""

  for i = 1, #desc do

    -- find a space before the wanted match string, within the FIND_OFFSET range
    if not first and
       desc:sub (i, i) == ' ' and
       i < st and
       st - i <= FIND_OFFSET then
      first = i
      first_dots = "... "
    end -- if

    -- find a space after the wanted match string, within the FIND_OFFSET range
    if not last and
      desc:sub (i, i) == ' ' and
      i > en and
      i - en >= FIND_OFFSET then
      last = i
      last_dots = " ..."
    end -- if

  end -- for

  if not first then
    first = 1
  end -- if
  if not last then
    last = #desc
  end -- if

  mapper.mapprint (first_dots .. Trim (string.gsub (desc:sub (first, last), "\n", " ")) .. last_dots)

end -- show_find_details

-- -----------------------------------------------------------------
-- Find a room
-- -----------------------------------------------------------------

function map_find (name, line, wildcards)

  local room_ids = {}
  local count = 0
  wanted = (wildcards [1]):lower ()     -- NOT local

  -- scan all rooms looking for a simple match
  for k, v in pairs (rooms) do
     local desc = v.desc:lower ()
     local name = v.name:lower ()
     if string.find (desc, wanted, 1, true) or string.find (name, wanted, 1, true)  then
       room_ids [k] = true
       count = count + 1
     end -- if
  end   -- finding room

  -- see if nearby
  mapper.find (
    function (uid)
      local room = room_ids [uid]
      if room then
        room_ids [uid] = nil
      end -- if
      return room, next (room_ids) == nil
    end,  -- function
    show_vnums,  -- show vnum?
    count,      -- how many to expect
    false,      -- don't auto-walk
    show_find_details -- callback function
    )

end -- map_find

-- -----------------------------------------------------------------
-- Go to a room
-- -----------------------------------------------------------------

function map_goto (name, line, wildcards)

  local wanted = wildcards [1]

  if current_room and wanted == current_room then
    mapper.mapprint ("You are already in that room.")
    return
  end -- if

  if not string.match (wanted, "^%x+$") then
    mapper.mapprint ("Room IDs are hex strings (eg. FC758) - you can specify a partial string")
    return
  end -- if

  -- they are stored as upper-case
  wanted = wanted:upper ()

  -- find desired room
  mapper.find (
    function (uid)
      return string.match (uid, wanted), string.match (uid, wanted)
    end,  -- function
    show_vnums,  -- show vnum?
    1,          -- how many to expect
    true        -- just walk there
    )

end -- map_goto

-- -----------------------------------------------------------------
-- line_received - called by a trigger on all lines
--   work out its line type, and then handle a line-type change
-- -----------------------------------------------------------------

last_deduced_type = nil
saved_lines = { }

function line_received (name, line, wildcards, styles)

  if (not config.BLANK_LINE_TERMINATES_LINE_TYPE) and Trim (line) == "" then
    return
  end -- if empty line

  local this_line = GetLinesInBufferCount()
  local deduced_type


  if config.BLANK_LINE_TERMINATES_LINE_TYPE and Trim (line) == "" then
    deduced_type = nil
  else
   deduced_type = analyse_line (this_line)
  end -- if

  if deduced_type ~= last_deduced_type then

    -- deal with previous line type
    -- INFO ("Now handling", last_deduced_type)

    if last_deduced_type then
      line_types [last_deduced_type].handler (saved_lines)  -- handle the line(s)
    end -- if we have a type

    last_deduced_type = deduced_type
    saved_lines = { }
  end -- if line type has changed

   -- INFO ("This line is", deduced_type)

  table.insert (saved_lines, { line = line, styles = styles } )
end -- line_received

-- -----------------------------------------------------------------
-- corpus_info - show how many times we trained the corpus
-- -----------------------------------------------------------------

function corpus_info ()
  mapper.mapprint  (string.format ("%15s %5s %5s", "Line type", "is", "not"))
  mapper.mapprint  (string.format ("%15s %5s %5s", string.rep ("-", 15), string.rep ("-", 5), string.rep ("-", 5)))
  for k, v in pairs (stats) do
    mapper.mapprint  (string.format ("%15s %5d %5d", k, v.is, v.isnot))
  end -- for each line type
end -- corpus_info

-- -----------------------------------------------------------------
-- OnHelp - show help
-- -----------------------------------------------------------------
function OnHelp ()
	mapper.mapprint (string.format ("[MUSHclient mapper, version %0.1f]", mapper.VERSION))
	mapper.mapprint (GetPluginInfo (GetPluginID (), 3))
  mapper.mapprint (string.rep ("-", 30))
  mapper.mapprint (string.format ("%s version %0.2f", GetPluginName(), GetPluginInfo (GetPluginID (), 19)))
end

function map_where (name, line, wildcards)

  if not mapper.check_we_can_find () then
    return
  end -- if

  local wanted = wildcards [1]
  -- they are stored as upper-case
  wanted = wanted:upper ()

  if current_room and string.match (current_room, wanted) then
    mapper.mapprint ("You are already in that room.")
    return
  end -- if

  local paths = mapper.find_paths (current_room,
           function (uid)
            return string.match (uid, wanted), string.match (uid, wanted)
            end)

  local uid, item = next (paths, nil) -- extract first (only) path

  -- nothing? room not found
  if not item then
    mapper.mapprint (string.format ("Room %s not found", wanted))
    return
  end -- if

  -- turn into speedwalk
  local path = mapper.build_speedwalk (item.path)

  -- display it
  mapper.mapprint (string.format ("Path to %s is: %s", wanted, path))

end -- map_where


-- -----------------------------------------------------------------
-- when_to_draw
-- mapper draw room on <option> --> when to draw the new room. Options are one of:
--                      room name, description, exits, prompt
--                      Normal: exits because exits usually come last.
--                      However if the exits come before the description draw after the description.
-- -----------------------------------------------------------------
local when_types = {
    ["room name"]   = DRAW_MAP_ON_ROOM_NAME,
    ["description"] = DRAW_MAP_ON_DESCRIPTION,
    ["exits"]       = DRAW_MAP_ON_EXITS,
    ["prompt"]      = DRAW_MAP_ON_PROMPT,
    } -- end of table

function when_to_draw (name, line, wildcards)
  local when = wildcards [1]:lower ()

  local w = when_types [when]
  if not w then
    mapper.mapprint ("Unknown time to draw the map: " .. wildcards [1])
    mapper.mapprint ("Valid times are:")
    for k in pairs (when_types) do
      mapper.mapprint ("  mapper draw room on " .. k)
    end -- for
    return
  end -- if type not found

  config.WHEN_TO_DRAW_MAP = w
  mapper.mapprint ("Map will be redrawn after " .. when:upper () .. " line type received")

end -- when_to_draw

function validate_colour (which)
  local colour = ColourNameToRGB (which)
  if colour == -1 then
    mapper.mapprint (string.format ('Colour name "%s" not a valid HTML colour name or code.', which))
    mapper.mapprint ("You can use HTML colour codes such as #123456 or names such as black or green.")
    mapper.mapprint ("See the Colour Picker (Edit menu -> Colour picker: Ctrl+Alt+P).")
    mapper.mapprint ("Colour not changed.")
    return false
  end -- if bad
  return true
end -- validate_colour

function colour_change (description, colour, which)
  mapper.mapprint (description .. " was previously: " .. config [which])
  if not validate_colour (colour) then
    return
  end -- bad colour name
  config [which] = colour
  mapper.mapprint (description .. " is now: " .. colour)
end -- colour_change

-- -----------------------------------------------------------------
-- mapper_status_background - eg. Type: mapper status background black
-- -----------------------------------------------------------------
function mapper_status_background (name, line, wildcards)
  colour_change ("Background colour for the room types window", wildcards [1], 'STATUS_BACKGROUND_COLOUR')
end -- mapper_status_background

-- -----------------------------------------------------------------
-- mapper_status_border - eg. Type: mapper status border gray
-- -----------------------------------------------------------------
function mapper_status_border (name, line, wildcards)
  colour_change ("Border colour for the room types window", wildcards [1], 'STATUS_FRAME_COLOUR')
end -- mapper_status_border

-- -----------------------------------------------------------------
-- mapper_status_text - eg. Type: mapper status text lightgreen
-- -----------------------------------------------------------------
function mapper_status_text (name, line, wildcards)
  colour_change ("Text colour for the room types window", wildcards [1], 'STATUS_TEXT_COLOUR')
end -- mapper_status_text

-- -----------------------------------------------------------------
-- mapper_uid_size - eg. mapper uid size 6
-- -----------------------------------------------------------------
function mapper_uid_size (name, line, wildcards)
  local size = tonumber (wildcards [1])
  if not size then
    mapper.mapprint ("Bad UID size: " .. wildcards [1])
    return
  end -- if

  if size < 3 or size > 25 then
    mapper.mapprint ("UID size must be in the range 3 to 25")
    return
  end -- if

  config.UID_SIZE = size
  mapper.mapprint (size .. " characters of the unique id (UID) will be shown")
end -- mapper_uid_size

-- -----------------------------------------------------------------
-- mapper_activate_description_after_exits - descriptions are ignored until after an exits line
-- -----------------------------------------------------------------
function mapper_activate_description_after_exits (name, line, wildcards)
  config.ACTIVATE_DESCRIPTION_AFTER_EXITS = true
  mapper.mapprint ("Description lines only active after an exit line has been received")
  mapper.mapprint ("To disable this, type: mapper activate description always")
end -- mapper_activate_description_after_exits

-- -----------------------------------------------------------------
-- mapper_activate_description_always - descriptions are always active
-- -----------------------------------------------------------------
function mapper_activate_description_always (name, line, wildcards)
  config.ACTIVATE_DESCRIPTION_AFTER_EXITS = false
  mapper.mapprint ("Description lines always active")
  mapper.mapprint ("To disable this, type: mapper activate description after exits")
end -- mapper_activate_description_always

-- -----------------------------------------------------------------
-- mapper_blank_lines_terminate_line_type - blank lines are considered a change of line type
-- -----------------------------------------------------------------
function mapper_blank_lines_terminate_line_type (name, line, wildcards)
  config.BLANK_LINE_TERMINATES_LINE_TYPE = true
  mapper.mapprint ("A blank line terminates the previous type of line")
  mapper.mapprint ("To disable this, type: mapper ignore blank lines")
end -- mapper_blank_lines_terminate_line_type

-- -----------------------------------------------------------------
-- mapper_ignore_blank_lines - descriptions are always active
-- -----------------------------------------------------------------
function mapper_ignore_blank_lines (name, line, wildcards)
  config.BLANK_LINE_TERMINATES_LINE_TYPE = false
  mapper.mapprint ("Blank lines are ignored")
  mapper.mapprint ("To disable this, type: mapper blank lines terminate line type")
end -- mapper_ignore_blank_lines

-- -----------------------------------------------------------------
-- mapper_add_newline_to_prompt - tries to add a newline to the end of packets without one
-- -----------------------------------------------------------------
function mapper_add_newline_to_prompt (name, line, wildcards)
  config.ADD_NEWLINE_TO_PROMPT = true
  mapper.mapprint ("Add a newline to a prompt at the end of packets without one")
  mapper.mapprint ("To disable this, type: mapper no add newline to prompt")
end -- mapper_add_newline_to_prompt

-- -----------------------------------------------------------------
-- mapper_no_add_newline_to_prompt - descriptions are always active
-- -----------------------------------------------------------------
function mapper_no_add_newline_to_prompt (name, line, wildcards)
  config.ADD_NEWLINE_TO_PROMPT = false
  mapper.mapprint ("Do not a newline to a prompt at the end of packets without one")
  mapper.mapprint ("To disable this, type: mapper add newline to prompt")
end -- mapper_no_add_newline_to_prompt

-- -----------------------------------------------------------------
-- mapper_config_info - summarize configuration
-- -----------------------------------------------------------------
function yesno (which)
  if which then
    return "Yes"
  else
    return "No"
  end -- if
end -- yesno

function mapper_config_info (name, line, wildcards)
  mapper.mapprint (string.format ("%50s: %s", "Background colour for the room types window", config.STATUS_BACKGROUND_COLOUR))
  mapper.mapprint (string.format ("%50s: %s", "Border colour for the room types window", config.STATUS_FRAME_COLOUR))
  mapper.mapprint (string.format ("%50s: %s", "Text colour for the room types window", config.STATUS_TEXT_COLOUR))
  mapper.mapprint (string.format ("%50s: %s", "UID size", config.UID_SIZE))
  mapper.mapprint (string.format ("%50s: %s", "Descriptions active only after exit lines", yesno (config.ACTIVATE_DESCRIPTION_AFTER_EXITS)))
  mapper.mapprint (string.format ("%50s: %s", "Blank lines terminate line type", yesno (config.BLANK_LINE_TERMINATES_LINE_TYPE)))
  mapper.mapprint (string.format ("%50s: %s", "Add newline to prompt at end of packet", yesno (config.ADD_NEWLINE_TO_PROMPT)))

  local when = "Unknown"
  for k, v in pairs (when_types) do
    if config.WHEN_TO_DRAW_MAP == v then
      when = k
      break
    end -- if
  end -- for
  mapper.mapprint (string.format ("%50s: %s", "Draw map after receiving", when))
  local count = 0
  for k, v in pairs (stats) do
    count = count + v.is + v.isnot
  end -- for each line type
  mapper.mapprint (string.format ("%50s: %s", "Number of times line types trained", count))

  mapper.mapprint ('  Type "mapper corpus info" for more information about line training')
  mapper.mapprint (string.format ("%50s: %s", "Show mapper training window and status", yesno (config.SHOW_LEARNING_WINDOW)))
  if not config.SHOW_LEARNING_WINDOW then
    mapper.mapprint ('  Type "mapper learn" to activate the training windows')
  end -- if
end -- mapper_config_info

-- -----------------------------------------------------------------
-- OnPluginPacketReceived - try to add newlines to prompts if wanted
-- -----------------------------------------------------------------
function OnPluginPacketReceived (pkt)

  if not config.ADD_NEWLINE_TO_PROMPT then
    return pkt
  end -- if

  -- add a newline to the end of a packet if it appears to be a simple prompt (just a ">" sign after a newline)
  if string.match (pkt, "\n>%s-$") then
    return pkt .. "\n";
  end -- if

  -- add a newline to the end of a packet if it appears to be a prompt with a colour change (ie. \n ESC (number) "m>")
  if string.match (pkt, "\n\027.-m>%s-$") then
    return pkt .. "\n";
  end -- if

  return pkt
end -- OnPluginPacketReceived

function show_corpus ()


  for name, type_info in pairs (line_types) do
    mapper.mapprint (string.rep ("=", 72))
    mapper.mapprint (type_info.short)
    mapper.mapprint (string.rep ("=", 72))
    corpus_line_type = corpus [name]
    for _, marker in ipairs (markers) do
      mapper.mapprint ("  " .. string.rep ("-", 70))
      mapper.mapprint ("  " .. marker.desc)
      mapper.mapprint ("  " .. string.rep ("-", 70))
      local f = marker.show
      local accessing_function  = marker.accessing_function
      if f then
        mapper.mapprint (string.format ("    %20s %5s %5s %7s", "Value", "Yes", "No", "Score"))
        mapper.mapprint (string.format ("    %20s %5s %5s %7s", "-------", "---", "---", "-----"))
        for k, v in accessing_function (corpus_line_type [marker.marker], function (a, b) return a:lower () < b:lower () end ) do
          f (k, v)
        end -- for each value
      end -- if function exists
    end -- for each marker type
  end -- for each line type

end -- show_corpus
