% % Generation
% num = 100;
% len = 1000;
% trans = [0.99,0.01; 0.05,0.95];
% emis = [(1:20); (1:20)+100];
% 
% donor = zeros(num,len);
% acceptor = zeros(num,len);
% for i = 1:num
%     [~, d] = hmmgenerate(len,trans,emis);
%     d = normalize(d,'range');
%     a = 1 - d;
%     d = normalize(d,'range');
%     a = normalize(a,'range');
%     
%     donor(i,:) = d;
%     acceptor(i,:) = a;
%     
% %     dat = [(1:len)', d', a'];
% %     dat_str = num2str(dat);
% %     dlmwrite(['/Users/jameslondon/Desktop/cor/trace_', num2str(i), '.dat'], dat_str , '');
% end

% Correlation
FRETDT      = FRETDwellTimes(donor);

% Display

f = figure;
ax = axes(f);
numStates = length(FRETDT);
for s = 1:numStates
    ax1 = subplot(1, numStates, s, ax); % 
    histogram(ax1, FRETDT{s,1});
    hold on;
    title(ax1, ['FRET State ' num2str(s) ' Dwell Times']);
    hold off;
end
