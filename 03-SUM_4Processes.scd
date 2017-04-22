// Added, 28.01.16
// for path compatibility across computers, lets use a file dialog to specify SEAFILE path:
(
q=q?();
FileDialog({ |path|
	q.seafilePath=path[0]; path.postln; // path is returned in an array!
}, {
	 "Path Dialogue cancelled".postln;
}, 2,0);
q.sumDevDir=q.seafilePath++"/SUM_lib/code-dev/"; // if needed for convenience
);

// THE SUM MKTL LOADER

// First Load the MKtl
// or simply use .loadRelative instead??
(q.seafilePath++"/SUM_lib/code-dev/01-SUM_loadMKtl.scd").loadPaths;
// Load the SerialPort stuff and Action Func
(q.seafilePath++"/SUM_lib/code-dev/02-SUM_loadSerial.scd".loadPaths;

// Then load here!
///////////////////////////
// now we get to do more triggered & complex stuff

// BOOT SERVER!
s.boot;


/// VARIATION I: simple triggered sounds, sinewave & noise upon changes
(
(
SynthDef(\bing, { arg out, freq=440, amp = 0.1, sustain=0.1, pan=0, vib=3;
	var sound, env, src;
	vib = SinOsc.kr(vib,mul: vib*2);
	sound = SinOsc.ar(freq+vib,0, 2);
	env = EnvGen.ar(Env.perc(0.01, sustain, -6.dbamp), doneAction:2);
	src = Pan2.ar(sound.softclip*env, pan, amp);
	Out.ar(out, src)
}).add;

SynthDef(\piff, { arg out, x=0.5, y=0.5, freq=80, amp = 0.1, sustain=0.5, rq=0.5;
	var env, src;
	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction:2);
	src=RHPF.ar(
		PinkNoise.ar(0.5 ! 2),
		XLine.kr(5000*x,freq, x*sustain),
		0.01+rq,
		XLine.kr(1,0.1,y*sustain)
	);
	Out.ar(out, src *amp)
}).add;

);

(
// do this on bigger change: "touch"
m.elAt.do{|el,i|
	if((el.name!=\x) || (el.name!=\y))
	{
		el.action.add(\jump, {|el|
			var change;
			change = el.value - el.prevValue;
			if(change>0.3) {
				(instrument: \piff, freq: change.linexp(0.2,1,20,200*i), \amp: el.value, \sustain: el.value, \x: change*3).play;
		} {if((change>0.1) && (change<0.25)){
				(instrument: \bing, freq: \freq.asSpec.map(change), \amp: el.value, \sustain: 1+el.value, \vib: change*10).play;
			}}
		})
	};
};
);

)

