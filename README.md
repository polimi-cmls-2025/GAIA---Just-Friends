# G.A.I.A.

## Overview

**G.A.I.A.** (Generative Audio via Interaction with Ambient) is an ambient generative system that transforms real-time environmental conditions and user interaction into immersive audiovisual experiences. It captures ambient data—temperature, humidity and light—using Arduino-based sensors and converts them into dynamic soundscapes and visuals. The system blends real-world inputs with algorithmic composition to produce evolving, meditative ambient music, visually enhanced by a responsive particle system.

G.A.I.A. is composed of modular units:
- **Arduino** collects environmental data and triggers rhythmic events.
- **SuperCollider** handles real-time audio synthesis based on sensor input.
- **JUCE** implements audio effects (distortion, delay, reverb) as VST plugins hosted in **Reaper**.
- **Processing** visualizes the sensor data through generative graphics.
- **OSC** protocol interconnects all modules seamlessly.
- A **custom 3D-printed enclosure** facilitates physical interaction with the system.

## Modules and Files

### GAIA_Arduino

   This module serves as the environmental sensing and event-timing engine of the G.A.I.A. system. It reads real-world data from two physical sensors: a **DHT22** (for temperature and humidity) and a **photoresistor (LDR)** for ambient light. These sensor readings are formatted and transmitted via **Open Sound Control (OSC)** over WiFi to two distinct recipients: **SuperCollider** (audio synthesis) and **Processing** (visual synthesis), each listening on a dedicated UDP port.

   All sensor values are sent as **integer values**:
   - **Temperature and humidity** are scaled by a factor of 100 and cast to four-digit integers for transmission (e.g., 22.53°C → 2253).
   - **Light** values are sent directly as raw analog readings (0–4095).

   The Arduino also manages musical timing and event generation:
   - A configurable **bar duration** (`durBar`) sets the length of each musical bar in milliseconds.
   - At the start of each bar, it sends a `triggerBar = 1` event to SuperCollider; for the rest of the bar duration, `triggerBar = 0` is sent.
   - Within each bar, it randomly sends `triggerNote` events to SuperCollider to trigger melodic components.

   Sensor values and timing triggers are transmitted every **200 ms**, creating a continuous and responsive data stream that links the physical environment to the system’s sonic and visual behavior.

### GAIA_Supercollider

   This module implements the generative audio engine of the G.A.I.A. system. It runs a SuperCollider script that receives real-time environmental data and control triggers from Arduino via **OSC**, translating them into a continuously evolving ambient soundscape. The system can operate in two modes: **Arduino Mode** (real sensor input) and **Simulator Mode** (randomized input for development or demonstration purposes).

   #### - Script Structure:
   - **Setup and Controls**: Initializes the SuperCollider server, configures audio and OSC settings, and defines shared global variables.
   - **OSC Reception**: Receives and maps OSC messages—temperature, humidity, light, bar trigger, bar duration, note trigger, and note pitch—into synthesis parameters.
   - **Print Routine**: Displays sensor and control values in real time for monitoring and debugging purposes.
   - **Synth Definition**: Defines the `\GAIA` SynthDef, which combines bass, chords, and melody layers—each shaped in real time by environmental inputs.

   #### - Execution Modes:
   - **Arduino Mode**: Receives live sensor data and musical events directly from the Arduino module.
   - **Simulator Mode**: Generates random values internally, enabling testing without hardware.

   #### - Sound Architecture (GAIA Synth):
   The GAIA synth is structured into three independent yet interrelated layers, all influenced by environmental parameters:

   - **Bass Layer**:  
     Plays a sequence of root notes triggered at each `triggerBar` using two detuned `LFPar` oscillators.  
     - **Light** intensity modulates the detuning amount and filter modulation depth, shaping the movement and texture.
     - **Temperature** sets the root pitch, influencing the tonal center around which chords and melodies are built.

   - **Chord Layer**:  
     On each `triggerBar`, a selected (on sequence) triad is played using `Blip` oscillators, creating a shimmering harmonic foundation.  
     - **Light** controls the number of partials (harmonics), enriching or simplifying the timbre.
     - **Humidity** modulates the chord envelope's sustain and release time, affecting its temporal shape.
     - **Temperature** contributes by adjusting the global tonal center, aligning the chord voicing with the bass and melody.

   - **Melodic Layer**:  
     Independent from the bar pulse, this layer responds to `triggerNote` and `note` messages, generating short melodic events using `SinOsc`.  
     - **Note pitch** and **duration** are received in real time, offering precise melodic articulation.
     - **Temperature** again influences the pitch reference by defining the modal center.

   #### - Audio Routing:
   The final output consists of **six discrete audio channels**, organized as three stereo pairs (bass, chords, melody). These are routed to **Reaper** using **ReaRoute**, where each layer is further processed through custom JUCE plugins.

   This modular and sensor-responsive design enables G.A.I.A. to translate real-world conditions into rich, immersive sonic textures that evolve continuously and organically.

