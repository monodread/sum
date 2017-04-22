// THE SUM MKTL LOADER

// Version = 11.12.15
// Prerequisites for running this code!
// You need the Quarks:
// adclib, JITLibExtensions, Modality-Toolkit

(
q = q ? ();
q.ktlNames2 = [\y, \x] ++ (1..23).collect { |i| "cv_%".format(i) };

~sumDesc = (
	    idInfo: ( ipAddress: "127.0.0.1" ),
	    protocol: \osc,
	    collectives: (
		//         buttons: (
		// 	            oscPath: 'buttons',
		// 	            elements: q.ktlNames2.collect([ _, _ ]),
		// 	            ioType: \in
		//         )
	    ),
	specs: (sumSens: [0, 1024, \lin, 1]),

	    elementsDesc: (
		shared: ( type: 'slider', ioType: \collectiveIn, \spec: \sumSens ),
		elements: q.ktlNames2.collect { |name|
			(key: name)
		}
    )
);
MKtl(\sum2).free; m.free; m = MKtl(\sum2, ~sumDesc );
m.gui.parent.alwaysOnTop_(true);
m.trace; // only when hardware is connected, not yet for serial
);

/*
// the top group:
m.elAt;
// do set values for fall controls from SerialPort:
m.elAt.valueAction_({ 1.0.rand }!23);

// set values for all controls and each one do their action
m.elAt.valueAction_({ 1.0.rand }!23).do(_.doAction);

// get a snapshot of all values
m.elAt.value;
m.elAt(6).value;
*/

(
// set thru dejitter
q.dejits = m.elAt.collect { |el| Dejitter(0.02, { |val| el.valueAction_(val) }) };
q.setVals = { |q, dejits, data|
	//for errorcatch
	if (dejits.size==data.size) {dejits.do { |dejit, i| dejit.set(data[i]) } }
	{"number of data input != sensors".postln;};
};

// set thru dejitter:
q.setVals(q.dejits, { 0.05.rand }!25);
q.setVals(q.dejits, { 1.0.rand }!25);

/*
// EXAMPLES
// set an action for one element
m.elAt(\x).action = { |el| "centroid X = %\n".postf(el.value)};
m.elAt(\x).action = { };
//m.elAt(\x).action = { |el| el.action_(MFunc())};

// see change in element, e.g. in first fader/slot:
m.elAt(\x).action = { |el| [el.prevValue, el.value,  el.value - el.prevValue].round(0.001).postln };

// for more flexibility, add MFunc by name
m.elAt(\x).action_(MFunc());
m.elAt(\x).action.add(\post, {|el| [el.name, el.value, el.value - el.prevValue].round(0.001).postln });
m.elAt(\x).action.add(\record, {|el| [\record, el.name, el.value].round(0.001).postln });
// how to disable them
m.elAt(\x).action.disable(\post);
m.elAt(\x).action.disable(\record);

m.elAt(\x).action.enable(\post);
*/
// put MFuncs into all Elements
m.elAt.do{|el| el.action_(MFunc())};
// add Func for Posting
m.elAt.do{|el| el.action.add(\post, {|el|
	var change;
	//only post for large Changes
	change = el.value - el.prevValue;
	if(change>0.001){ [el.name, el.value, change].round(0.01).postln } })
};
m.elAt.do{|el| el.action.disable(\post)}; // disable posting on all

/*
m.elAt.do{|el| el.action.enable(\post)}; // disable posting on all
// demo posting by random number input
q.setVals(q.dejits, { 1.0.rand }!25);
*/
)
