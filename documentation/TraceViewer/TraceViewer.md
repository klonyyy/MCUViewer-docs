(TraceViewer)=
# Trace Viewer

Trace Viewer module makes use of SWO output to collect very high frequency data from the target device. It allows to profile the interrupts, or display high speed signals in the form of plots. It has almost no runtime overhead - only single register write is needed per data point. 

```{note}
Trace Viewer is available on cores that support SWO. Cortex-M0 and Cortex-M0+ are not supported.
```

Trace Viewer window consists of four main parts:

1. [Control panel](ControlPanel) - main control panel.
2. [Indicators](Inticators) - trace status and error indicators.
3. [Channels list and settings](Channels) - list of all channels and quick-access settings.
4. [Channels canvas](ChannelsCanvas) - plots are drawn here.

```{figure} ./images/TraceViewer.png
:width: 1000px
:align: center
```

## Target setup

Connect SWDIO, SWCLK, SWO, and GND to your target. 

