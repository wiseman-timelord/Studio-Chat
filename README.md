# StudioChat
Working, not finished. Powershell-Core Multi-Window Chatbot with LM Studio hosted model(s). 

### DEVELOPMENT NOTES..
Early stages, it is limited. After upgrades below, there will be a review. The plan from here is...
1. format of main2 should include borders and separators, and re-draw, displaying, "current" and "recent" and "so-far", events, these will have to be consolidated by the model additionally.
2. Prompt Sent to AI with insertion of consolidated interactions in, current and recent and so-far, sections.  
3. Some kind of model for Image Generation, then use playground mode on LM Studio.
4. Requires to be created Window 3 for Graphics output, this can be based on description of "So-Far".

### RESEARCH..
- Useful Models; https://huggingface.co/models?sort=trending&search=LLama-3-8b-Uncensored+gguf , one from here should be unfiltered. Going to use this one for now, it swore at me multiple times in the first input, just asking if it had a horse, its a good sign >_> - https://huggingface.co/mradermacher/Uncensored-Frank-Llama-3-8B-GGUF/blob/main/Uncensored-Frank-Llama-3-8B.Q6_K.gguf .
- Noteworthy Models; Llama 3 Instruct-Chat Merge in 20B Paramneters, weighing around 20GB, quite acceptable for multi-line output and input, but possibly filtered. This is being investigated for use with development version of StudioChat - https://huggingface.co/AtakanTekparmak/llama-3-20b-instruct-Q8_0-GGUF/tree/main . Its Filtered.
- Noteworth Models; At some point will be using New Qwen-2 model, beating Llam 3 and producing GPT4 quality output - https://www.youtube.com/watch?v=4vrK_LvMHNM , https://huggingface.co/models?sort=downloads&search=Qwen2+57b+gguf , specifically https://huggingface.co/mradermacher/Qwen2-57B-A14B-GGUF/blob/main/Qwen2-57B-A14B.Q6_K.gguf @ 
47.1 GB.
- Powershell 7.5 Beta, PowerShell Core beta updates can significantly enhance a local model chatbot by improving data handling with ConvertTo-Json serialization of BigInteger, providing actionable error suggestions, and adding a progress bar to Remove-Item. Enhanced path handling, early resolver registration, and improved error formatting boost stability and usability. Process management fixes allow better credential handling without admin privileges and easier process monitoring, while improved stream redirection enhances integration with native applications. These updates collectively enhance robustness, efficiency, and user experience for local model chatbots.


## FEATURES:
- 2 Windows, Engine and Chat, taking up 1/4 of a widescreen display, 1/2 total.
- Multi-line input via Shift+Enter, no ability to return to earlier lines, entered with Enter at end. 

### PERVIEW:
- Engine Window...
```
Engine is running and listening on port 12345...
Sending request to LM Studio...
Received response from LM Studio



```
- Chat Window...
```
Chat Interface is running...
--------------------------------------------------------
You: hey, got a horse?
--------------------------------------------------------
Model: yes, I have a horse.

--------------------------------------------------------
You:


```
...

TBA
