## VT100 Parser in C3

This project provides a robust, UTF-8 aware VT100 escape/control sequence
parser written in C3. It is built on the comprehensive state machine design
described in [DEC’s ANSI-compatible video terminal
parser](https://vt100.net/emu/dec_ansi_parser), mirroring the behavior of
classic DEC VT100/VT220/VT500 terminals while transparently handling UTF-8
encoded streams.

### Features

- **State-machine accurate:** Implements the complete, correct state diagram
from the DEC reference.

- **UTF-8 safe:** Correctly decodes UTF-8 sequences outside escape/control
handling, and decodes multi-byte characters as appropriate.

- **Full ANSI/DEC compatibility:** Covers all C0 controls, ESC sequences, CSI
(Control Sequence Introducer), OSC (Operating System Command), DCS (Device
Control String), and others.

- **Composability:** Designed for integration into terminal emulators, logging
tools, or any VT100-aware I/O pipeline.

**Note:** This parser is intended as a reusable library and does not perform
rendering or host-dependent output; it emits structured actions for downstream
handling. For full terminal emulation, connect the parser output to a stateful
terminal model and rendering loop.

### Example

```c3
import vt100;
import std::io;

fn void parser_callback(VTParser *parser, Actions action, Char32 c) => @pool()
{
	char[4] out;
	switch (action)
	{
		case ACTION_PRINT:
			if (c > 0x7F)
			{
				if (try len = conv::char32_to_utf8(c, out[..])) 
				{
					io::printf("%s", (String)out[:len]);
				}	
			}
			else
			{
				io::printf("%c", (char)c);
			}
		case ACTION_EXECUTE:
			io::printf('\n');
		default:
			break;
	}
}

fn void main() => @assert_leak(true)
{
	VTParser parser;
	parser.init(&parser_callback);
	parser.parse(io::stdin());
}
```


### References

- [DEC ANSI parser state machine](https://vt100.net/emu/dec_ansi_parser)
- [Parser implementation in c](https://github.com/haberman/vtparse)
- [ANSI X3.64-1979 specification (summary)](https://vt100.net/docs/vt100-ug/chapter3.html)


### License

MIT License
