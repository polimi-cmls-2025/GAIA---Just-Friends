/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
GAIAJuceAudioProcessor::GAIAJuceAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       )
#endif
{
}

GAIAJuceAudioProcessor::~GAIAJuceAudioProcessor()
{
}

//==============================================================================
const juce::String GAIAJuceAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool GAIAJuceAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool GAIAJuceAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool GAIAJuceAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double GAIAJuceAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int GAIAJuceAudioProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int GAIAJuceAudioProcessor::getCurrentProgram()
{
    return 0;
}

void GAIAJuceAudioProcessor::setCurrentProgram (int index)
{
}

const juce::String GAIAJuceAudioProcessor::getProgramName (int index)
{
    return {};
}

void GAIAJuceAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
}

//==============================================================================
void GAIAJuceAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    // Use this method as the place to do any pre-playback
    // initialisation that you need..

    // Buffer setup
    dbuf.setSize(getTotalNumOutputChannels(), 100000);
    dbuf.clear();
	
    // Delay read and write initialization
	dr = 0;
	dw = 1;
}

void GAIAJuceAudioProcessor::releaseResources()
{
    // When playback stops, you can use this as an opportunity to free up any
    // spare memory, etc.
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool GAIAJuceAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
#if JucePlugin_IsMidiEffect
    juce::ignoreUnused(layouts);
    return true;
#else
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    // Some plugin hosts, such as certain GarageBand versions, will only
    // load plugins that support stereo bus layouts.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
        && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
#if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
#endif

    return true;
#endif
}
#endif

void GAIAJuceAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&)
{
    int numSamples = buffer.getNumSamples();
    auto totalNumInputChannels = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // Clear any output channels that don't have input data
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear(i, 0, numSamples);

    // Get pointers to input/output data for left and right channels
    const float* channelInDataL = buffer.getWritePointer(0);
    const float* channelInDataR = buffer.getWritePointer(1);
    float* channelOutDataL = buffer.getWritePointer(0);
    float* channelOutDataR = buffer.getWritePointer(1);

    // Get current delay buffer size
    int ds_now = getDelayDS();

    // Channel indices for delay buffer
    int leftIndex = 0, rightIndex = 1;

    for (int i = 0; i < numSamples; ++i)
    {
        // Store current input samples into delay buffer
        dbuf.setSample(leftIndex, dw, channelInDataL[i]);
        dbuf.setSample(rightIndex, dw, channelInDataR[i]);

        float left = channelInDataL[i];
        float right = channelInDataR[i];

        float processedLeft = left;
        float processedRight = right;

        // Apply distortion effect
        processDistortion(&processedLeft, &processedRight);

        // Apply delay effect
        processDelay(&processedLeft, &processedRight, dw, dr);

        // Store processed samples in output buffer
        channelOutDataL[i] = processedLeft;
        channelOutDataR[i] = processedRight;

        // Increment and wrap delay write/read positions
        dw = (dw + 1) % ds_now;
        dr = (dr + 1) % ds_now;
    }

    // Apply reverb effect to the processed output
    processReverb(channelOutDataL, channelOutDataR, numSamples);
}






//==============================================================================
bool GAIAJuceAudioProcessor::hasEditor() const
{
    return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* GAIAJuceAudioProcessor::createEditor()
{
    return new GAIAJuceAudioProcessorEditor (*this);
}

//==============================================================================
void GAIAJuceAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
}

void GAIAJuceAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new GAIAJuceAudioProcessor();
}