// =====================================================================
// copied from SimpleMessageSystem interface

SerialSMS : SerialDevice
{

	*parserClass {
		^SerialParserSMS
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

	}
}

SerialParserSMS : SerialParser
{
	var msg, msgArgStream, state;

	parse {
		msg = Array[];
		msgArgStream = CollStream();
		state = nil;
		\parsing_started.postln;
		loop { this.parseByte(port.read) };
	}

	finishArg {
		var msgArg = msgArgStream.contents; msgArgStream.reset;
		if (msgArg.notEmpty) {
			if (msgArg.first.isDecDigit) {
				msgArg = msgArg.asInteger;
				//"msgArg was %".postf(msgArg);
			};
			msg = msg.add(msgArg);
			//msg.postln;
		} {//\empty_msg.postln;
		}
	}
	convertString {
		msg = msg.split($ ).asInteger;
	}
	parseByte { | byte |
		var char = byte.asAscii; // MOD
		if (byte === 13) {	// wait for LF
			state = 13;
		} {
			if (byte === 10) {
				if (state === 13) {
					// CR/LF encountered, dispatch message
					this.finishArg;
					if (msg.notEmpty) {
						//this.convertString;
						this.dispatch(msg);
						msg = Array[];
					};
					state = nil;
				}
			} {
				if (byte === 32) {
					// eat them spaces
					state = 32;
				} {
					// anything else
					if (state == 32) {
						// finish last arg
						this.finishArg;
						state = nil;
					};
					if (byte.isNil.not)
					{ // add to current arg, if not nil
					msgArgStream << byte.asAscii;}
				}
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