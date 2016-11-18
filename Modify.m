%% Load
clear; close all; clc;
FileName = 'AB_UH_01-T01-15-12-18-kin.mat';
Path = 'D:\Work\Github\GaitSegManualCorrection\KinData\';
load([Path, FileName]);

index = kin.gc.event.index;
label = kin.gc.label;
for i = 1:size(index,1);
    CurrentStrideLabel = label{i};
    switch CurrentStrideLabel
        case 'LW'
            NumLabel(i,1) = 1;
        case 'RA'
            NumLabel(i,1) = 2;
        case 'RD'
            NumLabel(i,1) = 3;
        case 'SA'
            NumLabel(i,1) = 4;
        case 'SD'
            NumLabel(i,1) = 5;
        otherwise
            error('Double check the terrain label');
    end
end
index1 = [index, NumLabel];

index = index1;
clear index1

field = 'event';
kin.gc = rmfield(kin.gc, field);

%% Modify

% Step 1 - Locate each section - including LW1, LW2, LW3, LW4 & LW_PreSA,
% SA, SD, 


%% Format the modified results
fs = 30;
time = (label-1)/fs;

kin.gc.index = index(:,1:5);
kin.gc.time = (kin.gc.index-1)/fs;

ModifiedLabelNum = index(:,6);
for i = 1:size(ModifiedLabelNum,1)
    labelNum = ModifiedLabelNum(i);
    switch ModifiedLabelNum
        case 1
            ModifiedLabel{i,1} = 'LW';
        case 2
            ModifiedLabel{i,1} = 'RA';
        case 3
            ModifiedLabel{i,1} = 'RD';
        case 4
            ModifiedLabel{i,1} = 'SA';
        case 5
            ModifiedLabel{i,1} = 'SD';
        otherwise
            error('Double check');
    end 
end
    
    
kin.gc.label = ModifiedLabel;

%% Save the results
save([Path, 'Results\', FileName]);
