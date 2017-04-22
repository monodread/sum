// SUM v03, Demo for 3DMin Workshop Session, 25.7.16
"/dev/tty.usbmodem*".pathMatch

/////////// START SERIAL COMM
(
q=q?();
q.serial = SerialSUM(); // start the SerialPort comm
)/*
q.serial.close;
*/
// q.serial.action ={ |...msg| msg.postln}; // check incoming values
q.serial.action = { |...msg| try { MFdef(\arduino).value(*msg) } };

// add some verbosity
(
MFdef(\arduino).add(\post, { |... msg| msg.postcs });
q.verbose={|q, verbosity=true|
	if(verbosity)
	{MFdef(\arduino).enable(\post)}
	{MFdef(\arduino).disable(\post)};
};
)
q.verbose(false); // off
// q.verbose(true); // post the values

/////////// CREATE THE MKTL

(
"SUM_MKtl.desc.scd".loadRelative;
q.mktl=MKtl(\sum, ~sumTouchCube);
/*
// later or while extending ~desc:
q.mktl.rebuild( ~sumTouchCube);
*/
q.mktl.gui; // (parent, bounds)
q.mktl2.gui; // (parent, bounds)

MKtl(\sum).desc.fullDesc.at(\idInfo);
MKtl(\sum).device; // is nil because it's virtual at this point

// ADD MFunc into all elements of MKtl for indiv. actions
q.mktl.elAt.do{|elGroup| elGroup.elements.do {|el| el.action_(MFunc())} }; // individual actions

//////////// CONNECT THE TWO THROUGH MFdef.
// this sets the values / actions of the MKtl from the serial parsing
(
// parse block setter to MKtl
MFdef(\arduino).add(\setMKtl, { |... msg|
	var vals, rawVals, baselines;
	// msg is either Array size 2 or size 46!
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
		q.mktl.elAt(1).deviceValueAction_(vals);
	};

});
);

)

//////////////////////////
q.mktl.elAt(1).elements.at(0).action.orderedNames
// e.g. control the values of a Ndef
(
q.mapNdef={ |q, ndef|
	q.mktl.elAt(1).elements.do{|el, i|
		/*if(el.action.orderedNames.includes(\setNdef))
		{el.action.enable(\setNdef);}
		{*/
		el.action.add(\setNdef, {
			var ndef, key, change = el.value - el.prevValue;
			ndef=Ndef(ndef);
			key=ndef.controlKeys.wrapAt(i);
			[i, key, el.value].postln;
			ndef.set(key, ndef.getHalo.spec[key].map(el.value));
			//				ndef.setUni(key, el.value); // no spec found for key!
		});
		//el.action.enable(\setNdef);
		//}
	};
	"created \set Func vor ndef % \n".postf(ndef);
};
// THis is odd, whenever the mapping is done, then the gui stops working!
/*
q.mapNdef(\sum);
*/
q.disable(\set);
q.disable(\setNdef);
q.enable(\setNdef);
q.disable={|q, name| q.mktl.elementsDict.do{|el| if(el.action.activeNames.includes(name)) { el.action.disable(name) }} };
q.enable={|q,name| q.mktl.elementsDict.do{|el| try { el.action.enable(name) }} };

q.unmap={|q| q.mktl.elementsDict.do{|el| var name=\setNdef; if(el.action.activeNames.includes(name)) { el.action.disable(name) }} };

q.remap={|q| q.mktl.elementsDict.do{|el| var name=\setNdef; try { el.action.enable(name) }} };

// to take snapshot
q.snapshot={|q| q.mktl.elementsDict.asSortedArray.collect{|keyValPair| keyValPair[1].value} };
q.snapshot.value;
)
// a test Sound
(
var voices=23.collect{|i| (\k_++i).asSymbol; };
Ndef(\sum, {
	var kontrols = voices.collect{|name| name.asSymbol.kr(0, 0.08)};
	Splay.ar(SinOsc.ar(kontrols, 0, 0.1))
}).play;
voices.do {|name| Ndef(\sum).addSpec(name, \freq.asSpec) };
)

Ndef(\sum).gui
Ndef(\sum).play

// map it
q.mapNdef(\sum)
q.unmap
q.remap



/////////////////////
q.mktl.gui.parent.alwaysOnTop_(true).background_(Color.rand).alpha_(0.8)


////////////////////////
// MultiTouchPad

MTPsum.start;
MTPsum.gui;

/*
// DOES NOT WORK YET
(
MTPsum.touchAction = {|curID, xys| q.mktl.elAt(1).wrapAt(curID).value_(1-xys[1]); m.elAt.wrapAt(curID+11).value_(xys[0]) };
MTPsum.setAction = {|curID, xys| q.mktl.elAt(1).wrapAt(curID).value_(1-xys[1]); m.elAt.wrapAt(curID+11).value_(xys[0]) };
MTPsum.untouchAction = {|curID| q.mktl.elAt(1).wrapAt(curID).value_(0); m.elAt.wrapAt(curID+11).value_(0) };
)
*/


