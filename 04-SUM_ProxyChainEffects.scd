//////////////////////////////////////////////////////
// PROXYCHAIN Effects STUFF:
//globals, in case not done anywhere else:
// this needs latest adclib!

(
q=q?();
q.numChans=4; //quadra version
t=TempoClock.default;
);

(
// MAKE A REPERTOIRE of audio EFFECTS
q.filters = (
	// EQ Filtering
	\hpf: { |in, freq = 3000| HPF.ar(in * (freq / 500).sqrt, freq)},
	\hpf6K: { |in, freq = 6000| HPF.ar(in * (freq / 500).sqrt, freq)},
	\lpf: { |in, freq = 200, rq=0.8| BLowPass.ar(in, freq, rq)},
	\leakDC:  { |in, leak=0.99| LeakDC.ar(in, leak) },

	// DYNAMICS
	\distortion: {|in, dist = 1| var abs, excess; abs = in.abs; dist=dist.reciprocal.clip(0,1.0); excess = (abs-0.1).max(0.0).min(dist)/dist; (excess*(sin(excess*2pi*5)*0.5-0.5)).softclip; },
	\krush: { |in, bits = 4, downsamp = 8| in = in.round(0.5 ** bits); Latch.ar(in, Impulse.ar(SampleRate.ir / downsamp.max(2)))},
	\noizy: { |in, noizy = 0.5| in = in * GrayNoise.ar(noizy, 1 - noizy)},
	\noizy2: { |in, rate=3| var noizy=LFNoise0.kr(rate).range(0, 1).squared;in=in*GrayNoise.ar(noizy, 1 - noizy)},
	\tanh: { |in, noizy = 0.5| OnePole.ar((in * 10).tanh * 0.3, 0.5)},
	\wah: { |in, rate = 2, depth = 0.5, gain = 3| (Ringz.ar(in, VarSaw.kr(2, 0, 0.1, depth).lag(0.1).exprange(200, 5000), 0.003) * gain).tanh.lag(0.0003) / gain.sqrt},

// Chorus & FM mod
	\choruscompress: {|in| var source = in; var chorus;
	chorus= Splay.ar(Array.fill(4,{
		var maxdelaytime= rrand(0.005,0.02);
		DelayC.ar(source[0], maxdelaytime, LFNoise1.kr(Rand(0.1,0.6), 0.25*maxdelaytime, 0.75*maxdelaytime) )
	})); chorus = Compander.ar(4*(source + chorus),source,0.4,1,4);
	chorus },
	\chorus: { |in| Mix.fill(7, { var maxdelaytime= rrand(0.005,0.02); DelayC.ar(in, maxdelaytime, LFNoise1.kr( Rand(4.5,10.5), 0.25, 0.75) * maxdelaytime	)})},
	\ringmod: { |in, randrate=5|  in.asArray[0] 	// force mono inputs
		* SinOsc.ar(LFNoise1.kr([randrate, randrate]).exprange(300, 3000)).sum },
	// ADCs Dual Band Compression, limiting is below because it is an extra new class!
	\dualcomp: { |in, xfreq = 300,
	lflim = 0.7, hflim = 0.3, lfgain = 1.0, hfgain = 1.0|
	DualBandComp.ar(in, xfreq, lflim, hflim, lfgain, hfgain);
},

// DELAY & REVERBERATION
	\delay: {|in, dt=0.1, dcy=1| CombC.ar(in,dt,dt,dcy)},
	\delayRand0: {|in, dt=0.1, dcy=1| CombC.ar(in,dt,dt*LFNoise0.kr(dt,0.1,0.102).lag(dt),dcy)},
	\delayRand2: {|in, delay=0.25, dcy=2| delay=LFNoise2.kr(delay,delay/3,delay); CombC.ar(in,delay,delay,dcy)},
	// rhythmical to Masterclock
	\delay2: {|in| var delay=DelayC.ar(in[0].distort,t.tempo/2,t.tempo/2); delay},
	\delay4: {|in| var delay=DelayC.ar(in[0].distort,t.tempo/2,t.tempo/2); delay},
	\delay3: {|in, dt=0.1, dcy=1| CombC.ar(in,dt,t.tempo/3,dcy)},
	\delay6: {|in, dt=0.1, dcy=1| CombC.ar(in,dt,t.tempo/6,dcy)},
	\delay9: {|in, dt=0.1, dcy=1| CombC.ar(in,dt,t.tempo/9,dcy)},
	\pitchshift: { |in, freq = 1, pitch = 2| var fx = { |n| PitchShift.ar(PitchShift.ar(in[0], 2.9, LFNoise1.kr(freq).range(0, n-1), 0.01, 0.05), 1.9, pitch % 4 , 0.01, 0.05)}!4; Mix.new(fx)},
	\gverb: { |in, room=50, earlyRef=(-9), tail=(-12), amp=0.5| GVerb.ar(BPeakEQ.ar(in[0], 4000.0, 0.5, -6), roomsize: room, earlyreflevel: earlyRef.dbamp, taillevel: tail.dbamp, mul: amp)},
	\adcverb: { |in, revTime = 3, drift = 0.1, rate = 0.1| AdCVerb.ar(in*0.05, revTime, nOuts: 4, combScale: LFDNoise3.kr(rate, drift.clip2(0.9), 1))},

	// AMP MODULATIONS
	\strobe: { |in, rate=8, width=0.5| in * LFPulse.kr(rate, 0, width)},
	\strobe3: { |in, rate=3, width=0.5| in * LFPulse.kr(t.tempo * rate, 0, width)},
	\strobe16: { |in, rate=8, width=0.5| in * LFPulse.kr(t.tempo * rate, 0, width)},
	\lfosaw: { |in,rate=1| in * LFSaw.kr(rate*t.tempo,0,0.5,0.5)},
	\lfosaw3: { |in,rate=1| in * LFSaw.kr(rate*t.tempo * 2/3,0,0.5,0.5)},
	\lfosin: { |in,rate=1| in * SinOsc.kr(rate*t.tempo*0.5,pi/2,0.5,0.5)},
	\lfosin3: { |in,rate=1| in * SinOsc.kr(rate*t.tempo*2/3,pi/2,0.5,0.5)},

	// LIMITING
    \rollClip: { |in, clip=0.99, pole=0.2| OnePole.ar(in.clip2(clip), pole ** 0.7); },
    \ampFin: { |in, limDrive=1, ampLimit=0.8, postAmp=1 | Limiter.ar(in * limDrive, ampLimit) * postAmp; },


);

// and specs for them (e.g. for gui control)
// incomplete acc. to above...
Spec.add(\leak, [0.5, 0.999, \exp]);
Spec.add(\clip, [0.0, 1, \amp]);
Spec.add(\pole, [0, 0.95, \lin]);
Spec.add(\bits, [16, 1]);
Spec.add(\tempo, [0.1, 10, \lin]);
Spec.add(\downsamp, [1, 100, \exp]);
Spec.add(\limDrive, \ampx4);
Spec.add(\ampLimit, \amp);
Spec.add(\postAmp, \ampx4);

Spec.add(\xfreq, [100, 1000, \exp]);
Spec.add(\lflim, [0, 1, \amp]);
Spec.add(\hflim, [0, 1, \amp]);
Spec.add(\lfgain, [0, 4, \amp]);
Spec.add(\hfgain, [0, 4, \amp]);
);


