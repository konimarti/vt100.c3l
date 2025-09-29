module vt100;

import std::io;

enum States : const inline char
{
	STATE_NONE,
	STATE_CSI_ENTRY,
	STATE_CSI_IGNORE,
	STATE_CSI_INTERMEDIATE,
	STATE_CSI_PARAM,
	STATE_DCS_ENTRY,
	STATE_DCS_IGNORE,
	STATE_DCS_INTERMEDIATE,
	STATE_DCS_PARAM,
	STATE_DCS_PASSTHROUGH,
	STATE_ESCAPE,
	STATE_ESCAPE_INTERMEDIATE,
	STATE_GROUND,
	STATE_OSC_STRING,
	STATE_SOS_PM_APC_STRING,
}

enum Actions : const inline char
{
	ACTION_NONE,
	ACTION_CLEAR,
	ACTION_COLLECT,
	ACTION_CSI_DISPATCH,
	ACTION_ESC_DISPATCH,
	ACTION_EXECUTE,
	ACTION_HOOK,
	ACTION_IGNORE,
	ACTION_OSC_END,
	ACTION_OSC_PUT,
	ACTION_OSC_START,
	ACTION_PARAM,
	ACTION_PRINT,
	ACTION_PUT,
	ACTION_UNHOOK,
	ACTION_ERROR,
}

struct Transition
{
	States  state;
	Actions action;
}

Actions[States.len] entry_actions = {
   ACTION_NONE,
   ACTION_CLEAR,     /* CSI_ENTRY */
   ACTION_NONE,      /* none for CSI_IGNORE */
   ACTION_NONE,      /* none for CSI_INTERMEDIATE */
   ACTION_NONE,      /* none for CSI_PARAM */
   ACTION_CLEAR,     /* DCS_ENTRY */
   ACTION_NONE,      /* none for DCS_IGNORE */
   ACTION_NONE,      /* none for DCS_INTERMEDIATE */
   ACTION_NONE,      /* none for DCS_PARAM */
   ACTION_HOOK,      /* DCS_PASSTHROUGH */
   ACTION_CLEAR,     /* ESCAPE */
   ACTION_NONE,      /* none for ESCAPE_INTERMEDIATE */
   ACTION_NONE,      /* none for GROUND */
   ACTION_OSC_START, /* OSC_STRING */
   ACTION_NONE,      /* none for SOS_PM_APC_STRING */
};

Actions[States.len] exit_actions = {
   ACTION_NONE,
   ACTION_NONE,            /* none for CSI_ENTRY */
   ACTION_NONE,            /* none for CSI_IGNORE */
   ACTION_NONE,            /* none for CSI_INTERMEDIATE */
   ACTION_NONE,            /* none for CSI_PARAM */
   ACTION_NONE,            /* none for DCS_ENTRY */
   ACTION_NONE,            /* none for DCS_IGNORE */
   ACTION_NONE,            /* none for DCS_INTERMEDIATE */
   ACTION_NONE,            /* none for DCS_PARAM */
   ACTION_UNHOOK,          /* DCS_PASSTHROUGH */
   ACTION_NONE,            /* none for ESCAPE */
   ACTION_NONE,            /* none for ESCAPE_INTERMEDIATE */
   ACTION_NONE,            /* none for GROUND */
   ACTION_OSC_END,         /* OSC_STRING */
   ACTION_NONE,            /* none for SOS_PM_APC_STRING */
};

