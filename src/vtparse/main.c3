module vtparse;

import vt100;
import std::io;

fn void parser_callback(VTParser *parser, Actions action, Char32 c) => @pool()
{
	DString buf = dstring::temp();
	buf.appendf("Received action: %s\n", Actions.names[action]);
	buf.appendf("Char: 0x%04x ('", c);
	buf.append_char32(c);
	buf.append_chars("')\n");
	if (parser.num_chars)
	{
		buf.appendf("%d Intermediate chars:\n", parser.num_chars);
		for (usz i = 0; i < parser.num_chars; i++)
		{
			char ch = parser.chars[i];
			buf.appendf("  0x%02x ('%c')\n", ch, ch);
		}
	}
	if (parser.num_params)
	{
		buf.appendf("%d Parameters:\n", parser.num_params);
		for (usz i = 0; i < parser.num_params; i++)
		{
			buf.appendf("  %d\n", parser.params[i]);
		}
	}
	buf.append_char('\n');

	io::print(buf.str_view());
}

fn void main() => @assert_leak(true)
{
	VTParser parser;
	parser.init(&parser_callback);
	parser.parse(io::stdin());
}
