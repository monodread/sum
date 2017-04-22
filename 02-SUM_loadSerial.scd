// Added, 28.01.16
// for path compatibility across computers, lets use a file dialog to specify SEAFILE path:
/*
(
q=q?();
FileDialog({ |path|
	q.seafilePath=path[0]; path.postln; // path is returned in an array!
}, {
	 "Path Dialogue cancelled".postln;
}, 2,0);
q.sumDevDir=q.seafilePath++"/SUM_lib/code-dev/"; // if needed for convenience
);
*/
// THE SUM MKTL LOADER

// First Load the MKtl
// or simply use .loadRelative instead??
// (q.seafilePath++"/SUM_lib/code-dev/01-SUM_loadMKtl.scd").loadPaths;


//////////////////////
// Then load this!

// p = ArduinoSMS("/dev/tty.usbserial-A1000ecP", 115200); // was 9600 (changed by thor)
// p.action = { |... msg| msg.postln };
// try{if(q.serials.isNil || q.serials.at(0)==SerialPort){SerialPort.closeAll;} };
/*
SerialPort.closeAll; // Is there any automation for that?
*/
(
q = q ? ();
q.devices = "/dev/tty.usbmodem*".pathMatch;
// for the use of v0.1 + v0.2
// q.devices = SerialPort.devices.detect({|dev|dev.contains("/dev/tty.usbmodem1421") }).bubble;

// setup the serialports, put into array if more than 1
q.serials = q.devices.collect{ |device, i|
	SerialPort(device,
	baudrate: 115200,
	databits: 8,
	stopbit: 1,
	parity: nil,
	exclusive: true // need this ??
);
};
);

/*
Tdef(\acloop0).play;
Tdef(\acloop0).stop;
TdefAllGui(4);

q.setVals(q.dejits.drop(2), 1.0.rand!23);
*/

////////////////////////////////////
// DATA STRUCT from PSoC Chip:
// [centroidPos*2],[rawVals, baseLines] * 23
// we want: vals = raw-Baselines !
(
// set the sensitivity range of sensors & baseLines for calibration version
q.ranges = [[0,0]!23, [0,0]!23]; // size 2
// q.ranges.at(0).at(0); //first range pair

q.calibRange = {|q, vals, baseLines|
	if(vals.size==baseLines.size)
	{vals.do { |val, i|
		val=val-baseLines[i];
		if (val > q.ranges[0][i][1]) {
			q.ranges[0][i][1] = val;
		} { if (val < q.ranges[0][i][0]) {
				q.ranges[0][i][0] = val; }
		};
	};
	baseLines.do { |val, i|
		if (val > q.ranges[1][i][1]) {
			q.ranges[1][i][1] = val;
		} { if (val < q.ranges[0][i][0]) {
				q.ranges[0][i][0] = val; }
		};
	};
	};
	q.ranges[0].round(0.01).postln;
};

/*
q.calibRange(0.5.rand!23,0!23);
*/

/*
// first version of SetFunc sends to calibrate, not in autload-Version
q.rawSetVals = { |q, dejits, data|
	var rawData, baseLines;
	rawData=data.keep(23);
	baseLines=data.drop(23);
	//data.postln;
	q.calibRange(rawData, baseLines);
};

q.rawSetVals(q.dejits, 1024.rand!46);
q.rawSetCentroids(q.dejits, 256.rand!2);

);
////////////////////////////
(
q.calibRange = {}; //end calib

EXAMPLE RANGES & BASELINES
q.ranges[0] = [ [ -6, 850 ], [ -8, 887 ], [ -3, 910 ], [ -3, 1090 ], [ -2, 1311 ], [ -2, 1233 ], [ -3, 1130 ], [ -3, 928 ], [ -3, 919 ], [ -2, 979 ], [ -7, 1146 ], [ 0, 1483 ], [ -6, 2691 ], [ -15, 2125 ], [ -6, 1963 ], [ -6, 2251 ], [ -8, 1544 ], [ -8, 1628 ], [ -5, 1298 ], [ -10, 1251 ], [ -16, 1526 ], [ -4, 1590 ], [ -16, 1823 ] ];

q.ranges[1] = [ [ 0, 1082 ], [ 0, 1140 ], [ 0, 1193 ], [ 0, 1360 ], [ 0, 2049 ], [ 0, 2049 ], [ 0, 1725 ], [ 0, 1834 ], [ 0, 2395 ], [ 0, 2049 ], [ 0, 2012 ], [ 0, 1828 ], [ 0, 910 ], [ 0, 1061 ], [ 0, 1163 ], [ 0, 1282 ], [ 0, 1343 ], [ 0, 1446 ], [ 0, 1531 ], [ 0, 1531 ], [ 0, 1447 ], [ 0, 1482 ], [ 0, 1559 ] ];

*/

);

