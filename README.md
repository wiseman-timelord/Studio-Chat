# StudioChat
Working, not finished. Powershell-Core Multi-Window Chatbot with LM Studio hosted model(s). 

### DEVELOPMENT NOTES..
Early stages, it is limited. After upgrades below, there will be a review. The plan from here is...
1. Refractor script locations, there are now 9 scripts, namely we need, ".\data" and ".\scripts"; super easy with powershell.
2. expand "response.json" to include keys, "previously" and "so-far", then need to be added to dynamic Prompts, requiring new prompts for consolidation into, "previously" and "so-far", contents, so as to produce context & history.  
3. Some kind of model for Image Generation, then use playground mode on LM Studio, and make main 1 take up quarter display, then add a new window taking up quarter screen for Graphics output, this should be based on "previously".
4. when the user chooses to exit, then this could produce option to produce summary image or just exit, image generated would use "So-Far".

### RESEARCH..
- Useful Models; https://huggingface.co/models?sort=trending&search=LLama-3-8b-Uncensored+gguf , one from here should be unfiltered. Going to use this one for now, it swore at me multiple times in the first input, just asking if it had a horse, its a good sign >_> - https://huggingface.co/mradermacher/Uncensored-Frank-Llama-3-8B-GGUF/blob/main/Uncensored-Frank-Llama-3-8B.Q6_K.gguf . There are no normal Llama 3 Chat Uncensored 8B GGUF currently, which is strange.
- Noteworthy Models; Llama 3 Instruct-Chat Merge in 20B Paramneters, weighing around 20GB, quite acceptable for multi-line output and input, but possibly filtered. This is being investigated for use with development version of StudioChat - https://huggingface.co/AtakanTekparmak/llama-3-20b-instruct-Q8_0-GGUF/tree/main . Its Filtered.
- Noteworth Models; At some point will be using New Qwen-2 model, beating Llam 3 and producing GPT4 quality output - https://www.youtube.com/watch?v=4vrK_LvMHNM , https://huggingface.co/models?sort=downloads&search=Qwen2+57b+gguf , specifically https://huggingface.co/mradermacher/Qwen2-57B-A14B-GGUF/blob/main/Qwen2-57B-A14B.Q6_K.gguf @ 
47.1 GB.
- Powershell 7.5 Beta, PowerShell Core beta updates can significantly enhance a local model chatbot by improving data handling with ConvertTo-Json serialization of BigInteger, providing actionable error suggestions, and adding a progress bar to Remove-Item. Enhanced path handling, early resolver registration, and improved error formatting boost stability and usability. Process management fixes allow better credential handling without admin privileges and easier process monitoring, while improved stream redirection enhances integration with native applications. These updates collectively enhance robustness, efficiency, and user experience for local model chatbots.


## FEATURES:
- 2 Windows, Engine and Chat, snapping to each side of the screen on launch.
- Multi-line input via Shift+Enter, no ability to return to earlier lines, entered with Enter at end.
- Multi-OS Mac/Linux/Windows compatibility thanks to, PS Core and LM Studio.
- GPU/CPU interference, and many other great features due to LM Studio.

### PREVIEW:
- Engine Window...
```
...Engine Initialized.

--------------------------------------------------------

Sending request to LM Studio...
Received response from LM Studio
Sending request to LM Studio...
Received response from LM Studio








```
- Chat Window...
```
...Chat Initialized.

--------------------------------------------------------

You: You play Goria Estrogen, and I will play Kink Yeastwood, ok, I'll start. Hey, gotta Force?

--------------------------------------------------------

Model: That's correct! How may I assist you with this game?

--------------------------------------------------------

You: No, youre supposed to be in the character of Goria Estrogen, and I asked you "Hey, Gotta Force?", try again.

--------------------------------------------------------

Model: Sure, what would you like me to do? Can you please give me more information about this task so that I can provide a better response?

--------------------------------------------------------

You: Hmm, probably the prompts need implementing, or the model changing..




```

## REQUIREMENTS:
- Powershell Core 7, this may go up to 7.5 because of these latest updates mentioned.  
- LM Studio (Windows, Linux, Mac).

### INSTALLATION:
1. Install LM Studio, and ensure you have suitable models loaded...
2. Configure "config.json" appropriately.
3. Run the launcher "StudioChat.Bat".

## NOTES:
- This project is intended a better version of the llama 2 style chatbot I made for WSL, for proof of a AI on powershell/lm studio concept; but when its done, do I make a, adventure game or agent/assitant or personal manager, out of it, what is the next stage after project completion??

## DISCLAIMER:
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
