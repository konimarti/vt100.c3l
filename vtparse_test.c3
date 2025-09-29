module vt100_test;

import vt100;
import std::io;

fn void parser_callback(VTParser *parser, Actions action, Char32 c)
{
	DString *buf = (DString*)parser.user_data;
	switch (action)
	{
		case ACTION_PRINT: buf.append_char32(c);
		default:           break;
	}
}

struct TestCase
{
	String input;
	String want;
}

fn void test_parser() @test => @pool()
{
	TestCase[] tests = {
		{
			"AB\x00\x1B[;fCDE",
			"ABCDE",
		},
		{
			"A😀B\x00\x1B[;fCDE",
			"A😀BCDE",
		},
	};

	DString buf = dstring::temp();
	VTParser parser;

	foreach (tc : tests)
	{
		parser.init(&parser_callback, &buf);
		parser.parse(&&io::wrap_bytes(tc.input[..]));
		test::eq(tc.want, buf.str_view());
		buf.clear();
	}
}
