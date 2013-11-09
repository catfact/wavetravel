
// window
~win = Window.new("wave traveller", Rect(0, 0, 900, 600));
~win.view.background = Color.fromHexString("#112244");
~win.view.decorator = FlowLayout(~win.view.bounds, 10@10, 10@10);
~win.front;


// play button
~button_play = Button(~win, 880 @ 40);

~button_play.states = [
	[" play ", Color.fromHexString("#8888ff"), Color.fromHexString("#444499") ]
];

~button_play.action_({
	arg but;
	/// FIXME: must add playback position, i think
	w[~ui_voice_select].play;
});

// voice selection
~knob_voice = EZKnob(
	parent:~win, 
	bounds:160@180, 
	knobSize:150@150, 
	label:"voice",
	layout:\vert2,
	controlSpec:ControlSpec( 0, ~num_voices- 1, step:1 )
).setColors(
	stringBackground:Color.fromHexString(	"#333344"),
	stringColor:Color.fromHexString(		"#ffffff"), 
	numBackground:Color.fromHexString(		"#112244"), 
	numStringColor:Color.fromHexString(		"#ffffff"), 
	numNormalColor:Color.fromHexString(		"#ffffff"), 
	numTypingColor:Color.fromHexString(		"#ffaaaa"), 
	knobColors: [Color.fromHexString("#aa4477"), Color.fromHexString("#992244") ],
	background:Color.fromHexString(			"#333355")
).action = { arg ez;
	~handle_select_voice.value(ez.value);
};

// route selection knob
~knob_route = EZKnob(
	parent:~win, 
	bounds:160@180, 
	knobSize:150@150, 
	label:"route",
	layout:\vert2,
	controlSpec:ControlSpec( 0, ~num_routes - 1, step:1 )
).setColors(
	stringBackground:Color.fromHexString(	"#333344"),
	stringColor:Color.fromHexString(		"#ffffff"), 
	numBackground:Color.fromHexString(		"#112244"), 
	numStringColor:Color.fromHexString(		"#ffffff"), 
	numNormalColor:Color.fromHexString(		"#ffffff"), 
	numTypingColor:Color.fromHexString(		"#ffaaaa"), 
	knobColors: [Color.fromHexString("#44aa88"), Color.fromHexString("#229988") ],
	background:Color.fromHexString(			"#333355")
).action = { arg ez;
	~handle_select_route.value(ez.value);
};


// sound selection knob
~knob_sound = EZKnob(
	parent:~win, 
	bounds:160@180, 
	knobSize:150@150, 
	label:"sound",
	unitWidth:100,
	layout:\vert2,
	controlSpec:ControlSpec( 0, ~bufs.size - 1, step:1 )
).setColors(
	stringBackground:Color.fromHexString(	"#333344"),
	stringColor:Color.fromHexString(		"#ffffff"), 
	numBackground:Color.fromHexString(		"#112244"), 
	numStringColor:Color.fromHexString(		"#ffffff"), 
	numNormalColor:Color.fromHexString(		"#ffffff"), 
	numTypingColor:Color.fromHexString(		"#ffaaaa"), 
	knobColors: [Color.fromHexString("#4466aa"), Color.fromHexString("#224499") ],
	background:Color.fromHexString(			"#333355")
).action = { arg ez;
	~handle_sound.value(ez.value);
};


// loop knob for each route
~knob_loop = EZKnob(
	parent:~win, 
	bounds:160@180, 
	knobSize:150@150, 
	label:"loop count ", 
	layout:\vert2,
	controlSpec:ControlSpec( 1, 64, step:1 ), 
).setColors(
	stringBackground:Color.fromHexString(	"#333344"),
	stringColor:Color.fromHexString(		"#ffffff"), 
	numBackground:Color.fromHexString(		"#112244"), 
	numStringColor:Color.fromHexString(		"#ffffff"), 
	numNormalColor:Color.fromHexString(		"#ffffff"), 
	numTypingColor:Color.fromHexString(		"#ffaaaa"), 
	knobColors: [Color.fromHexString("#4466aa"), Color.fromHexString("#224499") ],
	background:Color.fromHexString(			"#333355")
).action = { arg ez;
	~handle_loop.value(i, ez.value);
};



/// force a new line of widgets
~win.view.decorator.nextLine;

// channel selection slider for each node
~slider_channel = 4.collect({ arg i;
	EZSlider(
		parent:~win, 
		bounds:160@60,
		label:"channel", 
		unitWidth:0, 
		numberWidth:60,
		layout:\line2,
		controlSpec:ControlSpec( 0, ~num_channels - 1, step:1 )
	).setColors(
		sliderBackground:Color.fromHexString(	"#333344"),
		stringBackground:Color.fromHexString(	"#333344"),
		stringColor:Color.fromHexString(		"#ffffff"), 
		numBackground:Color.fromHexString(		"#112244"), 
		numStringColor:Color.fromHexString(		"#ffffff"), 
		numNormalColor:Color.fromHexString(		"#ffffff"), 
		numTypingColor:Color.fromHexString(		"#ffaaaa"), 
		knobColor:Color.fromHexString(			"#224499"),
		background:Color.fromHexString(			"#333355")
	).action = { arg ez;
		~handle_node_channel.value(i, ez.value);
	}
});


/// force a new line of widgets
~win.view.decorator.nextLine;


// time knob for each node, plus one for fadeout
~knob_time = 5.collect({ arg i;
	EZKnob(
		parent:~win, 
		bounds:160@180, 
		knobSize:150@150, 
		label:"time " ++ i, 
		layout:\vert2,
		controlSpec:ControlSpec( 0.01, 20.0, warp:0.2, units:"sec" ), 
	).setColors(
		stringBackground:Color.fromHexString(	"#333344"),
		stringColor:Color.fromHexString(		"#ffffff"), 
		numBackground:Color.fromHexString(		"#112244"), 
		numStringColor:Color.fromHexString(		"#ffffff"), 
		numNormalColor:Color.fromHexString(		"#ffffff"), 
		numTypingColor:Color.fromHexString(		"#ffaaaa"), 
		knobColors: [Color.fromHexString("#4466aa"), Color.fromHexString("#224499") ],
		background:Color.fromHexString(			"#333355")
	).action = { arg ez;
		~handle_node_time.value(i, ez.value);
	}
});

~win.view.keyDownAction = {
	arg view, char;
	if(char == $ , {
		~handle_play.value;
	});
};