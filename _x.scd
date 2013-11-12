// wavetraveler application.
/*
	top-level execution script.

	first implementation using environment vars.
	should wrap in a class when "finished"

*/

// path of this document:
// Document class seems pretty broken on mac, sc3.6
/// hm, actually it seems intermittently broken everywhere? damn

/// so, instead of doing this:
//x = { |p| this.executeFile(Document.current.dir ++"/" ++ p); };

// we have to do this and change it manually
//~topdir = "/Users/don\ buchla/Desktop/wavetravel-master";
~topdir = "/home/emb/sc/wavetravel";

// external execution function
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
~src_dir = 	"/home/emb/snd/src";
//~src_dir = ~topdir ++ "/snd";


Routine {
	s = Server.local;
//	s.freeAll;

	s.waitForBoot {

		w = Array.fill(~num_voices, { WaveTravelVoice.new(s) });
		s.sync;
		// empty list, use GUI to populate
		~bufs = List.new;

		postln("///////////////
////////////////////////
//// initializing ui... 
");

		x.postln;

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
