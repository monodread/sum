// ============================================================
// copied for SUMv03 from SimpleMessageSystem interface

SerialSUM : SerialDevice
{

	*parserClass {
		^SerialParserSUM
	}
	// this method to communicate to SerialPort
	send { | ... args |
		var lastIndex = args.lastIndex;
		args.do { |obj,i|
			port.putAll(obj.asString);
			if (i !== lastIndex) {
				port.put(Char.space)
			};
		};
		port.put(13);
	}
	read {
		// TO DO?
	}
}

SerialParserSUM : SerialParser
{
	var msg, msgArgStream, state, string;

	parse {
		msg = Array[];
		msgArgStream = CollStream();
		state = nil;
		string="";
		\parsing_started.postln;
		loop { this.parseByte(port.read) };
	}

	finishArg {
		var msgArg = msgArgStream.contents; msgArgStream.reset;
		if (msgArg.notEmpty) {
			/*if (msgArg.first.isDecDigit) {
				msgArg = msgArg.asInteger;
				"msg is a digit: % \n".postf(msgArg);
			};
			msg = msg.add(msgArg);
			*/
			msg = string ++ msgArg;
			//string.class.postln;
		} {\empty_msg.postln;}
	}
	convertString {
		msg = msg.split($ ).asInteger;
	}
	parseByte { | byte |
		var char = byte.asAscii; // MOD
		state = 13;
		if (byte === 13) {	// wait for LF, never happens in SUM PSoc, so ignore this
			state = 13;
		} {
			if (byte === 10) {
				// if CR was encountered, dispatch message
				if (state === 13) {
					this.finishArg;
					if (msg.notEmpty) {
						this.convertString;
						this.dispatch(msg);
						msg = Array[];
					};
					state = nil;
				}
			}
			// else
			{
				if (byte.isNil.not)
				{
					msgArgStream << byte.asAscii;
				}

				/*
				if (byte === 32) {
				// eat them spaces
				state = 32;
				} {
				if (state == 32) {
				// finish last arg?
				this.finishArg;
				this.convertString;
				state = nil;
				};
				if (byte.isNil.not)
				{
				msgArgStream << byte.asAscii;
				}
				}
				*/
			}

		}
	}
}

// EOF
// our stuff
/*
{
		while({
			char=b.read; // b.next is non-blocking read
			char.isNil
		}, { 0.01.wait });

		char = char.asAscii;
		(char != 10.asAscii).if({
			raw = raw ++ char;
		}, {
			tmpArr = raw.split($ ).asInteger;
			// handle the data
			tmpArr.postln;

			raw = "";
		});
	}
*/