//
// disable the funcs from this section:
m.elAt.do{|el,i| el.action.disable(\jump)};
m.elAt.do{|el,i| el.action.disable(\post)};
////////////////////////
/// VARIATION II: controlling ongoing Ndef Sound, harmonics, amplitudes
(
(
Ndef(\cube).addSpec(\amod, \lofreq.asSpec);
Ndef(\cube).addSpec(\vib, \lofreq.asSpec);
Ndef(\cube).addSpec(\bits, [8, 0.5, \lin, 0.1, 5]);
Ndef(\cube).addSpec(\downsamp, [1, 200, \exp, 0.1, 4]);
Ndef(\cube).addSpec(\cutoff, [1.5, 100, \exp, 0.1, 2.5]);
// SoS modelling of hammond sound, sort of
// http://www.soundonsound.com/sos/nov03/articles/synthsecrets.htm
Ndef(\cube, {|amp=0, freq=150, cutoff=2.5, bits=4, downsamp=8, vib=0.1, amod=0.1|
	var src, harm, config, krush;
	freq=freq.lag(0.05)*0.5;
	harm=[1,3,2,4,6,8,10,12,16]; // 9 drawbars
	config = \harm.kr(9.collect{1.0.rand}.round(0.01).postln) * LFNoise1.kr(0.05,0.02,1);
	// [1,1,1,0,0,0,0,0,0].normalize; // classic 70ies rock config
	// [8,3,4,2,1,1,1,0,0].normalize
	// [0,0, 8,0,3,0, 2,0,0].normalize
	src = SinOsc.ar(freq*harm, 0, config);
	src[0]=BLowPass.ar(Mix(src[0] + Pulse.ar(freq*harm,0.5, config)), freq*cutoff, 0.1);
	krush = Latch.ar(src.round(0.5 ** bits), Impulse.ar(SampleRate.ir / downsamp.max(2)));
	src = (krush*0.5+src) * 0.5;
	Splay.ar(src.scramble.tanh*amp, SinOsc.kr(vib,0,0.5,0.5), SinOsc.kr(amod).range(0.1,0.5), SinOsc.kr(vib,0,0.5,0.5));
}).play;
);

/*
// different drawbar / harmonic configs
Ndef(\cube).set(\harm, 9.collect{1.0.rand}.round(0.01).postln);
// classic
Ndef(\cube).set(\harm, [8,3,4,2,1,1,1,0,0].normalize)
Ndef(\cube).set(\harm, [0,0, 8,0,3,0, 2,0,0].normalize)
Ndef(\cube).set(\harm, 1!3++(0!6))

//a quick player
(
Ndef(\cube)[1] = \set -> Pbind(
	\dur, Pwrand([0.5,1,0.1,0.2],[0.8,0.1,0.05,0.05].normalizeSum,inf) * 0.25,
	\freq, Prand([30,[30,34],37,39,42,44],inf).midicps
	)
)
*/
(
// Ndef(\cube).set(\amp, 0.1);
Ndef(\cube).fadeTime=0.5;
q.ndefGui=NdefGui(Ndef(\cube),8);
q.ndefGui.skipjack.dt_(0.05);

);

(
// do this on slight change:
// not \x and \y
m.elAt.drop(2).do{|el, i|
	el.action.add(\cube, {|el|
		var change = el.value - el.prevValue;
		if((change<0.2) && (el.value>0.1)) {
			var harm=m.elAt.drop(2).keep(9).collect{|el|el.value};
			"!!!  Sensor %, New Harmonix %   !!\n".postf(i, harm.round(0.01));
			Ndef(\cube).set(\freq, (28+ i).midicps,
				\harm, harm);
		};
		if(i>13) {
					if(i<16){ Ndef(\cube).set(\bits, Ndef(\cube).getHalo.spec[\bits].map(el.value*2));};
					if((i>16)&&(i<20)) { Ndef(\cube).set(\downsamp, Ndef(\cube).getHalo.spec[\downsamp].map(el.value*2));};
					if((i>19)&&(i<23)) { Ndef(\cube).set(\cutoff, Ndef(\cube).getHalo.spec[\cutoff].map(el.value*2));}
		};
	});
};

// add volume control on the centroids
m.elAt.keep(2).do{|el, i|
	el.action.add(\cube, {|el|
		Ndef(\cube).set(\amp, el.value.linlin(0,1,0.3,0.8),
			\vib, m.elAt(\x).value, \amod, m.elAt(\y).value*7.rand
		);
	});
};
);

)

