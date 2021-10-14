function [T,t] = getbftemp(time1,time2)
%   GETBFTEMP gets the bluefors temperature at a particular time
%  [T,t] = getbftime(t1) gets the bluefors temperature close to a
%  particular datetime t1. It returns temperature and the time that
%  temperature was taken.
%
%  [T,t] = getbftime(t1,t2) gets the bluefors temperature as a function of
% time between t1, and t2 
%
% example code:
%
% getBFtemp(datetime(2019,08,07,03,00,09))
% [T,t] = getBFtemp(datetime(2019,08,07,03,00,09),datetime(2019,08,07,23,00,09))
% plot(t,T)

if nargin==0
    time1 = datetime()
end

%    time1 = datetime(2019,8,7,11,59,09);
    tempstr = datestr(time1,'yy-mm-dd');
    filename = sprintf('Z:/BlueforsLogs/Logfiles_896/%s/CH6 T %s.log',tempstr,tempstr);
    
    fp = fopen(filename);
    
if nargin==1
    while true
        line = fgetl(fp);
        if isempty(line)
            break
        end
        a = sscanf(line,'%d-%d-%d,%d:%d:%d,%f');
        t = datetime(2000+a(3),a(2),a(1),a(4),a(5),a(6));
        T = a(7);
        if t>time1
            break
        end
        
    end
else
    
    count = 1
    while ~feof(fp)
        line = fgetl(fp);
        if isempty(line)
            break
        end
        a = sscanf(line,'%d-%d-%d,%d:%d:%d,%f');
        t = datetime(2000+a(3),a(2),a(1),a(4),a(5),a(6));
        T = a(7);
        if t>time1
            break 
        end
    end
    
    while ~feof(fp)
        line = fgetl(fp);
        if isempty(line)
            break
        end 
        disp(line)
        a = sscanf(line,'%d-%d-%d,%d:%d:%d,%f');    
        count = count+1;
        t(count) = datetime(2000+a(3),a(2),a(1),a(4),a(5),a(6));
        T(count) = a(7);
        if t>time2
            break
        end   
    end
end

    
    
    
    
%end

    
    
%end


%function