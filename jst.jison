
%{

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

%%
'//'.*                          /* skip line comment */
'/*'((\*+[^/*])|([^*]))*\**'*/' /* skip block comment */
\s+                             /* skip space */
'{{'(?!\{)                      return '{{';
'}}'(?!\})                      return '}}';
'{'                             return '{';
'}'                             return '}';
'('                             return '(';
')'                             return ')';
'#'                             return '#';
'.'                             return '.';
'='                             return '=';
\w[-\w]*                        return 'identifier';
\'(?:\\\'|[^'])*\'              return 'STRING_LITERAL';
\"(?:\\\"|[^"])*\"              return 'STRING_LITERAL';
<<EOF>>                         return 'EOF';

/lex

%start markups

%%  /* language grammar */

markups
    : elements EOF
        { $$ = $1; console.log(JSON.stringify($$, null, '  ')); }
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
    : tag_name tag_attributes block
        {
            $1.attributes = Object.assign({}, $2, $1.attributes);
            $1.nodes = $3;
            $$ = $1;
        }
    | tag_name tag_attributes
        {
            $1.attributes = Object.assign({}, $2, $1.attributes);
            $1.nodes = $2;
            $$ = $1;
        }
    | tag_name block
        {
            $1.nodes = $2;
            $$ = $1;
        }
    ;

tag_name
    : identifier
        { $$ = tag($1); }
    | identifier id_attribute
        { $$ = tag($1, $2); }
    | identifier id_attribute class_attributes
        { $$ = tag($1, Object.assign($2, $3)); }
    | identifier class_attributes
        { $$ = tag($1, $2); }
    | id_attribute
        { $$ = tag('div', $1); }
    | id_attribute class_attributes
        { $$ = tag('div', Object.assign($1, $2)); }
    | class_attributes
        { $$ = tag('div', $1); }
    ;

id_attribute
    : '#' identifier
        { $$ = { id: $2 }; }
    ;

class_attributes
    : class_attributes '.' identifier
        {
            $1.class.push($3);
            $$ = $1;
        }
    | '.' identifier
        {
            $$ = { class: [$2] };
        }
    ;

tag_attributes
    : '(' attributes ')'
        { $$ = $2; }
    | '(' ')'
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
    : identifier '=' attribute_value
        {
            $$ = {};
            $$[$1] = $2;
        }
    | identifier
        {
            $$ = {};
            $$[$1] = '';
        }
    ;

attribute_value
    : identifier
    | STRING_LITERAL
    ;

block
    : block_open elements block_close
        { $$ = $2; }
    | block_open block_close
        { $$ = []; }
    | expression
        {
            $$ = {
                type: 'Expression',
                nodes: $1
            };
        }
    | STRING_LITERAL
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
