(Recorder)= 
# Recorder 

The recorder module allows visualization of very high-speed signals, even on low-cost targets or when SWD communication speed is limited due to galvanic isolators or long cables. It is more intrusive than using a sampling group, as it must be compiled into your project—although the runtime penalty is usually minimal.

```{figure} ./images/RecorderDemo.gif
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
* Compile the project and add select the *.elf file in the Options->Acquisition window.
* Select the debug probe. 
* Enable the recorder module by ticking the "Recorder" checkbox (1) in the Options->Acquisition window.
* Click the `Detect recorder` button (2). If it is detected correctly there should be no errors, just a `Recorder detected!` information with all fields filled in as in the `recorderDefines.h` file.

In case of errors please first see the {ref}`FAQRecorder` section.

```{figure} ./images/RecorderSettings.png
:width: 1000px
:align: center
```

## Recorder usage

After successful setup it is now possible to add a new recorder group. Proceed to the {ref}`PlotGroupTree` section, right click and select `New->Recorder group`.

1. `Mode` - similarly to how oscilloscope works. `Auto` will continuously collect and display data, `Normal` will display data on each trigger occurrence, `Single` will display data only once for trigger occurrence. 
2. `Source` - select the variable that will be used as a trigger signal.
3. `Edge` - `Rising` will display data on the rising edge, `Falling` will display data on the falling edge.
4. `Downsample` - collect every Xth sample, allowing a longer acquisition window at the cost of reduced sampling rate.
5. `Trigger level drag line` - use to set up the trigger level. If not visible, double-left-click on plot area to adjust zoom. 
6. `Pretrigger drag line` - use to set up the amount of pre-trigger data. If not visible, double-left-click on plot area to adjust zoom.

```{figure} ./images/RecorderUsage.png
:width: 1000px
:align: center
```

```{warning}
Currently post-processed variables (for example error bits) cannot be used as trigger source. 
```