Transition[char.max][*] transition = {
	[States.STATE_CSI_ENTRY]           = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x20..0x2f] = { STATE_CSI_INTERMEDIATE, ACTION_COLLECT },
		[0x3a]       = { STATE_CSI_IGNORE, ACTION_NONE },
		[0x30..0x39] = { STATE_CSI_PARAM, ACTION_PARAM },
		[0x3b]       = { STATE_CSI_PARAM, ACTION_PARAM },
		[0x3c..0x3f] = { STATE_CSI_PARAM, ACTION_COLLECT },
		[0x40..0x7e] = { STATE_GROUND, ACTION_CSI_DISPATCH },
	},
	[States.STATE_CSI_IGNORE]          = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x20..0x3f] = { STATE_NONE, ACTION_IGNORE },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x40..0x7e] = { STATE_GROUND, ACTION_NONE },
	},
	[States.STATE_CSI_INTERMEDIATE]    = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x20..0x2f] = { STATE_NONE, ACTION_COLLECT },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x30..0x3f] = { STATE_CSI_IGNORE, ACTION_NONE },
		[0x40..0x7e] = { STATE_GROUND, ACTION_CSI_DISPATCH },
	},
	[States.STATE_CSI_PARAM]           = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x30..0x39] = { STATE_NONE, ACTION_PARAM },
		[0x3b]       = { STATE_NONE, ACTION_PARAM },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x3a]       = { STATE_CSI_IGNORE, ACTION_NONE },
		[0x3c..0x3f] = { STATE_CSI_IGNORE, ACTION_NONE },
		[0x20..0x2f] = { STATE_CSI_INTERMEDIATE, ACTION_COLLECT },
		[0x40..0x7e] = { STATE_GROUND, ACTION_CSI_DISPATCH },
	},
	[States.STATE_DCS_ENTRY]           = {
		[0x00..0x17] = { STATE_NONE, ACTION_IGNORE },
		[0x19]       = { STATE_NONE, ACTION_IGNORE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_IGNORE },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x3a]       = { STATE_DCS_IGNORE, ACTION_NONE },
		[0x20..0x2f] = { STATE_DCS_INTERMEDIATE, ACTION_COLLECT },
		[0x30..0x39] = { STATE_DCS_PARAM, ACTION_PARAM },
		[0x3b]       = { STATE_DCS_PARAM, ACTION_PARAM },
		[0x3c..0x3f] = { STATE_DCS_PARAM, ACTION_COLLECT },
		[0x40..0x7e] = { STATE_DCS_PASSTHROUGH, ACTION_NONE },
	},
	[States.STATE_DCS_IGNORE]          = {
		[0x00..0x17] = { STATE_NONE, ACTION_IGNORE },
		[0x19]       = { STATE_NONE, ACTION_IGNORE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_IGNORE },
		[0x20..0x7f] = { STATE_NONE, ACTION_IGNORE },
	},
	[States.STATE_DCS_INTERMEDIATE]    = {
		[0x00..0x17] = { STATE_NONE, ACTION_IGNORE },
		[0x19]       = { STATE_NONE, ACTION_IGNORE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_IGNORE },
		[0x20..0x2f] = { STATE_NONE, ACTION_COLLECT },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x30..0x3f] = { STATE_DCS_IGNORE, ACTION_NONE },
		[0x40..0x7e] = { STATE_DCS_PASSTHROUGH, ACTION_NONE },
	},
	[States.STATE_DCS_PARAM]           = {
		[0x00..0x17] = { STATE_NONE, ACTION_IGNORE },
		[0x19]       = { STATE_NONE, ACTION_IGNORE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_IGNORE },
		[0x30..0x39] = { STATE_NONE, ACTION_PARAM },
		[0x3b]       = { STATE_NONE, ACTION_PARAM },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x3a]       = { STATE_DCS_IGNORE, ACTION_NONE },
		[0x3c..0x3f] = { STATE_DCS_IGNORE, ACTION_NONE },
		[0x20..0x2f] = { STATE_DCS_INTERMEDIATE, ACTION_COLLECT },
		[0x40..0x7e] = { STATE_DCS_PASSTHROUGH, ACTION_NONE },
	},
	[States.STATE_DCS_PASSTHROUGH]     = {
		[0x00..0x17] = { STATE_NONE, ACTION_PUT },
		[0x19]       = { STATE_NONE, ACTION_PUT },
		[0x1c..0x1f] = { STATE_NONE, ACTION_PUT },
		[0x20..0x7e] = { STATE_NONE, ACTION_PUT },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
	},
	[States.STATE_ESCAPE]              = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x20..0x2f] = { STATE_ESCAPE_INTERMEDIATE, ACTION_COLLECT },
		[0x30..0x4f] = { STATE_GROUND, ACTION_ESC_DISPATCH },
		[0x51..0x57] = { STATE_GROUND, ACTION_ESC_DISPATCH },
		[0x59]       = { STATE_GROUND, ACTION_ESC_DISPATCH },
		[0x5a]       = { STATE_GROUND, ACTION_ESC_DISPATCH },
		[0x5c]       = { STATE_GROUND, ACTION_ESC_DISPATCH },
		[0x60..0x7e] = { STATE_GROUND, ACTION_ESC_DISPATCH },
		[0x5b]       = { STATE_CSI_ENTRY, ACTION_NONE },
		[0x5d]       = { STATE_OSC_STRING, ACTION_NONE },
		[0x50]       = { STATE_DCS_ENTRY, ACTION_NONE },
		[0x58]       = { STATE_SOS_PM_APC_STRING, ACTION_NONE },
		[0x5e]       = { STATE_SOS_PM_APC_STRING, ACTION_NONE },
		[0x5f]       = { STATE_SOS_PM_APC_STRING, ACTION_NONE },
	},
	[States.STATE_ESCAPE_INTERMEDIATE] = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x20..0x2f] = { STATE_NONE, ACTION_COLLECT },
		[0x7f]       = { STATE_NONE, ACTION_IGNORE },
		[0x30..0x7e] = { STATE_GROUND, ACTION_ESC_DISPATCH },
	},
	[States.STATE_GROUND]              = {
		[0x00..0x17] = { STATE_NONE, ACTION_EXECUTE },
		[0x19]       = { STATE_NONE, ACTION_EXECUTE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_EXECUTE },
		[0x20..0x7f] = { STATE_NONE, ACTION_PRINT },
	},
	[States.STATE_OSC_STRING]          = {
		[0x00..0x17] = { STATE_NONE, ACTION_IGNORE },
		[0x19]       = { STATE_NONE, ACTION_IGNORE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_IGNORE },
		[0x20..0x7f] = { STATE_NONE, ACTION_OSC_PUT },
	},
	[States.STATE_SOS_PM_APC_STRING]   = {
		[0x00..0x17] = { STATE_NONE, ACTION_IGNORE },
		[0x19]       = { STATE_NONE, ACTION_IGNORE },
		[0x1c..0x1f] = { STATE_NONE, ACTION_IGNORE },
		[0x20..0x7f] = { STATE_NONE, ACTION_IGNORE },
	},
};

