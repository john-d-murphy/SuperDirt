/*

Add your own instruments here.
They can be used in Tidal just as samples (ignoring the sample number, so instead of "bd:2" write "inr")

// supported parameters are e.g.
// sustain, speed, endSpeed, begin, end, pan, accelerate, offset, cps
// all instruments ought to use: out

If your SuperDirt instance is assigned to the variable ~dirt, you can livecode these synths.
*/

(




// modulated band limited impulse
(
SynthDef(\imp, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset|
	var env, sound, rate, phase;
	env = EnvGen.ar(Env.perc(0.01, 0.99, 1, -1), timeScale:sustain, doneAction:2);
	phase = Line.kr(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));
	sound = Blip.ar(rate.linexp(0, 1, 1, freq) * [1, 1.25, 1.51, 1.42], ExpRand(80, 118) * phase).sum;
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);


// modulated phase mod sines
(
SynthDef(\psin, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset, modfreq = 40|
	var env, sound, rate, phase, amp;
	amp = AmpCompA.kr(freq);
	env = EnvGen.ar(Env.perc(0.002, sustain, 1, -1), doneAction:2);
	phase = Line.ar(begin, end, sustain);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// cursor modulated phase mod sines
(
SynthDef(\pmsin, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset|
	var env, sound, rate, phase, modfreq, amp;
	freq = (MouseX.kr(30, 80).round + freq);
	modfreq = MouseY.kr(1, 200, 1);
	amp = AmpCompA.kr(freq);
	env = EnvGen.ar(Env.perc(0.002, sustain, 1, -1), doneAction:2);
	phase = Line.ar(begin, end, sustain);
	rate = speed + Sweep.kr(1, accelerate);
	sound = SinOsc.ar(freq, SinOsc.ar(modfreq * (1..5), 0, 1 - phase * 10 * env / (1..5), 0.5pi)).sum;
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// live audio input
(
SynthDef(\in, { |out, sustain = 1, pan, inputFadeTime = 0.03|
	var env, sound;
	env = Env.linen(inputFadeTime, sustain - (2 * inputFadeTime), inputFadeTime).kr;
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = sound * env;
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add
);

// read input from nth routing bus
// see also: effect "to"
(
SynthDef(\dirt_from, { |out, sustain = 1, in, pan, inputFadeTime = 0.03|
	var env, sound;
	env = Env.linen(inputFadeTime, sustain - (2 * inputFadeTime), inputFadeTime).kr;
	sound = InFeedback.ar(in, ~dirt.numChannels);
	sound = sound * env;
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;

~dirt.soundLibrary.addSynth(\from,
	(
		instrument: \dirt_from,
		in: {
			~dirt.audioRoutingBusses.wrapAt(~from ? 0).index
		}
	)
)
);

// panic button - equivalent of ctrl-.
(
~dirt.soundLibrary.addSynth(\superpanic, (play: { ~dirt.orbits.do(_.freeSynths) }))
);

// pitch shifted live audio input
(
SynthDef(\inr, { |out, sustain = 1, freq = 440, speed = 1, begin=0, end=1, pan, accelerate, offset, inputFadeTime = 0.03|
	var env, sound, rate, phase;
	env = Env.linen(inputFadeTime, sustain - (2 * inputFadeTime), inputFadeTime).kr;
	phase = Line.ar(begin, end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate)) * freq / 440;
	sound = SoundIn.ar([0, 1]); // stereo in
	sound = sound * env;
	sound = PitchShift.ar(sound, 0.1, rate, 0.02, 0.01);
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add
);

// gabor grain
(
SynthDef(\gabor, { |out, sustain = 0.03, freq = 440, pan = 0, width = 0.3|
	var env, sound;
	sound = SinOsc.ar(freq, 0.5pi);
	env = LFGauss.ar(sustain, width, loop: 0).range(0, 1);
	Out.ar(out,
		DirtPan.ar(env * sound, ~dirt.numChannels, pan)
	)
}).add;
);

// dirac delta function approximation
(
SynthDef(\dirac, { |out, sustain = 0.03, pan = 0|
	Out.ar(out,
		DirtPan.ar(Impulse.ar(0), ~dirt.numChannels, pan)
	)
}).add;
);

// shepard on a cycle
(
SynthDef(\cyclo, { |out, freq, sustain = 1, speed = 1, begin = 0, end = 1, pan, accelerate, cycle, ratio = 1|
	var env, sound, rate, phase;

	env = EnvGen.ar(Env.perc(0.01, 0.99, 1, -1), timeScale:sustain, doneAction:2);
	phase = Line.kr(begin, 1 - end, sustain);
	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));

	freq = (cycle * speed) % ((1..16) * ratio + phase) + 1 * freq * rate;

	sound = SinOsc.ar(freq).mean;
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan, env)
	)
}).add
);

// debug a few time related values
(
SynthDef(\debug, { |begin = -1, end = -1, delta = -1, sustain = -1, unitDuration = -1, cycle = -1|
	cycle.poll(Impulse.kr(0), label: "cycle");
	begin.poll(Impulse.kr(0), label: "begin");
	end.poll(Impulse.kr(0), label: "end");
	delta.poll(Impulse.kr(0), label: "delta");
	sustain.poll(Impulse.kr(0), label: "sustain");
	unitDuration.poll(Impulse.kr(0), label: "unitDuration");
	DC.kr(0).poll(Impulse.kr(0), label: "\n\n");
}).add
);

)
