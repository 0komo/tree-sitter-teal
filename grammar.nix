tree-sitter:
with tree-sitter;
grammar {
  name = "teal";
  rules = [
    (rule "root" (s: R ''.+''))
  ];
}
