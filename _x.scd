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

// we have to do this and change it manually... 
//~topdir = "/Users/don\ buchla/Desktop/wavetravel-master";
~topdir = "/home/emb/sc/wavetravel";

// external execution function
x = { |p| this.executeFile(~topdir ++"/" ++ p); };

//////////////////////////
/// FIXME: bad practice to use global env variables.
/// included files may or may not assume the existence of these.
/// should wrap in e.g. WaveTravelApp
/// this will also make it easy to archive the state of the app.

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

Routine {
	s = Server.local;
	s.freeAll;

	s.waitForBoot {

		w = Array.fill(~num_voices, { WaveTravelVoice.new(s) });
		s.sync;
		// empty list, use GUI to populate
		~bufs = List.new;

		x.postln;

		// UI
		// define glue
		x.value("ui.scd");
		// instantiate graphic widgets
		{ 
			x.value("gfx.scd"); 
			// select 1st value for editing and update widgets
			~handle_select_voice.value(0); 
		}.defer;

		
		
		// MIDI
		//	x.value("midi.scd");

		// initial values.. ??
	}


}.play;





// fn to archive the current state of the application
~write_archive  = {
	// TODO: use a monolithic application class and .writeArchive
};


// fn to extract state of application from archive, 
~read_archive  ={
	// TODO: use a monolithic application class and .readArchive
};
