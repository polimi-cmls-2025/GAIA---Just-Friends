/*
  ==============================================================================

    PluginEffects.cpp
    Created: 16 May 2025 11:06:40am
    Author:  Marco65701

  ==============================================================================
*/

#include <JuceHeader.h>
#include "PluginEffects.h"

// Returns the current delay buffer size from the corresponding slider.
// If the value is zero or negative, defaults to 50000.
int GAIAJuceEffects::getDelayDS()
{
    int v = delayBlock.sliders[2].getValue();
    if (v <= 0)
        v = 50000;
    return v;
}

// Set up all mixer UI components (Reverb, Distortion, Delay)
// by invoking setUpArea with correct coordinates.
void GAIAJuceEffects::setupMixerUI(std::function<void(juce::Component&)> addFn)
{
    setUpArea(addFn, Reverb, 0, 0);
    setUpArea(addFn, Distortion, 0, 250);
    setUpArea(addFn, Delay, 0, 500);
}

// Set up an individual effect area with sliders and labels.
void GAIAJuceEffects::setUpArea(std::function<void(juce::Component&)> addFn, int effectID, int posX, int posY)
{
    EffectUIBlock* block;
    int margin = 0;

    // Retrieve the correct effect UI block based on effect ID.
    retrieveData(effectID, block);

    // Adjust margins depending on number of parameters to center the UI.
    switch (block->numParams) {
    case 2:
        margin = 180;
        break;
    case 3:
        margin = 120;
        break;
    case 4:
        margin = 80;
        break;
    case 5:
        margin = 40;
        break;
    case 6:
        margin = 20;
        break;
    default:
        margin = 0;
        break;
    }

    // Define size and spacing of sliders.
    int sliderWidth = 100;
    int sliderHeight = 100;
    int spacing = (600 - margin * 2 - block->numParams * sliderWidth) / (block->numParams - 1);

    // Add the main label for this effect section.
    setMainLabel(addFn, effectID, posX, posY);

    // Loop over parameters to configure sliders and labels.
    for (int i = 0; i < block->numParams; ++i)
    {
        auto& slider = block->sliders[i];
        auto& label = block->labels[i];
        auto val = 0.5f;
        float minVal = 0.0, maxVal = 1.0, step = 0.01;

        // For Delay time (last slider), set a different range and default.
        if (effectID == Delay && i == block->numParams - 1)
        {
            minVal = 5000.0f;
            maxVal = 50000.0f;
            step = 100.0f;
            val = 50000.0f;
        }

        // Configure slider properties.
        slider.setSliderStyle(juce::Slider::Rotary);
        slider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
        slider.setRange(minVal, maxVal, step);
        slider.setValue(val, juce::dontSendNotification);

        // Configure label properties.
        label.setText(block->labelNames[i], juce::dontSendNotification);
        label.attachToComponent(&slider, false);

        // Add slider and label to the UI.
        addFn(slider);
        addFn(label);

        // Set bounds for slider and label.
        int x = posX + margin + i * (sliderWidth + spacing);
        int y = posY + sliderHeight;
        slider.setBounds(x, y, sliderWidth, sliderHeight);
        label.setBounds(x, y - 15, sliderWidth, 20);
        label.setJustificationType(juce::Justification::centred);
    }
}

// Apply delay effect to left and right audio samples.
void GAIAJuceEffects::processDelay(float* left, float* right, int dw, int dr)
{
    int leftIndex = 0;
    int rightIndex = 1;

    // Retrieve wet and dry levels from sliders.
    float wetLevel = delayBlock.sliders[0].getValue();
    float dryLevel = delayBlock.sliders[1].getValue();

    // Mix original and delayed samples.
    *left = dryLevel * *left + wetLevel * dbuf.getSample(leftIndex, dr);
    *right = dryLevel * *right + wetLevel * dbuf.getSample(rightIndex, dr);
    return;
}

// Apply reverb effect to stereo buffer.
void GAIAJuceEffects::processReverb(float* left, float* right, int numSamples)
{
    // Retrieve reverb parameters from sliders.
    float roomSize = reverbBlock.sliders[0].getValue();
    float damping = reverbBlock.sliders[1].getValue();
    float wetLevel = reverbBlock.sliders[2].getValue();
    float dryLevel = reverbBlock.sliders[3].getValue();
    float revWidth = reverbBlock.sliders[4].getValue();
    float freezeMode = reverbBlock.sliders[5].getValue();

    // Set parameters for JUCE Reverb object and apply to stereo samples.
    juce::Reverb::Parameters reverbParams = { roomSize, damping, wetLevel, dryLevel, revWidth, freezeMode };
    reverbHandler.setParameters(reverbParams);
    reverbHandler.processStereo(left, right, numSamples);
    return;
}

// Apply distortion effect to a stereo pair of samples.
void GAIAJuceEffects::processDistortion(float* sampleL, float* sampleR)
{
    float drive = distortionBlock.sliders[0].getValue();
    float mix = distortionBlock.sliders[1].getValue();

    // Apply simple distortion with drive scaling and dry/wet mixing.
    *sampleL = (1 - mix) * *sampleL + mix * juce::jlimit(-0.1f, 0.1f, *sampleL * drive);
    *sampleR = (1 - mix) * *sampleR + mix * juce::jlimit(-0.1f, 0.1f, *sampleR * drive);
    return;
}

// Set up the main label for each effect section in the UI.
void GAIAJuceEffects::setMainLabel(std::function<void(juce::Component&)> addFn, int effectID, int posX, int posY)
{
    juce::String mainLabelTitle = "sampleText";
    juce::Label* mainLabel = NULL;

    // Assign label object and title based on effect type.
    switch (static_cast<EffectID>(effectID))
    {
    case EffectID::Distortion:
        mainLabel = &distortionMainLabel;
        mainLabelTitle = "Distortion";
        break;

    case EffectID::Delay:
        mainLabel = &delayMainLabel;
        mainLabelTitle = "Delay";
        break;

    case EffectID::Reverb:
        mainLabel = &reverbMainLabel;
        mainLabelTitle = "Reverb";
        break;

    default:
        jassertfalse;
        break;
    }

    // Configure and add label to UI.
    if (mainLabel != NULL) {
        mainLabel->setBounds(posX, posY, 600, 60);
        mainLabel->setText(mainLabelTitle, juce::dontSendNotification);
        mainLabel->setFont(juce::Font(30));
        mainLabel->setJustificationType(juce::Justification::centred);
        addFn(*mainLabel);
    }
}

// Retrieve the correct EffectUIBlock pointer for the given effect ID.
void GAIAJuceEffects::retrieveData(int effectID, EffectUIBlock*& block)
{
    block = NULL;

    // Match effect ID to corresponding block.
    switch (static_cast<EffectID>(effectID))
    {
    case EffectID::Distortion:
        block = &distortionBlock;
        break;

    case EffectID::Delay:
        block = &delayBlock;
        break;

    case EffectID::Reverb:
        block = &reverbBlock;
        break;

    default:
        block = NULL;
        jassertfalse;
        break;
    }
}
