function [data, units] = HydroC_CO2_read_and_convert_raw_file(filepath)
%% FUNCTION HydroC_CO2_read_and_convert_raw_file
% DESCRIPTION:  
%
%   Reads in raw data from terminal output, or from _raw.txt file as
%   downloaded through the CONTROS Detect software.
%
%   Reads in raw file from HydroC CO2 and adjusts necessary parameters
%   using given conversion factors. Saves Matlab datafile 
%
%   Also writes to txt file with same format as that output from converted
%   DETECT software, or jupter notebook EXCEPT the only difference is
%   decimal separators are actually decimals, unlike file from Detect or
%   jupyter script where it is a comma.
%
% INPUTS 
%   filepath = full file path to raw file
%
% AUTHOR
%   Brita Irving <bkirving@alaska.edu>
%   github.com/britairving
%
% NOTES
%  Converted from 4H Jena's python script
%  "CSG Convert Raw HydroC CO2 data to output file 04_11_2020.ipynb"
%% Define paramter units 
% "2020_06_05_4HCON_Manual_HydroC_CO2_TOUGH_RevA" manual pg 19/35
units = struct();
units.Date      ='yyyy-mm-dd';
units.Time      = 'HH:MM:SS';
units.Weekday   = '';
units.P_pump    = 'W';
units.p_NDIR    = 'mbar';
units.p_in      = 'mbar';
units.I_total   = 'mA';
units.U_supply  = 'V';
units.Zero      = 'logical'; 
units.Flush     = 'logical';
units.external_pump = 'logical';
units.Runtime   = 's';
units.Signal_raw = 'digits';
units.Signal_ref = 'digits';
units.T_sensor   = 'C';
units.Signal_proc = 'digits';
units.Conc_estimate = 'ppm';
units.pCO2_corr     = 'uatm';
units.xCO2_corr     = 'uatm';
units.T_control     = 'C';
units.T_gas         = 'C';
units.rH_gas        = '%';

%% Define file folder and path, or use default
[folder,raw_file,ext] = fileparts(filepath);
raw_file = [raw_file ext];

%% Define filenames where converted data will be saved
converted_file = strrep(raw_file,'_raw.txt','.txt'); 
converted_file = fullfile(folder,converted_file);
mat_file       = strrep(converted_file,'.txt','.mat'); 

%% Define conversion factors
% User must confirm these conversions are correct! Information in
% documentation provided with the HydroC CO2 sensor.
conv.P_pump     = 0.001;
conv.p_NDIR     = 0.01;
conv.p_in       = 0.01;
conv.I_total    = 0.001;
conv.U_supply   = 0.000001;
conv.T_sensor   = 0.001;
conv.Signal_proc = 0.01;
conv.pCO2_corr  = 0.01;
conv.xCO2_corr  = 0.01;
conv.T_control  = 0.001;
conv.T_gas      = 0.001;
conv.rH_gas     = 0.001;

%% Define format and rounding precision
fmt =  struct();
fmt.Date       = '%s';
fmt.Time       = '%s';
fmt.Weekday    = '%d';
fmt.P_pump     = '%.3f';
fmt.p_NDIR     = '%.2f';
fmt.p_in       = '%.2f';
fmt.I_total    = '%.2f';
fmt.U_supply   = '%.2f';
fmt.Zero       = '%d';
fmt.Flush      = '%d';
fmt.external_pump = '%d';
fmt.Runtime    = '%d';
fmt.Signal_raw = '%d';
fmt.Signal_ref = '%d';
fmt.T_sensor   = '%.2f';
fmt.Signal_proc ='%.2f';
fmt.Conc_estimate ='%.2f';
fmt.pCO2_corr  = '%.2f';
fmt.xCO2_corr  = '%.2f';
fmt.T_control  = '%.2f';
fmt.T_gas      = '%.2f';
fmt.rH_gas     = '%.2f';

%% Read in raw data
fid = fopen(fullfile(folder,raw_file),'r');
first_line = fgetl(fid);
fclose(fid); 
if contains(first_line,'COTB1') || contains(first_line,'COTS1')
  raw = readtable(fullfile(folder,raw_file),'Delimiter',',','HeaderLines',1);
else
  raw = readtable(fullfile(folder,raw_file),'Delimiter',',','HeaderLines',0);
end

%% Replace all CODB with CODS & COTB with COTS  
%After the sensor has received "$CODBT,0,0,Wâ€? it starts to transmit the
%data stored on the internal datalogger. This data has the same structure
%as the live online data except that the identifiers are "CODB4â€? and
%â€œCOTB1â€? instead of â€œCODS4â€? and â€œCOTS1â€?
try
  raw.Var1 = strrep(raw.Var1,'CODS4','CODB4');
  raw.Var1 = strrep(raw.Var1,'COTS1','COTB1');
catch
  keyboard
end

%% Separate COTB and CODB datalines
idx_COTB = contains(raw.Var1,'COTB1');
idx_CODB = contains(raw.Var1,'CODB4');

