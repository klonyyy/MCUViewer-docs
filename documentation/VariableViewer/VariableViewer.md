
# Variable Viewer

Variable Viewer module allows to visualize values of variables in real time. It uses the debug probe to sample memory under addresses read from *.elf file of your project. It's quick to set up and almost non-intrusive way of accessing MCU data. Variable Viewer module allows to both read and write variables values in realtime. 

Variable Viewer window consists of five main parts:

1. [Control panel](ControlPanel) - main control panel
2. [Variable table](VariableTable) - imported variables will show up here
3. [Plot group tree](PlotGroupTree) - list of all groups and plots
4. [Plot settings](PlotSettings) - settings for currently selected plot
5. [Plot canvas](PlotCanvas) - plots are drawn here

```{figure} ./images/VarViewer.png
:width: 1000px
:align: center
```

(ControlPanel)=
## Control panel

There are three main buttons in the control panel:

1. START/STOP button - used to start/stop data acquisition. When error occurs the button will turn red and display the error message when hovered over.
2. Import variables button - used to import variables from your project and add them to the variable table
3. Refresh addresses - used to refresh addresses of imported variables in case automatic refresh did not succeed 

```{note}
When "refresh on *.elf change" in [Acquisition](Acquisition) window is checked the refresh button will be automatically pressed when the *.elf file is changed.
```

(VariableTable)=
## Variable table 

Variable table holds all variables 

There are two ways of adding variables to the table:
1. Click the import variables button and select the variables from your project.
2. Right click in the variable table area and select `New->Variable`. Set the name manually and close the window. This option can be used if your variable is not listed in the import dialog.
  
```{figure} ./images/AddVariable.png
:width: 1000px
:align: center
```

You can see each variable's settings by double clicking it or by right clicking and selecting Properties.

```{figure} ./images/VariableProperties.png
:width: 1000px
:align: center
```

Generally the default settings are usually sufficient. However there are some cases when some modifications are necesarry. 

### Variable not found in import window

Sometimes the import window is not able to detect some variables with more convoluted type. In such cases you can use the `New->Variable` option to add the variable manually. Then by changing the Name field the variable should be detected correctly when the window is closed

### Fixed point variable

MCUViewer is able to interpret fixed point variables. To do so make sure the original variable is imported. You can either copy the original and modify the copy or modify the original directly. 

```{note}
Right now interpreted variables cannot be easily distinguished from original variables - this is why it's recommended to copy the original variable and add a postfix to the copied variable name, eg. "_FR" to idicate a fractional variable. 
```

```{figure} ./images/Fractional.png
:width: 1000px
:align: center
```
1. Copy the original variable (right click -> copy). Add "_FR" to the copied variable name.
2. Select "Specify tracked name" setting
3. Select the original variable in the "Tracked name" field
4. Select the fixed point interpretation option (signed or unsigned)
5. Set the number of fractional bits (depends on the detected type)
6. Either type a numeric base (scaling factor) or select a variable that holds it. This is useful when you'd like to represent physical values in the plot.


### Error bits

Error bits can be easily extracted from an error word variable using the "Postprocessing" tab. 

```{figure} ./images/ErrorBits.png
:width: 1000px
:align: center
```

1. Add a new variable (right click -> New->Variable)
2. Select "Specify tracked name" setting and select the error word variable
3. In the "Postprocessing" tab select the number of right shifts (position of the bit)
4. Set the mask to 0x1 to cut only the last bit.

After that the variable should be set to one when the bit is set, and zero when it's cleared. 


(PlotGroupTree)=
## Plot group tree

Plot group tree holds all groups and plots. Each group can contain multiple plots. There are two types of groups: 

1. Sampling group - plots in this group are being sampled with sampling frequency set in the Acquisition window. It allows to take longer time series recordings, however it's not recommended for high speed signals as they can get distorted since the sampling frequency is not synchronized to the signal frequency.

2. Recorder group - curve plots in this group are displayed from the recorder's buffer. The recorder allows to display high frequency data without distortion. Please see [recorder setup](../Recorder/Recorder.md) for more details.

To add a new group simply right click in the plot group tree area and select `New->Sampling group` or `New->Recorder group`. 

```{note}
The recorder group can only be added if the recorder module is detected. Please see [recorder setup](../Recorder/Recorder.md) for more details.
```

To add a plot to a group right click on a group and select `New->Plot`.

Plot settings can be accessed by double clicking it's name or by right clicking and selecting Properties.

```{figure} ./images/PlotSettings.png
:width: 1000px
:align: center
```

By default the plot is of type curve, hovewer there are four types available: 

1. Curve - regular time based plot
2. Bar - bar plot
3. Table - table plot, also used to write values
4. XY - Curve plot with selectable X and Y axes

When new plots are added they are empty. One can drag and drop the variables from variable table to add them to the plot area. 

```{figure} ./images/DragNDrop.png
:width: 1000px
:align: center
```
(PlotSettings)=
## Plot settings

Plot settings window is a separate window that holds all the settings for currently selected plot. It might look differently based on the group type. This window allows to turn on cursors, statistics window, and manipulate the plot variable list. 

### Cursors

Cursors allow to measure signal properties like on an oscilloscope. 

```{figure} ./images/Cursors.png
:width: 1000px
:align: center
```

1. Turn on cursors
2. Drag the X0 or X1 cursor
3. The results are shown close to the X1 cursor
4. The values ov variables are displayed in the legend. These are the Y-axis values at X0 cursor position. 

### Statistics window

Statistics window allows to display statistics for the currently selected plot.

```{figure} ./images/Statistics.png
:width: 1000px
:align: center
```

1. Turn on statistics window
2. Select the series to be analyzed
3. Select range to pick a subset of data
4. Drag the ends of the range to modify it

### Plot variable list

Plot variable list allows to add/remove variables from the plot. Right click to remove a varaible from the plot. Check/uncheck to include/exclude the variable from the plot.

```{note}
Ticking the checkbox next to a variable will remove it from the sampling list only after restart. During acquisition it can be used to hide a particular series.
```

### Export to *.csv

Click to export to *.csv - the data is exported as a table of all series from the selected plot. 


(PlotCanvas)=
## Plot canvas

Plot canvas is where all plots are drawn. 

### Table plot

Table plot type can be used to read (1) and write (2) a variable value. Right clicking on the read field (1) allows to change the display format to hexadecimal, or binary.

```{figure} ./images/WriteValue.png
:width: 1000px
:align: center
```
```{note}
New variable value can be written when the write field is focused and enter key is pressed, or when the write button is clicked. When the field looses focus it will not be written.
```

### Curve plot

Curve plot manipulation is done using mouse - drag to pan, scroll to zoom, right click to open context menu. Right click and drag allows to select a zoom window. Double left click adjusts the scale to fit the data. 

```{Warning}
Zooming and dragging is not possible during the acquisition.
```