// Handle transitions that apply to all states (except STATE_NONE)
fn void init_transitions() @init
{
	$for var $i = 1; $i < States.len; $i++:
		transition[$i][0x18]       = { STATE_GROUND, ACTION_EXECUTE };
		transition[$i][0x1a]       = { STATE_GROUND, ACTION_EXECUTE };
		transition[$i][0x80..0x8f] = { STATE_GROUND, ACTION_EXECUTE };
		transition[$i][0x91..0x97] = { STATE_GROUND, ACTION_EXECUTE };
		transition[$i][0x99]       = { STATE_GROUND, ACTION_EXECUTE };
		transition[$i][0x9a]       = { STATE_GROUND, ACTION_EXECUTE };
		transition[$i][0x9c]       = { STATE_GROUND, ACTION_NONE };
		transition[$i][0x1b]       = { STATE_ESCAPE, ACTION_NONE };
		transition[$i][0x98]       = { STATE_SOS_PM_APC_STRING, ACTION_NONE };
		transition[$i][0x9e]       = { STATE_SOS_PM_APC_STRING, ACTION_NONE };
		transition[$i][0x9f]       = { STATE_SOS_PM_APC_STRING, ACTION_NONE };
		transition[$i][0x90]       = { STATE_DCS_ENTRY, ACTION_NONE };
		transition[$i][0x9d]       = { STATE_OSC_STRING, ACTION_NONE };
		transition[$i][0x9b]       = { STATE_CSI_ENTRY, ACTION_NONE };
	$endfor
}

alias VTParserCallback = fn void(VTParser*, Actions, char);

const usz MAX_CHARS = 2;

struct VTParser
{
	States    	  state;
	VTParserCallback  cb;
	char[MAX_CHARS+1] chars;
	int               num_chars;
	bool              ignore_flagged;
	int[16]           params;
	int               num_params;
	void*             user_data;
}

<*
*>
fn void VTParser.init(&self, VTParserCallback cb, void* user_data = null)
{
	self.state = STATE_GROUND;
	self.num_chars = 0;
	self.num_params = 0;
	self.ignore_flagged = false;
	self.cb = cb;
	self.user_data = user_data;
}

fn void VTParser.parse(&self, InStream in)
{
	while (try ch = in.read_byte())
	{
		self.state_change(ch);
	}
}

fn void VTParser.state_change(&self, char ch) @private
{
	Transition trn = transition[self.state][ch];
	if (trn.state != STATE_NONE)
	{
		// exit action (from current state)
		self.action(exit_actions[self.state], 0);

		// state action
		self.action(trn.action, ch);

		// entry action
		self.action(entry_actions[trn.state], 0);

		// state change
		self.state = trn.state;
	}
	else
	{
		self.action(trn.action, ch);
	}
}

fn void VTParser.action(&self, Actions action, char ch) @private
{
	switch (action)
	{
		case ACTION_PRINT:
		case ACTION_EXECUTE:
		case ACTION_HOOK:
		case ACTION_PUT:
		case ACTION_OSC_START:
		case ACTION_OSC_PUT:
		case ACTION_OSC_END:
		case ACTION_UNHOOK:
		case ACTION_CSI_DISPATCH:
		case ACTION_ESC_DISPATCH:
			self.cb(self, action, ch);
		case ACTION_IGNORE:
			break;
		case ACTION_COLLECT:
			if (self.num_chars + 1 > MAX_CHARS)
			{
				self.ignore_flagged = true;
			}
			else
			{
				self.chars[self.num_chars++] = ch;
			}
		case ACTION_PARAM:
			if (ch == ';')
			{
				self.num_params++;
				if (self.num_params >= self.params.len)
				{
					self.cb(self, ACTION_ERROR, 0);
					return;
				}
				self.params[self.num_params - 1] = 0;
			}
			else
			{
				int current_param;
				if (self.num_params == 0)
				{
					self.num_params = 1;
					self.params[0] = 0;
				}
				current_param = self.num_params - 1;
				self.params[current_param] *= 10;
				self.params[current_param] += (ch - '0');
			}

		case ACTION_CLEAR:
			self.num_chars = 0;
			self.num_params = 0;
			self.ignore_flagged = false;
		default:
			self.cb(self, ACTION_ERROR, 0);
	}
}
