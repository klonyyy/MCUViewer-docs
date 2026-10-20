---
description: "Capture very high-speed signals even over slow or isolated SWD links by adding the MCUViewer recorder module to your firmware, then plot the recorded data."
---
(Recorder)= 
# Recorder 

The recorder module allows visualization of very high-speed signals, even on low-cost targets or when SWD communication speed is limited due to galvanic isolators or long cables. It is more intrusive than using a sampling group, as it must be compiled into your project-although the runtime penalty is usually minimal.

```{figure} ./images/RecorderDemo.gif
:alt: MCUViewer Recorder capturing a high-speed signal with a trigger
:width: 1000px
:align: center
```

## Recorder setup

* Copy the recorder folder from the downloaded MCUViewer *.zip file to your project. The recorder module on the target side consists of three files: 

    - `recorder.c`
    - `recorder.h`
    - `recorderDefines.h`

* Add the recorder folder to the build system. 
* Modify the recorderDefines.h file to match your system configuration.
* Call recorderStep() function at the end of your high-frequency interrupt. Make sure the recorderStep() function cannot be preempted by other interrupts.
* Compile the project and select the *.elf file in the Options->Acquisition window.
* Select the debug probe. 
* Enable the recorder module by ticking the `Enable recorder` checkbox (1) in the Options->Acquisition window.
* Click the `Detect recorder` button (2). If it is detected correctly there should be no errors, just a `Recorder detected!` information with all fields filled in as in the `recorderDefines.h` file. If an older recorder version is detected, a message asks you to update the recorder files in your project.

In case of errors please first see the {ref}`FAQ` section and {ref}`Examples` section.

```{figure} ./images/RecorderSettings.png
:alt: Recorder settings in the Acquisition Settings window
:width: 1000px
:align: center
```

(RecorderUsage)=
## Recorder usage

After successful setup it is now possible to add a new recorder group. Proceed to the {ref}`PlotGroupTree` section, right click and select `New->Recorder group`. An existing sampling group can also be duplicated as a recorder group with `Copy to recorder group`.

The recorder settings are shown in the plot settings panel of a recorder group:

1. `Mode` - similarly to how oscilloscope works. `run` will continuously collect and display data, `normal` will display data on each trigger occurrence, `single` will display data only once for trigger occurrence. 
2. `Source` - select the variable that will be used as a trigger signal.
3. `Edge` - `rising` will display data on the rising edge, `falling` will display data on the falling edge.
4. `Level` - trigger level. It can be typed in or set with the trigger level drag line (6).
5. `Downsample` - number of samples skipped between two consecutive samples shown on the plot, allowing a longer acquisition window at the cost of reduced sampling rate.
6. `Trigger level drag line` - use to set up the trigger level. If not visible, double-left-click on plot area to adjust zoom. 
7. `Pretrigger drag line` - use to set up the amount of pre-trigger data. If not visible, double-left-click on plot area to adjust zoom.

```{figure} ./images/RecorderUsage.png
:alt: Recorder plot with the trigger level and pretrigger drag lines
:width: 1000px
:align: center
```

```{warning}
Post-processed variables (for example error bits) should not be used as trigger source - MCUViewer shows a warning when such a variable is selected, as the trigger may behave unexpectedly.
```