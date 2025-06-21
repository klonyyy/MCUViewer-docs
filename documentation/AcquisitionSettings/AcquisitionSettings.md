
(AcquisitionSettings)=
# Acquisition Settings

Acquisition settings window is used to control the acquisition. 

## General section

The general section holds general settings for the acquisition.

1. `*.elf file` - select the *.elf file of your project
2. `Save *.elf file path as relative` - check if you'd like to save the path in your *.mcuvproj file as relative. This can be useful when you share your project with others.
3. `Refresh on *.elf change` - if checked the addresses of imported variables will be automatically refreshed when the *.elf file is changed (whenever you recompile)
4. `Stop on *.elf change` - if checked the acquisition will be stopped when the *.elf file is changed (whenever you recompile)
5. `Sampling` - set the sampling frequency in Hz. Depending on your debug probe setup this can be reached or not. 
6. `Max points` - number of points in the circular buffer collecting the data. When acquisition is longer the oldest points are going to be lost. At low sampling frequencies you can use {ref}`Logging` to stream the data to a file.
7. `Viewport points` - width of the plot viewport in points during acquisition. Lower values are preferred as they make the interface more responsive.


```{figure} ./images/AcquisitionGeneral.png
:width: 1000px
:align: center
```

## Debug probe section

The debug probe section holds settings for the debug probe. The window below presents JLink settings, as STLink setup is more straightforward. Please see next section for GDB server probe setup.

1. `Debug probe selection` - select the debug probe you are using
2. `Debug probe serial number` - select a serial number of your debug probe
3. `SWD speed in kHz` - select a SWD speed in kHz. Be careful with too high values as they can cause target resets. Too low values will lower the maximum data rate. The recorder module is not affected by this setting.
4. `Target name` (JLink only) - select your target name. For some targets there might be a CPU halt issued on acquisition start. In such cases select a generic device, for example Cortex-M4 instead of STM32G474.
5. `Mode` (JLink only) - select either normal or [HSS]("https://kb.segger.com/J-Link_High-Speed_Sampling") mode. Normal mode will work on all JLink probes, however it's much slower. HSS mode allows to reach very high update frequencies (tens of kilohertz), however it's limited to certain JLink types. The recorder module is not affected by this setting.
6. `Keep connection` - if checked the connection will be kept open after acquisition is stopped. With ST-Link it's necessary to avoid target halts when restarting. Uncheck if CPU halts are not problematic in your application - this makes programming easier as you don't have to manually disconnect using the main screen top right status button. 

```{figure} ./images/AcquisitionDebugProbe.png
:width: 1000px
:align: center
```

## GDB server probe section

GDB server can be used in case your probe is not natively supported by MCUViewer (other than STLink and JLink).

To use the GDB server probe you first need to start a GDB server that can connect to your probe. It can be a vendor-provided GDB server or openOCD. Since GDB servers usually halt the target on connect we need to either resume it or configure it to not halt. There are two ways to achieve this:

1. Resume the target using telnet

2. Avoid halting the target by adding the following line to the target.cfg file:

```
$_TARGETNAME configure -event gdb-attach { resume }
gdb memory_map disable
```

After running the server ensure a correct IP and port number is set in MCUViewer. After that simply exit the window and start acquisition. If the acquisition is too slow please check out the {ref}`Recorder` page. 

The exact same GDB server can be used to download the new firmware so that no server restart is needed. In such cases make sure the target is halted before download and after it should be resumed. An example flow might look like this:

1. Start the GDB server, pass the probe and target as arguments
2. Connect using MCUViewer (at this stage it will most probably be halted so all traces will be constant)
3. Connect from other terminal using telnet to the GDB server
4. Download the new firmware
5. Resume the target
6. Go back to MCUViewer

This can be highly automated in a workflow described in {ref}`Examples` section.


## Recorder section

Recorder settings will be discusses in more detail in {ref}`Recorder`.

(Logging)=
## Logging section

Logging can be used to stream data to a *.csv file in real time. It works by saving all sampled variables in a csv table with a timestamp. A new log file is created on each start in the selected directory. 

```{note}
Logging can decrease the performance when using high frequency sampling. 
```

```{note}
Logging cannot be used with the recorder module.
```

## Advanced section

GDB is used to parse *.elf file. In case you'd like to select a different gdb instance on your PC you can change it in the `GDB command` field. 