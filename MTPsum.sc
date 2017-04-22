// only makes sense for a single multitouchpad, so killall is ok.

MTPsum {
	classvar <responder, <fingersDict, <activeBlobs, <>setAction, <>touchAction, <>untouchAction;
	classvar <guiOn, <guiWin, <uview, <>fingerCol, <>fingerSize, <fingerStrings;
	classvar <isRunning = false, <pid, <stopFunc, <device;
	classvar <>progpath = "";
	classvar <smallRect;

	*initClass {
		progpath = nil; // MOD because we have no standalone SuperCollider!
		//progpath = Platform.resourceDir +"/";
		responder = OSCresponderNode(nil, "/tuio/2Dobj", {|...args| this.processOSC(*args); });
		fingersDict = ();
		activeBlobs = List.new;
		guiOn = false;
		isRunning = false;
		stopFunc = { this.stop; };
		device = 0;
		fingerSize = 20;
		fingerCol = Color.red;
		fingerStrings = ();
	}

	*refresh {
		if (guiWin.notNil and: { guiWin.isClosed.not }) {
			defer { guiWin.refresh }
		}
	}

	*setDevice { |argDevice|

		argDevice.switch
		(
			\internal, { device = 0; },
			\external, { device = 1; },
			{ "argDevice must be \\internal for internal trackpad and \\external for external trackpad.".error; }
		);
	}

	*killAll { |func|
		"killall tongsengmod".unixCmd({ |res|
			if(res == 0, {
				"A dangling tongsengmod process was found and terminated.".postln;
				isRunning = false;
			});
			func.value;
		});
	}

	*start { |force = false|

		if (isRunning and: force.not) {
			"MTPsum is already active and running. Try: \n"
			" MTPsum.start(force: true);\n".error;
			^this
		};

		responder.remove;

		if (force) {
			this.killAll ({ MTPsum.prStart; });
		} {
			MTPsum.prStart;
		};
	}

	*prStart {
		var cmdStr;
		if(progpath==nil){
			cmdStr = ("tongsengmod localhost"
				+ NetAddr.langPort + device.asString)}
		{cmdStr = (progpath + "tongsengmod localhost"
			+ NetAddr.langPort + device.asString)};

		"MTPsum: starting tongsengmod ".postln;
		responder.add;
		isRunning = true;
		ShutDown.add(stopFunc);

		pid = cmdStr.unixCmd({ |res|
			if(res == 127, {
				"tongsengmod executable not found. See \n MTPsum.openHelpFile;".error;
				responder.remove;
				isRunning = false;
			});
			if (res == 0) {
				"MTPsum: tongsengmod stopped.".postln;
			};
		});
		this.refresh;
	}



	*stop {
		responder.remove;
		"killall tongsengmod".unixCmd;
		isRunning = false;
		"MTPsum stopped.".postln;
		this.refresh;
	}

	*processOSC { |time, responder, msg|

		//msg.postln;
		var toRemove = List.new;
		var curID = msg[2];
		var xys = msg[4..6];

		if(msg[1] == 'alive', {

			activeBlobs = msg[2..];
			fingersDict.keys.do ({|item|

				if(activeBlobs.includes(item).not,
					{
						toRemove.add(item);
				});
			});

			toRemove.do({|item|
				fingersDict.removeAt(item);
				untouchAction.value(item);
				fingerStrings.removeAt(item);
				this.refresh;
			});

			activeBlobs.do({|item|
				if(fingersDict.at(item).isNil, {
					fingersDict.put(item, -1); //-1 means xy not initialized
				});
			});

			^this;
		});

		if(msg[1] == 'set', {
			if(fingersDict.at(curID).isNil, {
				"MTPsum: bug? this should never happen.".postln;
			});
			if(fingersDict.at(curID) == -1, { touchAction.value(curID, xys); });
			fingersDict.put(curID, xys);
			setAction.value(curID, xys);
			this.refresh;
			^this;
		});
	}

	*maximize {
		smallRect = guiWin.bounds; // Rect(100, 100, 525, 375);
		guiWin.bounds_(Window.screenBounds);
	}
	*minimize {
		guiWin.bounds_(smallRect);
	}

	*gui { |force = false|
		if (force) { if (guiWin.notNil) { guiWin.close } };

		if (guiWin.notNil and: { guiWin.isClosed.not }) {
			^guiWin.front;
		};

		guiWin = Window("MTPsum", Rect(100, 100, 525, 375))
		.alpha_(0.7)
		.onClose_({ guiOn = false; guiWin = nil; uview = nil });

		guiWin.view.keyDownAction = { |view, key|
			if (key == $.) { MTPsum.stop };
			if (key == $ ) { MTPsum.start; };
			if (key == $m) { MTPsum.maximize };
			if (key == $x) { MTPsum.minimize };
		};

		uview = UserView(guiWin, guiWin.view.bounds)
		.background_(Color.grey(0.7)).resize_(5);
		// MODDED drawFunc!
		uview.drawFunc_({ |uv|
			var xgridDiv = 16, ygridDiv = 16;
			var bounds = uv.bounds, width = bounds.width, height = bounds.height;
			var xgrid = width / xgridDiv, ygrid = height / ygridDiv;
			var halfFing = MTPsum.fingerSize * 0.5;
			var status = ["OFF", "ON"][MTPsum.isRunning.binaryValue];

			Pen.stringAtPoint(status, 10@10, Font("Futura", 30), Color.white);

			((1..xgridDiv - 1) / xgridDiv).do { |i|
				var x = i * width;
				Pen.line(x@0, x@height);
				Pen.stroke;
			};

			((1..ygridDiv - 1) / ygridDiv).do { |i|
				var y = i * height;
				Pen.line(0@y, width@y);
				Pen.stroke;
			};


			MTPsum.fingersDict.keysValuesDo { |key, fItem|
				var x = bounds.width * fItem[0];
				var y = bounds.height * fItem[1];
				var fingSize = halfFing * fItem[2];

				// draw grid rect:
				Pen.color = Color.yellow;
				Pen.fillRect( Rect(x.trunc(xgrid), y.trunc(ygrid), xgrid, ygrid));

				// draw finger:
				Pen.color = MTPsum.fingerCol;
				Pen.fillOval( Rect.aboutPoint(x@y, halfFing, halfFing));

				// Pen.stringCenteredIn(
				// 	MTPsum.fingerStrings[key] ? key.asString,
				// 	Rect.aboutPoint(x@y, 60, 30)
				// );
			};
		});
		/*		uview.drawFunc_({ |uv|
		var bounds = uv.bounds;
		var halfFing = MTPsum.fingerSize * 0.5;
		var status = ["OFF", "ON"][isRunning.binaryValue];

		Pen.stringAtPoint(status, 10@10, Font("Futura", 30), Color.white);

		MTPsum.fingersDict.keysValuesDo { |key, fItem|
		var x = bounds.width - halfFing * fItem[0];
		var y = bounds.height - halfFing * fItem[1];
		var fingSize = MTPsum.fingerSize * fItem[2];

		Pen.color = MTPsum.fingerCol;
		Pen.strokeOval( Rect(x, y, fingSize, fingSize));

		Pen.stringCenteredIn(
		fingerStrings[key] ? key.asString,
		Rect.aboutPoint(x@y, 60, 30)
		);
		};
		});*/
		guiOn = true;
		^guiWin.front;
	}

	*resetActions {
		touchAction = {};
		untouchAction = {};
		setAction = {};
	}
}