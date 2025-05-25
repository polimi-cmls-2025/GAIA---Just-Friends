/*
=== USER GUIDE ===

With Arduino, to start in this order:
1. "SETUP AND CONTROLS" (only where necessary),
2. "VARIABLES AND OSC RECEPTION",
3. "PRINT ROUTINE",
4. "SYNTH",
5. "START WITH ARDUINO".

Without ARDUINO - With Simulator:
1. "SETUP AND CONTROLS" (only where necessary),
2. "SYNTH",
3. "ARDUINO SIMULATOR",
4. "START WITH SIMULATOR".
*/

// === SETUP E CONTROLLI ===
(
s.options.outDevice = "ASIO : ReaRoute ASIO";  // Driver In/Out
s.options.numOutputBusChannels = 6; // Number of channels
s.options.sampleRate = 48000;
s.reboot;
)

NetAddr.langPort; // Verify OSC port
OSCFunc.trace(true);  // Activate printing of all received OSC messages
OSCFunc.trace(false); // Disable if not necessary


// === VARIABLES AND OSC RECEPTION ===
(
// === Global variables ===
~tempRaw = 0; ~tonalCenter = 0;
~humRaw = 0; ~hum = 0.5;
~lightRaw = 0; ~light = 0.5;
~triggerBar = 0;
~durBar = 10000; // length [ms]
~triggerNote = 0;
~noteVal = 0;
~durNote = 0.5;  // seconds


// === OSC receive and synth update ===
OSCdef(\temp, { |msg|
	~tempRaw = msg[1];
	~temp = ~tempRaw.linlin(2500, 3000, 0.0, 1.0).clip(0.0, 1.0);
	~synth.set(\temp, ~temp);
	~tonalCenter = (~tempRaw.linlin(2500, 3000, 0, 11)).floor.clip(0, 11);
	~synth.set(\tonalCenter, ~tonalCenter);
}, "/sensors/temp");

OSCdef(\hum, { |msg|
	~humRaw = msg[1];
	~hum = ~humRaw.linlin(5000, 8000, 0.0, 1.0).clip(0.0, 1.0);
	~synth.set(\hum, ~hum);
}, "/sensors/humi");

OSCdef(\light, { |msg|
	~lightRaw = msg[1];
	~light = ~lightRaw.linlin(0, 4095, 0.0, 1.0).clip(0.0, 1.0);
	~synth.set(\light, ~light);
}, "/sensors/rldr");

OSCdef(\triggerBar, { |msg|
	~triggerBar = msg[1];
	~synth.set(\triggerBar, ~triggerBar);
}, "/trigger/tbar");

OSCdef(\durBar, { |msg|
	~durBar = msg[1] / 1000;  // Converte da ms a secondi
	~synth.set(\durBar, ~durBar);
}, "/duratat/dbar");

OSCdef(\triggerNote, { |msg|
	~triggerNote = msg[1];
	~synth.set(\triggerNote, ~triggerNote);
}, "/trigger/tnot");

OSCdef(\durNote, { |msg|
	~durNote = msg[1] / 1000; // da ms a secondi
	~synth.set(\durNote, ~durNote);
}, "/duratat/dnot");

OSCdef(\noteVal, { |msg|
	~noteVal = msg[1];
	~synth.set(\noteVal, ~noteVal);
}, "/musnote/note");
)


// === PRINT ROUTINE ===
(
~reader = Routine({
	loop {
		("Temp: " ++ (~tempRaw / 100).round(0.01) ++ " °C"
		 ++ " | Hum: " ++ (~humRaw / 100).round(0.01) ++ " %"
		 ++ " | Light: " ++ ~lightRaw).postln;

		("Tonal Center: " ++ ~tonalCenter
		 ++ " | triggerBar: " ++ ~triggerBar
		 ++ " | durBar: " ++ ~durBar ++ " s").postln;

		("Note: " ++ ~noteVal
		 ++ " | Trig: " ++ ~triggerNote
		 ++ " | Dur: " ++ ~durNote ++ " s").postln;

		"---------------------------".postln;

		0.2.wait;
	}
});
)


