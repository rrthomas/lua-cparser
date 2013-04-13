#!/usr/bin/env lua5.2
prog = {
  name = "clue",
  banner = "clue 0.04 (11 Feb 2013) by Reuben Thomas (rrt@sc3d.org)",
  purpose = "Wrap C fully automatically into Lua",
}

-- TODO: Make the lexer work fully
-- TODO: Make the parser work fully
-- TODO: Make the parser understand simple #defines (use cpp -dD)
-- TODO: Start outputting bindings

-- Things to output bindings for:
-- types
-- functions
-- variables

-- Types
--
-- need to have hardwired bindings for the basic types; we build
-- function bindings and variable bindings in terms of these
--
-- map numeric types to Lua numbers (integral types which are smaller
-- than the mantissa, and floating types which are smaller than or the
-- same as whatever is used for Lua numbers, if floating)
--
-- map bool to Lua booleans
--
-- map the string type used for Lua strings to Lua strings
--
-- all other types are mapped to userdata
--
-- Generate a get, set, addressOf and constructor method for each
-- type; these are used for variables


-- Variables
--
-- Primitive C objects are lightuserdata; complex objects are
-- userdata.


require "std"
local Parser = require "rrt.parser"

dofile "lexC.lua"
dofile "CGrammar.lua"

_DEBUG = 1


-- Generic routines

function filterTree (p, t)
  if p (t) then
    return t
  else
    local l = {}
    for _, v in ipairs (t) do
      if type(v) == "table" then
        l = list.concat (l, filterTree (p, v))
      end
    end
    return l
  end
end


-- Specific routines

function getTypes (ty)
  local typedef = list.filter (function (t)
                                 return t.ty == "Typedef"
                               end,
                               ty)
  for _, t in ipairs (typedef) do
    local declSpec, declList = t[1], t[2]
    for _, d in ipairs (declList) do
      print (d.declared, declSpec, declList)
    end
  end
end


-- Process a file
function clue ()
  local input = io.read ("*a")
  local lexer = CLexer {input}
  local parser = Parser {CGrammar}
  local tree, to = parser:parse ("translation_unit", lexer)
  -- print (tree)
  if to == false then
    die ("syntax error")
  elseif to <= #lexer then
    die ("extraneous tokens at end")
  end
  local decl = filterTree (function (t)
                             return t.ty == "Decl"
                           end,
                           tree)
  getTypes (decl)
end


-- Command-line options
options = {
}


-- Main routine
getopt.processArgs (prog)
io.processFiles (clue)
