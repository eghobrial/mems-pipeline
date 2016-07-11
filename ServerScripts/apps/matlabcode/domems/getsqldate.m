function [ sqldate ] = getsqldate()
%getsqldate
%return current date as an sql format
%%
dstr = datestr(now);

dvec = datevec(dstr);

sqldate= sprintf('%4d-%02d-%02d %02d:%02d:%02d',dvec(1,1),dvec(1,2),dvec(1,3),dvec(1,4),dvec(1,5),dvec(1,6));



end
