phonotaxis-experiments
===
This repository contains code and support files to run a series of phonotaxis experiments. This documentation is quite sparse currently, but `./config` and `./docs` folders contain a large amount of useful information. Additionally, `./literature` has a large number of papers that may be useful to peruse. 

#### Sound Stimuli
There are 8 speakers currently installed in a ring around the center of the rig. Each speaker can be driven independently thanks to an 8 channel sound card. Note that not all speakers are likely able to deliver the same sound field properties to the animal due to some of the optomechanical elements installed to hold hardware. 

#### Cameras
The phonotaxis rig is currently equipped with two cameras. One camera is positioned behind an air supported ball for use with FicTrac offline (or online) tracking. The second camera is positioned above the animal to track additional behavioral responses and kinematic features, for example limb position (e.g. grooming bouts) and antennal movements. 

Since responses can be quite transient, especially at low temporal resolution, dropping frames is a large concern. The system has been stress tested to acquire _at least_ 100fps from both cameras with 2x2 binning using externally sent triggers for each frame from MATALB. The following settings inside of the SpinView GUI or hardware configuration were used. I have roughly categorized the settings to help direct future tinkering.

Hardware Configuration:
- Power both cameras with 12V power supplies directly from FLIR.
- Acquired both via a FLIR (PtGrey) supplied USB3 PCIe card
- Acquired over a FLIR supplied locking USB3.1 cables and active extenders Amazon Basics brand
- Frames written to an NVMI drive 

Triggering Settings to use the optically isolated input to trigger a frame acquisition, and the programmable pin to read out when frame exposures are happening.
- Continusous aquisition mode
- Exposure Mode = timed
- Exposure Auto = Off
- Set the exposure to something that looks good on the display (in units of microseconds)
- Gain Auto = Off
- Trig Sel = frame start
- Trig mode = on
- Trig act = rising
- Trig overlap = read out (not clear this is required)
- Line 2 
	- mode = output 
	- exposure
	- leave inverted unchecked (personal preference)

Acquisition Performance Settings:
- Use Buffered Acquisition
- Buffer Handling Mode should be set to Oldest First (this is very important!!!)
- Set SpinView priority to realtime in Windows 10
- Turn off draw image OR limit the dispayed FPS (settings accessed by right clicking on images)
- Change the Device Link Throuput setting
     - To determine a conservative/valid setting, lower the value until the displayed max FPS decreases in the GUI, then increase it a bit. 
- Bin at 2x (this may not be required)

#### Misc. Notes
- The computer is high performance, so your mileage may vary with older or less powerful machines.
