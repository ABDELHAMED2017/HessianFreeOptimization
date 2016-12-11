clc; clear; close all;
maxIter = 100;
% network structure
layersizes = [25 30];
layertypes = {'logistic', 'logistic', 'softmax'};

[llrecord, errrecord] = lbfgs_train(maxIter, layersizes, layertypes);

fig = figure('color', [1 1 1]);
subplot(1,2,1);
plot(0:maxIter, -llrecord(:,1),'rx-');
hold on;
plot(0:maxIter, -llrecord(:,2),'bx-');
subplot(1,2,2);
plot(0:maxIter, errrecord(:,1),'rx-');
hold on;
plot(0:maxIter, errrecord(:,2),'bx-');
ylim([0 1]);
set(fig, 'Position', [10, 10, 1000, 400]);
