# Pre-deployment operations and calibrations

In addition to the standard pre-deployment procedures necessary for any ocean glider mission (e.g. [Rutgers RUCOOL Glider Operation Checklists](https://rucool.marine.rutgers.edu/data/underwater-gliders/glider-operation-checklists/)), sensor pre-calibration is an important part of the process for sensors measuring pCO<sub>2</sub> to ensure high quality data.

## Pre-deployment calibrations

## CONTROS HydroC<sup>TM</sup> CO<sub>2</sub>T

### Manufacturer calibration

An in-water 4-point calibration is performed at the manufacturer given expected temperatures supplied by the user. The sensor is calibrated in deionised water, sodium carbonate and bicarbonate are added to simulate seawater, against a flow-through *p*CO<sub>2</sub> system calibrated against primary and secondary standards {cite}`Fietzeketal2014`. To ensure the best quality data returns, a post-calibration at the manufacturer should be carried out to account for changes in the characteristics of the NDIR sensor.

(response_time_verification)=
### Response time verification

The response time with the HydroC CO<sub>2</sub> TOUGH membrane is very stable but is affected by pump speed, tube length, etc.. The below is included if the user wishes to verify the response time in the field to ensure the highest quality post-processed data product. The response time can be verified in the lab in a bucket or tank, or at deployment or recovery when the glider will be stationary for approximately 15 minutes and *p*CO<sub>2</sub> concentrations are stable. See {numref}`hydroc_zero_through_seaglider` for instructions how to perform a zeroing through the Seaglider communication cable. 

For estimating the response time, we look at the signal recovery from zero to ambient conditions, so we have to consider how the zeroing works:

- During zeroing the detector is separated from the membrane path and CO<sub>2</sub> is removed after the flow is directed through a soda lime cartridge
- when reconnecting with the membrane headspace the two gas volumes are mixed, which results in a fast increase in concentration (almost linear)
- the kink in the curve (close to the red dot) marks the end of the mixing phase
- after this mixing the slower exponential rise characterizes the sensors actual response via the membrane

:::{figure-md} zeroing
<img src="/book_files/zeroing.png" alt="zeroing" class="bg-primary mb-1" width="500px">

Zero cycle including zero CO<sub>2</sub> gas measurement and the subsequent flush of the zero gas with the ambient, or sample, gas. In the inset box, the whole zeroing cycle can be seen where *p*CO<sub>2</sub> drops to zero, then climbs rapidly as the two gas volumes mix (zero gas + ambient gas during the internal mixing). At the end of the internal mixing (yellow star), the time for the signal to recover to 63 % of the ambient concentration is the sensor response time, or 𝝉<sub>63</sub>. Figure adapted from *2021-01-14_Data_Processing_HydroC_CO2-2.pdf*.
:::


## Sensor configuration for deployment
The HydroC should be set to collect high resolution (<5 Hz) data to allow accurate response time correction (see {numref}`response_time_correction`). 