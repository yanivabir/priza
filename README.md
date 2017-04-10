# priza

This is version 1.0.1 of the revised experiment.
Features:
- Easy switching from mirror-stereoscope to 3d screen.
- Optional anti-shadowing for 3d screen.
- Mondrian masking is supported.
- Classic frame around the stimuli is supported.
- You can choose format of saved file for results.
- Different frames can be added easily enough.
- Types of experiments implemented:
  - Classical bCFS
  - A hard conscoius control (Stimulus appearing at maximal contrast on trials start, blended into dynamic mask)
  - A static conscoius control (Stimulus appearing at maximal contrast on trials start, blended into static mask)
  - Just stimulus
  - Monocular control - like classical bCFS, but without fade in	
- Only up-down variation of the task is supported right now.
- Only images as stimuli are supported right now.

Point of interest:
- It is coded for clarity and ease of use.
- Best practices of PTB have been used to make timing as reliable as possible.
- You can choose a frame rate for flipping the screen, thus decrease demand from hardwear and avoid missed frames.
- Keyboard monitoring is does independently of screen flips, and thus is as accurate as computer allows.
- To keep everything organized, sub functions are passed all their arguments in one or two structs.

The logic of the code:

There are two high-level files, that should suffice for changning the experiment without doing anything structural:

1. B1Params - this file holds all the presentation, timing, file naming etc. parameters of the experiment. They (should) all have a comment explaining what they are about. A few parameters worth knowing:
 - location - name of the room where the experiment is run. This is for presentaiton sizes etc, as all presentation size parameters are specified in visual angles. In order to caluculate the corresponding pixel size, the size of the screen and viewing distance must be known. These are saved in the mkDisplay.m file, as per room. Rooms should be added as we measure them and implement the code in them.
 - version - this is where you can name your experiment. The master version on git-hub is alway vanilla, and should have a clean copy of th experiment, up to date with new capabilites, but without any personal stuff.
 - saltShaker - if you want to try out your experiment with a salt shaker on the keyboard, set this to 1. Otherwise, set this to 0 to stop annoying subjects doing the same.
2. B1 - this is the main experiment file, which you run at Matlab. It has a simple structure, so you can easily add instructions, change them, add blocks, etc. There are two main functions you can call on this file to change the order of stuff:
  - doInstructions - a function that presents instructions, according to the struct variable you feed to it. Details in the function.
  - runBlock - a function that runs a block of stimuli, based on the csv file listing the stimuli. Details in the function.
  
Additionaly, mkDisplay holds all display information, plus has the stereoMode parameter, that can be used to easily switch from a mirror-streoscope ('streoscope') to a 3d screen ('3d').


Wishlist:
 - Textual stimuli.
 - Frames with stronger convergence cues.
 - Other types of masks.
 - Allow for differential alpha values for different groups of stimuli.
 - Calibrate monitor gamma function on startup.
