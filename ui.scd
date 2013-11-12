// state variables
~ui_voice_select = 0;
~ui_route_select = 0;
~ui_node_select = 0;

///// handler functions
~handle_select_voice = { arg val;
	~ui_voice_select = val;
	~ui_route_select = ~route_idx[val];
	~refresh_select_voice.value();
	~refresh_select_route.value();
	~refresh_sound.value();
	~refresh_loop.value();
};

~handle_select_route = { arg val;
	~ui_route_select = val;
	~route_idx[~ui_voice_select] = val;
	w[~ui_voice_select].route = ~route_data[~route_idx[~ui_voice_select]];
	~refresh_select_route.value();
	~refresh_loop.value();
 };

 ~handle_sound = { arg val;
	 //	postln("handle sound");
	 //	~ui_sound_select = val;
	 ~buf_idx[~ui_voice_select] = val;
	 w[~ui_voice_select].buf = ~bufs[val];
	 ~bufs[val].postln;
	 // making sound selection independent of route selection per voice
	 ~refresh_sound.value();
 };

 ~handle_node_channel = { arg i, val; 
	 /// set route data
	 ~route_data[~ui_route_select].targets[i] = val;
	 // set voice
	 w[~ui_voice_select].route.targets[i] = val;
	 ~refresh_node_channel.value(i);
};

~handle_node_time = { arg i, val;
	// set route data
	~route_data[~ui_route_select].times[i] = val;
	// set voice
	w[~ui_voice_select].route.times[i] = val;
};


~handle_fadein = { arg val;
	// set route data
	~route_data[~ui_route_select].fadeIn = val;
	// set voice
	w[~ui_voice_select].route.fadeIn = val;
};

~handle_fadeout = { arg val;
	// set route data
	~route_data[~ui_route_select].fadeOut = val;
	// set voice
	w[~ui_voice_select].route.fadeOut = val;
};


~handle_loop = { arg i, val;
	~route_data[~ui_route_select].numLoops = val;
	w[~ui_voice_select].route.numLoops = val;
};


///// refresh functions
~refresh_select_voice = {
	//...
};

~refresh_select_route = {
	4.do({ arg i;
		~refresh_node_channel.value(i);
		~refresh_node_time.value(i);
		~refresh_node_loop.value(i);
	});
	~knob_route.value_(~ui_route_select);
};

~refresh_sound = { 
	~knob_sound.value_(~buf_idx[~ui_voice_select]);
	~knob_sound.unitView.string_(
		PathName.new(~bufs[~buf_idx[~ui_voice_select]].path).fileName
	);
};

~refresh_node_channel = { arg i;
	~slider_channel[i].value_(~route_data[~ui_route_select].targets[i]);
};

~refresh_node_time = { arg i;
	~knob_time[i].value_(~route_data[~ui_route_select].times[i]);
};


~refresh_node_fadein = {
	~knob_fadein.value_(~route_data[~ui_route_select].fadeIn);
};

~refresh_node_fadeout = {
	~knob_fadeout.value_(~route_data[~ui_route_select].fadeOut);
};


~refresh_loop = {
	~knob_loop.value_(~route_data[~ui_route_select].numLoops);
};