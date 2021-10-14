clear
delete(instrfindall)

%% VNA init
% Fieldfox MAC address??
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

%% Grab VNA trace
% fprintf(FF, 'INITIATE:CONTINUOUS OFF');
% fprintf(FF, 'INITIATE:IMMEDIATE; *OPC?');
time_initial = datetime;
disp(['Started at t = ' datestr(time_initial)])

% Grab VNA trace
% fprintf(VNA, ':INIT1:CONT OFF');
fprintf(VNA, ':INIT1');
fprintf(VNA,':CALC1:DATA:SDAT?'); % Grab the data
data_SDAT_unformatted(:) = str2num(fscanf(VNA));


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
               %% 
               '11_november'; ...
               '12_december'};

    monthN = char(monthNs(str2double(month)));

    if ~exist(monthN,'dir');
        mkdir(monthN);
    end
    cd(monthN);

    % Change to 'day_absorptionspectra' folder
    dayname = strcat(day,'_ErLiF4_fridgescan');
    if ~exist(dayname,'dir');
        mkdir(dayname);
    end
    cd(dayname); 

%%% Filename and save

    filenum = 1;
    while 1;
        filename = [datestr(timestamp,'dd'),...
            '_medium_coax22_roomtemp',num2str(filenum)];
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

%% Close connection to the Field Fox
fclose(VNA); 