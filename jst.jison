%{

var DEBUG = true;
var INDENTS = '    ';

var row = 0;
var col = 0;
var depth = 0;


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
BR                          \r\n|\n|\r
SPACE                       [ \t]
BLANK                       \s+
LINE_COMMENT                '//'.*
BLOCK_COMMENT               '/*'((\*+[^/*])|([^*]))*\**'*/'
DOUBLE_QUOTE_TEXT           \"(?:\\\"|[^"])*\"
SINGLE_QUOTE_TEXT           \'(?:\\\'|[^'])*\'

%s block
%x tag attr trail

%%

//-----------------
// common rules
//-----------------

<<EOF>>                     return 'EOF';
\s+                         ;

{LINE_COMMENT}{BR}          ;
{BLOCK_COMMENT}             ;

{NAME} {
        log(yytext);
        this.begin('tag');
        return 'TAG_NAME';
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

'{' {
        log('{');
        ++depth;
        this.begin('block');
        return '{';
    }

'}' {
        --depth;
        log(yytext);
        return '}';
    }

{DOUBLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

{SINGLE_QUOTE_TEXT} {
        log(yytext);
        return 'STRING_LITERAL';
    }

. {
        log('unknown char="' + yytext + '"');
    }

//-----------------
// tag rules
//-----------------

<tag>{NAME} {
        log(yytext);
        return 'ATTR_NAME';
    }

<tag>[.#] {
        return yytext;
    }

<tag>'(' {
        log('(');
        this.begin('attr');
        return '(';
    }

<tag>{SPACE}*'{'+ {
        log('{');
        ++depth;
        this.begin('block');
        return '{';
    }

<tag>{SPACE}*'|'{SPACE}* {
        log('|');
        this.begin('trail');
        return '|';
    }

<tag>{SPACE}+ {
        log('SPACE');
        this.popState();
        return 'SPACE';
    }

<tag>{BR} {
        log('BR');
        this.popState();
        return 'EOL';
    }

//-----------------
// attr rules
//-----------------

<attr>{BLANK} {
    }

<attr>{NAME} {
        return 'ATTR_NAME';
    }

<attr>'=' {
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

<attr>')'{SPACE}*'|'?{SPACE}* {
        log(')');
        this.begin('trail');
        return ')';
    }

//-----------------
// trail text rules
//-----------------

<trail>{BR} {
        log('BR');
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
    : tag_chain block
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
    | tag_chain SPACE STRING_LITERAL
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
    |  '|' INNER_TEXT EOL
        { $$ = $2; }
    | STRING_LITERAL
    ;

tag_chain
    : tag_chain SPACE tag_declaration
        { $$ = $1.concat($3); }
    | tag_declaration
        { $$ = [$1]; }
    ;

tag_declaration
    : tag_shorthands tag_attributes
        {
            $1.attributes = Object.assign({}, $2, $1.attributes);
            $$ = $1;
        }
    | tag_shorthands
    ;

tag_shorthands
    : TAG_NAME id_attribute class_attributes
        { $$ = tag($1, Object.assign($2, $3)); }
    | TAG_NAME id_attribute
        { $$ = tag($1, $2); }
    | TAG_NAME class_attributes
        { $$ = tag($1, $2); }
    | TAG_NAME
        { $$ = tag($1); }
    | id_attribute class_attributes
        { $$ = tag('div', Object.assign($1, $2)); }
    | id_attribute
        { $$ = tag('div', $1); }
    | class_attributes
        { $$ = tag('div', $1); }
    ;

id_attribute
    : '#' ATTR_NAME
        { $$ = { id: $2 }; }
    ;

class_attributes
    : class_attributes '.' ATTR_NAME
        {
            $1.class.push($3);
            $$ = $1;
        }
    | '.' ATTR_NAME
        {
            $$ = { class: [$2] };
        }
    ;

tag_attributes
    : '(' attributes ')'
        { $$ = $2; }
    | '[' attributes ']'
        { $$ = $2; }
    | '(' ')'
        { $$ = {}; }
    | '[' ']'
        { $$ = {}; }
    ;

attributes
    : attributes attribute
        {
            $$ = Object.assign($2, $1);
        }
    | attribute
    ;

attribute
    : ATTR_NAME '=' attribute_value
        {
            $$ = {};
            $$[$1] = $3;
        }
    | ATTR_NAME ':=' attribute_value
        {
            $$ = {};
            $$[$1] = $3;
        }
    | ATTR_NAME
        {
            $$ = {};
            $$[$1] = "''";
        }
    ;

attribute_value
    : STRING_LITERAL
    | identifier
        { $$ = "'" + $1 + "'"; }
    ;

block
    : block_open elements block_close
        { $$ = $2; }
    | block_open block_close
        { $$ = []; }
    | STRING_LITERAL
        {
            $$ = [{
                type: 'Text',
                text: $1
            }];
        }
    ;

block_open
    : '{'
    ;

block_close
    : '}'
    ;

expression
    : '{{' expr '}}'
    | '{{' '}}'
    ;

expr
    : identifier
    ;
