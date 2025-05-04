(FAQ)=
# FAQ 

## Variable Viewer

1. **My variable is not listed in the import dialog.**

   First, make sure the variable is global, i.e., it has a constant address throughout the entire lifetime of your program. Next, check the type of your variable-if it's a pointer, it won't be detected. You can try creating a new variable by right-clicking in the variable table area and selecting `New ->Variable`. Set the name manually and close the window. If the variable is detected, the address will change from "NOT FOUND!" to a valid address. If that does not work, please contact us at contact@mcuviewer.com.

2. **I'm using a JLink probe and my target resets each time I start the acquisition.**

   Make sure that the JLink probe SWD speed is not set to too high of a value. Try lower speeds and ensure that the "keep connection" option in the Acquisition window is checked.

3. **I'm using a JLink probe and my target seems to halt for a few milliseconds each time I start the acquisition.**

   Try selecting a generic device (e.g., Cortex-M4 instead of STM32G474) and ensure that the "keep connection" option in the Acquisition window is checked.

4. **The sampling frequency set in the Acquisition window is not reached.**

   If possible, try selecting a higher SWD speed. If that's not possible, you can lower the sampling frequency or switch to the recorder module for high-frequency signals.

## Recorder 

1. **The recorder module is not detected.**

   Make sure the correct `*.elf` file is selected and that you're calling the `recorderStep()` function in your code. If the problem persists, please contact us at contact@mcuviewer.com.

2. **The recorder module does not show any data.**

   First, ensure that the recorder is detected correctly in the **Acquisition** settings window. If it is detected correctly, make sure that the mode referenced in {ref}`RecorderUsage` is set to `auto` so that the trigger is not needed for acquisition.

## Trace Viewer

1. **I see no data and get a timeout error.**

   Make sure that the SWO output is active-connect a logic analyzer or oscilloscope to see if it gets activated after pressing the start button. If the SWO is not active but there are no errors, please contact us at contact@mcuviewer.com.

2. **My MCU seems to halt each time I start the acquisition.**

   This is a known Trace Viewer issue that will be resolved in future releases. If this is a blocking issue, please use the {ref}`Recorder` module instead.

3. **I get a lot of error frames and red markers on the plots.**

   Most likely, the debug probe is not fast enough for the SWO output settings. Try increasing the prescaler and make sure the core frequency is set correctly.

4. **I get a lot of delayed frames and yellow markers on the plots.**

   Most likely, you're reaching the bandwidth limit of your probe. You can try reducing the prescaler, as long as there are no error frames.
