# StudioChat
Working, not finished. Powershell-Core Multi-Window Chatbot with LM Studio hosted model(s). 

### DEVELOPMENT NOTES..
Early stages, it is limited. After upgrades below, there will be a review. The plan from here is...
1. TODAY, CONTEXTUAL AWARENESS!
3. Some kind of model for Image Generation, then use playground mode on LM Studio, then add a new graphical window taking up quarter screen for Graphics output, this should be based on "recent_events".
4. In theory, there could be some kind of text generated world map in a new window taking up a quarter of the screen, the player will there have options of locations to go to, the npc could be randomised based on the theme of the location, the user can at any point travel elsewhere, to meet a different person at the other location, or even at most of the locations there would be no people, so as for the user to have to search around for people. 
5. In theory, scenario_history would be able to be consolidated into "total_history" for all locations in the gaming session, and total_history could be used to customize future scenarios, so that they are themed towards what the player wants to find, hence the game could adapt towards what kinds of, scenarios and characters, preferred by the player, therein creating a theme of world, maybe, these themes could be saved or persistent until new game, enabling a continue option if there is history for it?? 
6. In theory, The player could also enter physical details, like, height and body type and gender, and this could influence the scenarios, logically requiring the, height and body type and gender, to be generated for the NPCs, and this could be considered in the prompt sent to the model for interaction. Possibly the ai could also psychologically analyze the total_history, and come up with a character sheet for the player, in addition to the pre-defined, height and body type and gender and name. 


### RESEARCH..
- Useful Models; https://huggingface.co/models?sort=trending&search=LLama-3-8b-Uncensored+gguf , one from here should be unfiltered. Going to use this one for now, it swore at me multiple times in the first input, just asking if it had a horse, its a good sign >_> - https://huggingface.co/mradermacher/Uncensored-Frank-Llama-3-8B-GGUF/blob/main/Uncensored-Frank-Llama-3-8B.Q6_K.gguf . There are no normal Llama 3 Chat Uncensored 8B GGUF currently, which is strange.
- Noteworth Models; At some point will be using New Qwen-2 model, beating Llam 3 and producing GPT4 quality output - https://www.youtube.com/watch?v=4vrK_LvMHNM , https://huggingface.co/models?sort=downloads&search=Qwen2+57b+gguf , specifically https://huggingface.co/mradermacher/Qwen2-57B-A14B-GGUF/blob/main/Qwen2-57B-A14B.Q6_K.gguf @ 
47.1 GB.
- Powershell 7.5 Beta, PowerShell Core beta updates can significantly enhance a local model chatbot by improving data handling with ConvertTo-Json serialization of BigInteger, providing actionable error suggestions, and adding a progress bar to Remove-Item. Enhanced path handling, early resolver registration, and improved error formatting boost stability and usability. Process management fixes allow better credential handling without admin privileges and easier process monitoring, while improved stream redirection enhances integration with native applications. These updates collectively enhance robustness, efficiency, and user experience for local model chatbots.


## FEATURES:
- 2 Windows, Engine and Chat, snapping to each side of the screen on launch.
- Multi-line input via Shift+Enter, no ability to return to earlier lines, entered with Enter at end.
- Multi-OS Mac/Linux/Windows compatibility thanks to, PS Core and LM Studio.
- GPU/CPU interference, and many other great features due to LM Studio.

### PREVIEW:
- Engine Window (requires update)...
```

--------------------------------------------------------

Engine Initialized.
Loading menu.
Sending request to LM Studio...
Received response from LM Studio



```
- Chat Window...
```

========================================================

Human:
Human met with Wise-Llama.

--------------------------------------------------------

Wise-Llama:
Wise-Llama met with Human.

--------------------------------------------------------

Recent Events:
Human and Wise-Llama noticed each other.

--------------------------------------------------------

Scenario History:
The roleplay started.

========================================================

Your Input (Back=B):

```

## REQUIREMENTS:
- Powershell Core 7, may specify 7.5 later, 7.5 is interesting..  
- LM Studio (Windows, Linux, Mac).

### INSTALLATION:
1. Install LM Studio, and ensure you have suitable models loaded...
2. Extract StudioChat to a suitable folder, for example, `D:\Programs\StudioChat`.
3. Run the launcher "StudioChat.Bat", configure settings in menu.
4. Start the Chat interaction, input `b` to return to the menu.

## NOTES:
- This project is intended a better version of the llama 2 style chatbot I made for WSL, for proof of a AI on powershell/lm studio concept; but when its done, do I make a, adventure game or agent/assitant or personal manager, out of it, what is the next stage after project completion??

## DISCLAIMER:
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
