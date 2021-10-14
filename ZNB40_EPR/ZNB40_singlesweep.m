%% Talks to the ZNB40 VNA. Does a single
clear

%% ZNB40 initialization

% ZNB40 MAC address??
ZNB = 'TCPIP0::rsznb40::inst0::INSTR';

% Opening connection to ZNB
ZNB = visa('agilent',ZNB);
set(ZNB, 'InputBufferSize', 400000, 'Timeout', 1000);
fopen(ZNB);

% Whats the start frequency
fwrite(ZNB,'freq:star?');
fstart = str2num(fscanf(ZNB));

% Whats the stop frequecny
fwrite(ZNB,'freq:stop?');
fend=str2num(fscanf(ZNB));

% Number of data points?
fwrite(ZNB,'SWEEP:POIN?');
fpoints = str2num(fscanf(ZNB));

% Create a vector of the frequencies scanned
freqs = linspace(fstart,fend,fpoints);

%% Grab ZNB trace
fprintf(ZNB, 'INIT:CONT:ALL OFF'); % Stop continuous sweep
time_initial = datetime;
disp(['Started at t = ' datestr(time_initial)])
fprintf(ZNB, 'INIT:IMM; *WAI') % Starts a single scan and waits until the sweep is done
fprintf(ZNB,'CALC:DATA? SDAT'); % Grab the data
data_SDAT_unformatted(:) = str2num(fscanf(ZNB));

% Using SDAT the FF outputs the data in the format (real(datapoint1), imag(datapoint1), real(datapoint2), imag(datapoint2),...)
% we want to change this to (real(datapoint1) + j*imag(datapoint1), real(datapoint2) + j*imag(datapoint2), ..)

for ii = 1:fpoints
    data_SDAT_formatted(ii) = data_SDAT_unformatted(2*ii - 1) + j*data_SDAT_unformatted(2*ii);
end

data = data_SDAT_formatted;
gain = 20*log10(abs(data_SDAT_formatted));
phase = atan2(imag(data_SDAT_formatted),real(data_SDAT_formatted));

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
    if ~exist(year,'dir');
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

    if ~exist(monthN,'dir');
        mkdir(monthN);
    end
    cd(monthN);

    % Change to 'day_absorptionspectra' folder
    dayname = strcat(day,'_EPR_GdVO4');
    if ~exist(dayname,'dir');
        mkdir(dayname);
    end
    cd(dayname); 

%%% Filename and save

    filenum = 1;
    while 1;
        filename = [datestr(timestamp,'dd'),...
            '_EPR_FF',num2str(filenum)];
        if ~exist([filename,'.mat'],'file');                                     % if filename doesn't exist skip loop and proceed to save
            break;
        end
        filenum = filenum +1;
    end
    
    save([filename,'.mat']);    
cd(oldpwd)
disp('Data saved.')

%% Plot
figure
plot(freqs/1e9, gain)
xlabel('Frequency (GHz)')
ylabel('Gain (dB)')

%% Close connection to ZNB
fclose(ZNB); 