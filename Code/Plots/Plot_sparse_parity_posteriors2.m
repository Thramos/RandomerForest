%% Plot posterior heat maps

clear
close all
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);
LineWidth = 2;
FontSize = .2;
axWidth = 1.3;
axHeight = 1.3;
cbWidth = .1;
cbHeight = axHeight;
axLeft = [FontSize*3,FontSize*5+axWidth,FontSize*3,...
    FontSize*5+axWidth,FontSize*3,...
    FontSize*5+axWidth,FontSize*3,...
    FontSize*5+axWidth,FontSize*3,...
    FontSize*5+axWidth];
axBottom = [(FontSize*7.5+axHeight*4)*ones(1,2),(FontSize*6+axHeight*3)*ones(1,2),...
    (FontSize*4.5+axHeight*2)*ones(1,2),(FontSize*3+axHeight)*ones(1,2),...
    FontSize*1.5*ones(1,2)];
cbLeft = axLeft + axWidth + FontSize/2;
cbBottom = axBottom;
figWidth = cbLeft(end) + cbWidth + FontSize*2;
figHeight = axBottom(1) + axHeight + FontSize*2;

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

runSims = false;

if runSims
    run_sparse_parity_posteriors
else
    load Sparse_parity_true_posteriors
    load Sparse_parity_transformations_posteriors
end

Posteriors = Phats;
clear Phats

Posteriors{4}.truth.Untransformed = truth.posteriors;
Posteriors{4}.truth.Scaled = truth.posteriors;
Posteriors{4} = orderfields(Posteriors{4},[length(fieldnames(Posteriors{4})),1:length(fieldnames(Posteriors{4}))-1]);

Classifiers = fieldnames(Posteriors{4});
Classifiers(strcmp(Classifiers,'rr_rfr')) = [];

ClassifierNames = {'Posterior' 'RF' 'F-RC' 'F-RC(r)' 'RR-RF'};

fig = figure;
fig.Units = 'inches';
fig.PaperUnits = 'inches';
fig.Position = [0 0 figWidth figHeight];
fig.PaperPosition = [0 0 figWidth figHeight];
fig.PaperSize = [figWidth figHeight];

for i = 1:length(Classifiers)
    Transformations = fieldnames(Posteriors{4}.(Classifiers{i}));
    for j = 1:length(Transformations)
        ax((i-1)*2+j) = axes;
        p{(i-1)*2+j} = posterior_map(Xpost,Ypost,mean(Posteriors{4}.(Classifiers{i}).(Transformations{j}),3),false);
        title(['(' char('A'+(i-1)*2+j-1) ')'],'FontSize',14,'Units','normalized','Position',[-0.02 1],...
            'HorizontalAlignment','right','VerticalAlignment','top')
        if i==1
            text(0.5,1.05,Transformations{j},'FontSize',14,'FontWeight','bold','Units',...
                'normalized','HorizontalAlignment','center','VerticalAlignment'...
                ,'bottom')
            if j==1
                xlabel('X_1')
                ylabel({['\bf{',ClassifierNames{i},'}'];'\rm{X_2}'})
            end
        else
            if j==1
                ylabel(['\bf{',ClassifierNames{i},'}'])
            end
        end
        ax((i-1)*2+j).LineWidth = LineWidth;
        ax((i-1)*2+j).FontUnits = 'inches';
        ax((i-1)*2+j).FontSize = FontSize;
        ax((i-1)*2+j).Units = 'inches';
        ax((i-1)*2+j).Position = [axLeft((i-1)*2+j) axBottom((i-1)*2+j) axWidth axHeight];
        ax((i-1)*2+j).XTick = [];
        ax((i-1)*2+j).YTick = ax((i-1)*2+j).XTick;
        if i==1
            colormap(ax((i-1)*2+j),'jet')
        else
            colormap(ax((i-1)*2+j),'parula')
        end
        
        if i==1 && j==length(Transformations) || i==length(Classifiers) && j==length(Transformations)
            cb = colorbar;
            cb.Units = 'inches';
            cb.Position = [cbLeft((i-1)*2+j) cbBottom((i-1)*2+j) cbWidth cbHeight];
            cb.Box = 'off';
        end
    end
end

cdata = [];
for i = 3:length(p)
    cdata = [cdata;p{i}.CData(:)];
end
cmin = min(cdata);
cmax = max(cdata);

for i = 3:length(ax)
    caxis(ax(i),[cmin cmax])
end

% save_fig(gcf,[rerfPath 'RandomerForest/Figures/Fig1_posteriors'])