(
// some Effects better for FilterIn Functionality
q.filterIns = (
	\riseComb5: { arg in, delay = 0.023, dlDrift = 0.02, spread=0.5,
		decayRise=0.5, decayFall=100;
		var delayscales = 2 ** ((0 .. q.numChans - 1) * 2 / (q.numChans - 1) - 1 * spread);
		var dels = delayscales.scramble.collect { |dscale|
			var timedrift = LFDNoise3.kr(0.3, dlDrift, 1) * dscale;
			var ampcomp = (20 * decayRise).dbamp * (decayFall ** -0.25);
			var combs;
			in = in.asArray[0] * ampcomp.lag(0.2);
			combs = (decayFall * [ 1, decayRise]).collect { |decay|  CombL.ar(in, 1, delay * dscale, decay * delay) }; combs[0] - combs[1];	// combs come in slowly, like formlet.
		}; SplayAz.ar(4,dels) }
);


// and the specs for them
//Spec.add(\dt, [0.001, 0.2, \exp]);
//Spec.add(\dc, [0.01, 100, \exp]);
Spec.add(\spread, [0, 1, \amp]);
Spec.add(\decayRise, [0, 0.9, \amp]);
Spec.add(\decayFall, [1, 1000, \exp]);
Spec.add(\dlDrift, [0, 0.1, \amp]);
);

// dirty! WORKAROUND for now...
(
if(Class.allClasses.matchItem(\DualBandLim.asClass)) {
	ProxyChain.add(\dualim, \filter -> { |in, xfreq = 300,
	lflim = 0.7, hflim = 0.3, lfgain = 1.0, hfgain = 1.0|
	(\DualBandLim.asClass).ar(in, xfreq, lflim, hflim, lfgain, hfgain);
	} )};
);
// add our created dict of filter functions to the ProxyChain
(
// ProxyChain.clear;
// Make also the global ProxyChain with these effects
q.filters.keysValuesDo{|key, value| ProxyChain.add( key, \filter -> value)};
q.filterIns.keysValuesDo{|key, value| ProxyChain.add( key, \filterIn -> value)};
);


// optional: create a sound source for testing (a dust):
(
// add specs for the controls used (for NodeProxyEditor).
Spec.add(\dens, [0.1, 1000, \exp]);
Spec.add(\dustamp, [0, 1, \amp]);
Spec.add(\dustdec, [0.0001, 1, \exp]);
Spec.add(\dustfreq, \freq);

ProxyChain.add(
	\dust, \mix -> { |dens=20, dustdec=0.02, dustfreq= 600|
		Ringz.ar(Dust.ar(dens).lag(0.0001), dustfreq, dustdec)
	}
);
);

//////////////////////////////////////////////////
// Now use a MasterFX
// (basically similar, but ProxyChain can be added to individual Ndefs only (like bus/aux-effects)
/*
m = MasterFX(s, 2, [\dualim, \dualcomp]);
m = MasterFX.all[s.name];
m.gui(numItems: 12);
*/

(
// The order in slotNames determines order of execution of the fx!!
MasterFX.clear; // clean up old ones first
try {q.masterFXGui.close}; // and old guis
q.masterFX = MasterFX.new(server: s,
    numChannels: q.numChans,
    slotNames: [\hpf, \lpf, \delay, \tanh, \leakDC, \krush, \strobe3, \adcverb, \ampFin, \dualim, \dualcomp],
    busIndex: 0
);
q.masterFXGui = q.masterFX.gui; // make a new GUI
);
q.postfx = { q.filters.keys.asArray.sort; };

/*
(
//Example Code for creating an Effects line from an already existing Ndef:
Ndef(\dust, { |dens=20, dustdec=0.02, dustfreq= 600|
		Ringz.ar(Dust.ar(dens).lag(0.0001), dustfreq, dustdec)
});
// here you name all the effects you want to have in your chain!
c=ProxyChain.from(Ndef(\dust), [\ringmod, \distortion, \riseComb5, \ampFin]);
c.gui;
)

c.play;
c.end;
// kick effect in with given dry/wet
c.add(\riseComb5, 0.5);
c.remove(\riseComb5); // and out

*/