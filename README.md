JST - Template for JavaScript - Proposal of Jade like template engine

with:

1. Easy identifyable block with parentheses
2. Easy identifyable JavaScript expressions
3. ES2005 JavaScript expressions
4. AngularJS 2 expression syntax compatiable

```
doctype(html) {
	html {
		head {
			title {

			}
			link(href=styles.css rel=stylesheet)
			style(href=styles.css)	// short hand for above
			icon(href=favicon.ico)	// same as: link(href=favicon.ico rel=icon)

			script(src=main.js)
			script {

			}
	    }
	    body {
			// Directives and JavaScript expressions starts with '@' char.
			@import base.html	// unless there is blank space chars, '' or "" can be omitted.

	    	header {
	    		h1 {
	    			a(href={{href}} target=_blank) {{title}}
	    		}
	    	}
	    	
			// add id with '#' char; add class with '.' char; put other attributes in () parentheses, omit () parentheses when no attributes
			section.header() {{title}}	// refer variables in template with {{var}} syntax
				
			// JavaScript expressions can span multiple lines
			@var user = { 
				description: 'foo bar baz' 
			}
			@var items = [{
				name: 'apple',
				item: 3
			}, {	
				name: 'orange',
				item: 5
			}]

			// put inner html template in {} parentheses
			section#content() {
			    p.user {{user.description}}

				ul {
					@for (name, item in items) {
						li(id={{name}} (click)='onclick()') {
							{{name}}: {{item}}
						}
					}
				}
				div {

				}
			}
	    }
	}
}
```
