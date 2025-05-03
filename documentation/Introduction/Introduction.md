# MCUViewer 

MCUViewer is a non-intrusive GUI debug tool for microcontrollers which allows to quickly visualize values of variables.

## Downloads

MCUViewer can be downloaded from the [website](https://mcuviewer.com). 

## Installation

### Windows

On Windows MCUViewer can be either installed or unpacked. Unpacking might be prefereable in some cases as it does not require admin rights. 

* Installing - download the *.zip file, unpack it, and double click the installer. Follow the instructions.
* Unpacking - download the *.zip file, unpack it, and unpack the installer once again. Copy the unpacked folders to a prefered location. Run by double clicking the `MCUViewer.exe` file from bin directory. 

### Linux

Download the *.deb package and install it using:
`sudo apt install ./MCUViewer-x.y.z-Linux.deb`

### MacOS

Download the *.dmg package. Open it and drag and drop the MCUViewer app to Applications folder. If the application does not run due to unverified source, make sure to allow it in the security preferences.


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
```c
ITM->PORT[x].u8 = 0xaa; //enter tag 0xaa - plot state high
foo();
ITM->PORT[x].u8 = 0xbb; //exit tag 0xbb - plot state low
```
And for tracing "analog" signals you can use: 
```c
float a = sin(10.0f * i);          // some high frequency signal to trace
ITM->PORT[x].u32 = *(uint32_t*)&a; // type-punn to desired size: sizeof(float) = sizeof(uint32_t)
```
or

```c
uint16_t a = getAdcSample();       // some high frequency signal to trace
ITM->PORT[x].u16 = a;              
```

where x is the channel number in MCUViewer.

6. Click the large "STOPPED" button to begin acquisition



## License

MCUViewer is distributed under EULA License. The license is available in: 

* Windows: `C:\Program Files\MCUViewer\bin`
* Linux: `/usr/local/MCUViewer`
* MacOS: `Applications/MCUViewer/Contents/Resources`











  