// FOR AUTO_LOAD VERSION we use our last discovered ranges and the setting func directly
(
q.ranges[0] = [ [ -6, 850 ], [ -8, 887 ], [ -3, 910 ], [ -3, 1090 ], [ -2, 1311 ], [ -2, 1233 ], [ -3, 1130 ], [ -3, 928 ], [ -3, 919 ], [ -2, 979 ], [ -7, 1146 ], [ 0, 1483 ], [ -6, 2691 ], [ -15, 2125 ], [ -6, 1963 ], [ -6, 2251 ], [ -8, 1544 ], [ -8, 1628 ], [ -5, 1298 ], [ -10, 1251 ], [ -16, 1526 ], [ -4, 1590 ], [ -16, 1823 ] ];

q.ranges[1] = [ [ 0, 1082 ], [ 0, 1140 ], [ 0, 1193 ], [ 0, 1360 ], [ 0, 2049 ], [ 0, 2049 ], [ 0, 1725 ], [ 0, 1834 ], [ 0, 2395 ], [ 0, 2049 ], [ 0, 2012 ], [ 0, 1828 ], [ 0, 910 ], [ 0, 1061 ], [ 0, 1163 ], [ 0, 1282 ], [ 0, 1343 ], [ 0, 1446 ], [ 0, 1531 ], [ 0, 1531 ], [ 0, 1447 ], [ 0, 1482 ], [ 0, 1559 ] ];

// second version
q.rawSetVals = { |q, dejits, data|
	var rawData, baseLines, normData;
	if(data.size==46){
		//data[4].round(0.1).postln;
		rawData=data.keep(23);
		baseLines=data.drop(23);
		normData= rawData.collect { |val, i|
			val=val-baseLines[i];
			// if(i==4){val.postln};
			/*
			// MANUAL MOD! take offsets of 7..11 down!
			if((i<=11) && (i>=6)) {
				if(i==11) {val=val-180;} // this slot is very high!
				{val=val-60-i;} // offset down
			};
			*/
			val=(val).linlin(q.ranges[0][i][0], q.ranges[0][i][1], 0, 1.0);
		};
		q.setVals(dejits.drop(2), normData);
	};
};

q.rawSetCentroids={|q, dejits, data|
	var normCentroids;
	// data.postln;
	if(data.size==2){
		normCentroids = data.collect { |val, i|
			val.linlin(0, 255, 0, 1.0);
		};
		// workaround to zero values in case of no-touch
		if((data[0]==65535) || (m.elAt.value.drop(2).detect{|val, i| val>0.1}).isNil)
		{normCentroids[0]=0};
		if((data[1]==65535) || (m.elAt.value.drop(2).detect{|val, i| val>0.1}).isNil)
		{normCentroids[1]=0};

		q.setVals(dejits.keep(2), normCentroids);
	}
};
);

//////////////
(
// start polling loop
Tdef(\acloop0, {
	var char;
	var raw = "";
	var tmpArr;
	if(q.serials[0].class==SerialPort){
		inf.do {
			while({
				char=q.serials[0].next; char.isNil
			}, { 0.01.wait });

			char = char.asAscii;
			(char != 10.asAscii).if({
				raw = raw ++ char;
			}, {
				tmpArr = raw.split($ ).asInteger;
				tmpArr.postln;
				if (tmpArr.size==46)
				// first case of 46: 23 sense vals+23 baselines
				{ q.rawSetVals(q.dejits, tmpArr); }
				{ if(tmpArr.size==2) {q.rawSetCentroids(q.dejits, tmpArr); }};

				raw = "";
			});
	}}
}).play;

//
try {q.tdefgui.close};
q.tdefgui = TdefAllGui(4);

);


/*
/////////////////////////
(
// second version
q.rawSetVals = { |q, dejits, data|
	var rawData, baseLines, normData;
	if(data.size==46){
		//data[4].round(0.1).postln;
		rawData=data.keep(23);
		baseLines=data.drop(23);
		normData= rawData.collect { |val, i|
			val=val-baseLines[i];
			// if(i==4){val.postln};
			/*
			// MANUAL MOD! take offsets of 7..11 down!
			if((i<=11) && (i>=6)) {
				if(i==11) {val=val-180;} // this slot is very high!
				{val=val-60-i;} // offset down
			};
			*/
			val=(val).linlin(q.ranges[0][i][0], q.ranges[0][i][1], 0, 1.0);
		};
		q.setVals(dejits.drop(2), normData);
	};
};

);

*/
