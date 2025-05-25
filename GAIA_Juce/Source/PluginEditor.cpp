/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"
#include "PluginEffects.h"

//==============================================================================
GAIAJuceAudioProcessorEditor::GAIAJuceAudioProcessorEditor (GAIAJuceAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    // Make sure that before the constructor has finished, you've set the
    // editor's size to whatever you need it to be.
    
    //Setup UI
    audioProcessor.setupMixerUI([this](juce::Component& comp) { addAndMakeVisible(comp); });

    // Each block is 200 x 250 pixels
    setSize (600, 750);
}

GAIAJuceAudioProcessorEditor::~GAIAJuceAudioProcessorEditor()
{

}

//==============================================================================
void GAIAJuceAudioProcessorEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    // UI Separators
	g.setColour(juce::Colours::grey); 
    g.drawHorizontalLine(250, 0, getWidth());
    g.drawHorizontalLine(500, 0, getWidth());

    // Title
    g.setColour (juce::Colours::white);
    g.setFont (juce::FontOptions (40.0f));
    g.drawFittedText ("G.A.I.A.", getLocalBounds(), juce::Justification::centredBottom, 1);
}

void GAIAJuceAudioProcessorEditor::resized()
{
    // This is generally where you'll want to lay out the positions of any
    // subcomponents in your editor..
}
