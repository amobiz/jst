%{

var DEBUG = true;
var INDENTS = '    ';

var row = 0;
var col = 0;
var depth = 0;
var blocks = [];

function log() {
    if (DEBUG) {
        var i, s = '';
        for (i = 0; i < depth; ++i) {
            s += INDENTS;
        }
        for (i = 0; i < arguments.length; ++i) {
            s += arguments[i];
        }
        console.log(s);
    }
}

function tag(name, attributes) {
    return {
        type: 'Tag',
        name: name,
        attributes: attributes || {}
    };
}

%}

/* lexical grammar */

%lex

NAME                        [a-zA-Z_][a-zA-Z0-9_-]*
EOL                         \r\n|\n|\r
SPACE                       [ \t]
BLANK                       \s+
LINE_COMMENT                '//'.*
BLOCK_COMMENT               '/*'((\*+[^/*])|([^*]))*\**'*/'
DOUBLE_QUOTE_TEXT           \"(?:\\\"|[^"\r\n])*\"
SINGLE_QUOTE_TEXT           \'(?:\\\'|[^'\r\n])*\'
CODE_QUOTE_TEXT             \`(?:\\\`|[^`])*\`
CODE_QUOTE_LANG             \`\`\`({NAME})?(?:\\\`|[^`])*\`\`\`

%s block expr
%x tag attr trail

%%

//--------------------------------------------------------------------------------------------------
// common rules
// For any line, first non-blank char must be:
// TAG, `#`, `.`, `|`, `{`, `}`, `{{`, `}}`, `"`, `'` or "`".
//--------------------------------------------------------------------------------------------------

<<EOF>>                     return 'EOF';
\s+                         ;

{LINE_COMMENT}{EOL}         ;
{BLOCK_COMMENT}             ;

{NAME} {
        log(yytext);
        this.begin('tag');
        return 'NAME';
    }

'#' {
        log(yytext);
        this.begin('tag');
        return '#';
    }

'.' {
        log(yytext);
        this.begin('tag');
        return '.';
    }

'|'{SPACE}* {
        log('|');
        this.begin('trail');
        return '|';
    }

'{'+ {
        // After the `{` symnbol, begins "block mode".
        log(yytext);
        if (yyleng > 2) {
            throw new Error('unexpected symbol: ' + yytext);
        }
        ++depth;
        blocks.unshift(yyleng);
        if (yyleng === 1) {
            return '{';
        }
        this.begin('expr');
        return '{{';
    }

'}'{1,2} {
        var block;

        --depth;
        log(yytext);
        if (yyleng < blocks[0]) {
            throw new Error('unexpected symbol: ' + yytext);
        }

        block = blocks[0];
        if (yyleng !== block) {
            this.less(block);
        }
        blocks.shift();
        return block === 1 ? '}' : '}}';
    }

{DOUBLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

{SINGLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

{CODE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

. {
        log('unknown char="' + yytext + '"');
    }


//--------------------------------------------------------------------------------------------------
// TAG rules
// This state is a temporary state and should go back (pop) to original state, usually 'block'.
//--------------------------------------------------------------------------------------------------

<tag>{NAME} {
        log(yytext);
        return 'NAME';
    }

<tag>[.#] {
        return yytext;
    }

<tag>'(' {
        log('(');
        this.begin('attr');
        return '(';
    }

<tag>{BLANK}*'{'+ {
        var match = yytext.trim();
        log(match);
        if (match.length > 2) {
            throw new Error('unexpected symbol: ' + yytext);
        }
        this.popState();
        ++depth;
        blocks.unshift(match.length);
        if (match.length === 1) {
            return '{';
        }
        this.begin('expr');
        return '{{';
    }

<tag>{SPACE}*'|'{SPACE}* {
        log('|');
        this.popState();
        this.begin('trail');
        return '|';
    }

<tag>{SPACE}*'+'{SPACE}* {
        log('+');
        return '+';
    }

<tag>{DOUBLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

<tag>{SINGLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

<tag>{CODE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

<tag>{SPACE}+ {
        log('SPACE');
        return 'SPACE';
    }

<tag>{EOL} {
        log('EOL');
        this.popState();
        return 'EOL';
    }

//--------------------------------------------------------------------------------------------------
// attr rules
// This state is a temporary state and should go back (pop) to original state, i.e. 'tag'.
//--------------------------------------------------------------------------------------------------

<attr>{BLANK} {
    }

<attr>{NAME} {
        log(yytext);
        return 'NAME';
    }

<attr>'=' {
        log('=');
        return '=';
    }

<attr>[:!]'=' {
        log(':=');
        return ':=';
    }

<attr>{DOUBLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

<attr>{SINGLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

<attr>')' {
        log(')');
        this.popState();
        return ')';
    }

//--------------------------------------------------------------------------------------------------
// trail text rules
//--------------------------------------------------------------------------------------------------

<trail>{EOL} {
        log('EOL');
        this.popState();
        return 'EOL';
    }

<trail>[^\n\r]+ {
        log(yytext);
        return 'INNER_TEXT';
    }

/lex

%start markup

%%  /* language grammar */

markup
    : elements EOF
        { $$ = $1; log(JSON.stringify($$, null, '  ')); }
    ;

elements
    : elements element
        { $$ = $1.concat($2); }
    | element
        { $$ = [$1]; }
    ;

element
    : tag
    | expression
    ;

tag
    : tag_chain tag_block
        {
            var nodes = $1, node = nodes[0];
            $$ = node;
            for (var i = 0; i < nodes.length; ++i) {
                node.nodes = [nodes[i]];
                node = nodes[i];
            }
            node.nodes = $2;
        }
    | tag_chain '|' INNER_TEXT EOL
        {
            var nodes = $1, node = nodes[0];
            $$ = node;
            for (var i = 0; i < nodes.length; ++i) {
                node.nodes = [nodes[i]];
                node = nodes[i];
            }
            node.nodes = $3;
        }
    | tag_chain SPACE STRING_LITERAL EOL
        {
            var nodes = $1, node = nodes[0];
            $$ = node;
            for (var i = 0; i < nodes.length; ++i) {
                node.nodes = [nodes[i]];
                node = nodes[i];
            }
            node.nodes = $3;
        }
    | tag_chain EOL
    | '|' INNER_TEXT EOL
        { $$ = $2; }
    | STRING_LITERAL
    ;

tag_chain
    : tag_chain SPACE tag_siblings
        { $$ = $1.concat($3); }
    | tag_siblings
        { $$ = [$1]; }
    ;

tag_siblings
    : tag_siblings '+' tag_declaration
    | tag_declaration
    ;

tag_declaration
    : tag_name_shorthands tag_attributes
        {
            $1.attributes = Object.assign({}, $2, $1.attributes);
            $$ = $1;
        }
    | tag_name_shorthands
    ;

tag_name_shorthands
    : NAME id_attribute class_attributes
        { $$ = tag($1, Object.assign($2, $3)); }
    | NAME id_attribute
        { $$ = tag($1, $2); }
    | NAME class_attributes
        { $$ = tag($1, $2); }
    | NAME
        { $$ = tag($1); }
    | id_attribute class_attributes
        { $$ = tag('div', Object.assign($1, $2)); }
    | id_attribute
        { $$ = tag('div', $1); }
    | class_attributes
        { $$ = tag('div', $1); }
    ;

id_attribute
    : '#' NAME
        { $$ = { id: $2 }; }
    ;

class_attributes
    : class_attributes '.' NAME
        {
            $1.class.push($3);
            $$ = $1;
        }
    | '.' NAME
        {
            $$ = { class: [$2] };
        }
    ;

tag_attributes
    : '(' tag_attribute_chain ')'
        { $$ = $2; }
    | '[' tag_attribute_chain ']'
        { $$ = $2; }
    | '(' ')'
        { $$ = {}; }
    | '[' ']'
        { $$ = {}; }
    ;

tag_attribute_chain
    : tag_attribute_chain tag_attribute
        {
            $$ = Object.assign($2, $1);
        }
    | tag_attribute
    ;

tag_attribute
    : NAME '=' tag_attribute_value
        {
            $$ = {};
            $$[$1] = $3;
        }
    | NAME ':=' tag_attribute_value
        {
            $$ = {};
            $$[$1] = $3;
        }
    | NAME
        {
            $$ = {};
            $$[$1] = "''";
        }
    ;

tag_attribute_value
    : STRING_LITERAL
    | identifier
        { $$ = "'" + $1 + "'"; }
    ;

tag_block
    : '{' elements '}'
        { $$ = $2; }
    | '{' '}'
        { $$ = []; }
    ;

expression
    : '{{' expr '}}'
    | '{{' '}}'
    ;

expr
    : identifier
    ;
