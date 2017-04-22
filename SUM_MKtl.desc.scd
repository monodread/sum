/* Question is:
Do we make a unified MKtl which collects all values or separate ones, for each controller?
I would opt for second choice, because it's easier to understand...
We only need to do better variable bookkeeping then. no global vars

What type of identifiers are touchpads?
Are they 'pad's

// map input from 100 - max into unipolar,
// adapt warp for sensititvity curve:
x = [100, 1023, 4].asSpec;
(0 .. 1023).collect(x.unmap(_)).plot;
~sumTouchCube.isValidDescDict
Example for a Desc File
~validDesc = (
    idInfo: \ex,
    protocol: \virtual,
    description: (
        \sl: 5.collect { ( type: \slider, ioType: \in, \spec: \midiCC ) },
        \bt: 5.collect { ( type: \button, ioType: \in, \spec: \but ) },
        \play: ( type: \button, ioType: \in, \spec: \but ),
        \stop: ( type: \button, ioType: \in, \spec: \but )
    )
)
MKtl.new(\test, ~validDesc)
~sumTouchCube[\idInfo]
~sumTouchCube[\protocol]
~sumTouchCube[\description]
*/
// according to current definition,
// \idInfo, \protocol, \description (or \elementsDesc) are required;
// There were version changes for MKtlDesc ??

//////////////////////////////////////////
q=q?();

(
// The desc
q.sumCubeDesc= (
	name: \sumTouchCube, //opt?
	idInfo: "/dev/tty.usbmodem*", // not used yet,
	protocol: \serial, // serial is not implemented yet
//	protocol: \virtual,
	specs: (
		sumCubeTouch: [ 100, 2048, 4].asSpec,
		// 4096 is the max without baseline correction!
		sumCubeCentroid: [ 0, 255].asSpec,
		sumCubeBaseLine: [ 0, 2048, -3].asSpec,
	),
	elementsDesc: (
		elements: [
			(
				key: \centroid,
				shared: ( elementType: \slider, ioType: \in, \spec: \sumCubeCentroid),
				elements: 	[
					( key: 'x',
						style: (row: 0.5, column: 0, width: 0.5, height: 6)),
					( key: 'y',
						style: (row: 0, column: 0.5, width: 6, height: 0.5))
				],

			),
			(
				key: \pad,
				shared: ( elementType: \pad, ioType: \in, \spec: \sumCubeTouch),
				elements:
				(1..23).collect { |i| var row,style;
					case
					{i<13}{row=0;style=(row: 0.5*(i%13), column: 0.5, width: 6, height: 0.5)}
					{i>12}{row=2; style=(row: 0.5, column: 0.8+((i%13)*0.5), width: 0.5, height: 6)};
					(key: (i).asSymbol,
					style: style
					//style: (row: row, column: i*0.5, width: 0.5, height: 2)
					//style: (row: 1, column: i*0.5, width: 0.5, height: 2)

				) }
			)
			/*(
				key: \baseline,
				shared: ( elementType: \slider, ioType: \in, \spec: \sumCubeBaseline),
				elements:
				(1..23).collect { |i| (key: ("bl_"++i).asSymbol
//					, style: (row: 1, column: (i-1)*0.5, width: 0.5, height: 2)
				) }
			) */
		]
	)
);
// for backwards compatibility:
~sumTouchCube=q.sumCubeDesc;
);
/*
~sumTouchCube.isValidDescDict;
~sumTouchCube.dump
[\parentDesc];
m.free;
m=MKtl.new(\sumCube_1, ~sumTouchCube);
m.gui;
m.rebuild(~sumTouchCube);
MKtl(\manta, "snyderphonics-manta.desc").gui;
MKtl.openDescFolder
*/
////// For the Matrix Board
(
// The desc
q.sumWeightsDesc=(
	name: \sumWeightsBoard, //opt?
	idInfo: "/dev/tty.usbmodem*", // not used yet,,
	protocol: \serial,
	specs: (
		sumWeights: [ 0, 1000, -4].asSpec,
		//sumCubeCentroid: [ 0, 255].asSpec,
	),
	elementsDesc: (
		key: \pad,
		shared: ( elementType: 'pad', ioType: \in, \spec: \sumWeights ),
		elements:
		([\a,\b,\c].collect{ |col| (1..4).collect { |i| col++"%".format(i) } }.flatten).collect{ |name, i| var row=(i/4).trunc(1); (key: name, style: (row: row, column: i%4, width: 1, height: 1)) }

	)
);
~sumWeightsBoard=q.sumWeightsDesc;
);

