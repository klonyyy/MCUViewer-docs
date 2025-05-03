(FAQ)=
# FAQ 

(FAQVariableViewer)=
## FAQ - Variable Viewer

1. *My variable is not listed in the import dialog.*

First make sure the variable is global i.e. it has a constant address throughout the whole lifetime of your program. Next check the type of your variable - for example if it's a pointer it won't be detected. You can try making a new variable by right clicking in the variable table area and selecting New->Variable. Set the name manually and close the window. If the variable is detected the address will change from "NOT FOUND!" to a valid address. If that does not work please contact us at contact@mcuviewer.com.

2. *I'm using JLink probe and my target resets each time I start the acquisition.*

Make sure that the JLink probe SWD speed is not set to a too high value. Try lower speeds and make sure the "keep connection" from Acquisition window is checked.

2. *I'm using JLink probe and my target seems to halt for a few milliseconds each time I start the acquisition.*
   
Try selecting a generic device (eg. Cortex-M4 instead of STM32G474) and make sure the "keep connection" from Acquisition window is checked.

3. *The sampling frequency set in the Acquisition window is not reached.* 

If possible try selecting a higher SWD speed. If that's not possible you can lower the sampling frequency or switch to a recorder module for high-frequency singnals. 
   
(FAQRecorder)=
## FAQ - Recorder 

1. *The recorder module is not detected.*

Make sure the correct *.elf file is selected and that you're calling the `recorderStep()` function in your code. If the problem persists please contact us at contact@mcuviewer.com.


(FAQTraceViewer)=
## FAQ - Trace Viewer

1. TODO




