clc; clear; close all;
maxIter = 100;
%% network structure
params.layersizes = [200 30];
params.layertypes = {'logistic', 'logistic', 'softmax'};
params.weight_decay = 2e-3;

%% load datasets.
indata = loadMNISTImages('raw_data/train-images.idx3-ubyte');
y = loadMNISTLabels('raw_data/train-labels.idx1-ubyte');
y(y==0) = 10;
intest = loadMNISTImages('raw_data/t10k-images.idx3-ubyte');
yt = loadMNISTLabels('raw_data/t10k-labels.idx1-ubyte');
yt(yt==0) = 10;

outdata = zeros(10,size(indata,2));
for i = 1:10
	outdata(i,:) = (y == i);
end

outtest = zeros(10,size(intest,2));
for i = 1:10
	outtest(i,:) = (yt == i);
end

%% training
gd_iters = 1000;
[llrecord, errrecord, params] = gd_train('adam', gd_iters, params, indata, outdata, intest, outtest);
save(sprintf('adam-%d.mat', gd_iters), 'llrecord', 'errrecord', 'params');
hf_iters = 100;
[llrecord2, errrecord2, params2] = lbfgs_train(hf_iters, params, indata, outdata, intest, outtest, params);
% [llrecord2, errrecord2, ~] = hf_train(60, layersizes, layertypes, params);
save(sprintf('hf-%d.mat', gd_iters), 'llrecord2', 'errrecord2', 'params2');
llrecord = [llrecord; llrecord2];
errrecord = [errrecord; errrecord2];
%%
plot_curve(llrecord,  errrecord);