### GAIA_Reaper

   This module provides a complete **Reaper** project that integrates the GAIA system's audio pipeline with the custom JUCE plugin. It acts as the host environment for final audio processing and recording.

   The session is preconfigured with **three stereo tracks**, each loaded with a unique instance of the `GAIA_Juce.vst3` plugin. These tracks are functionally identical and allow parallel processing of the three sound layers produced by SuperCollider: **bass**, **chords**, and **melody**.

   #### - Configuration Details:
   - Each track is set to **stereo input and output**, with JUCE plugins **active and unbypassed**.
   - The plugin instances are spatially arranged in the workspace using **floating windows**, enabling real-time visual monitoring and manipulation.
   - The DAW project is configured for **recording and playback**, making it suitable both for performance and evaluation.

   #### - Audio Routing:
   The input signals are routed into Reaper via **ReaRoute**, which connects SuperCollider’s six-channel output directly to Reaper's mixer. Each stereo pair from SuperCollider (bass L/R, chords L/R, melody L/R) is routed to one of the three JUCE plugin tracks for individual processing.

   This setup enables full control over the spatial and spectral treatment of each sound layer, allowing the user to shape and refine the generative output using the dedicated distortion, delay, and reverb units in each JUCE plugin instance.

### GAIA_Juce 

   This module provides a custom **JUCE-based audio plugin** that processes stereo audio using three fundamental effects: **distortion**, **delay**, and **reverb**. It is designed to work in synergy with the audio output of the GAIA synth from SuperCollider and is hosted in Reaper for final mixing and processing.

   The plugin architecture is modular and follows a clear separation of concerns across three main components:

   #### - Plugin Processor (`PluginProcessor.cpp`):
   This is the core of the plugin’s signal processing logic. It defines the `GAIAJuceAudioProcessor` class, which inherits from JUCE's `AudioProcessor` and utilizes the custom `GAIAJuceEffects` class for effect implementation.

   - A **circular buffer** is initialized for implementing the delay effect, with dynamic resizing in `prepareToPlay()` and sample-level control in `processBlock()`.
   - Each incoming audio buffer is processed in three stages:
     1. **Distortion**: A simple waveshaping algorithm is applied, with user-controlled drive and blending.
     2. **Delay**: Reads a delayed sample from the buffer and blends it with the dry signal.
     3. **Reverb**: Uses JUCE’s built-in reverb module, applied post-effect.
   - The system uses floating-point processing and clamping (via `jlimit`) to ensure audio safety and responsiveness.

   #### - Plugin Effects (`PluginEffects.cpp/.h`):
   This component handles the implementation of effects and their UI controls. Effects are encapsulated into modular structures using the `EffectUIBlock` class.

   - The GUI elements (sliders and labels) are dynamically created via `setupMixerUI()` and `setUpArea()`.
   - Each effect's parameters are mapped to rotary sliders with real-time visual feedback.
   - Parameter ranges and defaults are customized per effect (e.g., distortion drive, delay time, reverb size/damping).

   #### - Plugin Editor (`PluginEditor.cpp`):
   The plugin’s graphical interface is defined in `GAIAJuceAudioProcessorEditor`.

   - It arranges all GUI components programmatically, invoking `setupMixerUI()` from the processor to populate the editor.
   - The visual design includes distinct horizontal sections for each effect, with custom drawing via the `paint()` method to create a clean layout.

   This JUCE module acts as a high-level audio effects unit, giving users real-time control over the final spatial and spectral shape of GAIA’s sound output.