COTB = raw(idx_COTB,:);
old_names = [7 8 10 11 15 18]; %{'Var7' 'Var8' 'Var11' 'Var15' 'Var18'};
new_names = {'Date' 'Time' 'Weekday' 'T_control' 'T_gas' 'rH_gas'};
COTB = COTB(:,old_names);
COTB.Properties.VariableNames = new_names; %strrep(COTB.Properties.VariableNames,old_names,new_names);

CODB = raw(idx_CODB,:);
old_names = [7 8 10 11 13 14 17 18 19 20 21 26 27 28 29 30 31 32 33]; 
new_names = {'Date' 'Time' 'Weekday' 'P_pump' 'p_NDIR' 'p_in' 'I_total' 'U_supply' 'Zero' 'Flush' 'external_pump'...
  'Runtime' 'Signal_raw' 'Signal_ref' 'T_sensor' 'Signal_proc' 'Conc_estimate' 'pCO2_corr' 'xCO2_corr'};
CODB = CODB(:,old_names);
CODB.Properties.VariableNames = new_names; 

%% Convert to table
COTB = table2struct(COTB,'ToScalar',true);
CODB = table2struct(CODB,'ToScalar',true);

%% Catch if xCO2_corr was read in as a cell due to a * character
if iscell(CODB.xCO2_corr)
  CODB.xCO2_corr = extractBefore(CODB.xCO2_corr,'*');
  CODB.xCO2_corr = str2double(CODB.xCO2_corr);
end
%% Convert data using conversion factors for specific parameters
COTB_fields = fieldnames(COTB);
CODB_fields = fieldnames(CODB);
% loop through fields from $COTB1 lines
for nf = 1:numel(COTB_fields)
  cfield = COTB_fields{nf};
  if isfield(conv,cfield)
    COTB.(cfield) = COTB.(cfield) .* conv.(cfield);
  end
end
% loop through fields from $CODB4 lines
for nf = 1:numel(CODB_fields)
  cfield = CODB_fields{nf};
  try
    if isfield(conv,cfield)
      CODB.(cfield) = CODB.(cfield) .* conv.(cfield);
    end
  catch
    fprintf('Could not read variable %s\n',cfield)
    keyboard
  end
end
%% Calculate datenum
if iscell(COTB.Time)
  t = datetime(COTB.Time,'InputFormat','HH:mm:ss');
  COTB.Time = t -  datetime(floor(now),'ConvertFrom','datenum');
end
COTB.DateTime = COTB.Date + COTB.Time; % doesn't display as you'd think, but it really does add the duration
COTB.datenum  = datenum(COTB.DateTime);
COTB = rmfield(COTB,'DateTime'); % remove to avoid confusion

if iscell(CODB.Time)
  t = datetime(CODB.Time,'InputFormat','HH:mm:ss');
  CODB.Time = t -  datetime(floor(now),'ConvertFrom','datenum');
end
CODB.DateTime = CODB.Date + CODB.Time; % doesn't display as you'd think, but it really does add the duration
CODB.datenum  = datenum(CODB.DateTime);
CODB = rmfield(CODB,'DateTime'); % remove to avoid confusion

%% Merge COTB and CODB data 
% i.e. add T_control, T_gas, and rH_gas to other fields
% first, pull out indicies where dates match
gd = ismember(CODB.datenum,COTB.datenum);
gd_COTB = ismember(COTB.datenum,CODB.datenum(gd));
hydroc = struct2table(CODB);
hydroc = hydroc(gd,:);
hydroc.T_control = COTB.T_control(gd_COTB);
hydroc.T_gas     = COTB.T_gas(gd_COTB);
hydroc.rH_gas    = COTB.rH_gas(gd_COTB);
% Pull out unique timestamps and sort by datenum
[~,isort] = unique(hydroc.datenum);
hydroc = hydroc(isort,:);

% covert back to structure
data = table2struct(hydroc,'ToScalar',true);
% move datenum field to the end
data = rmfield(data,'datenum');
data.datenum = hydroc.datenum;
% add datetime too
data.datetime = datetime(data.datenum,'ConvertFrom','datenum');
%% Parse instrument
try % this won't be applicable unless the file was downloaded from Detect
  data.HydroC_SN = strcat('CO2', extractBetween(raw_file,'CO2','_raw.txt'));
end
%% Save file
save(mat_file,'data','units');

%% Write text file with same format as output from Detect or Jupyter notebook script from 4H Jena (AK_CO2_convert_raw_to_output_file.ipynb)
% NOTE: the only difference is decimal separators are actually decimals,
% unlike file from Detect or jupyter script where it is a comma.

% put this into self contained function Aug 2023 - may not work in every
% situation...
HydroC_SN = data.HydroC_SN;
data   = rmfield(data,{'datenum' 'datetime' 'HydroC_SN'});
HydroC_writetable_co2(T,converted_file,HydroC_SN,';');


end