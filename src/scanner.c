#include "tree_sitter/alloc.h"
#include "tree_sitter/parser.h"

#include <stdio.h>
#include <wctype.h>

#define SERIALIZE_STATE(x, y)                                                  \
  do {                                                                         \
    buffer[x] = y;                                                             \
  } while (0)

#define DESERIALIZE_STATE(x, y)                                                \
  if (length > x)                                                              \
    y = buffer[x];

#define LOG(x) "[tree-sitter-teal] " x
#define STRING(x) (char[2]){x, 0}

enum TokenType {
  BLOCK_COMMENT_START,
  BLOCK_COMMENT_CONTENT,
  BLOCK_COMMENT_END,

  BLOCK_STRING_START,
  BLOCK_STRING_CONTENT,
  BLOCK_STRING_END,
};

typedef struct {
  uint8_t level_count;
} State;

static inline void mark_end(TSLexer *lx) {
  lx->log(lx, LOG("marked end before '%s' on column %d"), STRING(lx->lookahead),
          lx->get_column(lx));
  lx->mark_end(lx);
}

static inline void consume(TSLexer *lx) {
  lx->log(lx, LOG("consumed '%s' on column %d"), STRING(lx->lookahead),
          lx->get_column(lx) + 1);
  lx->advance(lx, false);
}

static inline void skip(TSLexer *lx) {
  lx->log(lx, LOG("skipped '%s' on column %d"), STRING(lx->lookahead),
          lx->get_column(lx) + 1);
  lx->advance(lx, true);
}

static inline bool consume_char(TSLexer *lx, int32_t c) {
  if (lx->lookahead != c)
    return false;

  consume(lx);
  return true;
}

static inline uint8_t consume_and_count_char(TSLexer *lx, int32_t c) {
  uint8_t count = 0;
  while (lx->lookahead == c) {
    ++count;
    consume(lx);
  }
  return count;
}

static inline void skip_ws(TSLexer *lx) {
  while (iswspace(lx->lookahead)) {
    skip(lx);
  }
}

static inline void reset_state(State *state) { state->level_count = 0; }

void *tree_sitter_teal_external_scanner_create() {
  State *state = ts_calloc(1, sizeof(State));
  return state;
}

void tree_sitter_teal_external_scanner_destroy(void *ud) {
  ts_free((State *)ud);
}

unsigned tree_sitter_teal_external_scanner_serialize(void *ud, char *buffer) {
  State *state = (State *)ud;
  SERIALIZE_STATE(0, state->level_count);
  return 1;
}

void tree_sitter_teal_external_scanner_deserialize(void *ud, const char *buffer,
                                                   unsigned length) {
  State *state = (State *)ud;
  DESERIALIZE_STATE(0, state->level_count);
}

static bool scan_block_start(State *state, TSLexer *lx) {
  if (consume_char(lx, '[')) {
    uint8_t level = consume_and_count_char(lx, '=');

    if (consume_char(lx, '[')) {
      state->level_count = level;
      return true;
    }
  }

  return false;
}

static bool scan_block_end(State *state, TSLexer *lx) {
  if (consume_char(lx, ']')) {
    uint8_t level = consume_and_count_char(lx, '=');

    if (state->level_count == level && consume_char(lx, ']')) {
      return true;
    }
  }

  return false;
}

static bool scan_block_content(State *state, TSLexer *lx) {
  while (!lx->eof(lx)) {
    if (lx->lookahead == ']') {
      mark_end(lx);

      if (scan_block_end(state, lx))
        return true;
    } else {
      consume(lx);
    }
  }

  return false;
}

bool tree_sitter_teal_external_scanner_scan(void *ud, TSLexer *lx,
                                            const bool *valid_symbols) {
  State *state = (State *)ud;

  if (valid_symbols[BLOCK_STRING_END] && scan_block_end(state, lx)) {
    reset_state(state);
    lx->result_symbol = BLOCK_STRING_END;
    return true;
  }

  if (valid_symbols[BLOCK_STRING_CONTENT] && scan_block_content(state, lx)) {
    lx->result_symbol = BLOCK_STRING_CONTENT;
    return true;
  }

  if (valid_symbols[BLOCK_COMMENT_END] && scan_block_end(state, lx)) {
    reset_state(state);
    lx->result_symbol = BLOCK_COMMENT_END;
    return true;
  }

  if (valid_symbols[BLOCK_COMMENT_CONTENT] && scan_block_content(state, lx)) {
    lx->result_symbol = BLOCK_COMMENT_CONTENT;
    return true;
  }

  skip_ws(lx);

  if (valid_symbols[BLOCK_STRING_START] && scan_block_start(state, lx)) {
    lx->result_symbol = BLOCK_STRING_START;
    return true;
  }

  if (valid_symbols[BLOCK_COMMENT_START] && consume_char(lx, '-') &&
      consume_char(lx, '-')) {
    mark_end(lx);

    if (scan_block_start(state, lx)) {
      mark_end(lx);
      lx->result_symbol = BLOCK_COMMENT_START;
      return true;
    }
  }

  return false;
}
