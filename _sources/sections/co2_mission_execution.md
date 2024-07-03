(mission_execution)=
# Mission execution

## Deployment

### HydroC CO<sub>2</sub> considerations

The HydroC CO<sub>2</sub> must go through a warm-up interval, typically 30 minutes, to allow the internal gas circuity to reach a stable temperature and ensure quality data. This warm-up interval can take place on deck during transit or in the water during the first dive(s). During the warm-up interval, the pump is programmed to be off to limit power requirement.

It is important to minimize bubble entrainment in the membrane head of the HydroC CO<sub>2</sub>, so care must be taken when deployment the seaglider and data should be examined carefully over the first few dives as a quality check.

Before deployment, safety thresholds should be programmed so that an error is logged whenever a threshold is reached or exceeded. During the deployment, alongside typical log file monitoring, HydroC CO<sub>2</sub> errors should be monitored.

Example log file error line: $CD_ERRORS,P_in:0,rH_gas:0,T_control:0,P_pump:0

Example thresholds for HydroC CO<sub>2</sub>

- P_in 1100 mbar max
- \%rH_gas 85% max
- T_control must stay around +/- 0.5 degree of set temperature.
- P_pump 0.3-1.6 W, **outside of this** may indicate a problem.

During a mission while the glider is at the surface, it may be useful for data processing and response time verification to have the HydroC perform a zeroing interval. See Appendix 12.1.1 HydroC<sup>TM</sup> CO<sub>2</sub>T Zeroing for instructions on how to do this while connected to the Seaglider.

## In situ reference data

*p*CO<sub>2</sub> concentrations can have large spatial and temporal gradients, so an _in situ_ calibration may be difficult and must be carefully evaluated for usefulness. However, collecting discrete samples for reference, for example, to see if the sensor has drifted from reference samples over time or to verify that the difference observed between a discrete sample and the HydroC CO<sub>2</sub> is similar when taken during a controlled tank experiment compared to when deployed at sea, could be valuable. For example, see {numref}`RTC` and {cite}`Haurietal2024`.

### Discrete seawater samples

See SOP 1 in the [Guide to Best Practices for Ocean CO2 Measurements](https://www.ncei.noaa.gov/access/ocean-carbon-acidification-data-system/oceans/Handbook_2007.html) for details on discrete sample collection and analysis.

## Piloting

Once a new glider mission has been initiated, after acquiring the first GPS fix, the glider will turn the HydroC on and sync time. The sensor will stay on from this point on until commanded to be turned off by the pilot (using \$LOGGERS,0). This gives sufficient time for HydroC warmup since the glider launch procedure usually takes at least an hour. Once the glider is in the water, and a dive is initiated ($RESUME), the glider turns the pump on and starts diving.

For our CO2 Seaglider development project, the following commands were available after surfacing to be carried out in the following dive:

$CD_PUMP

- 0: Do not change the pump status
- 1: Turn the pump off after zeroing. This is used at the end of the mission in order to turn off the pump in the last dive, just before recovering the glider so as to avoid running the pump in air.

$CD_ZERO

- 0: Do not zero
- 1: Zero after the end of a dive (apogee)
- 2: Zero after the end of a climb (surface)

$CD_DATA

- 0: No data
- 1: Get “Critical” data in the following order:
- 2: Get “Nice to have” data in following order:
- 3: Get “Ideal” data in following order:
