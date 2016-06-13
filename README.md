JST - Template for JavaScript - Proposal of Jade like template engine (v0.3)

with:

1. Easily identifiable block with brackets,
2. Easily identifiable JavaScript expressions with AngularJS 2 expression syntax,
3. Easily switch between template and JavaScript expression, and
4. Build in ES2015 support.

### Processing Phases

The processing of jst has three phases:

1. Expansion phase

The `{{` `}}` block will be transpiled to a function, so variables are local.
And then the function will be executed immediately, emitting new parts of jst.

2. Parsing phase

The whole jst then parsed to AST.

3. Generating phase

Generator generates HTML from the AST.

### Sample

Here is a simple example, see document source [index.jst] for full examples.

```
doctype(html)

html {
	head {
		// switch to JavaScript expression mode with {{expr}} syntax.
		// the JavaScript expression also called "jst script".
		// the jst script can be processed by plugins, e.g. babel.
		{{
			global.href = '//github.com/amobiz/jst';
			global.title = 'Template for JavaScript - Proposal of Jade like template engine (v3)';
		}}

		/*
		the above code then being transipled to an IIFE, so variables are local:

		(function (global) {
			global.href = '//github.com/amobiz/jst';
			global.title = 'Template for JavaScript - Proposal of Jade like template engine (v3)';
		})(context.global);
		*/

		// inline scripts can be processed using plugins, e.g. babel.
		script {
			var href = {{ global.href }};
			var title = {{ global.title }};

			function onclick(e) {
			}
		}

		// use variable defined in the above jst script section.
		// in template, use JavaScript expressions / variables with {{ expr }} syntax
		title {{ global.title }}
		// put attributes in () parenthesis, omit () parenthesis when no attributes
		link(href=styles.css rel=stylesheet)
		style(href=styles.css)	// short hand for above
		icon(href=favicon.ico)	// same as: link(href=favicon.ico rel=icon)

		// external script
		script(src=main.js)
	}
	body {
		// directives starts with '@' character.
		// unless there is blank space characters, '' or "" can be omitted.
		@import header.jst

		header {
			h1 {
				a(href={{ global.href }} target=_blank) {{ global.title }}
			}
		}

		// add id with '#' character; add class with '.' character;
		section.header {{ global.title }}

		{{
			var user = {
				name: 'guest',
				description: 'foo bar baz',
				nested: {
					key: {
				}}	// this should also work without problem.
			};
			var items = [{
				name: 'apple',
				item: 3
			}, {
				name: 'orange',
				item: 5
			}];

			var styles = {
				color: '#333'
			};

			{{
				section#content.container(style={{ styles }}) {
					h2 {{ user.name }}
					p {{ user.description }}

					// skip template {} bracket if the only inner item is JavaScript expression.
					// you can think of `{{}}` as a way to switch between template and JavaScript expression.
					ul {{	// switch to js expression.
						for (name, item in items) {{	// switch to template expression.
							// AngularJS 2.0 like event handler.
							li(id={{ name }} class={{ item.active ? 'active' : '' }} (click)={{ onclick }}) {
								{{ name }}: {{ item }}
							}
						}}
					}}
				}
			}}
		}}

		@import footer.html
	}
}
```
