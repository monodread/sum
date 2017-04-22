SerialDevice
{
	classvar <>crtscts=true;
	var <port, <parser, inputThread;
	var <>action;

	*parserClass {
		^this.subclassResponsibility(thisMethod)
	}
	*new {
		| portName,
		baudrate(115200),
		databits(8),
		stopbit(false),
		parity(nil),
		crtscts(false),
		xonxoff(false)
		exclusive(true) |
		portName= portName ? "/dev/tty.usbmodem*".pathMatch.first;
		if(portName.isNil.not) {
			^super.newCopyArgs(
				SerialPort(
					portName,
					baudrate,
					databits, stopbit, parity,
					// without flow control data written only seems to
					// appear at the device after closing the connection
					// aug.2008: made this into a class variable so it can be turned off in certain subclass environments (nescivi)
					crtscts: crtscts,
					xonxoff: xonxoff, exclusive: exclusive
				)
			).init
		} {
			"no USB to Serial Device found".postcs;
			^nil
		}
	}
	init {
		parser = this.class.parserClass.new(this);
		inputThread = fork { parser.parse };
	}

	close {
		inputThread.stop;
		port.close;
	}
	send { | ... args |
		^this.subclassResponsibility(thisMethod)
	}

	// PRIVATE
	prDispatchMessage { | msg |
		action.value(*msg);
		//'dispatched'.postln;
	}
}

SerialParser
{
	classvar <>verbose=false; // MOD
	var <serialdevice, <port;

	*new { | serialdevice |
		^super.newCopyArgs(serialdevice, serialdevice.port).init
	}
	init {
	}
	parse {
		^this.subclassResponsibility(thisMethod)
	}
	dispatch { | msg |
		serialdevice.prDispatchMessage(msg);
	}
}

// EOF