library mustache_test;

import 'package:unittest/unittest.dart';
import 'package:mustache/mustache.dart';

const MISMATCHED_TAG = 'Mismatched tag';
const UNEXPECTED_EOF = 'Unexpected end of input';
const BAD_VALUE_SECTION = 'Invalid value type for section';
const BAD_VALUE_INV_SECTION = 'Invalid value type for inverse section';
const BAD_TAG_NAME = 'Unless in lenient mode, tags may only contain';
const VALUE_NULL = 'Value was null or missing';
const VALUE_MISSING = 'Value was missing';
const UNCLOSED_TAG = 'Unclosed tag';

Template parse(String source, {bool lenient: false})
  => new Template(source, lenient: lenient);

main() {
	group('Basic', () {
		test('Variable', () {
			var output = parse('_{{var}}_')
				.renderString({"var": "bob"});
			expect(output, equals('_bob_'));
		});
		test('Comment', () {
			var output = parse('_{{! i am a\n comment ! }}_').renderString({});
			expect(output, equals('__'));
		});
	});
	group('Section', () {
		test('Map', () {
			var output = parse('{{#section}}_{{var}}_{{/section}}')
				.renderString({"section": {"var": "bob"}});
			expect(output, equals('_bob_'));
		});
		test('List', () {
			var output = parse('{{#section}}_{{var}}_{{/section}}')
				.renderString({"section": [{"var": "bob"}, {"var": "jim"}]});
			expect(output, equals('_bob__jim_'));
		});
		test('Empty List', () {
			var output = parse('{{#section}}_{{var}}_{{/section}}')
				.renderString({"section": []});
			expect(output, equals(''));
		});
		test('False', () {
			var output = parse('{{#section}}_{{var}}_{{/section}}')
				.renderString({"section": false});
			expect(output, equals(''));
		});
		test('Invalid value', () {
			var ex = renderFail(
				'{{#section}}_{{var}}_{{/section}}',
				{"section": 42});
			expect(ex is TemplateException, isTrue);
			expect(ex.message, startsWith(BAD_VALUE_SECTION));
		});

		test('True', () {
			var output = parse('{{#section}}_ok_{{/section}}')
				.renderString({"section": true});
			expect(output, equals('_ok_'));
		});

		test('Nested', () {
			var output = parse('{{#section}}.{{var}}.{{#nested}}_{{nestedvar}}_{{/nested}}.{{/section}}')
				.renderString({"section": {
					"var": "bob",
					"nested": [
						{"nestedvar": "jim"},
						{"nestedvar": "sally"}
					]
				}});
			expect(output, equals('.bob._jim__sally_.'));
		});

    test('isNotEmpty', () {
      var t = new Template(
'''{{^ section }}
Empty.
{{/ section }}
{{# section.isNotEmpty }}
  <ul>
  {{# section }}
    <li>{{ . }}</li>
  {{/ section }}
  </ul>
{{/ section.isNotEmpty }}
''');
      expect(t.renderString({"section": [1, 2 ,3] }), equals(
'''  <ul>
    <li>1</li>
    <li>2</li>
    <li>3</li>
  </ul>
'''));
      expect(t.renderString({"section": [] }), equals('Empty.\n'));
    });
		
		test('Whitespace in section tags', () {
      expect(parse('{{#foo.bar}}oi{{/foo.bar}}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{# foo.bar}}oi{{/foo.bar}}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{#foo.bar }}oi{{/foo.bar}}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{# foo.bar }}oi{{/foo.bar}}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{#foo.bar}}oi{{/ foo.bar}}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{#foo.bar}}oi{{/foo.bar }}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{#foo.bar}}oi{{/ foo.bar }}').renderString({'foo': {'bar': true}}), equals('oi'));
      expect(parse('{{# foo.bar }}oi{{/ foo.bar }}').renderString({'foo': {'bar': true}}), equals('oi'));
		});
		
    test('Whitespace in variable tags', () {
      expect(parse('{{foo.bar}}').renderString({'foo': {'bar': true}}), equals('true'));
      expect(parse('{{ foo.bar}}').renderString({'foo': {'bar': true}}), equals('true'));
      expect(parse('{{foo.bar }}').renderString({'foo': {'bar': true}}), equals('true'));
      expect(parse('{{ foo.bar }}').renderString({'foo': {'bar': true}}), equals('true'));
    });
    
    
    
    test('Odd whitespace in tags', () {
      
      render(source, values, output) 
        => expect(parse(source, lenient: true)
            .renderString(values), equals(output));
      
      render(
        "{{\t# foo}}oi{{\n/foo}}",
        {'foo': true},
        'oi');
      
      render(
        "{{ # # foo }} {{ oi }} {{ / # foo }}",
        {'# foo': [{'oi': 'OI!'}]},
        ' OI! ');

      render(
        "{{ #foo }} {{ oi }} {{ /foo }}",
        {'foo': [{'oi': 'OI!'}]},
        ' OI! ');

      render(
        "{{\t#foo }} {{ oi }} {{ /foo }}",
        {'foo': [{'oi': 'OI!'}]},
        ' OI! ');

      render(
        "{{{ #foo }}} {{{ /foo }}}",
        {'#foo': 1, '/foo': 2},
        '1 2');

// Invalid - I'm ok with that for now.
//      render(
//        "{{{ { }}}",
//        {'{': 1},
//        '1');

      render(
        "{{\nfoo}}",
        {'foo': 'bar'},
        'bar');

      render(
        "{{\tfoo}}",
        {'foo': 'bar'},
        'bar');

      render(
        "{{\t# foo}}oi{{\n/foo}}",
        {'foo': true},
        'oi');

      render(
        "{{{\tfoo\t}}}",
        {'foo': true},
        'true');

//FIXME empty, or error in strict mode.
//      render(
//        "{{ > }}",
//        {'>': 'oi'},
//        '');      
    });
    
    test('Empty source', () {
      var t = new Template('');
      expect(t.renderString({}), equals(''));
    });
    
    test('Template name', () {
      var t = new Template('', name: 'foo');
      expect(t.name, equals('foo'));
    });
    
    test('Bad tag', () {
      expect(() => new Template('{{{ foo }|'), throwsException);
    });
    
	});

	group('Inverse Section', () {
		test('Map', () {
			var output = parse('{{^section}}_{{var}}_{{/section}}')
				.renderString({"section": {"var": "bob"}});
			expect(output, equals(''));
		});
		test('List', () {
			var output = parse('{{^section}}_{{var}}_{{/section}}')
				.renderString({"section": [{"var": "bob"}, {"var": "jim"}]});
			expect(output, equals(''));
		});
		test('Empty List', () {
			var output = parse('{{^section}}_ok_{{/section}}')
				.renderString({"section": []});
			expect(output, equals('_ok_'));
		});
		test('False', () {
			var output = parse('{{^section}}_ok_{{/section}}')
				.renderString({"section": false});
			expect(output, equals('_ok_'));
		});
		test('Invalid value', () {
			var ex = renderFail(
				'{{^section}}_{{var}}_{{/section}}',
				{"section": 42});
			expect(ex is TemplateException, isTrue);
			expect(ex.message, startsWith(BAD_VALUE_INV_SECTION));
		});
		test('True', () {
			var output = parse('{{^section}}_ok_{{/section}}')
				.renderString({"section": true});
			expect(output, equals(''));
		});
	});

	group('Html escape', () {

		test('Escape at start', () {
			var output = parse('_{{var}}_')
				.renderString({"var": "&."});
			expect(output, equals('_&amp;._'));
		});

		test('Escape at end', () {
			var output = parse('_{{var}}_')
				.renderString({"var": ".&"});
			expect(output, equals('_.&amp;_'));
		});

		test('&', () {
			var output = parse('_{{var}}_')
				.renderString({"var": "&"});
			expect(output, equals('_&amp;_'));
		});

		test('<', () {
			var output = parse('_{{var}}_')
				.renderString({"var": "<"});
			expect(output, equals('_&lt;_'));
		});

		test('>', () {
			var output = parse('_{{var}}_')
				.renderString({"var": ">"});
			expect(output, equals('_&gt;_'));
		});

		test('"', () {
			var output = parse('_{{var}}_')
				.renderString({"var": '"'});
			expect(output, equals('_&quot;_'));
		});

		test("'", () {
			var output = parse('_{{var}}_')
				.renderString({"var": "'"});
			expect(output, equals('_&#x27;_'));
		});

		test("/", () {
			var output = parse('_{{var}}_')
				.renderString({"var": "/"});
			expect(output, equals('_&#x2F;_'));
		});

	});

	group('Invalid format', () {
		test('Mismatched tag', () {
			var source = '{{#section}}_{{var}}_{{/notsection}}';
			var ex = renderFail(source, {"section": {"var": "bob"}});			
			expectFail(ex, 1, 22, 'Mismatched tag');
		});

		test('Unexpected EOF', () {
			var source = '{{#section}}_{{var}}_{{/section';
			var ex = renderFail(source, {"section": {"var": "bob"}});
			expectFail(ex, 1, 31, UNEXPECTED_EOF);
		});

		test('Bad tag name, open section', () {
			var source = r'{{#section$%$^%}}_{{var}}_{{/section}}';
			var ex = renderFail(source, {"section": {"var": "bob"}});
			expectFail(ex, null, null, BAD_TAG_NAME);
		});

		test('Bad tag name, close section', () {
			var source = r'{{#section}}_{{var}}_{{/section$%$^%}}';
			var ex = renderFail(source, {"section": {"var": "bob"}});
			expectFail(ex, null, null, BAD_TAG_NAME);
		});

		test('Bad tag name, variable', () {
			var source = r'{{#section}}_{{var$%$^%}}_{{/section}}';
			var ex = renderFail(source, {"section": {"var": "bob"}});
			expectFail(ex, null, null, BAD_TAG_NAME);
		});

		test('Missing variable', () {
      var source = r'{{#section}}_{{var}}_{{/section}}';
      var ex = renderFail(source, {"section": {}});
      expectFail(ex, null, null, VALUE_MISSING);
		});
		
		// Null variables shouldn't be a problem.
    test('Null variable', () {
      var t = new Template('{{#section}}_{{var}}_{{/section}}');
      var output = t.renderString({"section": {'var': null}});
      expect(output, equals('__'));
    });
    
    test('Unclosed section', () {
      var source = r'{{#section}}foo';
      var ex = renderFail(source, {"section": {}});
      expectFail(ex, null, null, UNCLOSED_TAG);
    });
   
	});

	group('Lenient', () {
		test('Odd section name', () {
			var output = parse(r'{{#section$%$^%}}_{{var}}_{{/section$%$^%}}', lenient: true)
				.renderString({r'section$%$^%': {'var': 'bob'}});
			expect(output, equals('_bob_'));
		});

		test('Odd variable name', () {
			var output = parse(r'{{#section}}_{{var$%$^%}}_{{/section}}', lenient: true)
				.renderString({'section': {r'var$%$^%': 'bob'}});
		});

		test('Null variable', () {
			var output = parse(r'{{#section}}_{{var}}_{{/section}}', lenient: true)
				.renderString({'section': {'var': null}});
			expect(output, equals('__'));
		});

		test('Null section', () {
			var output = parse('{{#section}}_{{var}}_{{/section}}', lenient: true)
				.renderString({"section": null});
			expect(output, equals(''));
		});

// Known failure
//		test('Null inverse section', () {
//			var output = parse('{{^section}}_{{var}}_{{/section}}', lenient: true)
//				.renderString({"section": null}, lenient: true);
//			expect(output, equals(''));
//		});

	});

	group('Escape tags', () {
		test('{{{ ... }}}', () {
			var output = parse('{{{blah}}}')
				.renderString({'blah': '&'});
			expect(output, equals('&'));
		});
		test('{{& ... }}', () {
			var output = parse('{{{blah}}}')
				.renderString({'blah': '&'});
			expect(output, equals('&'));
		});
	});

	group('Partial tag', () {

	  String _partialTest(Map values, Map sources, String renderTemplate, {bool lenient: false}) {
	    var templates = new Map<String, Template>();
	    var resolver = (name) => templates[name];
	    for (var k in sources.keys) {
	      templates[k] = new Template(sources[k],
	          name: k, lenient: lenient, partialResolver: resolver);
	    }
	    var t = resolver(renderTemplate);
	    return t.renderString(values);
	  }
	  
    test('basic', () {
      var output = _partialTest(
          {'foo': 'bar'},
          {'root': '{{>partial}}', 'partial': '{{foo}}'},
          'root');
      expect(output, 'bar');
    });

    test('missing partial strict', () {
      var threw = false;
      try {
        _partialTest(
          {'foo': 'bar'},
          {'root': '{{>partial}}'},
          'root',
          lenient: false);  
      } catch (e) {
        expect(e is TemplateException, isTrue);
        threw = true;
      }
      expect(threw, isTrue);
    });   

    test('missing partial lenient', () {
      var output = _partialTest(
          {'foo': 'bar'},
          {'root': '{{>partial}}'},
          'root',
          lenient: true);
      expect(output, equals(''));
    });

    test('context', () {
      var output = _partialTest(
          {'text': 'content'},
          {'root': '"{{>partial}}"',
            'partial': '*{{text}}*'},
          'root',
          lenient: true);
      expect(output, equals('"*content*"'));
    });

    test('recursion', () {
      var output = _partialTest(
          { 'content': "X", 'nodes': [ { 'content': "Y", 'nodes': [] } ] },
          {'root': '{{>node}}',
            'node': '{{content}}<{{#nodes}}{{>node}}{{/nodes}}>'},
          'root',
          lenient: true);
      expect(output, equals('X<Y<>>'));
    });


    test('standalone without previous', () {
      var output = _partialTest(
          { },
          {'root':     '  {{>partial}}\n>',
            'partial': '>\n>'},
          'root',
          lenient: true);
      expect(output, equals('  >\n  >>'));
    });

    
    test('standalone indentation', () {
      var output = _partialTest(
          { 'content': "<\n->" },
          {'root':     "\\\n {{>partial}}\n\/\n",
            'partial': "|\n{{{content}}}\n|\n"},
          'root',
          lenient: true);
      expect(output, equals("\\\n |\n <\n->\n |\n\/\n"));
    });
    
	});

  group('Lambdas', () {
    
    _lambdaTest({template, lambda, output}) =>
        expect(parse(template).renderString({'lambda': lambda}), equals(output));
    
    test('basic', () {
      _lambdaTest(
          template: 'Hello, {{lambda}}!',
          lambda: (_) => 'world',
          output: 'Hello, world!');
    });

    test('escaping', () {
      _lambdaTest(
          template: '<{{lambda}}{{{lambda}}}',
          lambda: (_) => '>',
          output: '<&gt;>');
    });

    test('sections', () {
      _lambdaTest(
          template: '{{#lambda}}FILE{{/lambda}} != {{#lambda}}LINE{{/lambda}}',
          lambda: (LambdaContext ctx) => '__${ctx.renderString()}__',
          output: '__FILE__ != __LINE__');
    });

    //FIXME
    skip_test('inverted sections truthy', () {
      var template = '<{{^lambda}}{{static}}{{/lambda}}>';
      var values = {'lambda': (_) => false, 'static': 'static'};
      var output = '<>';
      expect(parse(template).renderString(values), equals(output));
    });
  
    test("seth's use case", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (ctx) => ctx.renderString().toLowerCase(), 'content': 'OI YOU!'};
      var output = '<oi you!>';
      expect(parse(template).renderString(values), equals(output));      
    });

    
    test("Lambda v2", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (ctx) => ctx.source, 'content': 'OI YOU!'};
      var output = '<{{content}}>';
      expect(parse(template).renderString(values), equals(output));      
    });
    
    
    test("Lambda v2...", () {
      var template = '<{{#markdown}}dsfsf dsfsdf dfsdfsd{{/markdown}}>';
      var values = {'markdown': (ctx) => ctx.source};
      var output = '<dsfsf dsfsdf dfsdfsd>';
      expect(parse(template).renderString(values), equals(output));      
    });

    test('Alternate Delimiters', () {

      // A lambda's return value should parse with the default delimiters.
      
      var template = '{{= | | =}}\nHello, (|&lambda|)!';
      
      //function() { return "|planet| => {{planet}}" }
      var values = {'planet': 'world',
                    'lambda': (LambdaContext ctx) => ctx.renderSource(
                        '|planet| => {{planet}}') };
      
      var output = 'Hello, (|planet| => world)!';
      
      expect(parse(template).renderString(values), equals(output));
    });

    test('Alternate Delimiters 2', () {

      // Lambdas used for sections should parse with the current delimiters.
      
      var template = '{{= | | =}}<|#lambda|-|/lambda|>';
      
      //function() { return "|planet| => {{planet}}" }
      var values = {'planet': 'Earth',
                    'lambda': (LambdaContext ctx) {
                      var txt = ctx.source;
                      return ctx.renderSource('$txt{{planet}} => |planet|$txt');
                     }
      };
      
      var output = '<-{{planet}} => Earth->';
      
      expect(parse(template).renderString(values), equals(output));
    });
    
    test('LambdaContext.lookup', () {
      var t = new Template('{{ foo }}');
      var s = t.renderString({'foo': (lc) => lc.lookup('bar'), 'bar': 'jim'});
      expect(s, equals('jim'));
    });

    test('LambdaContext.lookup closed', () {
      var t = new Template('{{ foo }}');
      var lc2;
      var s = t.renderString({'foo': (lc) => lc2 = lc, 'bar': 'jim'});      
      expect(() => lc2.lookup('foo'), throwsException);
    });
    
  });
	
	group('Other', () {
		test('Standalone line', () {
			var val = parse('|\n{{#bob}}\n{{/bob}}\n|').renderString({'bob': []});
			expect(val, equals('|\n|'));
		});
	});

	group('Array indexing', () {
		test('Basic', () {
			var val = parse('{{array.1}}').renderString({'array': [1, 2, 3]});
			expect(val, equals('2'));
		});
		test('RangeError', () {
			var error = renderFail('{{array.5}}', {'array': [1, 2, 3]});
			expect(error, isRangeError);
		});
	});

	group('Mirrors', () {
    test('Simple field', () {
      var output = parse('_{{bar}}_')
        .renderString(new Foo()..bar = 'bob');
      expect(output, equals('_bob_'));
    });

    test('Simple field', () {
      var output = parse('_{{jim}}_')
        .renderString(new Foo());
      expect(output, equals('_bob_'));
    });
    
    test('Lambda', () {
      var output = parse('_{{lambda}}_')
        .renderString(new Foo()..lambda = (_) => 'yo');
      expect(output, equals('_yo_'));
    });
  });

  group('Delimiters', () {
    test('Basic', () {
      var val = parse('{{=<% %>=}}(<%text%>)')
          .renderString({'text': 'Hey!'});
      expect(val, equals('(Hey!)'));
    });

    test('Single delimiters', () {
      var val = parse('({{=[ ]=}}[text])')
          .renderString({'text': 'It worked!'});
      expect(val, equals('(It worked!)'));
    });
  });
  
  group('Lambda context', () {
    
    test("LambdaContext write", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (ctx) {
        ctx.write('foo');
      }};
      var output = '<foo>';
      expect(parse(template).renderString(values), equals(output));      
    });

    test("LambdaContext render", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'content': 'bar', 'markdown': (ctx) {
        ctx.render();
      }};
      var output = '<bar>';
      expect(parse(template).renderString(values), equals(output));      
    });

    test("LambdaContext render with value", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (LambdaContext ctx) {
        ctx.render(value: {'content': 'oi!'});
      }};
      var output = '<oi!>';
      expect(parse(template).renderString(values), equals(output));      
    });

    test("LambdaContext renderString with value", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (LambdaContext ctx) {
        return ctx.renderString(value: {'content': 'oi!'});
      }};
      var output = '<oi!>';
      expect(parse(template).renderString(values), equals(output));      
    });

    test("LambdaContext write and return", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (LambdaContext ctx) {
        ctx.write('foo');
        return 'bar';
      }};
      var output = '<foobar>';
      expect(parse(template).renderString(values), equals(output));      
    });

    test("LambdaContext renderSource with value", () {
      var template = '<{{#markdown}}{{content}}{{/markdown}}>';
      var values = {'markdown': (LambdaContext ctx) {
        return ctx.renderSource(ctx.source, value: {'content': 'oi!'});
      }};
      var output = '<oi!>';
      expect(parse(template).renderString(values), equals(output));      
    });
    
  });
}

renderFail(source, values) {
	try {
		parse(source).renderString(values);
		return null;
	} catch (e) {
		return e;
	}
}

expectFail(ex, int line, int column, [String msgStartsWith]) {
		expect(ex is TemplateException, isTrue);
		if (line != null)
			expect(ex.line, equals(line));
		if (column != null)
			expect(ex.column, equals(column));
		if (msgStartsWith != null)
			expect(ex.message, startsWith(msgStartsWith));
}

class Foo {
  String bar;
  Function lambda;
  jim() => 'bob';
}
