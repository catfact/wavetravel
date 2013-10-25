/*
	classes for wavetraveler SC application

	goes in SC extensions library
	on my system this seems to be ~/.local/share/SuperCollider/Extensions
	mac will be /Library/SuperCollider ... ??
*/

// POD class to store a travel route
WaveTravelRoute {
	/// 4 arbitrary speaker positions
	var <>targets;//[0, 1, 0, 1];
	/// 3 pan times plus fade in/out
	var <>times;// = #[2, 1, 1, 1, 2];
	/// number of loops
	var <>numLoops = 1;

	*new {
		^super.new.init();
	}

	init {
		/// FIXME: should parameterize sequence length, i guess
		targets = [0, 1, 0, 1];
		times = [2, 1, 1, 1, 2];
	}
}

// a single "voice" that plays back an audio buffer
// with arbitrary "12-choose-2" pan-envelope thing.

WaveTravelVoice {
	// buffer index
	var <>bufnum = -1;
	// 12-channel control bus for output levels
	var <ampBus;
	// sequence data
	var <route;

	// quarter-sine and quarter-cosine buffers.
	/// FIXME: don't actually need these for each voice.
	//// not that it really matters.
	var <sinBuf;
	var <cosBuf;

	// groups for routing : input, process, output
	var <ig, <xg, <og;

	// fade buffer size
	var <fadeBufSize = 2048;

	/// TODO:
	// do we need a handle to 1-shot synths?
	// do we need a nodewatcher for UI feedback?
	// classvar waveTravelVoiceWatcher;

	*new { arg serv;
		^super.new.init(serv);
	}

	init { arg s;
		
		Routine.new({
			if(s.serverRunning.not, {
				s.boot;
				s.sync;
			});

			// buffer playback synth
			// one-shot with duration
			SynthDef.new(\waveTravelPlay, {
				arg out, bufnum, 
				amp = #[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				dur=1.0, pos=0.0, rate=1.0,
				atk = 0.1, rel=0.1, curve=\cubed;
				var ampenv, play;

				ampenv = EnvGen.ar (
					Env.linen ( 
						attackTime:atk, 
						// sustainTime:dur - atk - rel, 
						// actually add atk and rel to the duration.
						// result is a delayed crossfade
						sustainTime:dur, 
						releaseTime:rel, 
						curve:curve
					), doneAction:2 
				);
				play = PlayBuf.ar(numChannels:1, bufnum:bufnum, startPos:pos, rate:rate);
				Out.ar( out, play * ampenv * amp ); 
			}).send(s);
			
			s.sampleRate.asFloat.postln;
			s.options.blockSize.asFloat.postln;


			// control-rate fade synths
			// a one-shot control-rate envelope
			//// FIXME: this default curve setting is not really doing it.
			////// sounds like a dip in power at the middle of the xfade.
			SynthDef.new(\fadeEnv, { arg out, dur, start=0.0, end=1.0, curve=\sine;
				var env = Env.new([start, end], [dur], curve);
				ReplaceOut.kr(out, EnvGen.kr(env, doneAction:2));
			}).send(s);

			// 12-channel amplitude bus
			ampBus = Bus.control(s, 12);

			route = WaveTravelRoute.new;

			ig = Group.new(s);
			xg = Group.after(ig);
			og = Group.after(xg);

		}).play; // init routine

	}

	//	WaveTravel.play(position, rate)
	// start a note-sequence playing
	// note: position is given in samples!
	play { arg pos = 0.0, rate=1.0, atk=0.5, rel=0.5, curve=\cub;
		Routine ({
			var time, syn, dur, target, prev;
			if(route.numLoops > 1, {
				postln("performing multiple loops.");
				// if there is more than one loop...
				dur = route.times[0..3].sum;

				// spawn synth for first loop
				syn = Synth.new(\waveTravelPlay, [
					\bufnum, bufnum, \dur, dur, \pos, pos, \rate, rate,
					\atk, atk, \rel, rel, \curve, curve
				]).map(\amp, ampBus);
					
				// fade in
				postln("fading in.");
				target = route.targets[0];
				time = route.times[0];
				this.fadeIn(target, time);
				time.wait;
				// finish first loop
				3.do({ arg i;
					postln("finish first loop, node " ++ (i+1));
					prev = target;
					target = route.targets[i+1];
					time = route.times[i+1];
					this.pan(prev, target, time);
					time.wait;
				});
				// perform remaining loops
				postln("performing remaining loops.");
				(route.numLoops - 1).do({ arg i;
					if (i == (route.numLoops - 2), {
						// last loop, duration includes fadeout
						dur = route.times.sum;
					});
					postln("loop count: " ++ (i+1));
					4.do({ arg i;
						// spawn synth for this loop
						syn = Synth.new(\waveTravelPlay, [
							\bufnum, bufnum, \dur, dur, \pos, pos, \rate, rate,
							\atk, atk, \rel, rel, \curve, curve
						]).map(\amp, ampBus);

						postln("node: " ++ (i+1));
						prev = target;
						target = route.targets[i];
						time = route.times[i];
						postln(" [ prev, target, time: ] : " ++ [prev, target, time]);
						this.pan(prev, target, time);
						time.wait;
					});
				});
			}, {
				// if this is the only loop, do the same thing,
				// except with no loops and fadeout at the end
				postln("performing single loop..");
				dur = route.times[0..3].sum;
				// spawn synth
				syn = Synth.new(\waveTravelPlay, [
					\bufnum, bufnum, \dur, dur, \pos, pos, \rate, rate,
					\atk, atk, \rel, rel, \curve, curve
				]).map(\amp, ampBus);
				// fade in
				postln("fading in...");
				target = route.targets[0];
				time = route.times[0];
				this.fadeIn(target, time);
				time.wait;
				// finish first loop
				3.do({ arg i;
					postln("node: " ++ (i+1));
					prev = target;
					target = route.targets[i+1];
					time = route.times[i+1];
					postln(" [ prev, target, time: ] : " ++ [prev, target, time]);
					this.pan(prev, target, time);
					time.wait;
				});			
				// perform fadeout
				this.fadeOut(route.times[4]);
			});

		}).play;
	} // .play


	// WaveTravel.pan(target, value)
	// pan/fadein
	pan { arg prev, target, time;
		
		//		var maxIdx, maxVal;
		// find index of bus with highest value
		ampBus.getn(12, {
			arg val; // array of bus values		
			// fade out
			Synth.new(\fadeEnv, [
				\out, prev,
				\start, val[prev], 
				\end, 0.0,
				\dur, time
			]);
			// fade in
			Synth.new(\fadeEnv, [
				\out, target,
				\start, val[target],
				\end, 1.0,
				\dur, time
			]);
		});
	} // .pan

	// fadein
	fadeIn { arg target, time;
		// fade in
		Synth.new(\fadeEnv, [
			\buf, sinBuf.bufnum, 
			\out, target, 
			\start, 0.0,
			\end, 1.0,
			\dur, time
		]);
	} // .fadeIn

	// fadeout
	fadeOut { arg time;	
		// if any bus is nonzero, fade it out
		ampBus.getn(12, {
			arg val; // array of values
			val.do({ arg v, i;
				if(v > 0.0, {
					Synth.new(\fadeEnv, [
						\out, i,
						\start, v,
						\end, 0.0,
						\dur, time
					]);
				});
			});
		});
	} // .fadeOut

}

// UI class...

// application class...