// === SYNTH ===
(
SynthDef(\GAIA, { | temp = 0.5, hum = 0.5, light = 0.5,	tonalCenter = 0, triggerBar = 0, durBar = 10, triggerNote = 0, durNote = 0.5, noteVal = 0 |

	// === Preliminary operation ===
	var harmonyLFOFreq = temp.linlin(0, 1, 0.2, 5);
	var durEnv = hum.linlin(0, 1, (durBar / 2), 0.5);
	var bassLFOFreq = light.linlin(0, 1, 12, 0);
	var numHarm = light.linlin(0, 1, 1, 12).round;

	// === Modulation LFO ===
	var bassLFO = SinOsc.kr(bassLFOFreq).range(0.7, 1.3);
	var harmonyLFO = SinOsc.kr(harmonyLFOFreq).range(0.3, 0.7);

	// === Triggering ===
	var barTrig = Trig1.kr(triggerBar, 0.001);
	var noteTrig = Trig1.kr(triggerNote, 0.001);
	var row = Demand.kr(barTrig, 0, Dseq((0..8), inf));

	// === Envs ===
	var harmonyEnv = EnvGen.kr(
		Env.linen(durEnv, (durBar - (2 * durEnv)), durEnv),
		gate: barTrig

	);
	var noteEnv = EnvGen.kr(
		Env.perc(0.01, durNote),
		gate: noteTrig

	);

	// === Armonic Matrices ===
	var basses = [
		[0], [2], [7], [5], [7], [9], [4], [0], [2]
	];
	var chords = [
		[0, 5, 12], [2, 9, 16], [0, 7, 14],
		[5, 9, 14], [7, 11, 16], [9, 14, 21],
		[4, 7, 12], [4, 11, 16], [0, 9, 14]
	];

	// === Selection ===
	var bass = 24 + tonalCenter + Select.kr(row, basses.collect(_.first));
	var chord = Select.kr(row, chords).collect { |n| 48 + tonalCenter + n };
	var note = 72 + tonalCenter + noteVal;

	// === Midi to Freqs ===
	var bassFreq1 = (bass).midicps;
	var bassFreq2 = (bass + 12).midicps;
	var chordFreqs = chord.collect(_.midicps);
	var noteFreq = (note).midicps;

	// === Oscillators ===
	var bassOSC1 = LFPar.ar(bassFreq1, 0.25, 0.5 * bassLFO);
	var bassOSC2 = LFPar.ar(bassFreq2, 0.5, 0.3 * bassLFO);
	var chordOSC = Mix.fill(chordFreqs.size, { |i| Blip.ar(chordFreqs[i], numHarm, 0.15)});
	var noteOSC = SinOsc.ar(noteFreq, 0, 0.4);

	// === Signals ===
	var bassSig = harmonyEnv * harmonyLFO * (bassOSC1 + bassOSC2);
	var chordSig = harmonyEnv * harmonyLFO * chordOSC;
	var noteSig = noteEnv * noteOSC;

	// === Output ===
	Out.ar(0, [bassSig, bassSig, chordSig, chordSig, noteSig, noteSig]);
}).add;
)

// === START WITH ARDUINO ===
(
~reader.play;  // Start the reader console
~synth = Synth(\GAIA);  // Start th synth
)

// === ARDUINO SIMULATOR ===
(
var now;

// SERVICE RECEIVERS
~pr = NetAddr("127.0.0.1", 57130); // Processing

// === INITIALIZATION ===
~tempRaw = 2500;
~humRaw = 5000;
~lightRaw = 2048;

~durBar = rrand(5000, 15000);   // ms
~durNote = rrand(1500, 3000);   // ms
~noteVal = rrand(0, 11);

~triggerBar = 0;
~triggerNote = 0;

~barStart = Main.elapsedTime;
~noteStart = Main.elapsedTime;

// === SIMULATION LOOP ===
~simulateArduino = Routine({
	loop {
		now = Main.elapsedTime;

		// === TRIGGER BAR ===
		if (((now - ~barStart) * 1000) >= ~durBar) {
			~triggerBar = 1;
			~durBar = rrand(5000, 15000);
			~barStart = now;
		} {
			~triggerBar = 0;
		};

		// === TRIGGER NOTE ===
		if (((now - ~noteStart) * 1000) >= ~durNote) {
			~triggerNote = 1;
			~durNote = rrand(1500, 3000);
			~noteVal = rrand(0, 11);
			~noteStart = now;
		} {
			~triggerNote = 0;
		};

		// === SIMULATED SENSORS ===
		~tempRaw = rrand(1500, 3500);
		~humRaw = rrand(1000, 9000);
		~lightRaw = rrand(0, 4095);

		// === SYNTH UPDATE ===
		~synth.set(
			\tonalCenter, ((~tempRaw.linlin(1500, 3500, 0, 11)).floor.clip(0, 11)),
			\hum, (~humRaw.linlin(1000, 9000, 0.0, 1.0).clip(0, 1)),
			\light, (~lightRaw.linlin(0, 4095, 0.0, 1.0).clip(0, 1)),
			\triggerBar, ~triggerBar,
			\durBar, (~durBar / 1000),
			\triggerNote, ~triggerNote,
			\durNote, (~durNote / 1000),
			\noteVal, ~noteVal
		);

		// === DEBUG PRINT ===
		("Temp: " ++ (~tempRaw / 100).round(0.01) ++ " °C"
		 ++ " | Hum: " ++ (~humRaw / 100).round(0.01) ++ " %"
		 ++ " | Light: " ++ ~lightRaw).postln;

		("Tonal Center: " ++ (~tempRaw.linlin(1500, 3500, 0, 11)).floor
		 ++ " | triggerBar: " ++ ~triggerBar
		 ++ " | durBar: " ++ (~durBar / 1000).round(0.01) ++ " s").postln;

		("Note: " ++ ~noteVal
		 ++ " | Trig: " ++ ~triggerNote
		 ++ " | durNote: " ++ (~durNote / 1000).round(0.01) ++ " s").postln;

		"--------------------------".postln;

		// === SEND TO PROCESSING ===
		~pr.sendMsg("/sensors/temp", ~tempRaw);
		~pr.sendMsg("/sensors/humi", ~humRaw);
		~pr.sendMsg("/sensors/rldr", ~lightRaw);

		0.2.wait;
	}
}).play(SystemClock);
)


// === START WITH SIMULATOR ===
~synth = Synth(\GAIA);  // Start the synth

