-- Lex preprocessed C source into tokens
-- (c) Reuben Thomas 2002-2004


-- At the moment the lexer is severely limited:
--
--   * only rudimentary efforts are made to separate out operators and
--     separators (which is really a spurious class)
--   * numbers are all returned as integer_constant


require "set"


local punct = "%(%)%{%}%[%]%,%?%*%;%:"

local keyword = set.new {
  "auto", "break", "case", "char", "const", "continue", "default",
  "do", "double", "else", "enum", "extern", "float", "for", "goto",
  "if", "int", "long", "offsetof", "register", "return", "short",
  "signed", "sizeof", "static", "struct", "switch", "typedef",
  "union", "unsigned", "void", "volatile", "while",
}

local function getTok (s, from, pat)
  local to, _ = string.find (s, pat, from)
  to = to or 0
  return to, string.sub (s, from, to - 1)
end

CLexer = Object {
  _init = {"input"},
  i = 1,
  typedef = {},
}

function CLexer:__index (i)
  if self.i == -1 then
    return nil
  end
  self:nextTok ()
  return self[i]
end

function CLexer:nextTok ()
  local i = string.find (self.input, "%S", self.i)
  if i == nil then
    self.i = -1
    return
  end
  self.i = i
  local c = string.sub (self.input, self.i, self.i)
  local to, tok
  if string.find (c, "[" .. punct .. "]") then
    ty, tok = "separator", c
    to = self.i + 1
  else
    if string.find (c, "%d") then
      to, tok = getTok (self.input, self.i, "[^%a%d%.%-]")
      ty = "integer_constant"
    elseif string.find (c, "[%a%_]") then
      to, tok = getTok (self.input, self.i, "[^%w_]")
      if keyword[tok] then
        ty = "keyword"
      elseif self.typedef[tok] then
        ty = "typedef_name"
      else
        ty = "identifier"
      end
    elseif c == "'" then
      to, tok = getTok (self.input, self.i, "[^%\\]'")
      ty = "character_constant"
    elseif c == "\"" then
      to, tok = getTok (self.input, self.i, "[^%\\]\"")
      ty = "string"
    else
      to, tok = getTok (self.input, self.i,
                         "[^%+%-%/%<%>%=%%%^%~%&%#]")
      ty = "operator"
    end
  end
  table.insert (self, {ty = ty, tok = tok})
  self.i = to
end


-- Changelog

-- 22apr02 First version
-- 23apr02 Renamed lexemes to match grammar
--         Removed '.' from punct, because of vararg "..."
-- 24apr02 Set the tok component of the token in separators
-- 26apr02 Made lexer object-oriented and lazy
-- 27apr02 Return typedef names as typedef_name
--         Increased object orientation
-- 29jan04 Updated to Lua 5 and current stdlib