// control disableton
(
MTPsum.touchAction = {|curID, xys|
	if(xys[1]>0.5){
	var tdef=Tdef.all.keys.reject({|key| key==\master}).asArray.wrapAt(curID);
	"Playing now %\n".postf(tdef);
	Tdef(tdef).play; //xys[1]
	};
};
)
/*
(
MTPsum.setAction = {|curID, xys|
	q.mktl.elAt(1).wrapAt(curID).value_(1-xys[1]); m.elAt.wrapAt(curID+11).value_(xys[0])
};
MTPsum.untouchAction = {|curID|
	q.mktl.elAt(1).wrapAt(curID).value_(0); m.elAt.wrapAt(curID+11).value_(0)
};
)
*/

// switch em off
(
MTPsum.touchAction = {};
MTPsum.untouchAction = {};
MTPsum.setAction = {};
)

////////////////////////////
// Niko's Disableton Setup:

t.tempo=2; // 120 bpm
(
Tdef(\master, {
	inf.do{
		var dur= t.tempo *0.5;
		Tdef.all.choose.play;
		//Tdef.all.wchoose([0.8, 0.8, 0.3, 0.6, 0,0,0,0].normalizeSum).play;
		//Tdef.all.at(\bloc2).play;
		dur.wait
	}
});
)

Tdef(\master).play
Tdef(\master).stop


// Load the FX ProxyChain
//(q.nikolfoPath++"/DA_nikoLfo/NikoLfo_ProxyChainEffects.scd").loadPaths;
"/Users/bonusjonas/GencompUDK/Seafile/SUM_lib/code-dev/DA_nikoLfo/NikoLfo_ProxyChainEffects.scd".loadPath;


q.mktl.rebuild(~sumTouchCube)
q.mktl.gui
/////////////////////////// ///////
// INFLUX WEIGHTS CONTROL!!!
// make a sum input influx - 12-in, 11-out ??
(
var sumkeys = [q.mktl.elAt(1).keys.keep(12), q.mktl.elAt(1).keys.drop(12)];
q.influx = Influx(sumkeys[0], sumkeys[1]);
q.influxWGui = InfluxWGui(q.influx);
q.influxGui = InfluxKtlGui(q.influx);
)
// hook up to MKtl, via snapshot function
(
q.mktl.elAt(1).elements.do{|el, i|
	el.action.remove(\influx); // cleanup?
	el.action.add(\influx, {
		var influx, key;
		influx = q.influx;
		// if(i<=influx.inNames.size) {}
		//{ influx.setw([q.snapshot.drop(2).keep(12),q.snapshot.drop(14)].linlin(0,1.0,-1,1.0)) };
			// the range is decisive here, if it is bipolar, then it defaults to -1!
		influx.blend(q.snapshot.drop(2).linlin(0,1.0,-1,1.0));
	});

};
)

[q.snapshot.drop(2).keep(12),q.snapshot.drop(14)].shape
q.mktl.elAt(1,1).action; // is there an MFunc?
q.mktl.elAt(1).elements.do{|el, i| el.action.disable(\influx)};
q.mktl.elAt(1).elements.do{|el, i| el.action.enable(\influx)};

// hook influx up to some ndef
q.influx.attachMapped(Ndef(\sum));
q.influx.detach(\sum);




/////////////////////////////////
// FOR SECOND SERIAL

q.serial2 = SerialSUM("/dev/tty.usbmodem*".pathMatch[1]);
q.serial2.action = { |...msg| try { MFdef(\arduino2).value(*msg) } };

q.mktl2=MKtl(\sum2, ~sumTouchCube);
q.mktl2.rebuild(~sumTouchCube)
q.mktl2.gui
(
////////////
(
// ADD MFunc into all elements of MKtl for indiv. actions
q.mktl2.elAt.do{|elGroup| elGroup.elements.do {|el| el.action_(MFunc())} }; // individual actions

// parse block setter to MKtl
MFdef(\arduino2).add(\setMKtl2, { |... msg|
	var vals, rawVals, baselines;
	// msg is either Array size 2 or size 46!
	if(msg.size==2) {
		msg.do{ |val, i|
			//val.postln;
			if(val==65535) {/*\zeroCentroid.postln; */val=0};
			q.mktl2.elAt(0, i).deviceValueAction_(val)
		}
	};

	if(msg.size==46) {
		rawVals=msg.keep(23);
		baselines=msg.drop(23);
		vals = (rawVals-baselines).abs; //.clip(0,1.0);
		//vals.postln; // DEBUG
		//baselines[3].postln;
		vals.do{ |val, i|
			var elem = q.mktl2.elAt(1, i);
			var elemDevVal = elem.deviceValue;
			var dejit = Dejitter(0.02, { |val| elem.deviceValueAction_(val) });
			if ((elemDevVal != val)) { dejit.set(val) };
			// if(val>=100) { [\offsetOn, elem.name,elemDevVal, val].postln}; // pad 20,21 were offsetting!
		};

	};

});
);

)