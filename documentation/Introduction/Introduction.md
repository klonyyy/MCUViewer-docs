# Introduction 

MCUViewer is a non-intrusive GUI debugging tool for microcontrollers that allows quick visualization of variable values in real-time.

```{figure} ./images/VariableViewer.gif
:width: 1000px
:align: center
```

## Downloads

MCUViewer can be downloaded from the [MCUViewer website](https://mcuviewer.com/#downloads).

## Installation

### Windows

On Windows MCUViewer can be either installed or unpacked (portable version). Unpacking might be preferable in some cases as it does not require admin rights. 

* Installing - download the *.zip file, unpack it, and double click the installer. Follow the instructions.
* Unpacking - download the *.zip file, unpack it, and unpack the installer once again. Copy the unpacked folders to a preferred location. Run by double clicking the `MCUViewer.exe` file from bin directory. 

```{note}
Minimum supported version is Windows 10.
```

### Linux

Download the *.deb package and install it using:
`sudo apt install ./MCUViewer-x.y.z-Linux.deb`

```{note}
Minimum supported version is Ubuntu 22.04 LTS. 
```

### MacOS

Download the *.dmg package. Open it and drag and drop the MCUViewer app to Applications folder. If the application does not run due to unverified source, make sure to allow it in the security preferences.

```{note}
Minimum supported version is MacOS 12 (Monterey).
```

## Quick Start - Variable Viewer

```{figure} ./images/VarViewerWhite.png
:width: 1000px
:align: center
```

The Variable Viewer module samples the addresses of selected variables at regular time intervals. It is generally well-suited for medium-frequency signals, as the sampling rate is limited by the SWD speed and the type of probe used. If high-speed readout is required, please refer to the {ref}`Recorder` section or try the SWO-based Trace Viewer.

Your target should be connected to the debug probe using SWDIO, SWCLK, and GND pins.

1. Select the `*.elf` file of your project in `Options->Acquisition`.  
2. Choose the debug probe.  
3. Close the `Options->Acquisition` window and click the `Import Variables` button.  
4. Select the variables you want to visualize and click `Import`.  
5. Drag and drop the selected variables onto the plot canvas.  
6. Click the large `STOPPED` button to start data acquisition.

In case of any errors make sure to visit {ref}`VariableViewer` and {ref}`FAQ`


## Quick Start - Trace Viewer

```{figure} ./images/TraceViewerWhite.png
:width: 1000px
:align: center
```

The Trace Viewer module parses SWO trace data and displays the results in the form of plots. It enables visualization of high-speed signals with minimal overhead, as well as digital plots for visualizing and profiling interrupt execution.

Your target should be connected to the debug probe using the `SWDIO`, `SWCLK`, `SWO`, and `GND` pins.

1. Switch to the `Trace Viewer` tab.  
2. Select the debug probe in `Options → Acquisition`, then close the window.  
3. Enter your core frequency in kHz in the main window.  
4. Select a trace prescaler - start with a relatively high value (e.g., ~20), as this depends heavily on your debug probe and SWD setup.  
5. In your code, place special markers:


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

6. Click the large `STOPPED` button to begin acquisition

In case of any errors please visit {ref}`TraceViewer` and {ref}`FAQ`

## License

MCUViewer is distributed under the EULA License. The license is available in:

* Windows: `C:\Program Files\MCUViewer\bin`
* Linux: `/usr/local/MCUViewer`
* MacOS: `Applications/MCUViewer/Contents/Resources`












  

