function getstudyinfo
% This function gets study info of database and produce graphs
% Input: 
%
% Output:
%        
%
% Author: Eman Ghobrial
%         fMRI center, Radiology, UC San Diego
%         May 2013
%
%
%% Create the connection
javaclasspath('/usr/lib/pgsql/postgresql-8.4-703.jdbc3.jar');
conn = database('mems_db1','emang','','Vendor','PostGreSQL');
%% Get the info for RS1
studyinfo = exec(conn,'select rs1attrb from studyinfo');
setdbprefs('DataReturnFormat','cellarray')
rs1info = fetch(studyinfo);
rs1snr = zeros(length(rs1info.data),1);

x = 1:length(rs1info.data);
      
for i = 1:length(rs1info.data)
    if strcmp(rs1info.data{i},'not set')
        %do nothing
        rs1snr (i) = nan;
    else 
       %  c = strsplit(rs1info.data{i},',');
%         rs1snr (i) = str2num(c{1})
         c = rs1info.data{i}(1:4);
      rs1snr (i) = str2num(c);
      if rs1snr(i) < 10
          rs1snr(i) = rs1snr(i) * 10;
      end    
          
    end  
end    
fsize = 12;
figure(1);
h1 = plot (x,rs1snr, ':*'); axis([0 length(rs1info.data) -10 35]);grid on;
set(h1,'Linewidth',1,'MarkerSize',4);
ylabel('tsnr');
title('Resting State Run 1 TSNR');
saveas(1, ['/var/log/mems/tsnrRS1QA.jpg']);

%% Get the info for RS2
studyinfo2 = exec(conn,'select rs2attrb from studyinfo');
setdbprefs('DataReturnFormat','cellarray')
rs2info = fetch(studyinfo2);
rs2snr = zeros(length(rs2info.data),1);

x = 1:length(rs2info.data);
      
for i = 1:length(rs2info.data)
    if strcmp(rs2info.data{i},'not set')
        %do nothing
        rs2snr (i) = nan;
    else 
       %  c = strsplit(rs1info.data{i},',');
%         rs1snr (i) = str2num(c{1})
         c = rs2info.data{i}(1:4);
      rs2snr (i) = str2num(c);
         if rs2snr(i) < 10
          rs2snr(i) = rs2snr(i) * 10;
      end      
    end  
end    
fsize = 12;
figure(2);
h1 = plot (x,rs2snr, ':*'); axis([0 length(rs2info.data) -10 35]);grid on;
set(h1,'Linewidth',1,'MarkerSize',4);
ylabel('tsnr');
title('Resting State Run 2 TSNR');
saveas(2, ['/var/log/mems/tsnrRS2QA.jpg']);

%% close connection
close(studyinfo);
close(conn);
