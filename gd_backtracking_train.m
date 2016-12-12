function [llrecord, errrecord] = gd_backtracking_train(algorithm, maxIter, layersizes, layertypes, indata, outdata, intest, outtest)
% variables
llrecord = zeros(maxIter+1,2);
errrecord = zeros(maxIter+1,2);

%standard L_2 weight-decay:
weight_decay = 2e-5;

autodamp = 1;
drop = 2/3;
boost = 1/drop;

% the amount to decay the previous search direction for the
% purposes of initializing the next run of CG.
decay = 0.95; % Should be 0.95

%next try using autodamp = 0 for rho computation.  both for version 6 and
%versions with rho and cg-backtrack computed on the training set
%mattype = 'gn'; %Curvature matrix: Gauss-Newton.

% IMPORTANT NOTES:  The most important variables to tweak are `initlambda' (easy) and
% `maxiters' (harder).  Also, if your particular application is still not working the next 
% most likely way to fix it is tweaking the variable `initcoeff' which controls
% overall magnitude of the initial random weights.  Please don't treat this code like a black-box,
% get a negative result, and then publish a paper about how the approach doesn't work :)  And if
% you are running into difficulties feel free to e-mail me at james.martens@gmail.com

%Fortunately after only 1 'epoch'
%you can often tell if you've made a bad choice.  The value of rho should lie
%somewhere between 0.75 and 0.95.  I could automate this part but I'm lazy
%and my code isn't designed to make such automation a natural thing to add.  Also
%note that 'lambda' is being added to the normalized curvature matrix (i.e.
%divided by the number of cases) while in the ICML paper I was adding it to
%the unnormalized curvature matrix.  This doesn't make any real
%difference to the optimization, but does make it somewhat easier to guage
%lambda and set its initial value since it will be 'independent' of the
%number of training cases in each mini-batch
initlambda = 45.0;

layersizes = [size(indata,1) layersizes size(outdata,1)];
numlayers = size(layersizes,2) - 1;

[indims numcases] = size(indata);
outputString(['input size:' num2str(indims) 'x' num2str(numcases)])

y = cell(1, numlayers+1);

psize = layersizes(1,2:(numlayers+1))*layersizes(1,1:numlayers)' + sum(layersizes(2:(numlayers+1)));

% pack all the parameters into a single vector
function M = pack(W,b)
    M = zeros( psize, 1 );
    cur = 0;
    for i = 1:numlayers
        M((cur+1):(cur + layersizes(i)*layersizes(i+1)), 1) = vec( W{i} );
        cur = cur + layersizes(i)*layersizes(i+1);
        M((cur+1):(cur + layersizes(i+1)), 1) = vec( b{i} );
        cur = cur + layersizes(i+1);
    end
end

% unpack parameters from a vector
function [W,b] = unpack(M)
    W = cell( numlayers, 1 );
    b = cell( numlayers, 1 );
    cur = 0;
    for i = 1:numlayers
        W{i} = reshape( M((cur+1):(cur + layersizes(i)*layersizes(i+1)), 1), [layersizes(i+1) layersizes(i)] );
        cur = cur + layersizes(i)*layersizes(i+1);
        b{i} = reshape( M((cur+1):(cur + layersizes(i+1)), 1), [layersizes(i+1) 1] );
        cur = cur + layersizes(i+1);
    end
end

function [ll, err] = computeLL(params, in, out)
    [W,b] = unpack(params);
    schunk = size(in,2);
    
    yi = in(:, 1:schunk );
    outc = out(:, 1:schunk );
    for i = 1:numlayers
        xi = W{i}*yi + repmat(b{i}, [1 schunk]);
        if strcmp(layertypes{i}, 'logistic')
            yi = 1./(1 + exp(-xi));
        elseif strcmp(layertypes{i}, 'softmax' )
            tmp = exp(xi);
            yi = tmp./repmat( sum(tmp), [layersizes(i+1) 1] );   
        end
    end
    
    ll = 0;
    if strcmp( layertypes{numlayers}, 'softmax' )
        ll = sum(sum(outc.*log(yi)));
    elseif strcmp( layertypes{numlayers}, 'logistic' )
        ll = sum(sum(xi.*(outc - (xi >= 0)) - log(1+exp(xi - 2*xi.*(xi>=0)))));
    end
    
    err = sum( sum(outc.*yi,1) ~= max(yi,[],1) ) / size(in,2);

    ll = ll / size(in,2);
    ll = ll - 0.5*weight_decay*params'*params;
end

ch = zeros(psize, 1);

lambda = initlambda;

lambdarecord = zeros(maxIter,1);
times = zeros(maxIter,1);

totalpasses = 0;

% initialization of params.
paramsp = zeros(psize,1);
[Wtmp,btmp] = unpack(paramsp);
numconn = 15;
for i = 1:numlayers
    initcoeff = 1;
    for j = 1:layersizes(i+1)
        idx = ceil(layersizes(i)*rand(1,numconn));
        Wtmp{i}(j,idx) = randn(numconn,1)*initcoeff;
    end
end
paramsp = pack(Wtmp, btmp);

function grad = calcu_grad(paramsp)
    [Wu, bu] = unpack(paramsp);
    y = cell(1, numlayers+1);
    %ll = 0;
    %forward prop:
    y{1, 1} = indata(:, 1:numcases );
    yip1 =  y{1, 1} ;
    dEdW = cell(numlayers, 1);
    dEdb = cell(numlayers, 1);

    for i = 1:numlayers
        yi = yip1;
        xi = Wu{i}*yi + repmat(bu{i}, [1 numcases]);
        if strcmp(layertypes{i}, 'logistic')
            yip1 = 1./(1 + exp(-xi));
        elseif strcmp( layertypes{i}, 'softmax' )
            tmp = exp(xi);
            yip1 = tmp./repmat( sum(tmp), [layersizes(i+1) 1] );
        end
        y{1, i+1} = yip1;
    end
    outc = outdata(:, 1:numcases );
    
    for i = numlayers:-1:1
        if i < numlayers
            if strcmp(layertypes{i}, 'logistic')
                dEdxi = dEdyip1.*yip1.*(1-yip1);
            end
        else
            dEdxi = outc - yip1; %simplified due to canonical link
        end
        dEdyi = Wu{i}'*dEdxi;

        yi = y{1, i};

        %standard gradient comp:
        dEdW{i} = dEdxi*yi';
        dEdb{i} = sum(dEdxi,2);

        dEdyip1 = dEdyi;
        yip1 = yi;
    end

    % psize x 1
    grad = pack(dEdW, dEdb);
    grad = grad / numcases;
    grad = grad - weight_decay*(paramsp);
end


outputString('================Training================')
% Main part: train and test.

m = size(paramsp,1);

[ll, err] = computeLL(paramsp, indata, outdata);
llrecord(1,1) = ll;
errrecord(1,1) = err;
outputString( ['Train Log likelihood: ' num2str(ll) ', error rate: ' num2str(err)] );

[ll_test, err_test] = computeLL(paramsp, intest, outtest);
llrecord(1,2) = ll_test;
errrecord(1,2) = err_test;
outputString( ['Test Log likelihood: ' num2str(ll_test) ', error rate: ' num2str(err_test)] );
outputString( '' );

tic
grad = calcu_grad(paramsp);


for epoch = 1:maxIter

    %-grad since we maximize the log likelihood.

    step = 2;
    c = 10^(-2);
    j = 0;
    oldll = ll;
    [ll, err] = computeLL(paramsp + step*grad, indata, outdata);
    while j < 60
        if ll >= oldll + c*step*grad'*grad
            break;
        else
            %disp('hi')
            step = 0.8*step;
            j = j + 1;
            [ll, err] = computeLL(paramsp + step*grad, indata, outdata);
        end
    end
    
    fprintf('epoch: %d\t\n',epoch);
    
    paramsp = paramsp + step*grad;
    
    outputString( ['#backtracking: ' num2str(j) ', step size: ' num2str(step)] );
    
    grad = calcu_grad(paramsp);
    [ll, err] = computeLL(paramsp, indata, outdata);
    llrecord(epoch+1,1) = ll;
    errrecord(epoch+1,1) = err;
    outputString( ['Train Log likelihood: ' num2str(ll) ', error rate: ' num2str(err)] );

    [ll_test, err_test] = computeLL(paramsp, intest, outtest);

    llrecord(epoch+1,2) = ll_test;
    errrecord(epoch+1,2) = err_test;
    outputString( ['Test Log likelihood: ' num2str(ll_test) ', error rate: ' num2str(err_test)] );
    outputString( '' );

    times(epoch) = toc;
    
end

outputString( ['Total time: ' num2str(sum(times)) ] );
end

function outputString( s )
    fprintf( '%s\n', s );
end

function v = vec(A)
    v = A(:);
end