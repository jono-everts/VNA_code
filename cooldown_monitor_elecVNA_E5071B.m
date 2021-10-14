% Copied from Taine's FFsinglesweep.m
% Read the FF from time to time to see how the GdVO4 changes as the fridge
% cools down.
% GK, 15-Dec-MMXX
% cooldown_monitor.m changed to use the ELEC 8.5 GHz VNA instead.
% GK, 1-Feb-MMXXI

clear

%% Fieldfox initialization
VNAaddress = 'GPIB0::17::INSTR'; 

% Opening connection to FF
VNA = visa('agilent',VNAaddress);
% set(VNA, 'InputBufferSize', 200000, 'Timeout', 1000);
set(VNA, 'InputBufferSize', 200000, 'Timeout', 20);
fopen(VNA);

% Set the start frequency
fwrite(VNA,':SENS1:FREQ:STAR?');
fstart = str2num(fscanf(VNA));

% Whats the stop frequecny
fwrite(VNA,':SENS1:FREQ:STOP?');
fend=str2num(fscanf(VNA));

% Number of data points?
fwrite(VNA,'SENS1:SWE:POIN?');
fpoints = str2num(fscanf(VNA));

% Create a vector of the frequencies scanned
freqs = linspace(fstart,fend,fpoints);

% Set IFBW
fwrite(VNA,':SENS1:BAND 30'); % range 10Hz to 0.1 MHz

%% While the script runs, grab a trace and stick it on the end of the data matrix.
pause_time = 120; %s

% Each row is a scan of the FF
init_rows = 150; % Number of rows to add each time the data matrix grows.
data_mat = nan(init_rows,fpoints);
timestamps = nan(init_rows, 1); % Use the "now" old style;
unixtimestamps = nan(size(timestamps)); % Get the unix timestamp using (posixtime(datetime)).
datetimestamps = NaT(size(timestamps)); % Preallocate a empty "not a time" matrix.

monitor_fig = figure;

% Loop: while true
ii = 1;
while true
% Check if there is a "kill" file in the PWD; if so cleanly finish.
if exist("KILL",'file')
    delete('KILL')
    break
end

% Check the length of the data matrix; if full, add another 100 rows; save
% a bit of time in allocating memory.
if ~any(isnan(data_mat))
    data_mat = [data_mat; nan(init_rows, fpoints)];
    timestamps = [timestamps; nan(init_rows, 1)];
    unixtimestamps = [unixtimestamps; nan(init_rows, 1)];
    datetimestamps = [datetimestamps; NaT(init_rows, 1)];
end


% Grab FieldFox trace
% fprintf(FF, 'INITIATE:CONTINUOUS OFF');
% fprintf(FF, 'INITIATE:IMMEDIATE; *OPC?');
datetimestamps(ii) = datetime;
unixtimestamps(ii) = posixtime(datetimestamps(ii));
timestamps(ii) = now;

fprintf(1,'Starting to read FF at %s...', datetime);

fprintf(VNA,':CALC1:DATA:SDAT?'); % Grab the data
data_SDAT_unformatted(:) = str2num(fscanf(VNA));

% Using SDAT the FF outputs the data in the format (real(datapoint1), imag(datapoint1), real(datapoint2), imag(datapoint2),...)
% we want to change this to (real(datapoint1) + j*imag(datapoint1), real(datapoint2) + j*imag(datapoint2), ..)

data_SDAT_formatted = nan(1, fpoints);
for jj = 1:fpoints
    data_SDAT_formatted(jj) = data_SDAT_unformatted(2*jj - 1) + 1j*data_SDAT_unformatted(2*jj);
end

data = data_SDAT_formatted;
gain = 20*log10(abs(data_SDAT_formatted));
phase = atan2(imag(data_SDAT_formatted),real(data_SDAT_formatted));

data_mat(ii,:) = data;

fprintf(1,'Done. Trace %u.\n Waiting for %u s. Make a file KILL in PWD to stop. \n',ii,pause_time);

ii = ii+1;

% Save a local copy in case of faults
save('WORKSPACE.MAT')

% Plot a monitor trace, to look at from home or desk.
figure(monitor_fig)
plot(freqs/1e9, gain)
xlabel('Frequency (GHz)')
ylabel('Gain (dB)')
title('Cooling...','interpreter','none')
grid on
drawnow;

pause(pause_time);

end

%% Ask for some notes:

notes = inputdlg('Enter some notes to be saved with the file:','Notes on this data set',[10,30]);

%% Close connection to the Field Fox
fclose(VNA); 

%% Save data
timestamp = now;
year      = datestr(timestamp,'yyyy');
month     = datestr(timestamp,'mm');
day       = datestr(timestamp,'dd');

oldpwd   = cd;                                  % Save current directory to come back to it after files are saved
dataroot = 'C:\Users\labrat\Desktop\labdata\Jono'; % Data directory
cd(dataroot);                                   % Change to data directory

%%% Create/change folder
    % Change to 'year' folder
    if ~exist(year,'dir')
        mkdir(year);
    end
    cd(year);                           

    % Change to 'month' folder
    monthNs = {'01_january'; ...
               '02_february'; ...
               '03_march'; ...
               '04_april'; ...
               '05_may'; ...
               '06_june'; ...
               '07_july'; ...
               '08_august'; ...
               '09_september'; ...
               '10_october'; ...
               '11_november'; ...
               '12_december'};

    monthN = char(monthNs(str2double(month)));

    if ~exist(monthN,'dir')
        mkdir(monthN);
    end
    cd(monthN);

    % Change to 'day_absorptionspectra' folder
    dayname = strcat(day,'_coax_resonator_cooldown_ErLiF4');
    if ~exist(dayname,'dir')
        mkdir(dayname);
    end
    cd(dayname); 

%%% Filename and save

    filenum = 1;
    while 1
        filename = [datestr(timestamp,'dd'),...
            '_cooldownlog_VNA',num2str(filenum)];
        if ~exist([filename,'.mat'],'file')                                     % if filename doesn't exist skip loop and proceed to save
            break;
        end
        filenum = filenum +1;
    end
    
   filename =  [filename, '.mat'];
   
   filename = uiputfile('*.mat','Select filename to save data',filename);
   if isstr(filename)
       save([filename,'.mat']);
       disp('Data saved.')
   else
       warndlg('You pressed cancel --- data NOT saved.', 'Data NOT saved!','modal')
       warning('You pressed cancel --- data NOT saved.')
   end
cd(oldpwd)


%% Plot
figure
%pcolor(timestamps,freqs/1e9, real(data_mat)')
pcolor(timestamps, freqs/1e9, 20*log10(abs(data_mat')))
set(get(gca,'children'),'edgecolor','none')
datetick('x')
ylabel('Frequency (GHz)')
xlabel('Time')
%zlabel('Gain (dB)')
title(filename,'interpreter','none')
text(min(get(gca,'xlim')), min(get(gca,'ylim')), notes,'VerticalAlignment','Bottom')
grid on

