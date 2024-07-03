function HydroC_CO2_tidy_data_for_hysteresis_correction(hydrocfile)
%% function HydroC_CO2_tidy_data_for_hysteresis_correction
% Description: 
%   Reads in processed (or just converted) HydroC CO2 file, tidies data to
%   avoid spikes in response time corrected signal, then saves data
%
%   Tidy data before hysteresis correction to avoid erroneous RTC spikes
%     - remove where HydroC went through zeroing + remove_minutes after   
%     - fill small gaps in data 
%     - smooth the data while keeping the original resolution
%
% Author: 
%   Brita Irving <bkirving@alaska.edu> 
%   github.com/britairving
%% Define script parameters
remove_minutes = 10;     % minutes to remove after zeroing interval
smooth_method = 'loess'; % see matlab's smoothdata doc for info
smooth_minute = 2;       
small_gap_fill = minutes(2); 

%% Define hydrocfile path - if not passed through in arguments
if nargin ~= 1
  error('** Must define hydrocfile **')
end

%% Initialize file to write tidied data to
newfile = strrep(hydrocfile,'.txt','_edited_loess.txt');

%% Read HydroC Data
opt = detectImportOptions(hydrocfile);
opt.VariableUnitsLine = 2;
opt.DataLines(1) = 3;
opt.VariableNamingRule = 'preserve';    
co2 = readtable(hydrocfile,opt);

%% Limit to unique values
[~,idx_unique] = unique(co2.Date_Time);
co2 = co2(idx_unique,:);

%% Add Date_Time parameter - not included if NOT post-processed, which is true for 2023 real-time data, unfortunately. 
if ~ismember('Date_Time',co2.Properties.VariableNames)
  co2.Date_Time = co2.Date + co2.Time;
  co2.Date_Time.Format = 'yyyy-MM-dd HH:mm:ss';
end

%% Define which pCO2 parameter to use
if ~ismember('pCO2_pp',co2.Properties.VariableNames)
  pco2_var = 'pCO2_corr'; % necessary if post processed file not available 
else
  pco2_var = 'pCO2_pp';   % used post processed pCO2
end

%% Move Date_Time to the first parameter 
% just for visual asthetics... 
co2 = movevars(co2,{'Date_Time'},'Before',1);

%% Remove unnecessary sections that will complicate deconvolution
figure; plot(co2.Date_Time,co2.(pco2_var),'k.')
fprintf('Examine pCO2 data and note any sections to remove. For example, during warmup on deck or before/after deployment.\n')
if contains(hydrocfile,'SD_datafile_20220507_150531CO2T-0422-001')% May 7 CTD cast
  bad = co2.Date_Time < datetime(2022,05,07,17,50,0) | ...  % before cast
    co2.Date_Time >= datetime(2022,05,07,19,07,55);          % after cast
else
  fprintf('need to define sections of data to remove...\n')
  keyboard
end
% Now remove those bad sections and plot 
if exists('bad','var')
  co2(bad,:) = [];
  hold on; plot(co2.Date_Time,co2.(pco2_var),'r.')
end

%% Remove where zeroing and XX minutes after zeroing...
xmins = minutes(remove_minutes);
zero = co2.Zero == 1;
% Pull out index where zeroing ends
idx_zero = find(zero);
if ~isempty(idx_zero) % winter 2023 co2 seaglider mission never went through a zeroing interval
  idx_diff = diff(idx_zero);
  idx_1 = idx_diff > 1;  idx_1 = [true; idx_1];
  idx_zero_start = idx_zero(idx_1);

  idx_diff = diff(idx_zero(2:end));
  idx_2 = idx_diff > 1;
  idx_zero_end = [idx_zero(idx_2);idx_zero(end)];
  % add xmins minutes to the end of zeroing to ignore
  ignore = [];
  for nz = 1:numel(idx_zero_end)
    idx = find(co2.Date_Time <= co2.Date_Time(idx_zero_end(nz))+xmins,1,'last');
    ignore = [ignore idx_zero_start(nz):idx];
    %co2.(pco2_var)(idx_zero_start(nz):idx) = nan;
  end
  %co2.(pco2_var)(ignore) = nan;
  co2(ignore,:) = [];
  hold on; plot(co2.Date_Time,co2.(pco2_var),'.')
end

%% Fill small gaps or uneven timesteps
% save original table for debugging purposes
co2_orig = co2;

%% Now, interpolate over small gaps to avoid rtc spikes
% small gaps may be caused by clock issue or something, but regardless of
% causes results in spikes in the response time corrected signal
med_dt = median(diff(co2.Date_Time));
% identify gaps larger than 3x the median sample interval but smaller than
% 5 minutes (which should be removed after RTC as part of the subsequent
% processing)
idx_gap   = find(diff(co2.Date_Time) > med_dt*3 & diff(co2.Date_Time) < small_gap_fill ,1);
if ~isempty(idx_gap)
  % Pull out table column names so can interpolate over all gaps
  vars = co2.Properties.VariableNames;
  % Loop through gaps until there are no more
  done_finding_gaps = 0;
  while ~done_finding_gaps
    fprintf('interpolating over small gaps in HydroC data to avoid spikes\n')
    % Now interpolate over the gap and write to a new table
    % create a timestep array that goes from the gap+1 timestep to the gap
    % end - one timestep.
    time_fill = co2.Date_Time(idx_gap)+med_dt:med_dt:co2.Date_Time(idx_gap + 1)-med_dt;
    % inialize new table for this specific gap
    new_co2 = table;
    for nvar = 1:numel(vars)
      v = vars{nvar};
      new_co2.(v) = interp1(co2.Date_Time,co2.(v),time_fill,'linear')';
    end
    % plot to see where gaps were
    % plot(new_co2.Date_Time,new_co2.(pco2_var),'g*')
    %% fill gaps
    co2 = [co2(1:idx_gap,:); new_co2; co2(idx_gap+1:end,:)];
    clearvars new_co2
    idx_gap = find(diff(co2.Date_Time) > med_dt*3 & diff(co2.Date_Time) < small_gap_fill,1);
    % if no more gaps are present, exit loop
    if isempty(idx_gap)
      done_finding_gaps = 1;
    end
  end
end

%% Add uncertainty to figure
% plot an uncertainty of 1%
gd = isfinite(co2.(pco2_var));
unc = co2.(pco2_var)(gd)*.01; % 1%
try
  xfill = [co2.Date_Time(gd);flipud(co2.Date_Time(gd))];
  yfill = [co2.(pco2_var)(gd)+unc; flipud(co2.(pco2_var)(gd)-unc)];
  fill(gca,xfill,yfill,[0 0 0.75],'FaceAlpha',0.1,'LineStyle','none','DisplayName','pCO\_2 pp \pm 1 %%');
catch
  % just skip this if it doesn't work 
end
%% Smooth data
var_smo = [pco2_var '_' smooth_method];
co2.(var_smo) = smoothdata(co2.(pco2_var),smooth_method,minutes(smooth_minute),'omitnan','SamplePoints',co2.Date_Time);
% plot the smoothed data
plot(co2.Date_Time,co2.(var_smo),'b.-')

%% Format data to write to file
% writes HydroC processed data to file
fprintf('writing data to %s\n',newfile)
HydroC_writetable_co2(co2,newfile); 

end %% END OF FUNCTION
