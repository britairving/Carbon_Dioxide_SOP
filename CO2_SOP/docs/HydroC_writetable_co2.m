function HydroC_writetable_co2(T,writefilename,HydroC_SN,delm)
%% FUNCTION HydroC_writetable_co2
% DESCRIPTION: 
%   Write data to CSV file with variable name header, variabl units, and
%   correct precision and formatting.  
% 
%
% AUTHOR
%   Brita Irving <bkirving@alaska.edu>
%% Catch if not enough input arguments
add_HydroC_SN = 0; % default to NO
if nargin == 1
  writefilename = fullfile(pwd,'HydroC_CO2_data.csv'); % DEFAULT TO CSV FILE
elseif nargin >= 3 
  add_HydroC_SN = 1;
end
%% Define delimiter & convert to structure so can easily access fields
if nargin < 4
  delm = ','; % DEFAULT TO COMMA
end
if ismember('%rH_gas',T.Properties.VariableNames)
  T = renamevars(T,'%rH_gas','rH_gas');
end
datastructure = table2struct(T,'ToScalar',true);

%% Define paramter units 
% "2020_06_05_4HCON_Manual_HydroC_CO2_TOUGH_RevA" manual pg 19/35
units = struct();
units.Date_Time ='yyyy-mm-dd HH:MM:SS';
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
units.xCO2_corr     = 'ppm';
units.T_control     = 'C';
units.T_gas         = 'C';
units.rH_gas        = '%rH';
units.p_TDLAS       = 'mbar'; % add these so can use for HydroC CH4 too
units.pCH4          = 'uatm'; % add these so can use for HydroC CH4 too
units.xCH4          = 'ppm';  % add these so can use for HydroC CH4 too

% add additional extra variables to account for different levels of data
units.datetime_UTC = '';
units.datenum      = 'matlab_datenum';
units.S_2beam      = '';
units.S_2beamZt_interp = '';
% add response time correct variables
unit_fields = fieldnames(units);
fields = T.Properties.VariableNames;
[ia,~] = ismember(fields,unit_fields);
add_fields = fields(~ia); 
for nf = 1:numel(add_fields)
  var = add_fields{nf};
  if contains(var,'pCO2_RTC') || contains(var,'pCH4_RTC') || contains(var,'u_a_estimate') || contains(var,'std_uncertainty_estimate')
    units.(var) = 'uatm';
  elseif contains(var,'pCO2_pp')
    units.(var) = 'uatm';
  elseif contains(var,'xCO2_pp')
    units.(var) = 'ppm';
  else
    units.(var) = '';
  end
end

% Now remove those
[ia,~] = ismember(unit_fields,fields);
units = rmfield(units,unit_fields(~ia));
% make sure the order is correct for units and writing format
units = orderfields(units,datastructure);
% convert to cell array
units = struct2cell(units);


%% Define variable formats and rounding precisions
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
% add ch4 parameters
fmt.p_TDLAS    = '%.2f';
fmt.pCH4       = '%.3f';
fmt.xCH4       = '%.3f';
% add additional extra variables to account for different levels of data
fmt.datetime_UTC = '%s';
fmt.datenum      = '%f';
fmt.S_2beam      = '%.8f';
fmt.S_2beamZt_interp = '%.8f';
% add response time correct variables
fmt_fields = fieldnames(fmt);
fields = T.Properties.VariableNames;
[ia,~] = ismember(fields,fmt_fields);
add_fields = fields(~ia); 
for nf = 1:numel(add_fields)
  var = add_fields{nf};
  switch class(T.(var))
    case 'int32'
      fmt.(var) = '%d';
    case 'datetime'
      fmt.(var) = '%s';
    case 'double'
      fmt.(var) = '%.2f';
    otherwise
      keyboard
  end
end
% Now remove those
[ia,~] = ismember(fmt_fields,fields);
fmt = rmfield(fmt,fmt_fields(~ia));
% make sure the order is correct for units and writing format
fmt = orderfields(fmt,datastructure);
% convert to cell array
fmt = struct2cell(fmt);
% join and add line break
fmt = strjoin(fmt,delm);
fmt = [fmt '\n'];

%% Prepare data table for writing

% prepare data for writing
% First, remove all erroneous data
ignore = isnan(T.Runtime);
T(ignore,:) = [];
data_write   = table2cell(T); % convert to cell array to handle different variable types
data_write   = data_write';            % transpose because fprintf function prints data columnwise

%% Open file and write
fprintf('Writing data to %s\n',writefilename)
fileID = fopen(writefilename,'w');

% write HydroC SN to header x2
if add_HydroC_SN                            
  line12 = repmat(HydroC_SN,1,numel(fields));
  line12 = strjoin(line12,dlm);
  fprintf(fileID,'%s\n',line12);             
  fprintf(fileID,'%s\n',line12);
end
fprintf(fileID,'%s\n',strjoin(fields,delm)); % write fieldnames to header
fprintf(fileID,'%s\n',strjoin(units,delm));  % write units to header
fprintf(fileID,fmt,data_write{:});           % write data to file
fclose(fileID);                              % close file

