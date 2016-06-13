
%{

var row = 1;
var col = 1;
var indent = [0];

function log(x) {
	console.log(x);
}

function tag(name) {
	return {
		type: 'Tag',
		name: name,
		nodes: []
	};
}

function _indent(lexer, lexeme) {
    var indentation = lexeme === 'EOF' ? 0 : lexeme.length - 1;

	++row;
    col += indentation;

    if (indentation > indent[0]) {
        indent.unshift(indentation);
        return 'INDENT';
    }

	if (true) {
		var tokens = [];
		while (indentation < indent[0]) {
			tokens.push('OUTDENT');
			indent.shift();
		}

		if (tokens.length) {
			if (lexeme === 'EOF') {
				return tokens.concat('EOF');
			}
			return tokens;
		}

		if (lexeme === 'EOF') {
			return 'EOF';
		}

		return;
	}

    if (indentation < indent[0]) {
        indent.shift();
		lexer.less(0);
		return 'OUTDENT';
    }

	if (lexeme === 'EOF') {
		return 'EOF';
	}
}

%}

/* lexical grammar */

%lex

BR                          \r\n|\n|\r

%%

<<EOF>>			log('EOF'); return _indent(this, 'EOF');
{BR}[ \t]*/.	log(yytext); return _indent(this, yytext);
{BR}			log(yytext); ++row; /* */

[_a-zA-Z]\w*	log(yytext); return 'IDENTIFIER';

/lex

%start markup

%%

markup
	: elements EOF
		{ $$ = $1; log(JSON.stringify($1, null, '    ')); }
	;

elements
	: elements element
		{ $$ = $1; $1.concat($2); }
	| element
		{ $$ = [$1]; }
	;

element
	: tag
	;

tag
	: IDENTIFIER block
		{ $$ = tag($1); $$.nodes = $2; }
	| IDENTIFIER
	;

block
	: INDENT elements OUTDENT
		{ $$ = $2; }
	| INDENT OUTDENT
		{ $$ = []; }
	;

line
	: IDENTIFIER
		{ $$ = tag($1); }
	;
