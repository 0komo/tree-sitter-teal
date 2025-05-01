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
  };

  one_or_more = x: repeat1 (seq x);
  zero_or_more = x: repeat (seq x);
  may_appear = x: optional (seq x);
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
    (rule "expression" (s: s._expression))

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
        s.simple_type
        s.array_type
        s.tuple_type
        s.map_type
        s.function_type
      ]
    ))

    (rule "union_type" (
      s:
      (prec.left 2 (seq [
        (field "lhs" s._type)
        (field "separator" "|")
        (field "rhs" s._type)
      ]))
    ))

    (rule "simple_type" (
      s:
      prec.right 0 (seq [
        s._simple_type
        (field "args" (optional s.type_args))
      ])
    ))

    (rule "_simple_type" (
      s:
      choice [
        s._multi_simple_type
        s._single_simple_type
      ]
    ))

    (rule "_single_simple_type" (s: field "name" s.identifier))

    (rule "_multi_simple_type" (
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
        (field "generic" (optional s.type_generic))
        (field "opening_parenthesis" "(")
        (field "parameter_types" (optional s.function_type_param_list))
        (field "closing_parenthesis" ")")
        (may_appear [
          (field "return_type_indicator" ":")
          (field "return_types" s.function_type_return_list)
        ])
      ])
    ))

    (rule "function_type_param_list" (
      s:
      let
        vararg_param = s.function_type_param_vararg;
        multi_param = seq [
          s.function_type_param
          (zero_or_more [
            ","
            s.function_type_param
          ])
          (may_appear [
            ","
            s.function_type_param_vararg
          ])
        ];
      in
      choice [
        vararg_param
        multi_param
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
      let
        vararg_return = s.function_type_return_vararg;
        multi_return = (
          prec.right 0 (seq [
            s._type
            (repeat (
              prec.right 0 (seq [
                ","
                s._type
              ])
            ))
            (may_appear [
              ","
              s.function_type_return_vararg
            ])
          ])
        );
      in
      (prec.right 0 (choice [
        vararg_return
        multi_return
      ]))
    ))

    (rule "function_type_return_vararg" (
      s:
      (seq [
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
          (field "parent_type" s.type_generic_simple_type)
        ])
      ]
    ))

    (rule "type_generic_simple_type" (s: s._simple_type))

    (rule "_expression" (
      s:
      choice [
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
        s._prefix_expression
      ]
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
        # ignore
        block_comment = seq [
          (field "start" (alias s._block_comment_start "--[["))
          (field "content" (alias s._block_comment_content (s "comment_content")))
          (field "end" (alias s._block_comment_end "]]"))
        ];
      in
      choice [
        line_comment
        # block_comment
      ]
    ))

  ];
}
