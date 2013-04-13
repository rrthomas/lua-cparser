-- Grammar for C
-- based on that given in K&R 2nd Edition
-- (c) Reuben Thomas 2002-2013


-- TODO: Add rules for function_definition
-- TODO: Make enumeration_constant work in the same way as typedefs

local set = require "std.set"

-- Remove housekeeping info
do
  local extra = {"declared"} -- list of extra housekeeping symbols
  function cleanTree (tree)
    for _, v in ipairs (extra) do
      tree[v] = nil
    end
    for i = 1, #tree do
      if type (tree[i]) == "table" then
        tree[i] = cleanTree (tree[i])
      end
    end
    return tree
  end
end


-- The grammar

CGrammar = {
  translation_unit = {
    {"external_declaration_list", action = cleanTree, ExtDecls = {1}},
  },
  external_declaration = {
--    {"function_definition"},
    {"declaration", Decl = {1}},
  },
  declaration = {
    {"declaration_specifier_list", "init_declarator_list_,_opt", ";",
      DeclStmt = {1, 2}
    },
    {"typedef", "declaration_specifier_list", "declarator_list_,", ";",
      action = function (tree, lexer)
                 for _, v in ipairs (tree[3]) do
                   lexer.typedef[v[2].declared] = true
                 end
                 return tree
               end,
      Typedef = {2, 3}
    },
  },
  declaration_specifier = {
    {"auto", Auto = {}},
    {"register", Register = {}},
    {"static", Static = {}},
    {"extern", Extern = {}},
    {"type_specifier", TypeSpec = {1}},
    {"type_qualifier", TypeQual = {1}},
  },
  type_specifier = {
    {"void", Void = {}},
    {"char", Char = {}},
    {"short", Short = {}},
    {"int", Int = {}},
    {"long", Long = {}},
    {"float", Float = {}},
    {"double", Double = {}},
    {"signed", Signed = {}},
    {"unsigned", Unsigned = {}},
    {"struct_or_union_specifier", AggrSpec = {1}},
    {"enum_specifier", EnumSpec = {1}},
    {"typedef_name", TypedefName = {1}},
  },
  type_qualifier = {
    {"const", Const = {}},
    {"volatile", Volatile = {}},
  },
  struct_or_union_specifier = {
    {"struct_or_union", "identifier", "{", "struct_declaration_list",
      "}",
      NamedAggregateSpec = {1, 2, 4}},
    {"struct_or_union", "{", "struct_declaration_list", "}",
      AggregateSpec = {1, 3}},
    {"struct_or_union", "identifier",
      AggregateName = {1, 2}},
  },
  struct_or_union = {
    {"struct", Struct = {}},
    {"union", Union = {}},
  },
  init_declarator = {
    {"declarator", "=", "initializer"},
    {"declarator"},
  },
  struct_declaration = {
    {"specifier_qualifier_list", "struct_declarator_list_,", ";"},
  },
  specifier_qualifier = {
    {"type_specifier"},
    {"type_qualifier"},
  },
  struct_declarator = {
    {"declarator_opt", ":", "constant_expression"},
    {"declarator"},
  },
  enum_specifier = {
    {"enum", "identifier_opt", "{", "enumerator_list_,", "}"},
    {"enum", "identifier"},
  },
  enumerator = {
    {"identifier", "=", "constant_expression"},
    {"identifier"},
  },
  declarator = {
    {"pointer_opt", "direct_declarator",
      action = function (tree)
                 return {ty = "Declarator", tree[1], tree[2],
                   declared = tree[2][1]}
               end,
    },
  },
  direct_declarator = {
    {"identifier", "direct_declarator_body_list_opt",
      action = function (tree)
                 return {ty = "IdDeclarator", tree[1], tree[2],
                   declared = tree[1]}
               end,
    },
    {"(", "declarator", ")", "direct_declarator_body_list_opt",
      action = function (tree)
                 return {ty = "DeclDeclarator", tree[2], tree[4],
                   declared = tree[2].declared}
               end,
    },
  },
  direct_declarator_body = {
    {"[", "constant_expression_opt", "]"},
    {"(", "parameter_types", ")"},
    {"(", "identifier_list_,_opt", ")"},
  },
  pointer = {
    {"*", "type_qualifier_list_opt", "pointer"},
    {"*", "type_qualifier_list_opt"},
  },
  parameter_types = {
    {"parameter_declaration_list_,", ",", "..."},
    {"parameter_declaration_list_,"},
  },
  parameter_declaration = {
    {"declaration_specifier_list", "declarator"},
    {"declaration_specifier_list", "abstract_declarator_opt"},
  },
  initializer = {
    {"assignment_expression"},
    {"{", "initializer_list_,", ",_opt", "}"},
  },
  type_name = {
    {"specifier_qualifier_list", "abstract_declarator_opt"},
  },
  abstract_declarator = {
    {"pointer_opt", "direct_abstract_declarator"},
    {"pointer"},
  },
  direct_abstract_declarator = {
    {"enclosed_direct_abstract_declarator_opt",
      "direct_abstract_declarator_body_list"},
    {"enclosed_direct_abstract_declarator"},
  },
  enclosed_direct_abstract_declarator = {
    {"(", "abstract_declarator", ")"},
  },
  direct_abstract_declarator_body = {
    {"[", "constant_expression_opt", "]"},
    {"(", "parameter_types_opt", ")"},
  },
  assignment_expression = {
    {"conditional_expression"},
    {"unary_expression", "assignment_operator",
      "assignment_expression"},
  },
  assignment_operator = {
    {"="},
    {"*="},
    {"/="},
    {"%="},
    {"+="},
    {"-="},
    {"<<="},
    {">>="},
    {"&="},
    {"^="},
    {"|="},
  },
  conditional_expression = {
    {"logical_OR_expression", "?", "expression", ":",
      "conditional_expression"},
    {"logical_OR_expression"},
  },
  constant_expression = {
    {"conditional_expression"},
  },
  logical_OR_expression = {
    {"logical_AND_expression", "||", "logical_OR_expression"},
    {"logical_AND_expression"},
  },
  logical_AND_expression = {
    {"inclusive_OR_expression", "&&", "logical_AND_expression"},
    {"inclusive_OR_expression"},
  },
  inclusive_OR_expression = {
    {"exclusive_OR_expression", "|", "inclusive_OR_expression"},
    {"exclusive_OR_expression"},
  },
  exclusive_OR_expression = {
    {"AND_expression", "^", "exclusive_OR_expression"},
    {"AND_expression"},
  },
  AND_expression = {
    {"equality_expression", "&", "AND_expression"},
    {"equality_expression"},
  },
  equality_expression = {
    {"relational_expression", "==", "equality_expression"},
    {"relational_expression", "!=", "equality_expression"},
    {"relational_expression"},
  },
  relational_expression = {
    {"shift_expression", "<", "relational_expression"},
    {"shift_expression", ">", "relational_expression"},
    {"shift_expression", "<=", "relational_expression"},
    {"shift_expression", ">=", "relational_expression"},
    {"shift_expression"},
  },
  shift_expression = {
    {"additive_expression", "<<", "shift_expression"},
    {"additive_expression", ">>", "shift_expression"},
    {"additive_expression"},
  },
  additive_expression = {
    {"multiplicative_expression", "+", "additive_expression"},
    {"multiplicative_expression", "-", "additive_expression"},
    {"multiplicative_expression"},
  },
  multiplicative_expression = {
    {"cast_expression", "*", "multiplicative_expression"},
    {"cast_expression", "/", "multiplicative_expression"},
    {"cast_expression", "%", "multiplicative_expression"},
    {"cast_expression"},
  },
  cast_expression = {
    {"(", "type_name", ")", "cast_expression"},
    {"unary_expression"},
  },
  unary_expression = {
    {"++", "unary_expression"},
    {"--", "unary_expression"},
    {"unary_operator", "cast_expression"},
    {"sizeof", "unary_expression"},
    {"sizeof", "(", "type_name", ")"},
    {"postfix_expression"},
  },
  unary_operator = {
    {"&"},
    {"*"},
    {"+"},
    {"-"},
    {"~"},
    {"!"},
  },
  postfix_expression = {
    {"postfix_expression", "[", "expression", "]"},
    {"postfix_expression", "(", "argument_expression_list_,_opt", ")"},
    {"postfix_expression", ".", "identifier"},
    {"postfix_expression", "->", "identifier"},
    {"postfix_expression", "++"},
    {"postfix_expression", "--"},
    {"primary_expression"},
  },
  primary_expression = {
    {"identifier"},
    {"constant"},
    {"string"},
    {"(", "expression", ")"},
  },
  constant = {
    {"integer_constant"},
    {"character_constant"},
    {"floating_constant"},
    {"enumeration_constant"},
  },

  -- lexeme classes
  lexemes = set.new {
    "separator", "integer_constant", "keyword", "identifier",
    "character_constant", "string", "operator",
    "enumeration_constant", "typedef_name"},
}


-- Changelog

-- 11feb13 Update to current stdlib and Lua 5.2
-- 30may07 Update use of set module
-- 02feb04 Fixed propagation of typedef names in declaration
-- 28apr02 Used new _list_sep suffix
-- 27apr02 Added actions
--         Used new _list suffix
-- 26apr02 Made typedef_name and enumeration_constant terminals
-- 25apr02 Removed left-recursion
-- 23apr02-
-- 24apr02 First version
