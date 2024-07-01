# 12\. Appendices

## 12.1 Communicating with the sensor using a terminal program and a cable

All information regarding communication with the HydroC, whether through the comm cable or via scripted commands were taken from the _NMEA HydroC Protocol overview_ (provided by the manufacturer upon request).

### 12.1.1 HydroC<sup>TM</sup> CO<sub>2</sub>T Zeroing

During a mission while the glider is at the surface, it may be useful for data processing and response time verification to have the HydroC perform a zeroing interval.

Below are instructions how to instruct the HydroC to start a zeroing interval while connected to the Seaglider with the comm cable but the user should always take care to ensure this is appropriate and applicable to their HydroC sensor and Seaglider.

**While the glider is still in the water, connect the comm cable so we can run the HydroC through zeroing mode for 2 minutes.**

# Go to loggers menu

\[2\] hw

\[11\] loggers

\[2\] HydroC

\# make sure the the hydroC is on, then go to direct comms

\[1\] turn on

\[11\] Direct comms

\# dialog should begin writing to the screen. For example...

$COTS1,0,0,D,0,0,2021-11-11,06:54:41,,7,21360,0,,0,18839,0,0,85368,0,0\*5b

$CODS4,0,0,D,0,0,2021-11-11,06:54:43,,7,506,,102789,99472,,,1052250,24350008,0,0,1,,,,,107729,13839,18495,19100,441260,0,44803,45637\*5d

$COTS1,0,0,D,0,0,2021-11-11,06:54:43,,7,21724,0,,,18849,0,0,86055,0,0\*64

$CODS4,0,0,D,0,0,2021-11-11,06:54:45,,7,504,,102818,99487,,,1008875,24302890,0,0,1,,,,,107731,13839,18493,19200,440657,0,44719,45545\*57

\# the flags, 0, 0, 1 indicate logical "Zero", "Flush", and "external pump", respectively

\# turn on config, turn off pump, put glider into zero mode

$COCFG,0,0,W,1 # turn on config mode -- takes glider out of measure mode

$COPEX,0,0,W,0,0 # turn off pump, not necessary for zeroing

$COMDI, 0,0,W,1,120,1,1,1 # puts glider into zeroing mode for 120 seconds

\# after 2 minutes, it's okay to turn off HydroC and recover

## 12.2 Useful files

With the HydroC operating in logdev mode, the hydroc.cnf file tells the Seaglider how to communicate with the logger and allows scripts to be called with further instructions.

#### 12.2.1 hydroc.cnf

**hydroc.cnf**

name=HYDROC

prefix=cd

warmup=400

timeout=4000

baud=9600

voltage=24

current=0.35

cmdprefix=$CD_

prompt=not_used

datatype=u

start=%Y%F$COPEX,0,0,W,1,0%r%n%9%9%9%9%9$COCFG,0,0,W,0%r%n%\[$COCFG,0,0,D,0\*3a%r%n\]

stop=%X

clock-set=%Y%F%{$CORTS,0,0,W,1000,%y,%m,%d,0,%H,%M,%S,0}%r%n$CORTS,0,0,R,1000%r%n%\[%r%n\]

clock-read=%Y%F$CORTS,0,0,R,1000%r%n%\[%r%n\]

clock-sync=gps1

status=%F$COPOL,0,0,R,1%r%n

download=%F$COPOL,0,0,R,1%r%n

post-stop=on

post-clock=on

post-transfer=on

script-x=CD_STOP

script-y=CD_CFG

**CD_STOP**

%F$COCFG,0,0,W,1%r%n%\[$COCFG,0,0,D,1\*3b%r%n\]

%F$COPEX,0,0,W,1,0%r%n%9%9%9%9%9

%F$COCFG,0,0,W,0%r%n%\[$COCFG,0,0,D,0\*3a%r%n\]

**CD_CFG**

%F$COCFG,0,0,W,1%r%n%\[$COCFG,0,0,D,1\*3b%r%n\]

#### 12.2.2 HydroC_CO2_read_and_convert_raw_file.m

#### 12.2.3 HydroC_writetable_co2.m

## 12.3 Lessons learned and improvement ideas

- Have a watchdog that cuts power for the HydroC/loggers after no comms for XX hours (e.g. ~8 hours). This would be useful to ensure the HydroC is off and thus not using battery power, for example if communication is lost with the glider but a rescue is still feasible.
- Have an emergency weight release, similar to the Slocum ejection weight, that triggers at predetermined events. This would be useful if the glider hit the seafloor and sediment was sucked into the HydroC flowhead by the pump and not able to clear itself, thus making the glider too heavy to surface.
- Loitering/hovering could be useful to characterize the HydroC response time by performing a zeroing interval during the loiter/hover or to collect discrete samples at the loiter depth. However, this may present more challenges than benefits though, because the glider would need to be perfectly ballasted.
- Similar to how it’s useful to have up/downcast pairs to apply thermal lag correction to glider data, it’s useful to have up/downcast pairs to apply response time correction to the CO<sub>2</sub> data.
- The HydroC is very power hungry so power on/off according to scientific objectives
- In the configuration detailed here, the HydroC was installed directly in front of the altimeter and rendered it useless.