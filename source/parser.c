#include <parser.h>
#include <util.h>

#include <limits.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdbool.h>

struct token {
    // single symbols stored as ascii
    enum {
        TOK_COMMENT = CHAR_MAX + 1,
        TOK_NUMBER,
        TOK_SYMBOL,
        TOK_STRING,
    } kind;

    size_t start, end;
};

struct lexer {
    char *src;
    size_t pos;
};

// initialize the lexer with a file's contents
static void lexer_init_file(struct lexer *lx, char *path) {
    // open source file for reading
    FILE *file = fopen(path, "r");

    if (!file) 
        die("lexer_init_file");

    // get file size 
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    rewind(file);

    // allocate zeroed-out buffer for file data
    lx->src = calloc(size + 1, 1);

    if (!lx->src) 
        die("lexer_init_file");

    // read file into buffer
    size_t bytes_read = fread(lx->src, 1, size, file);
    if (bytes_read < size && ferror(file))
        die("lexer_init_file");

    fclose(file);

    // if null byte found, file contains invalid ASCII
    // TODO: support UTF-8
    for (size_t i = 0; i < size; i++)
        if (lx->src[i] == '\0')
            die_with("lexer_init_file", "invalid ASCII");

    lx->pos = 0;
}

// deallocate lexer
static void lexer_free(struct lexer *lx) {
    free(lx->src);
}

// read a token from the stream
static struct token lexer_next(struct lexer *lx) {
    struct token tk;

    printf("\nchar = %c\n\n", lx->src[lx->pos]);

    switch (lx->src[lx->pos]) {
        case '#':
            tk.kind = TOK_COMMENT;
            tk.start = lx->pos;

            while (lx->src[lx->pos] != '\n' && lx->src[lx->pos++] != '\0');

            tk.end = ++lx->pos;

            break;

        default:
            die_with("fuck", "you");
    }

    return tk;
}

// unit tests
#ifdef TESTRUN

#include <testing.h>

MKTEST(parser_lex_comment) {
    struct lexer lx;
    lexer_init_file(&lx, "tests/comment.bbd");

    struct token tok = lexer_next(&lx);

    if (tok.kind != TOK_COMMENT)
        FAIL;

    printf("\n\n%.*s", (int)(tok.end - tok.start), lx.src + tok.start);

    lexer_free(&lx);

    PASS;
}

#endif