// Stop Ndef playing and the posting from "Cube" Actions
Ndef(\cube).stop; m.elAt.collect{|el| el.action.disable(\cube)};
/////////////////////////////
// A sample player-sequencer
// load file
"/Users/bonusjonas/Dropbox/PHD/code/_Performance CODE/_AllSynths-Drumkit_Collection.scd".loadPath;
//or some percussion sounds:
(
q.percSounds = [\hhRev, \clap, \snare909, \kickSOS, \kalimba];
(
SynthDef(\hhRev, {|out, sustain = 0.1, amp=0.1, freq=6799, pan=0|
	// these are synths argumiments
		var env = XLine.kr(0.1, 1, sustain, 5, doneAction: 2);
		// variable- envelope
		var son = BBandPass.ar(WhiteNoise.ar(0.4),freq*XLine.kr(1.1,0.8,sustain/4), 0.2, 3);
		//sinewave sound generator with se
	Out.ar(out, Pan2.ar(son * env * amp, pan));
	}).add;
);
(
SynthDef(\clap, {	arg out=0, pan=0, amp = 0.1;
		var env1, env2, sig, noise1, noise2;

		env1 = EnvGen.ar(Env.new([0, 1, 0, 1, 0, 1, 0, 1, 0], [0.001, 0.013, 0, 0.01, 0, 0.01, 0, 0.03], [0, -3, 0, -3, 0, -3, 0, -4]));
		env2 = EnvGen.ar(Env.new([0, 1, 0], [0.02, 0.3], [0, -4]), doneAction:2);

		noise1 = WhiteNoise.ar(env1);
		noise1 = HPF.ar(noise1, 600);
		noise1 = BPF.ar(noise1, 2000, 3);

		noise2 = WhiteNoise.ar(env2);
		noise2 = HPF.ar(noise2, 1000);
		noise2 = BPF.ar(noise2, 1200, 0.7, 0.7);

		sig = noise1 + noise2;
		sig = sig * 2;
		sig = sig.softclip * amp * -12.dbamp;

	Out.ar(out, Pan2.ar(sig,pan));
	}).add;
);
(
SynthDef(\snare909,{ |out=0,amp=0.1, vol=1, pan=0|

      var excitation, membrane;
      excitation = LPF.ar(WhiteNoise.ar(1), 7040, 1) * (0.1 + vol);
      membrane = (
 // Two simple enveloped oscillators represent the loudest resonances of the drum membranes
                     (LFTri.ar(330,0,1) * EnvGen.ar(Env.perc(0.0005,0.055), doneAction:0) * 0.25)
                    + (LFTri.ar(185,0,1) * EnvGen.ar(Env.perc(0.0005,0.075), doneAction:0) * 0.25)

     // Filtered white noise represents the snare
                    +(excitation * EnvGen.ar(Env.perc(0.0005,0.4),doneAction:2) * 0.2)
                    +(HPF.ar(excitation, 523, 1) * EnvGen.ar(Env.perc(0.0005,0.283), doneAction:0) * 0.2)

                   ) * amp;
	Out.ar(out, Splay.ar(membrane, 0, 1, pan))
   }).add;
);

(
SynthDef(\kickSOS,
	{ arg out = 0, freq = 50, mfreq = 5, mod_index = 5, sustain = 0.4, amp = 0.4, noise = 0.025, pan=0;
	var pitch_contour, drum_osc, drum_lpf, drum_env;
	var beater_source, beater_hpf, beater_lpf, lpf_cutoff_contour, beater_env;
	var kick_mix;
	freq=freq.explin(20,20000,40,120);
	pitch_contour = Line.kr(freq*2, freq, 0.02);
	drum_osc = PMOsc.ar(	pitch_contour,
				mfreq,
				mod_index/1.3,
				mul: 1,
				add: 0);
	drum_lpf = LPF.ar(in: drum_osc, freq: 1000, mul: 1, add: 0);
	drum_env = drum_lpf * EnvGen.ar(Env.perc(0.005, sustain), 1.0, doneAction: 2);
	beater_source = WhiteNoise.ar(noise);
	beater_hpf = HPF.ar(in: beater_source, freq: 500, mul: 1, add: 0);
	lpf_cutoff_contour = Line.kr(6000, 500, 0.03);
	beater_lpf = LPF.ar(in: beater_hpf, freq: lpf_cutoff_contour, mul: 1, add: 0);
	beater_env = beater_lpf * EnvGen.ar(Env.perc, 1.0, doneAction: 2);
	kick_mix = Mix.new([drum_env, beater_env]) * 2 * amp;
	Out.ar(out, Pan2.ar(kick_mix, pan))
	}
	).add
);

(
SynthDef(\kalimba, {|out, sustain = 0.3, freq = 200, amp=0.1, ring=0.1, noise=1, pan=0|
		var env1, env2, son;
		env1 = Line.kr(XLine.kr(0.9,0.4, 0.01), 0, sustain, doneAction: 2);
		env2 = EnvGen.kr(Env.perc(0.001, sustain));
		son = BPF.ar(PinkNoise.ar(1, 2), XLine.kr(freq*2,freq,0.01), 0.5);
		son = Ringz.ar(son, freq, ring, mul:0.1);
		noise = noise*WhiteNoise.ar(LFNoise1.kr(6).range(1/30, 1/60))*env2;

	Out.ar(out, Splay.ar((son.tanh + HPF.ar(noise,freq*2, 0.1)) * env1, 0,amp, pan));
	}).add;
)
)

////////////////////////////////////
// A little Step Sequencer
// sounds nice especially in low tempo sets below 40 bpm
(
Tdef(\steppy, {inf.do{ |i|
	var bar=16, step=1/bar, slot, instr;
	i = i.asInteger%bar;
	(step*1/TempoClock.default.tempo).wait;
	slot=i+2;
/*	// simple bing sound, this will be triggered by slots 2..(bar+2)
	if(m.elAt(slot).value>0.16) {
		var microtone=m.elAt(slot).value * [1.5,-1.5].choose;
	(instrument: \bing, sustain:step,
			freq: (68+slot+microtone).midicps,
			amp: m.elAt(slot).value).play; };
*/
	// use synthesis percussions, random choice
		if(m.elAt(slot+7).value>0.16) {
		// instr = q.percSounds.wchoose([0.4,0.1,0.5,0.5,0.3].normalizeSum);
		instr = q.percSounds@(i%q.percSounds.size);
		(instrument: instr.postln, sustain:step*exprand(1,10.0),
			//freq: \freq.asSpec.map(m.elAt(slot+7).value*0.5),
			freq: (44+slot+7).midicps,
			amp: m.elAt(slot+7).value*2).play;
		};
	}
}).play;

// change tempo on some
[m.elAt(5),m.elAt(13),m.elAt(19)].do{|el,i|
		el.action.add(\tempo, {|el|
			var change;
			change = (el.value - el.prevValue).abs;
			if(change>0.25) {
			if(TempoClock.default.tempo>1.8) {TempoClock.default.tempo=0.2};
			TempoClock.default.tempo=TempoClock.default.tempo+change;
			"Tempo New is % \n".postf(TempoClock.default.tempo);
		} { if((change<0.25) && (change>0.1) ) {
			if(TempoClock.default.tempo<0.2) {TempoClock.default.tempo=1};
			TempoClock.default.tempo=TempoClock.default.tempo-change;
			"Tempo New is % \n".postf(TempoClock.default.tempo);
		} }
	})
};
)

