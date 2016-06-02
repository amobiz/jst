JST - Template for JavaScript - Proposal of Jade like template engine (v0.2)

with:

1. Easily identifiable block with brackets,
2. Easily identifiable JavaScript expressions with AngularJS 2 expression syntax,
3. Easily switch between template and JavaScript expression, and
4. Build in ES2015 support.

Version 0.2:
```
doctype(html)

// put inner template in {} brackets.
// if you prefer, you can still omit brackets and just use indent instead.
html {
	head {
		// inline script: variables defined here are also available in the template.
		// can be processed using plugins, e.g. babel.
		script {
			var href = '//github.com/amobiz/jst';
			var title = 'Template for JavaScript - Proposal of Jade like template engine (v2)';

			function onclick(e) {
			}
		}

		// use variable defined in above script section.
		// in template, use JavaScript expressions / variables with {{expr}} syntax
		title {{title}}
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
				a(href={{href}} target=_blank) {{title}}
			}
		}

		// add id with '#' character; add class with '.' character;
		section.header {{title}}

		// switch to JavaScript expression with {{expr}} syntax.
		// this can be processed using plugins, e.g. babel.
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
		}}

		section#content.container(style={{styles}}) {
			h2 {{user.name}}
			p {{user.description}}

			// skip template {} bracket if the only inner item is JavaScript expression.
			// you can think of `{{}}` as a way to switch between template and JavaScript expression.
			ul {{	// switch to js expression.
				for (name, item in items) {{	// switch to template expression.
					// AngularJS 2.0 like event handler.
					li(id={{name}} class={{item.active ? 'active' : ''}} (click)={{onclick}}) {
						{{name}}: {{item}}
					}
				}}
			}}
		}

		@import footer.html
	}
}
```
