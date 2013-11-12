// scope the control busses
w[0].ampBus.scope;

// scope the audio busses...
// 12 output busses for monitoring
~monitor_b = Bus.audio(s, 12);
// assign output to busses
w.do({ arg v; v.outOffset = ~monitor_b.index; });
// scope
~monitor_b.scope;
// patch back to outputs
12.do({ arg i;
	{ Out.ar( i, In.ar(~monitor_b.index + i)) }.play(target:s, addAction:\addToTail);
});