// disable this example
Tdef(\steppy).stop; m.elAt.drop(2).do{|el,i| el.action.disable(\tempo) };
//////////////////
// take Rhythmicon from Class example
//

// basic implementation,
// without seventeenth key for syncopation
(
~nums = (1..16);
~rnames = ~nums.collect { |n| ("r" ++ n).asSymbol };
~rnames.do(Spec.add(_, \amp));

Spec.add(\rate, [0.1, 10, \exp]);

(
Ndef(\rhythmicon, {
	var nums = ~nums;
	var freqs = nums * \root.kr(200);
	var pulses = Impulse.ar(nums * \rate.kr(1));
	var envs = Decay.ar(pulses, \dcy.kr(0.1));
	var oscs = SinOsc.ar(freqs);
	var pulsed = envs * oscs;
	var amps = ~rnames.collect { |r| r.kr.lag(0, 0.1) };
	Splay.ar((pulsed * amps).softclip);
}).play;
);
// and a Gui

w = Window("Rhythmicon", Rect(200, 200, 400, 500)).front;
w.view.addFlowLayout;
Button(w).states_([["all"]]).action_ {
	Ndef(\rhythmicon).set(*[~rnames, 1].flop.flat);
};
Button(w).states_([["off"]]).action_ {
	Ndef(\rhythmicon).set(*[~rnames, 0].flop.flat);
};
Button(w).states_([["rand"]]).action_ {
	Ndef(\rhythmicon).set(*~rnames.collect { |r| [r, 2.rand] }.flat);
};

w.view.decorator.nextLine;
~rnames.do { |r|
	Button(w).states_([[r, Color.black, Color.grey], [r]])
	.action_({ |bt| Ndef(\rhythmicon).set(r, bt.value); });
};
w.view.decorator.nextLine.shift(0, 10);
NdefGui(Ndef(\rhythmicon), 20, w);
);

(
//// and some controls
m.elAt.drop(2).do{|el,i|
	// first 16 sensors go to amps
	if(i<16){
	el.action.add(\rycon, {|el|
		var ktlNames;
		ktlNames=~rnames;
			if(el.value>0.1){ Ndef(\rhythmicon).set(ktlNames[i], (el.value*3).clip(0,1)); }
			{Ndef(\rhythmicon).set(ktlNames[i], 0); };
	})};
	// 17 to 20 influence decay
	if((i<21)&&(i>16)) {el.action.add(\rycon, {|el| Ndef(\rhythmicon).set(\dcy, el.value); })};
	// 20 to 23 influence the root freq and the rate
	if(i>20){
		el.action.add(\rycon, {|el|
		var change, ktlNames;
		change = (el.value - el.prevValue).abs;
		ktlNames=~rnames;
			if((change<0.1)&&(change>0.02))
			{ var off=el.value*50*[1,-1].choose;
				Ndef(\rhythmicon).set(\root, 200+off;)}
			{ Ndef(\rhythmicon).set(\rate, 0.5+(change*10))};
	})};

	};

);

// in error, delete the funcs
// m.elAt.drop(2).do{|el,i| el.action.remove(\rycon) };
 Ndef(\rhythmicon).stop;

//////////////////////////////////////////////////////////////////////
// FX ADD
// some reverb

Ndef(\rhythmicon).set(\wet1, 0.2);  // some wet
Ndef(\rhythmicon).set(\wet1, 0); // dry signal

Ndef(\rhythmicon)[1]= \filterIn -> { |in, revTime = 1, drift = 0.01, rate = 0.1| Splay.ar(AdCVerb.ar(in*0.5, revTime, combScale: LFDNoise3.kr(rate, drift.clip2(0.9), 1)))};
// HPF
Ndef(\rhythmicon).set(\wet2, 0.1);
Ndef(\rhythmicon)[2]=	\filter -> { |in, freq = 3000| HPF.ar(in * (freq / 500).sqrt, freq)};

/////// FX DICTIONARY
// if you load the "04...effects" file, then you can add it like this:
// lookup which effects have been loaded into our storage:
q.postfx; // choose a name
Ndef(\rhythmicon).set(\wet1, 0.2);
Ndef(\rhythmicon)[1]= \filterIn -> q.filters[\adcverb];

