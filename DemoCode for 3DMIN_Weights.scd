// 25.07.16
// code for the Weights Board (Arduino)
"/dev/tty.usbmodem*".pathMatch

(
q=q?();
q.arduino = SerialSMS("/dev/tty.usbmodem*".pathMatch.last, baudrate: 19200, crtscts: true); // start the SerialPort comm
)
//// SEE IF VALUES ARE COING
q.arduino.action = {|...msg| msg.postln};
q.arduino.action = nil;
q.arduino.close;
////
(
q.arduino.action = { |...msg| try { MFdef(\arduino).value(*msg) } };
~mktl3 = MKtl(\sum3, ~sumWeightsBoard);
// ~mktl3.rebuild(~sumWeightsBoard);
~mktl3.gui;

(
// parse block setter to MKtl
MFdef(\arduino).add(\setMKtl, { |... msg|
	var vals, rawVals, baselines;
	//msg.size.postln;
	// from weights matrix
	if(msg.size==12){
		msg.do{ |val, i|
			//val.postln;
			~mktl3.elAt(i).deviceValueAction_(val)
		}
	};
	// From Cubes, msg is either Array size 2 or size 46!
	if(msg.size==2) {
		msg.do{ |val, i|
			//val.postln;
			if(val==65535) {/*\zeroCentroid.postln; */val=0};
			q.mktl.elAt(0, i).deviceValueAction_(val)
		}
	};

	if(msg.size==46) {
		rawVals=msg.keep(23);
		baselines=msg.drop(23);
		vals = (rawVals-baselines).abs; //.clip(0,1.0);
		//vals.postln; // DEBUG
		//baselines[3].postln;
		vals.do{ |val, i|
			var elem = q.mktl.elAt(1, i);
			var elemDevVal = elem.deviceValue;
			var dejit = Dejitter(0.02, { |val| elem.deviceValueAction_(val) });
			if ((elemDevVal != val)) { dejit.set(val) };
			// if(val>=100) { [\offsetOn, elem.name,elemDevVal, val].postln}; // pad 20,21 were offsetting!
		};

	};

});
);

)
)