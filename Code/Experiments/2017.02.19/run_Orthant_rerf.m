close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

rng(1);

ps = [2,4,6];
ns{1} = [20,200,400];
ns{2} = [80,400,4000];
ns{3} = [400,2000,4000];
ntest = 10000;
ntrials = 10;

Classifiers = {'rerf'};

OOBError = cell(length(ns{1}),length(ps));
OOBAUC = cell(length(ns{1}),length(ps));
TrainTime = cell(length(ns{1}),length(ps));
Depth = cell(length(ns{1}),length(ps));
NumNodes = cell(length(ns{1}),length(ps));
NumSplitNodes = cell(length(ns{1}),length(ps));
TestError = cell(length(ns{1}),length(ps));
Bias = cell(length(ns{1}),length(ps));
Variance = cell(length(ns{1}),length(ps));
MR = cell(length(ns{1}),length(ps));
BestIdx = cell(length(ns{1}),length(ps));

for j = 1:length(ps)
    p = ps(j);
    fprintf('p = %d\n',p)
    
    Xtest = dlmread(sprintf([rerfPath 'RandomerForest/Data/Orthant/Orthant_test_p%d.dat'],p));
    Ytest = cellstr(num2str(Xtest(:,end)));
    Xtest(:,end) = [];
    ClassPosteriors = dlmread(sprintf([rerfPath 'RandomerForest/Data/Orthant/Orthant_test_posteriors_p%d.dat'],p));
      
    for i = 1:length(ns{j})
        ntrain = ns{j}(i);
        fprintf('n = %d\n',ntrain)
        
        if p <= 5
            mtrys = [1:p p.^[2 3]];
        elseif p <= 10 && ntrain <= 10000
            mtrys = ceil(p.^[1/4 1/2 3/4 1 2 3]);
        elseif p <= 100 && ntrain <= 2000
            mtrys = ceil(p.^[1/4 1/2 3/4 1 2 2.5]);
        elseif p <= 100 && ntrain <= 10000
            mtrys = ceil(p.^[1/4 1/2 3/4 1 2]);
        else
            mtrys = [ceil(p.^[1/4 1/2 3/4 1]) 20*p];
        end
        mtrys_rf = mtrys(mtrys<=p);

        for c = 1:length(Classifiers)
            fprintf('%s start\n',Classifiers{c})
            
            if ntrain <= 1000
                Params{i,j}.(Classifiers{c}).nTrees = 1000;
            else
                Params{i,j}.(Classifiers{c}).nTrees = 500;
            end
            Params{i,j}.(Classifiers{c}).Stratified = true;
            Params{i,j}.(Classifiers{c}).NWorkers = 12;
            Params{i,j}.(Classifiers{c}).Rescale = 'off';
            Params{i,j}.(Classifiers{c}).mdiff = 'off';
            if strcmp(Classifiers{c},'rf')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'rf';
                Params{i,j}.(Classifiers{c}).d = mtrys_rf;
            elseif strcmp(Classifiers{c},'rerf')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'rerf';
                Params{i,j}.(Classifiers{c}).RandomMatrix = 'binary';
                Params{i,j}.(Classifiers{c}).d = mtrys;
                Params{i,j}.(Classifiers{c}).rho = (1:min(p,3))/p;
            elseif strcmp(Classifiers{c},'rr_rf')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'rf';   
                Params{i,j}.(Classifiers{c}).Rotate = true;
                Params{i,j}.(Classifiers{c}).d = mtrys_rf;
            end

            if strcmp(Params{i,j}.(Classifiers{c}).ForestMethod,'rf')
                OOBError{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d),Params{i,j}.(Classifiers{c}).nTrees);
                OOBAUC{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d),Params{i,j}.(Classifiers{c}).nTrees);
                TrainTime{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
                Depth{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d));
                NumNodes{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d));
                NumSplitNodes{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d));
                TestError{i,j}.(Classifiers{c}) = NaN(ntrials,1);
                Bias{i,j}.(Classifiers{c}) = NaN(1,length(Params{i,j}.(Classifiers{c}).d));
                Variance{i,j}.(Classifiers{c}) = NaN(1,length(Params{i,j}.(Classifiers{c}).d));
                MR{i,j}.(Classifiers{c}) = NaN(1,length(Params{i,j}.(Classifiers{c}).d));
                TestPredictions = cell(ntest,ntrials,length(Params{i,j}.(Classifiers{c}).d));
                BestIdx{i,j}.(Classifiers{c}) = NaN(ntrials,1);
            else
                OOBError{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho),Params{i,j}.(Classifiers{c}).nTrees);
                OOBAUC{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho),Params{i,j}.(Classifiers{c}).nTrees);
                TrainTime{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                Depth{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                NumNodes{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                NumSplitNodes{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                TestError{i,j}.(Classifiers{c}) = NaN(ntrials,1);
                Bias{i,j}.(Classifiers{c}) = NaN(1,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                Variance{i,j}.(Classifiers{c}) = NaN(1,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                MR{i,j}.(Classifiers{c}) = NaN(1,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                TestPredictions = cell(ntest,ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).rho));
                BestIdx{i,j}.(Classifiers{c}) = NaN(ntrials,1);
            end

            for trial = 1:ntrials
                fprintf('Trial %d\n',trial)
                
                Xtrain = dlmread(sprintf([rerfPath 'RandomerForest/Data/Orthant/Orthant_train_p%d_n%d_trial%d.dat'],p,ntrain,trial));
                Ytrain = cellstr(num2str(Xtrain(:,end)));
                Xtrain(:,end) = [];

                % train classifier
                poolobj = gcp('nocreate');
                if isempty(poolobj)
                    parpool('local',Params{i,j}.(Classifiers{c}).NWorkers,...
                        'IdleTimeout',360);
                end

                [Forest,~,TrainTime{i,j}.(Classifiers{c})(trial,:)] = ...
                    RerF_train(Xtrain,Ytrain,Params{i,j}.(Classifiers{c}));
                
                fprintf('Training complete\n')

                % compute oob auc, oob error, and tree stats

                for k = 1:length(Forest)
                    Labels = Forest{k}.classname;
                    nClasses = length(Labels);
                    Scores = rerf_oob_classprob(Forest{k},...
                        Xtrain,'every');
                    for t = 1:Forest{k}.nTrees
                        Predictions = predict_class(Scores(:,:,t),Labels);
                        OOBError{i,j}.(Classifiers{c})(trial,k,t) = ...
                            misclassification_rate(Predictions,Ytrain,...
                        false);
                        if nClasses > 2
                            Yb = binarize_labels(Ytrain,Labels);
                            [~,~,~,OOBAUC{i,j}.(Classifiers{c})(trial,k,t)] = ... 
                                perfcurve(Yb(:),Scores((t-1)*ntrain*nClasses+(1:ntrain*nClasses)),'1');
                        else
                            [~,~,~,OOBAUC{i,j}.(Classifiers{c})(trial,k,t)] = ...
                                perfcurve(Ytrain,Scores(:,2,t),'1');
                        end
                    end
                    Depth{i,j}.(Classifiers{c})(trial,:,k) = forest_depth(Forest{k})';
                    NN = NaN(1,Forest{k}.nTrees);
                    NS = NaN(1,Forest{k}.nTrees);
                    Trees = Forest{k}.Tree;
                    parfor kk = 1:Forest{k}.nTrees
                        NN(kk) = Trees{kk}.numnodes;
                        NS(kk) = sum(Trees{kk}.isbranch);
                    end
                    NumNodes{i,j}.(Classifiers{c})(trial,:,k) = NN;
                    NumSplitNodes{i,j}.(Classifiers{c})(trial,:,k) = NS;
                    Scores = rerf_classprob(Forest{k},Xtest,'last');
                    TestPredictions(:,trial,k) = predict_class(Scores,Labels);
                end
                
                % select best model for test predictions
                BI = hp_optimize(OOBError{i,j}.(Classifiers{c})(trial,:,end),...
                    OOBAUC{i,j}.(Classifiers{c})(trial,:,end));
                BestIdx{i,j}.(Classifiers{c})(trial) = BI(end);
                
                TestError{i,j}.(Classifiers{c})(trial) = ...
                    misclassification_rate(TestPredictions(:,trial,BestIdx{i,j}.(Classifiers{c})(trial)),Ytest,false);

                clear Forest
            end
            for k = 1:length(Params{i,j}.(Classifiers{c}).d)
                Bias{i,j}.(Classifiers{c})(k) = classifier_bias(TestPredictions(:,:,k),ClassPosteriors);
                Variance{i,j}.(Classifiers{c})(k) = classifier_variance(TestPredictions(:,:,k));
            end
            fprintf('%s complete\n',Classifiers{c})
            save([rerfPath 'RandomerForest/Results/2017.02.19/Orthant_' Classifiers{c} '.mat'],'ps',...
                'ns','Params','OOBError','OOBAUC','TestError',...
                'TrainTime','Depth','NumNodes','NumSplitNodes','Bias',...
                'Variance','BestIdx')
        end
    end   
end
delete(gcp('nocreate'));