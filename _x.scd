// wavetraveler application.
/*
	first implementation using environment vars.
	should wrap in a class when "finished"
*/

// external execution 
x = { |p| this.executeFile(Document.current.dir ++"/" ++ p); };


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
Routine {

	s.freeAll;

	w = Array.fill(~num_voices, { WaveTravelVoice.new(s); });

	// fill list of buffers from directory of soundfiles
	// this will crap out with enough files (hundreds or thousands)
	~bufs = List.new;
	// FIXME: (i guess) - won't work on windows. use Platform
	p = Pipe.new("ls " ++ ~src_dir, "r");
	~filename = p.getLine;
	while( {~filename.notNil }, {
		~bufs.add( Buffer.read(s, ~src_dir ++ "/" ++ ~filename) );
		~bufs.add( Buffer.read(s, ~src_dir ++ "/" ++ ~filename) );
		~filename = p.getLine;
		~filename.postln;
	});
	p.close;

	// UI

	// define glue
	x.value("ui.scd");

	// instantiate graphics
	{ x.value("gfx.scd"); }.defer;
	

	// MIDI
	//	x.value("midi.scd");

	// initial values.. ?? 
	

}.play;



/*

	midi interface:

	first key press chooses trajectory 
	2nd key plays sound at given trajectory



~route_data
~route_data[~ui_route_select].times
~slider_channel[0].value
*/

// touchOSC