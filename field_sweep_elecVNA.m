%% Sweep the magnetic field and record cavity transmission with the FieldFox.
% This code controls the American Magnetics 430 power supply programmer
% and the field fox, to get a transmission spectrum as a function of B
% field.

% Note: If error occurs and still connected to FF, run fclose(FF) and
% delete(instrfindall)
clear

%% Inputs

% Magnet scan values
Bmin = 0; % Starting magnetic field value (T)
Bmax = 0.5; % Final magnetic field value (T)
steps = 300; % Number of steps betweem 
Bz = linspace(Bmin,Bmax,steps); % Vector holding B values used in scan

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
data = zeros(fpoints, length(Bz));
gain = zeros(fpoints, length(Bz));
phase = zeros(fpoints, length(Bz));

%% Magnet controller initialization

% Set field units to Tesla
AMIwrite('CONF:FIELD:UNITS 1'); 
funit = str2num(AMIquery('FIELD:UNITS?'));
if funit == 1
    disp('Field units set to: Tesla')
elseif funit == 0
    disp('Field units set to: kG')
end

% Setting number of ramp segments
AMIwrite('CONF:RAMP:RATE:SEG 1')
rrseg = str2num(AMIquery('RAMP:RATE:SEG?'));
fprintf('Number of ramp segments: %u \n', rrseg)


% Setting ramp rate
AMIwrite('CONF:RAMP:RATE:UNITS 1');
rrunit = str2num(AMIquery('RAMP:RATE:UNITS?')); 
if rrunit == 1
    disp('Ramp rate units set to: /minute')
elseif rrunit == 0
    disp('Ramp rate units set to: /second')
end
% AMIwrite(['CONF:RAMP:RATE:FIELD 1,0.1,' num2str(Bmax)]) % Set ramp rate of segment one to 100mT/sec and upperbound to Bmax
AMIwrite('CONF:RAMP:RATE:FIELD 1,0.1,1') % NOTE: DOESNT SEEM TO WANT TO CHANGE UPPERBOUND???? SO JUST LEAVING IT AT 3
rrstr = AMIquery('RAMP:RATE:FIELD:1?'); % Has format (ramprate, upperbound)
disp(['Ramp rate set to: ' rrstr(1:10)])
% disp(rr)


% Setting field to Bmin
fprintf('\n')
disp('Starting up Magnet..')
finit = str2num(AMIquery('FIELD:MAG?'));
disp(['Initial Field = ' num2str(finit)])
AMIsetfield(Bmin); 
fprintf('\n')

% Scan Bz
disp('Starting field scan...')
measF = 0*Bz;
time_initial = datetime;
disp(['Started at t = ' datestr(time_initial)])
fprintf('\n')

for i=1:length(Bz)
    fprintf('Loop %u/%u \n', i,length(Bz))
    AMIsetfield(Bz(i)) % Setting magnetic field
    measF_vec(i) = str2double(AMIquery('FIELD:MAG?')); % Collecting a vector of measured Field values before a scan is grabbed
    
    % Grab VNA trace
    fprintf(VNA, 'INITIATE:CONTINUOUS OFF');
    fprintf(VNA, 'INITIATE:IMMEDIATE;');
    pause(17)
    fprintf(VNA,'CALC1:DATA:SDAT?'); % Grab the data
    data_SDAT_unformatted(:) = str2num(fscanf(VNA));
    
    % Using SDAT the FF outputs the data in the format (real(datapoint1), imag(datapoint1), real(datapoint2), imag(datapoint2),...)
    % we want to change this to (real(datapoint1) + j*imag(datapoint1), real(datapoint2) + j*imag(datapoint2), ..)
    
    for ii = 1:fpoints
        data_SDAT_formatted(ii) = data_SDAT_unformatted(2*ii - 1) + j*data_SDAT_unformatted(2*ii);
    end
    
    data(:,i) = data_SDAT_formatted;
    gain(:,i) = 20*log10(abs(data_SDAT_formatted));
    phase(:,i) = atan2(imag(data_SDAT_formatted),real(data_SDAT_formatted));
    
    
    % Continuous plot
    figure(1)
    imagesc(Bz,freqs/1e9,gain);
    set(gca,'YDir','normal')
    xlabel('Magnetic Field (T)');
    ylabel('Frequency (GHz)');
    c = colorbar;
    ylabel(c, 'S21 - cavity transmission (dB)')
    title('Log plot')
end
time_final = datetime;
disp(['Finished at t = ' datestr(time_final)])
disp('Resetting magnet back to zero')
AMIsetfield_noblock(0)
% AMIsetzero()


%% Close connection to the Field Fox
fclose(VNA); 

%% save data
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
    dayname = strcat(day,'_coax_ErLiF4');
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

%% Plot the transmission data
figure();
imagesc(Bz,freqs/1e9,gain);
set(gca,'YDir','normal')
xlabel('Magnetic Field (T)');
ylabel('Frequency (GHz)');
c = colorbar;
ylabel(c, 'S21 - cavity transmission (dB)')
title('Log plot')

figure();
imagesc(Bz,freqs/1e9,10.^(gain/10));
set(gca,'YDir','normal')
xlabel('Magnetic Field (T)');
ylabel('Frequency (GHz)');
c = colorbar;
ylabel(c, 'S21 - cavity transmission (Linear)')
title('Linear plot')






