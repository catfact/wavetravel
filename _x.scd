// wavetraveler application.
/*
	top-level execution script.

	first implementation using environment vars.
	should wrap in a class when "finished"

*/

// external execution
~topdir = "/Users/don\ buchla/Desktop/wavetravel-master";
// Document class seems pretyt broken on mac, sc3.6
//x = { |p| this.executeFile(Document.current.dir ++"/" ++ p); };
x = { |p| this.executeFile(~topdir ++"/" ++ p); };


//////////////////////////
/// FIXME: bad practice to use global env variables.
/// included files may or may not assume the existence of these.
/// should wrap in e.g. WaveTravelApp
/// globals
~num_voices = 6;
~num_channels = 12;
~num_routes = 32;
// arbitrary large collection of routes
~route_data = Array.fill(~num_routes, { WaveTravelRoute.new });
// index in the route data array for each voice
// rather inefficiently copy the selected route data to the voice when it changes.
~route_idx = Array.fill(~num_voices, { |i| i });
// slected sound for voice
~buf_idx = Array.fill(~num_voices, { 0 });
/////////////////////////

// path for sound files
//~src_dir = 	"/home/emb/snd/src";
~src_dir = ~topdir ++ "/snd";


Routine {
	s = Server.local;
//	s.freeAll;

	s.waitForBoot {

		w = Array.fill(~num_voices, { WaveTravelVoice.new(s) });
		w.do({ arg voice, i; voice.run(s); });
		s.sync;
		// fill list of buffers from directory of soundfiles
		// this will crap out with enough files (hundreds or thousands)
		~bufs = List.new;

		// FIXME: (i guess) - won't work on windows. use Platform

		postln("searching for sounds in : " ++ ~src_dir);

	/*
		p = Pipe.new("ls " ++ ~src_dir, "r");
		~filename = p.getLine;
		while( {~filename.notNil }, {
		~bufs.add( Buffer.read(s, ~src_dir ++ "/" ++ ~filename) );
		~filename = p.getLine;
		~filename.postln;
		});
		p.close;
*/

		/// ughh...
		// Pipe wont work cause don's home directory has a space in its name.
		// awesome
		~bufs.add( Buffer.read(s, ~src_dir ++ "/" ++ "261.wav") );
		s.sync;


		// UI
		// define glue
		x.value("ui.scd");
		// instantiate graphic widgets
		{ x.value("gfx.scd"); }.defer;

		// MIDI
		//	x.value("midi.scd");

		// initial values.. ??
	}


}.play;