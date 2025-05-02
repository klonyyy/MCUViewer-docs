# MCUViewer 

MCUViewer is a non-intrusive GUI debug tool for microcontrollers which allows to quickly visualize values of variables.


## Downloads

MCUViewer can be downloaded from the [website]("XXX"). 

## Installation

### Windows

On Windows MCUViewer can be either installed or unpacked. Unpacking might be prefereable in some cases as it does not require admin rights. 

* Installing - download the *.zip file, unpack it, and double click the installer. Follow the instructions.
* Unpacking - download the *.zip file, unpack it, and unpack the installer once again. Copy the unpacked folders to a prefered location. Run by double clicking the `MCUViewer.exe` file from bin directory. 

### Linux

Download the *.deb package and install it using:
`sudo apt install ./MCUViewer-x.y.z-Linux.deb`

### MacOS

Download the *.dmg package. Open it and drag and drop the MCUViewer app to Applications folder.


## Quick Start - Variable Viewer

![alt text](images/VarViewer_white.png)

Variable viewer module samples the selected variables addresses in regular time intervals - it's generally well suited for medium frequency signals as the sampling rate is limited by SWD speed and type of probe that is used. If high speed readout is needed please refer to the [Recorder](#recorder) section, or try the SWO-based Trace Viewer. 

1. Select *.elf file of your project in Options->Acquisition
2. Select the debug probe
3. Close the Options -> Acquisition window and click import variables button. 
4. Select variables you'd like to visualize and click import
5. Now drag and drop the variables onto the plot canvas
6. Click the large "STOPPED" button to begin acquisition

In case of any errors make sure to follow the instructions and visit FAQ.


## Quick Start - Trace Viewer

![alt text](images/TraceViewer_white.png)

Trace Viewer module parses SWO trace data an displays the results in the form of plots. It is possible to visualize high speed signals with minimum overhead, as well as digital plots to visualize/profile interrupt execution.

1. Switch to Trace Viewer tab
2. Select the debug probe in Options->Acquisition, close the window
3. Type in your core frequency in kHz
4. Select trace prescaller - start with a rather high value (~20) as it largely depends on your debug probe and SWD setup
5. In your code place special markers: 

Example for digital data: 
```
ITM->PORT[x].u8 = 0xaa; //enter tag 0xaa - plot state high
foo();
ITM->PORT[x].u8 = 0xbb; //exit tag 0xbb - plot state low
```
And for tracing "analog" signals you can use: 
```
float a = sin(10.0f * i);          // some high frequency signal to trace
ITM->PORT[x].u32 = *(uint32_t*)&a; // type-punn to desired size: sizeof(float) = sizeof(uint32_t)
```
or

```
uint16_t a = getAdcSample();       // some high frequency signal to trace
ITM->PORT[x].u16 = a;              
```

where x is the channel number in MCUViewer.

6. Click the large "STOPPED" button to begin acquisition



## License

MCUViewer is distributed under EULA License. The license is available in: 

* Windows -> C:\Program Files\MCUViewer\bin
* Linux -> /usr/local/MCUViewer
* MacOS -> Applications/MCUViewer/Contents/Resources
  

## Variable Viewer

Variable Viewer window consists of four main parts:

1. Variable table - imported variables will show up here
2. Plot group tree - list of all groups and plots
3. Plot Settings - settings for currently selected plot
4. Plot canvas - plots are drawn here

![alt text](VarViewer.png)

### Variable table

There are two ways of adding variables to the table:
* Click the import variables button and select the variables from your project.
* Right click in the variable table area and select New->Variable. Set the name manually and close the window. This option can be used if your variable is not listed in the import dialog.
  
![alt text](image.png)

You can see each varaible's settings by double clicking it or by right clicking and selecting Properties.





### Plots 




## FAQ 

### Variable Viewer

1. *My variable is not listed in the import dialog.*

Make sure the *.elf file is correct, and check the type of your variable - if it's a pointer it won't be detected. You can try making a new variable by right clicking in the variable table area and selecting New->Variable. Set the name manually and close the window. If the variable is detected the address will change from "NOT FOUND!" to a valid address.

2. *I'm using JLink probe and my target resets each time I start the acquisition.*

Make sure that the JLink probe SWD speed is not set to a too high value. Try lower speeds and make sure the "keep connection" from Acquisition window is checked.

2. *I'm using JLink probe and my target seems to halt for a few milliseconds each time I start the acquisition.*
   
Try selecting a generic device (eg. Cortex-M4 instead of STM32G474) and make sure the "keep connection" from Acquisition window is checked.

3. *The sampling frequency set in the Acquisition window is not reached.* 

If possible try selecting a higher SWD speed. If that's not possbile you can lower the sampling frequency or switch to a recorder module for high-frequency singnals. 
   













  