/*
m=MKtl.new( \sumCube_2, ~sumWeightsBoard);
~mktl.rebuild(~sumWeightsBoard);
~mktl.gui;

m.free;
m=MKtl.new( \sumCube_1, ~sumTouchCube);
m.gui;
*/
//////////////////////////////////////////
/*
m.free;
(
m = MKtl.new( \sumCube_1, ~sumTouchCube, false );
m = MKtl.new( \sumBoard, ~sumWeightsBoard, false );
)
m.elAt
m.postElements



// OFFICIAL TEST CODE

// test this desc file:
// get name from file when code is within a desc file
// ~thisdescname = thisProcess.nowExecutingPath.basename.split($.).first.postcs;
// or set desc full or partial file name by hand:
~thisdescname = "korg-nanokontrol";

~descs = MKtlDesc.loadDescs(~thisdescname); ~descs.size.postln; ~thisdesc = ~descs.first;
// check web info for it
~thisdesc.web;

// close old ~mktl, open new one, make gui:
~mktl.free; ~mktl = MKtl(\test, ~thisdescname);
try { ~mgui.close }; ~mgui = ~mktl.gui.parent.alwaysOnTop_(true);

~mktl.trace;
// -> wiggle all elements now on gui and/or device

// give all elements an action:
~mktl.trace(false);
~mktl.elAt.action = { |el|
	"TEST: % has val %.\n".postf(el.name.cs, el.value.round(0.0001));
};
// -> AGAIN, now wiggle all elements now on gui and/or device


// is the number of elements and hierarchy plausible?
~mktl.elementsDict.size;
~mktl.postElements;

// can all elements can be set to random values?
// (should post and appear on gui):
~mktl.elementsDict.do(_.valueAction_(1.0.rand)); "";

// do all outputElelements change on device and gui?
~mktl.outputElements.size; // how many are there?
~mktl.outputElements.do(_.valueAction_(1)); ""; // all on
~mktl.outputElements.do(_.valueAction_(0)); ""; // all off

// when done, update test status!
~mktl.desc.openFile;












Examples for creating an MKtl desc:
// these are the bare minimum parameters! name, idInfo, protocol, elementsDesc…
(
~descOne = (
	    name: \oneBut,
	    idInfo: \oneBut,
	    protocol: \virtual, //[\osc, \midi, \hid
	    elementsDesc: (
		        elements: [
			            (key: \bt, type: \button, ioType: \in, \spec: \but )
		        ]
	    )
);
)
// or bit more complex

(
~descOne = (
	name: \oneBut,
	idInfo: \oneBut,
	protocol: \virtual, //[\osc, \midi, \hid
	elementsDesc: (
		(
			    key: \bt,
			    shared: (elementType: \button, ioType: \in, \spec: \but ),
			    elements: [\a, \b, \c, \d].collect { |key| (key: key)  }
		)
))
)


// Create it
m = MKtl.new( \fourButtons, ~descOne, false);

m.elAt;
m.postElements;


// maybe need custom spec?
specs: (
    mantaTouch: [ 0, 227 ].asSpec,
    mantaSlider: [ 0, 4095 ].asSpec,
    // led can be off, amber or red
    mantaLed: ItemsSpec.new( ["off","amber","red"] ),
)

// When in rows and columns, these can be nested:
(
    key: \bt,
    shared: (\midiMsgType: \cc, \type: \button, \midiChan: 0, \spec: \midiCC),
    elements: [(32..39),(48..55),(64..71)].collect { |xs|
        (
            elements: xs.collect { |i| (\midiNum: i) }
        )
    }
)



// EXAMPLE

(
// ...
elementsDesc: [ // the elementsDesc of the whole device
    (
        key: \top,  // name of this group,
                    // all elements use cc and midichan 0
        shared: (midiChan: 0, midiMsgType: \control),

                    // the elements descriptions:
        elements: [
                    // a group of 2 sliders
            (
                key: \sl,   // group name
                    // they share elementType and spec
                shared: (elementType: \slider, spec: \midiCC ),
                elements: [

                    ( key: \1, midiNum: 21 ),
                    ( key: \2, midiNum: 22 )
                ]
            ),
                    // a group of 2 buttons
            (
                key: \bt,
                    // they share elementType and spec
                shared: (elementType: \button, spec: \midiBut),
                elements: [
                    ( key: \1, midiNum: 41 ),
                    ( key: \2, midiNum: 42 )
                ]
            )
        ]
    )
]
)

*/