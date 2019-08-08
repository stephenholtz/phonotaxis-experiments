# phonotaxis-experiments
Code and support files to run a series of phonotaxis experiments 


Jumbled notes for acquiring frames without dropping for long duration experiments. So far this means 2x cameras at 100fps:
- Power Cameras with 12V power supplies
- Use PtGrey(FLIR) supplied USB3 PCIe card
- Use PtGrey(FLIR) supplied locking USB3.1 cables and active extenders (amazon basics)
- Acquire using buffered mode to Motion JPEG -- 85% quality is fine for tracking
- acquire to NVMI drive 
- Set SpinView priority to realtime in windows, maybe also do that for matlab
- Turn off draw image or linmit dispayed FPS(menu showed by right clicking on image)
- Change the Device Link througput to somethign that makes sense, keep it low -- if it is too low then the max FPS will decrease in the GUI to let you know it needs to be higher
- *** Buffer Handling Mode should be set to Oldest First
- Continusous aquisition
- Exposure Mode = timed
Exposure Auto = Off
Gain Auto = Off
Trig Sel = frame start
Trig mode = on
Trig act = risign
trig overlab = read out
Line 2 mode should be output , and exposure
Bin at 2x

not all of these are required settings for high FPS and no dropped frames, just what I settled on... will update soon! email if you have questions
