%%
clear
close all

while true
    clear
    delaytime = 1*60; % Time between FF scans (seconds)
    %% Fieldfox initialization

    % Fieldfox MAC address??
    FF='TCPIP0::fieldfox.px.otago.ac.nz::inst0::INSTR'; 

    % Opening connection to FF
    FF = visa('agilent',FF);
    set(FF, 'InputBufferSize', 200000, 'Timeout', 1000);
    fopen(FF);

    % Whats the start frequency
    fwrite(FF,'freq:star?');
    fstart = str2num(fscanf(FF));

    % Whats the stop frequecny
    fwrite(FF,'freq:stop?');
    fend=str2num(fscanf(FF));

    % Number of data points?
    fwrite(FF,'SWEEP:POIN?');
    fpoints = str2num(fscanf(FF));

    % Create a vector of the frequencies scanned
    frequencies = linspace(fstart,fend,fpoints);

    %% Grab FieldFox trace
    % fprintf(FF, 'INITIATE:CONTINUOUS OFF');
    % fprintf(FF, 'INITIATE:IMMEDIATE; *OPC?');
    time_initial = datetime;
    disp(['Started at t = ' datestr(time_initial)])

    fprintf(FF,'CALC:DATA:SDAT?'); % Grab the data
    data_SDAT_unformatted(:) = str2num(fscanf(FF));

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
        dayname = strcat(day,'_ErLiF4_cooldown4K');
        if ~exist(dayname,'dir');
            mkdir(dayname);
        end
        cd(dayname); 

    %%% Filename and save

        filenum = 1;
        while 1;
            filename = ['FF_scan',num2str(filenum)];
            if ~exist([filename,'.mat'],'file');                                     % if filename doesn't exist skip loop and proceed to save
                break;
            end
            filenum = filenum +1;
        end

        save([filename,'.mat'],'time_initial','gain','frequencies');    
    cd(oldpwd)
    disp('Data saved.')

    %% Close connection to the Field Fox
    fclose(FF); 
    
    %% PAUSE UNTIL NEXT SWEEP
    pause(delaytime)
end

%% Plotting data versus time
clear
% Loop through files and grab time/gain data
% NEED TO SET JJ numbers to run through

for jj = 1:196
    load(['C:\Users\labrat\Desktop\labdata\Jono\2020\11_november\02_ErLiF4_cooldown4K\FF_scan' num2str(jj) '.mat'])
    time_all(jj) = time_initial;
    gain_all(:,jj) = gain;
end

% for jj = 1:144
%     load(['C:\Users\labrat\Desktop\labdata\Jono\2019\11_november\01_ErLiF4_cooldown4K\FF_scan' num2str(jj) '.mat'])
%     time_all(jj) = time_initial;
%     gain_all(:,jj) = gain;
% end

figure();
imagesc(datenum(time_all),frequencies/1e9,gain_all);
set(gca,'YDir','normal')
xlabel('Time');
ylabel('Frequency (GHz)');
c = colorbar;
ylabel(c, 'S21 - cavity transmission (dB)')
title('Log plot')
dateFormat = 13;
datetick('x',dateFormat)


figure();
imagesc(datenum(time_all),frequencies/1e9,10.^(gain_all/10));
set(gca,'YDir','normal')
xlabel('Time');
ylabel('Frequency (GHz)');
c = colorbar;
ylabel(c, 'S21 - cavity transmission (Linear)')
title('Linear plot')
dateFormat = 13;
datetick('x',dateFormat)

%P lot Temp data
[T,t] = getBFtemp(time_all(1),time_all(end));
figure
plot(t,T)