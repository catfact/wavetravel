/*
	classes for wavetraveler SC application

	goes in SC extensions library
	on my system this seems to be ~/.local/share/SuperCollider/Extensions
	mac will be /Library/Application\ Support/SuperCollider ... or something.
*/

// POD class to store a travel route
WaveTravelRoute {
	/// 4 arbitrary speaker positions
	var <>targets;
	/// 3 pan times
	var <>times;
	// fade in/out times
	var <>fadeIn = 2.0;
	var <>fadeOut = 4.0;
	/// number of loops
	var <>numLoops = 1;

	*new {
		^super.new.init();
	}

	init {
		/// FIXME: should parameterize sequence length, i guess
		/// 4 node targets
		targets = [0, 1, 0, 1];
		/// 4 fade times; last one is used when looping
		times = [0.5, 0.5, 0.5, 0.5];
	}
}

// a single "voice" that plays back an audio buffer
// with arbitrary "12-choose-2" pan-envelope thing.

WaveTravelVoice {
	// server
	var server;
	// buffer index
	var <>buf;
	// 12-channel control bus for output levels
	var <>ampBus;
	// sequence data
	var <>route;
	// fade group
	var <>fadeGroup;
	// playback group
	var <>playGroup
	// output channel offset
	var <>outOffset = 0;

	/// TODO:
	// do we need a handle to 1-shot synths?
	// do we need a nodewatcher for UI feedback?
	// classvar waveTravelVoiceWatcher;

	*new { arg serv;
		^super.new.init(serv);
	}

	init { arg s;
		server = s;

		Routine.new({
			if(s.serverRunning.not, {
				s.boot;
				s.sync;
			});

			// buffer playback synth
			// one-shot with duration
			SynthDef.new(\waveTravelPlay, {
				arg out, buf, 
				amp = #[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				dur=1.0, pos=0.0, rate=1.0,
				atk = 0.1, rel=0.1, curve=\welch;
				var ampenv, play;

				ampenv = EnvGen.ar (
					Env.linen ( 
						attackTime:atk, 
						// sustainTime:dur - atk - rel, 
						// actually add atk and rel to the duration.
						// result is a sort of delayed crossfade
						sustainTime:dur, 
						releaseTime:rel, 
						curve:curve
					), doneAction:2 
				);
				play = PlayBuf.ar(
					numChannels:1, 
					bufnum:buf, 
					startPos:pos, 
					rate:rate * BufRateScale.kr(buf)
				);
				Out.ar( out, play * ampenv * amp ); 
			}).send(s);
			
			//			s.sampleRate.asFloat.postln;
			//			s.options.blockSize.asFloat.postln;

			// control-rate fade synths
			// a one-shot control-rate envelope
			SynthDef.new(\fadeEnv, { arg out, dur, start=0.0, end=1.0, curve=\welch;
				var env = Env.new([start, end], [dur], curve);
				ReplaceOut.kr(out, EnvGen.kr(env, doneAction:2));
			}).send(s);

			// 12-channel amplitude bus
			ampBus = Bus.control(s, 12);

			route = WaveTravelRoute.new;

			fadeGroup = Group.new(s);
			playGroup = Group.new(s);

		}).play; // init routine

	}

	//	WaveTravel.play(position, rate)
	// start a note-sequence playing
	// note: position is given in samples!
	// spec for the instrument doesn't provide start position,
	// so i guess its no big deal.
	play { arg pos = 0.0, rate=1.0, atk=0.5, rel=0.5, curve=\welch;
		var syn;
		
		postln("playing buffer: "++buf);

		Routine {
			// fade in from the position argument.
			syn = Synth.new(\waveTravelPlay, [
				\dur, route.fadeIn, 
				\buf, buf, \pos, pos, \rate, rate,
				\atk, atk, \rel, rel, \curve, \exp,
				\out, outOffset
			], playGroup).map(\amp, ampBus);

			postln("\r\n fading in, target: "++route.targets[0]++" ; time: "++ route.fadeIn);
			
			Synth.new(\fadeEnv, [
				\out, ampBus.index + route.targets[0],
				\start, 0.0,
				\end, 1.0,
				\dur, route.fadeIn,
				\curve, curve
			], fadeGroup);

			route.fadeIn.wait;
			
			// loop back to the position reached at the end of fadein... 
			// not totally sure this was the desired behavior...
			// but looping back to the fadein position seems weird.
			pos = pos + (route.fadeIn * buf.sampleRate);

			route.numLoops.do({ arg loop;
				var dur; // duration of sample playback for this loop
				var n; // number of nodes to process in this loop
				var lastLoop = (loop == (route.numLoops - 1));
				if(lastLoop, {
					dur = route.times[1..3].sum + route.fadeOut;
					n = 3;
				}, {
					dur = route.times.sum;
					n = 4;
				});

				// play the sample
				syn = Synth.new(\waveTravelPlay, [
					\dur, dur, 
					\buf, buf, \pos, pos, \rate, rate,
					\atk, atk, \rel, rel,
					\out, outOffset
				], playGroup).map(\amp, ampBus);
				
				postln("\r\n playing sample, duration: "++ dur);
				postln("");

				// process nodes
				n.do({ arg node;
					var target, time;
					target = route.targets.wrapAt(node + 1);
					time = route.times.wrapAt(node + 1);	
					post("\r\n node index: "++node++
						" ; target: "++target++" ; time: "++time);
					
					// kill any running fades
					fadeGroup.freeAll;
					server.sync;

					// fade out the last channel and fade in the new one.
					ampBus.getn(12, {
						arg val; // array of bus values		
						postln("");
						postln("crossfading, bus values: " ++ val);
						val.do({ arg v, i;
							if(i == target, {
								// fade in the target bus
								Synth.new(\fadeEnv, [
									\out, ampBus.index + i,
									\start, v,
									\end, 1.0,
									\dur, time,
									\curve, curve
								], fadeGroup);	
							}, {	
								// fade out everything else that's non-zero
								if(v > 0.0, {
									Synth.new(\fadeEnv, [
										\out, ampBus.index + i,
										\start, v,
										\end, 0.0,
										\dur, time,
										\curve, curve
									], fadeGroup);	
								});
							});
						});
						
					});
					time.wait;
				});

				if(lastLoop, {
					postln("");
					postln("fadeout, time: "++route.fadeOut);

					// kill any running fades
					fadeGroup.freeAll;
					server.sync;
					ampBus.getn(12, {
						arg val; // array of bus values		
						val.do({ 
							arg v, i;
							postln("\r\n fading out; bus index: "++i++" ; value: "++v);
							// fade out all nonzero busses
							if(v > 0.0, {
								Synth.new(\fadeEnv, [
									\out, ampBus.index + i,
									\start, v,
									\end, 0.0,
									\dur, route.fadeOut,
									\curve, \exp
								], fadeGroup);
							});
						});
					});
				});
			}) // loops

		}.play;
} // WaveTravelVoice.play
}				

// UI class...

// application class...