### GAIA_Processing

   This module implements the **visual feedback system** of G.A.I.A. using **Processing**. It renders a generative particle system that responds in real time to environmental sensor data received via **OSC** from Arduino. The visualization reacts expressively to temperature, humidity, and light levels, creating an ambient, data-driven visual landscape.

   #### - File Structure:

   - **`GAIA_processing.pde`**:  
     Sets up the OSC receiver on a specific UDP port and parses incoming integer values representing temperature, humidity, and light. These values are stored and used as global control variables for the visual system. This file initializes the `ParticleSystem`, updates it on each frame, and manages the rendering loop. It also includes print statements for debugging and real-time monitoring of OSC communication.

   - **`particle.pde`**:  
     Defines the `Particle` class, representing each visual unit in the system. Particles have properties such as position, velocity, acceleration, size, lifespan, and color hue. They respond to forces by updating their acceleration and velocity, resulting in smooth, organic motion. Lifespan decreases over time until the particle is removed. The hue and appearance of each particle are determined at creation time and visually encode the current **light** level.

   - **`particleSys.pde`**:  
     Implements the `ParticleSystem` class, which maintains a list of active particles and controls their behavior.  
     - New particles are generated at a rate proportional to the **humidity** value: higher humidity leads to denser visuals.  
     - **Temperature** scales the magnitude of forces applied to the particles, affecting their speed and dynamism.  
     - **Light** defines the **hue** (color) of new particles, establishing a direct visual representation of environmental brightness.  
     The system applies small randomized forces and limits the total number of particles to maintain performance while preserving the organic, fluid aesthetic.

   This Processing module provides G.A.I.A. with a rich audiovisual link between ambient data and expressive, immersive graphics.

### GAIA_3DPrint

   This module defines a **custom 3D-printable enclosure** for the electronic components of G.A.I.A., written in **OpenSCAD**. The case is designed to host the Arduino MKR WiFi 1010 board along with the DHT22 and LDR sensors, optimizing both **physical protection** and **interactive usability**.

   #### - Design Features:
   - The enclosure consists of a **main rectangular body** with internal space to accommodate the MKR board, wiring and a battery.
   - Two **tilted cylindrical ports** are integrated into the top surface:
     - One for the **photoresistor (LDR)**.
     - One for the **DHT22 temperature and humidity sensor**.
     These angled ports are designed to enhance ambient exposure and improve sensor responsiveness.
   - A **detachable top cover** ensures easy access to internal components, enabling fast assembly, maintenance, or modification.
   - The design is **modular**: each structural part (main box, cover, sensor ports) is defined separately in the script, allowing for scalable customization or part-by-part printing.

   This enclosure offers a practical and robust physical foundation for G.A.I.A., ensuring tidy hardware arrangement, improved sensor positioning, and seamless integration with the artistic and performative goals of the project.

## Technologies Used

- **Interaction System**:  
  Arduino MKR WiFi 1010, DHT22 temperature and humidity sensor, LDR photoresistor, WiFi communication, OSC protocol (Open Sound Control)

- **Sound Synthesis & Processing**:  
  SuperCollider (generative synthesis engine), JUCE (VST plugin for effects: distortion, delay, reverb), Reaper (DAW and signal routing with ReaRoute)

- **Visual Feedback**:  
  Processing (real-time particle system visualization)

- **Physical Interface**:  
  OpenSCAD (custom 3D-printed enclosure design)

## Credits

This project was developed as part of the *Computer Music: Languages and Systems* course at Politecnico di Milano (2024/2025).

- Andrea Crisafulli — andrea.crisafulli@mail.polimi.it  
- Giacomo De Toni — giacomo1.detoni@mail.polimi.it  
- Filippo Longhi — filippo1.longhi@mail.polimi.it  
- Marco Porcella — marco.porcella@mail.polimi.it
