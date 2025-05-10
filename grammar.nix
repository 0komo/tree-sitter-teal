tree-sitter:
with tree-sitter;
let
  PREC = {
    or = prec.left 1;
    and = prec.left 2;
    is = prec.left 3;
    compare = prec.left 4;
    bor = prec.left 5;
    bnot = prec.left 6;
    band = prec.left 7;
    bshift = prec.left 8;
    concat = prec.right 9;
    arith = prec.left 10;
    multi = prec.left 11;
    unary = prec.left 12;
    power = prec.right 13;
    as = prec.left 14;
    union = prec.right 15;
  };

  one_or_more = x: repeat1 (seq x);
  zero_or_more = x: repeat (seq x);
  may_appear = x: optional (seq x);

  make_local =
    x:
    seq [
      "local"
      x
    ];
  make_global =
    x:
    seq [
      "global"
      x
    ];
in
grammar {
  name = "teal";
  externals = [
    "_block_comment_start"
    "_block_comment_content"
    "_block_comment_end"
    "_block_string_start"
    "_block_string_content"
    "_block_string_end"
  ];
  extras = s: [
    (R ''[\n]'')
    (R ''\s'')
    s.comment
  ];
  conflicts = s: [
  ];
  rules = [
    (rule "chunk" (s: optional s._block))

    (rule "block" (s: s._block))
    (rule "_block" (
      s:
      choice [
        (seq [
          s._statement
          (optional s.return_statement)
        ])
        s.return_statement
      ]
    ))

    (rule "_statement" (
      s:
      choice [
        s.function_call
        s.empty_statement
        s.break_statement
        s.goto_statement
        s.goto_label
        s.do_statement
        s.global_type_statement
        s.global_record_statement
        s.global_enum_statement
        s.local_type_statement
        s.local_record_statement
        s.local_enum_statement
      ]
    ))

    (rule "global_enum_statement" (s: make_global s._enum_statement))
    (rule "local_enum_statement" (s: make_local s._enum_statement))

    (rule "_enum_statement" (
      s:
      seq [
        "enum"
        (field "name" s.identifier)
        s._enum_body
      ]
    ))

    (rule "global_record_statement" (s: make_global s._record_statement))
    (rule "local_record_statement" (s: make_local s._record_statement))

    (rule "_record_statement" (
      s:
      seq [
        "record"
        (field "name" s.identifier)
        s._record_body
      ]
    ))

    (rule "global_type_statement" (s: make_global s._type_statement))
    (rule "local_type_statement" (s: make_local s._type_statement))

    (rule "_type_statement" (
      s:
      seq [
        "type"
        (field "name" s.identifier)
        (field "type_generic" (optional s.type_generic))
        "="
        (field "type" s._new_type)
      ]
    ))

    (rule "_new_type" (
      s:
      choice [
        s.record_type
        s.enum_type
        s.nominal_type
        s.external_nominal_type
      ]
    ))

    (rule "external_nominal_type" (
      s:
      seq [
        "require"
        "("
        (field "module" s.string)
        ")"
        (may_appear [
          "."
          (field "type" s.nominal_type)
        ])
      ]
    ))

    (rule "record_type" (
      s:
      seq [
        "record"
        s._record_body
      ]
    ))

    (rule "enum_type" (
      s:
      seq [
        "enum"
        s._enum_body
      ]
    ))

    (rule "_record_body" (
      s:
      seq [
        (field "type_generic" (optional s.type_generic))
        (may_appear [
          "is"
          (field "interfaces" s.interface_list)
        ])
        (may_appear [
          "where"
          (field "where_exp" s._expression)
        ])
        (field "entries" (optional s.record_entries))
        "end"
      ]
    ))

    (rule "interface_list" (
      s:
      choice [
        s._interface_list_normal
        s._interface_list_array
      ]
    ))

    (rule "_interface_list_normal" (
      s:
      seq [
        s.nominal_type
        (zero_or_more [
          ","
          s.nominal_type
        ])
      ]
    ))

    (rule "_interface_list_array" (
      s:
      seq [
        "{"
        (field "base_array_type" s._type)
        "}"
        (zero_or_more [
          ","
          s.nominal_type
        ])
      ]
    ))

    (rule "record_entries" (s: repeat1 s._record_entry))

    (rule "_record_entry" (
      s:
      choice [
        s.record_entry_userdata
        s.record_entry_type
        s.record_entry_record
        s.record_entry_enum
        s.record_entry_key
        s.record_entry_metamethod_key
      ]
    ))

    (rule "record_entry_userdata" (s: "userdata"))

    (rule "record_entry_type" (
      s:
      seq [
        "type"
        (field "name" s.identifier)
        "="
        s._new_type
      ]
    ))

    (rule "record_entry_enum" (
      s:
      seq [
        "enum"
        (field "name" s.identifier)
        s._enum_body
      ]
    ))

    (rule "record_entry_record" (
      s:
      seq [
        "record"
        (field "name" s.identifier)
        s._record_body
      ]
    ))

    (rule "record_entry_key" (
      s:
      seq [
        s._record_key
        ":"
        (field "type" s._type)
      ]
    ))

    (rule "record_entry_metamethod_key" (
      s:
      seq [
        "metamethod"
        s._record_key
        ":"
        (field "type" s._type)
      ]
    ))

    (rule "_record_key" (
      s:
      choice [
        (field "name" s.identifier)
        (seq [
          "["
          (field "name" s.string)
          "]"
        ])
      ]
    ))

    (rule "_enum_body" (
      s:
      seq [
        (repeat s.string)
        "end"
      ]
    ))

    (rule "do_statement" (
      s:
      seq [
        "do"
        (field "block" s.block)
        "end"
      ]
    ))

    (rule "return_statement" (
      s:
      seq [
        "return"
        (alias s._expression_list (s "expression_list"))
      ]
    ))

    (rule "goto_label" (
      s:
      seq [
        "::"
        (field "name" s.identifier)
        "::"
      ]
    ))

    (rule "goto_statement" (
      s:
      seq [
        "goto"
        (field "name" s.identifier)
      ]
    ))

    (rule "break_statement" (s: "break"))

    (rule "empty_statement" (s: ";"))

    (rule "_type" (
      s:
      choice [
        s._basic_type
        s.union_type
        s.grouped_type
      ]
    ))

    (rule "grouped_type" (
      s:
      seq [
        "("
        s._type
        ")"
      ]
    ))

    (rule "_basic_type" (
      s:
      choice [
        s.nominal_type
        s.array_type
        s.tuple_type
        s.map_type
        s.function_type
      ]
    ))

    (rule "union_type" (
      s:
      PREC.union (seq [
        s._type
        (repeat1 (
          prec.right 0 (seq [
            "|"
            s._type
          ])
        ))
      ])
    ))

    (rule "nominal_type" (
      s:
      prec.right 0 (seq [
        s._nominal_type
        (field "args" (optional s.type_args))
      ])
    ))

    (rule "_nominal_type" (
      s:
      choice [
        s._multi_nominal_type
        s._single_nominal_type
      ]
    ))

    (rule "_single_nominal_type" (s: field "name" s.identifier))

    (rule "_multi_nominal_type" (
      s:
      prec.right 0 (seq [
        (field "parents" (
          alias (one_or_more [
            s.identifier
            "."
          ]) (s "parents")
        ))
        (field "name" s.identifier)
        (field "args" (optional s.type_args))
      ])
    ))

    (rule "function_type" (
      s:
      prec.right 0 (seq [
        (field "type" "function")
        (field "type_generic" (optional s.type_generic))
        "("
        (field "parameter_types" (optional s.function_type_param_list))
        ")"
        (may_appear [
          ":"
          (field "return_types" s.function_type_return_list)
        ])
      ])
    ))

    (rule "function_type_param_list" (
      s:
      choice [
        (seq [
          s.function_type_param
          (zero_or_more [
            ","
            s.function_type_param
          ])
          (may_appear [
            ","
            s.function_type_param_vararg
          ])
        ])
        s.function_type_param_vararg
      ]
    ))

    (rule "function_type_param" (
      s:
      let
        with_name_form = seq [
          (field "name" s.identifier)
          (field "optional" (optional "?"))
          (field "separator" ":")
          (field "type" s._type)
        ];
        only_type_form = seq [
          (field "optional" (optional "?"))
          (field "type" s._type)
        ];
      in
      choice [
        with_name_form
        only_type_form
      ]
    ))

    (rule "function_type_param_vararg" (
      s:
      let
        with_name_form = seq [
          (field "name" (alias "..." (s "vararg")))
          (field "separator" ":")
          (field "type" s._type)
        ];
        only_type_form = seq [
          # i don't know why Teal allowed optional type on the "only-type" param syntax,
          # probably semantic issue
          #                           vvv
          (field "optional" (optional "?"))
          (field "type" s._type)
          (field "vararg" "...")
        ];
      in
      choice [
        with_name_form
        only_type_form
      ]
    ))

    (rule "function_type_return_list" (
      s:
      prec.right 0 (choice [
        (seq [
          s._type
          (zero_or_more [
            ","
            s._type
          ])
          (may_appear [
            ","
            s.function_type_return_vararg
          ])
        ])
        s.function_type_return_vararg
      ])
    ))

    (rule "function_type_return_vararg" (
      s:
      prec 1 (seq [
        (field "type" s._type)
        (field "vararg" "...")
      ])
    ))

    (rule "map_type" (
      s:
      seq [
        (field "start" "{")
        (field "key" (s._type))
        (field "separator" ":")
        (field "value" (s._type))
        (field "end" "}")
      ]
    ))

    (rule "tuple_type" (
      s:
      seq [
        (field "start" "{")
        (field "type" (s.type_list))
        (field "end" "}")
      ]
    ))

    (rule "array_type" (
      s:
      seq [
        (field "start" "{")
        (field "type" (s._type))
        (field "end" "}")
      ]
    ))

    (rule "type_args" (
      s:
      seq [
        (field "start" "<")
        (field "type" (choice [
          s._type
          s.type_list
        ]))
        (field "end" ">")
      ]
    ))

    (rule "type_list" (
      s:
      seq [
        s._type
        (one_or_more [
          ","
          s._type
        ])
      ]
    ))

    (rule "type_generic" (
      s:
      seq [
        (field "start" "<")
        (field "type" (choice [
          s.type_generic_expr
          s.type_generic_list
        ]))
        (field "end" ">")
      ]
    ))

    (rule "type_generic_list" (
      s:
      seq [
        s.type_generic_expr
        (one_or_more [
          ","
          s.type_generic_expr
        ])
      ]
    ))

    (rule "type_generic_expr" (
      s:
      choice [
        (field "name" s.identifier)
        (seq [
          (field "name" s.identifier)
          (field "is" "is")
          (field "parent_type" s.type_generic_nominal_type)
        ])
      ]
    ))

    (rule "type_generic_nominal_type" (s: s._nominal_type))

    (rule "_expression" (
      s:
      prec.left 0 (choice [
        s.number
        s.boolean
        s.nil
        s.string
        s.vararg_expression
        s.binary_operation
        s.unary_operation
        s.table
        s.is_operation
        s.as_operation
        s.function_expression
        s._prefix_expression
      ])
    ))

    (rule "_prefix_expression" (
      s:
      choice [
        s.grouped_expression
        s.variable
        s.function_call
      ]
    ))

    (rule "grouped_expression" (
      s:
      seq [
        "("
        s._expression
        ")"
      ]
    ))

    (rule "function_expression" (
      s:
      seq [
        "function"
        s._function_body
      ]
    ))

    (rule "_function_body" (
      s:
      seq [
        (field "type_generic" (optional s.type_generic))
        "("
        (field "parameters" (optional s.function_param_list))
        ")"
        (may_appear [
          ":"
          (field "returns" s.function_return_list)
        ])
        (field "body" (optional s.block))
        "end"
      ]
    ))

    (rule "function_return_list" (
      s:
      choice [
        (seq [
          s._type
          (zero_or_more [
            ","
            s._type
          ])
          (may_appear [
            ","
            s.function_return_vararg
          ])
        ])
        s.function_return_vararg
      ]
    ))

    (rule "function_return_vararg" (
      s:
      seq [
        s._type
        "..."
      ]
    ))

    (rule "function_param_list" (
      s:
      choice [
        (seq [
          s._function_param_name_list
          (may_appear [
            ","
            s.function_param_vararg
          ])
        ])
        s.function_param_vararg
      ]
    ))

    (rule "_function_param_name_list" (
      s:
      prec.right 0 (seq [
        s.function_param_name
        (zero_or_more [
          ","
          s.function_param_name
        ])
      ])
    ))

    (rule "function_param_vararg" (
      s:
      seq [
        (field "name" (alias "..." (s "vararg")))
        (may_appear [
          (field "type_separator" ":")
          (field "type" s._type)
        ])
      ]
    ))

    (rule "function_param_name" (
      s:
      seq [
        (field "name" s.identifier)
        (field "optional" (optional "?"))
        (may_appear [
          (field "type_separator" ":")
          (field "type" s._type)
        ])
      ]
    ))

    (rule "function_call" (
      s:
      choice [
        (seq [
          (field "function" s._prefix_expression)
          (field "args" s.function_args)
        ])
        (seq [
          (field "object" s._prefix_expression)
          (field "separator" ":")
          (field "method" s.identifier)
          (field "args" s.function_args)
        ])
      ]
    ))

    (rule "function_args" (
      s:
      choice [
        (seq [
          "("
          (optional s._expression_list)
          ")"
        ])
        s.table
        s.string
      ]
    ))

    (rule "table" (
      s:
      seq [
        "{"
        (optional s.table_field_list)
        "}"
      ]
    ))

    (rule "table_field_list" (
      s:
      seq [
        s.table_field
        (zero_or_more [
          s._table_field_sep
          s.table_field
        ])
        (optional s._table_field_sep)
      ]
    ))

    (rule "_table_field_sep" (
      s:
      choice [
        ","
        ";"
      ]
    ))

    (rule "table_field" (
      s:
      choice [
        s._table_field_simple
        s._table_field_name_pair
        s._table_field_expr_pair
      ]
    ))

    (rule "_table_field_expr_pair" (
      s:
      seq [
        (field "key" s.table_key_expression)
        (field "separator" "=")
        (field "value" s._expression)
      ]
    ))
    (rule "table_key_expression" (
      s:
      seq [
        (field "start" "[")
        (field "expression" s._expression)
        (field "end" "]")
      ]
    ))

    (rule "_table_field_name_pair" (
      s:
      prec 1 (seq [
        (field "key" s.identifier)
        (may_appear [
          ":"
          (field "type" s._type)
        ])
        (field "separator" "=")
        (field "value" s._expression)
      ])
    ))
    (rule "_table_field_simple" (s: s._expression))

    (rule "as_operation" (
      s:
      PREC.as (seq [
        (field "expression" s._expression)
        (field "op" "as")
        (field "type" s._type)
      ])
    ))

    (rule "is_operation" (
      s:
      PREC.is (seq [
        (field "expression" s._expression)
        (field "op" "is")
        (field "type" s._type)
      ])
    ))

    (rule "unary_operation" (
      s:
      PREC.unary (seq [
        (choice [
          "not"
          "#"
          "-"
          "~"
        ])
        s._expression
      ])
    ))

    (rule "binary_operation" (
      s:
      choice (
        let
          pair = op: preced: { inherit op preced; };
        in
        map
          (
            x:
            let
              inherit (x) op preced;
            in
            preced (seq [
              s._expression
              op
              s._expression
            ])
          )
          [
            (pair "or" PREC.or)
            (pair "and" PREC.and)
            (pair "<" PREC.compare)
            (pair ">" PREC.compare)
            (pair "<=" PREC.compare)
            (pair ">=" PREC.compare)
            (pair "~=" PREC.compare)
            (pair "==" PREC.compare)
            (pair "|" PREC.bor)
            (pair "~" PREC.bnot)
            (pair "&" PREC.band)
            (pair "<<" PREC.bshift)
            (pair ">>" PREC.bshift)
            (pair ".." PREC.concat)
            (pair "+" PREC.arith)
            (pair "-" PREC.arith)
            (pair "*" PREC.multi)
            (pair "/" PREC.multi)
            (pair "//" PREC.multi)
            (pair "%" PREC.multi)
            (pair "^" PREC.power)
          ]
      )
    ))

    (rule "vararg_expression" (s: "..."))

    (rule "nil" (s: "nil"))

    (rule "boolean" (
      s:
      choice [
        "true"
        "false"
      ]
    ))

    (rule "string" (
      s:
      choice [
        s._single_quote_string
        s._double_quote_string
        s._block_string
      ]
    ))
    (rule "_block_string" (
      s:
      seq [
        (field "start" (alias s._block_string_start "[["))
        (field "content" (alias s._block_string_content (s "string_content")))
        (field "end" (alias s._block_string_end "]]"))
      ]
    ))
    (rule "_double_quote_string" (
      s:
      seq [
        (field "start" "\"")
        (field "content" (optional (alias s._double_quote_string_content (s "string_content"))))
        (field "end" "\"")
      ]
    ))
    (rule "_double_quote_string_content" (
      s:
      repeat1 (choice [
        (token.immediate (prec 1 (R ''[^"\\\n]+'')))
        s.escape_sequence
      ])
    ))
    (rule "_single_quote_string" (
      s:
      seq [
        (field "start" "'")
        (field "content" (optional (alias s._single_quote_string_content (s "string_content"))))
        (field "end" "'")
      ]
    ))
    (rule "_single_quote_string_content" (
      s:
      repeat1 (choice [
        (token.immediate (prec 1 (R ''[^'\\\n]+'')))
        s.escape_sequence
      ])
    ))
    (rule "escape_sequence" (
      s:
      token.immediate (seq [
        "\\"
        (choice [
          (R ''[\nabfnrtv\\'"]'')
          (R ''z\s*'')
          (R ''x[[:xdigit:]]{2}'')
          (R ''\d{1,3}'')
          (R ''u\{[[:xdigit:]]{1,8}\}'')
        ])
      ])
    ))

    (rule "number" (
      s:
      let
        decimal_digits = R ''[0-9]+'';
        signed_integer = seq [
          (optional (choice [
            "-"
            "+"
          ]))
          decimal_digits
        ];
        decimal_exponent_part = seq [
          (choice [
            "e"
            "E"
          ])
          signed_integer
        ];

        decimal_integer_literal = choice [
          "0"
          (seq [
            (optional "0")
            (R ''[1-9]'')
            (optional decimal_digits)
          ])
        ];

        hex_digits = R ''[a-fA-F0-9]+'';
        hex_exponent_part = seq [
          (choice [
            "p"
            "P"
          ])
          signed_integer
        ];

        decimal_literal = choice [
          (seq [
            decimal_integer_literal
            "."
            (optional decimal_digits)
            (optional decimal_exponent_part)
          ])
          (seq [
            "."
            decimal_digits
            (optional decimal_exponent_part)
          ])
          (seq [
            decimal_integer_literal
            (optional decimal_exponent_part)
          ])
        ];

        hex_literal = seq [
          (choice [
            "0x"
            "0X"
          ])
          hex_digits
          (optional (seq [
            "."
            hex_digits
          ]))
          (optional hex_exponent_part)
        ];
      in
      token (choice [
        decimal_literal
        hex_literal
      ])
    ))

    (rule "variable" (
      s:
      choice [
        s._variable_simple
        s._variable_index_name
        s._variable_index_expr
      ]
    ))

    (rule "_variable_simple" (s: (field "name" s.identifier)))
    (rule "_variable_index_name" (
      s:
      (seq [
        (field "parent" s._prefix_expression)
        "."
        (field "name" s.identifier)
      ])
    ))
    (rule "_variable_index_expr" (
      s:
      (seq [
        (field "parent" s._prefix_expression)
        (field "start" "[")
        (field "expression" s._expression)
        (field "end" "]")
      ])
    ))
    (rule "identifier" (s: R ''[a-zA-Z_][a-zA-Z0-9_]*''))

    (rule "_expression_list" (
      s:
      seq [
        s._expression
        (zero_or_more [
          ","
          s._expression
        ])
      ]
    ))

    (rule "comment" (
      s:
      let
        line_comment = seq [
          (field "start" "--")
          (field "content" (alias (R ''[^\r\n]*'') (s "comment_content")))
        ];
        block_comment = prec 1 (seq [
          (field "start" (alias s._block_comment_start "--[["))
          (field "content" (alias s._block_comment_content (s "comment_content")))
          (field "end" (alias s._block_comment_end "]]"))
        ]);
      in
      choice [
        line_comment
        block_comment
      ]
    ))

  ];
}
