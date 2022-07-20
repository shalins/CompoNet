function [output_hull, output_hullIndices] = func_paretoFront(input_data, input_quadrants, input_plotType)
%% func_paretoFront.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 11/20/21
%   Last Revision: 11/21/21
%
%   File Description:
%       This function returns the xy points which form the hull (or
%       pareto-front) of a set of input xy data. It also returns the linear
%       indices of the original data which belong to the hull --- 
%       output_hull = input_data(output_hullIndices,:).
%       Can ignore NaN values which convhull() can not do by default.
%       
%       The hull can be one of many types according to the specified
%       quadrant(s) (in counter-clockwise order): '1' is only quadrant I,
%       '12' is quadrant I & II, etc.
%
%   Inputs:
%       - data          -- all xy coordinate data (data = [x,y])
%       - quadrants     -- quadrants of hull (character string: '1', '2',
%                           '12', etc.)
%       - plotType      -- is the plot linear or logarithmic
%
%   Outputs:
%       - hull          -- convex hull of xy coordinate data (hull = [x,y])
%       - hullIndices   -- indices of data set which form hull
%
%   Other m-files required: set_figure_style.m
%   Other files required: Relevant csv files
%

% Requires MATLAB's Curve Fitting Toolbox and version R2019a or later
%% Debug
% % close all
% clear all
% clc
% 
% % Plot Options
% k_plotscaling = 1.5; % Set relative size of plot fonts. Recommend 1.5 or 2.
% k_plotsize = 1.2;
% plot_shape = 'square';
% if(strcmp(plot_shape, 'square'))
%     k_plot_w = 450;
%     k_plot_h = 350;
% elseif(strcmp(plot_shape, 'rect'))
%     k_plot_w = 850;
%     k_plot_h = 385;
% end
% colormap_MAT = get(groot,'DefaultAxesColorOrder'); % Get defualt plot colors
% color0 = [0,0,0]; % black
% color1 = colormap_MAT(2,:);
% color2 = colormap_MAT(1,:);
% color3 = colormap_MAT(4,:);
% 
% % Imported data
% input_foldername = 'RawData_Digikey';
% % filename_1 = 'AlumPoly_11082019.csv';
% % filename_1 = 'AlumElec_11152019.csv';
% filename_1 = 'AlumElec_03282021.csv';
% % filename_1 = 'FilmPaper_03282021.csv';
% % filename_1 = 'PowerCeramic_10142021.csv';
% tic
% disp(['Parsing data from file: ',filename_1,' ...'])
% table_1 = func_ParseCapacitorPages(filename_1,input_foldername);
% % table_1 = input_table;
% % Remove outliers
% outlierFilepath = fullfile(input_foldername,'outlierCaps_03282021.txt');
% table_1 = func_removeOutliers(outlierFilepath, table_1);
% disp(['Finished parsing data.'])
% toc
% 
% % Pre-configure data by removing invalids. Note that this could break
% % output_hullIndices being at the correct indices of table_1 data.
% % m = (~isnan(table_1.EnergyDensity));
% % table_1a = table_1(m,:);
% 
% table_1a = table_1;
% % x_data_lin = table_1a.Voltage;
% % y_data_lin = table_1a.EnergyDensity*1e-9*1e3; % Conversion from [J/m^3] to [mJ/mm^3]
% % x_data_lin = table_1a.Capacitance;
% % y_data_lin = table_1a.Voltage;
% % x_data_lin = table_1a.CurrentRippleLF(:,1)./table_1a.Volume;
% % y_data_lin = table_1a.EnergyDensity;
% 
% units_energyDensity = 1e-9*1e6; % Conversion from [J/m^3] to [uJ/mm^3]
% % units_energyDensity = 1;
% units_costDensity = 1e-9; % Conversion from [$/m^3] to [$/mm^3]
% units_volume = 1e9; % Conversion from [m^3] to [mm^3]
% % units_volume = 1;
% % Voltage
% data_voltage = table_1a.Voltage;
% % Volumetric energy density
% data_energyDensity = table_1a.EnergyDensity*units_energyDensity; % Convert units
% % Capacitor volume
% data_volume = table_1a.Volume*units_volume; % Conversion from [m^3] to [mm^3]
% % Maximum current ripple at low frequency (120 Hz)
% if ismember('CurrentRippleLF', table_1a.Properties.VariableNames)
%     data_currRippleLF = table_1a.CurrentRippleLF;
% %         data_currRippleLF_A = data_currRippleLF
% else
%     data_currRippleLF = zeros(height(table_1a),2);
% end
% % Power Density
% data_powerDensity = data_voltage.*data_currRippleLF(:,1)./data_volume; % [W/mm^3]
% data_powerDensity(data_volume == 0) = NaN;
% 
% x_data_lin = data_powerDensity;
% y_data_lin = data_energyDensity;
% 
% 
% % Test
% % x_data_lin = [NaN,1,2,1]';
% % y_data_lin = [NaN,2,3,10]';
% % x_data_lin = [NaN,1,2]';
% % y_data_lin = [NaN,2,3]';
% % x_data_lin = [NaN,1,2,2]';
% % y_data_lin = [NaN,2,3,3]';
% 
% % % Pre-condition data (remove invalids)
% % x_data_lin = x_data_lin(y_data_lin ~= 0);
% % y_data_lin = y_data_lin(y_data_lin ~= 0);
% 
% % Define inputs
% input_data = [x_data_lin,y_data_lin];
% input_quadrants = '412';
% % input_plotType = 'linear';
% input_plotType = 'log';


%% Initialize and formulate data

% Supress warning messages
warning('off','MATLAB:nearlySingularMatrix');
warning('off','stats:robustcov:ZeroHOrderStatistic');

data = input_data;

% % Sort data (this assists outlier removal option B)
% [y_data_sorted,i_sorted] = sort(data(:,2),1);
% x_data_sorted = data(i_sorted,1);
% data = [x_data_sorted,y_data_sorted];

x_data_lin = data(:,1);
y_data_lin = data(:,2);

% Compute logarithmic version of data for potential use in hull computations
x_data_log = log10(x_data_lin);
y_data_log = log10(y_data_lin);


%% Generate convex hull

% Determine if hull should be computed for linear on logarithmic data
if strcmp(input_plotType,'linear')
    x_data = x_data_lin;
    y_data = y_data_lin;
elseif strcmp(input_plotType,'log')
    x_data = x_data_log;
    y_data = y_data_log;
end

% Pre-condition to omit nan (and inf) values from convex hull computation
i_nan = isnan(x_data) | isnan(y_data) | isinf(x_data) | isinf(y_data);
x_data_omitnan = x_data(~i_nan);
y_data_omitnan = y_data(~i_nan);

% Hull can only be defined with 3+ valid and distinct valid xy values.
if (length(unique(vecnorm([x_data_omitnan,y_data_omitnan]',1)')) >= 3)
    % Find convex hull of data exculding nan values.
%     k_omitnan_linearIndex = paretoQS([x_data_omitnan,y_data_omitnan]);
%     k_omitnan_linearIndex = paretoQS([x_data_omitnan,1./y_data_omitnan]);
    k_omitnan_linearIndex = func_getPareto([x_data_omitnan,y_data_omitnan],input_quadrants);
else
    k_omitnan_linearIndex = [];
end
% Remove duplicate points from convex hull. Must be done before
% re-integrating NaN data values.
k_omitnan_linearIndex = unique(k_omitnan_linearIndex,'stable');

% Convert linear hull indices to logical indexing. The correct order of the
% hull indices is lost here but will be recovered later.
k_omitnan_logicalIndex = false(size(x_data_omitnan));
k_omitnan_logicalIndex(k_omitnan_linearIndex) = true; 

k_logicalIndex = nan(size(x_data));
k_logicalIndex(~i_nan) = k_omitnan_logicalIndex;
k_logicalIndex(i_nan) = 0;

% Convert logical indexing to linear indices of data (including nan) which
% belong to the hull.
k_linearIndex = find(k_logicalIndex);

% Re-order the hull indices to be in the correct order.
[~,i_order] = ismember(k_omitnan_linearIndex,sort(k_omitnan_linearIndex));
k_linearIndex = k_linearIndex(i_order);
k = k_linearIndex;

% idx2 = (~isnan(x_plot{1}+y_plot{1}))'
% a = x_plot{1}(idx2)
% b = y_plot{1}(idx2)
% i_sort = data_voltage{1}<100
% a1 = a(i_sort);
% b1 = b(i_sort);
% idx1 = paretoQS([1./a1 1./b1])
% d = sortrows([a1(idx1),b1(idx1)])
% plot(d(:,1),d(:,2),'k')

x_hull = x_data_lin(k,:);
y_hull = y_data_lin(k,:);

%% Scatter plot - Power Density versus Energy Density versus Voltage
% figure;
% hold on;
% clear x_plot y_plot z_plot smoothHull_plot % Clear plot variables
% 
% % Unit conversion
% units_temp1 = 1e3*1e0; % Conversion from [W/mm^3] to [W/cm^3]
% units_temp1 = 1e3*1e0; % Conversion from [W/mm^3] to [mW/mm^3]
% units_temp1 = 1;
% units_temp2 = 1e-3; % Conversion from [uJ/mm^3] to [uJ/cm^3]
% units_temp2 = 1;
% 
% % Set data to plot
% % x_plot = data_powerDensity*units_temp1; % [W/mm^3]
% % y_plot =  data_energyDensity*units_temp2; % [uJ/mm^3]
% x_plot = x_data_lin*units_temp1; % [W/mm^3]
% y_plot =  y_data_lin*units_temp2; % [uJ/mm^3]
% z_plot = data_voltage;
% 
% Nplot = length(x_plot);
% scatter(x_plot,y_plot,5,z_plot,'filled')
% % scatter(x_plot_1,y_plot_1,10,z_plot_1)
% 
% % Include Enphase capacitor (UVZ1H332MHD)
% plot(50*0.188,438,'x','Color',[0 0 0],'MarkerSize',10,'LineWidth',2);
% 
% d = [x_plot(k,:), y_plot(k,:)];
% plot(d(:,1),d(:,2),'k-o')
% 
% xlim([5E-5 2E-1]*units_temp1)
% ylim([2E2 5E6]*units_energyDensity*units_temp2)
% xticks(10.^(-15:1:5))
% yticks(10.^[-15:3:15])
% 
% % title(input_types{k})
% xlabel ('Power Density (at 120 Hz) [mW/mm$^3$]')
% % ylabel('Energy Density [mJ/mm$^3$]')
% ylabel('Energy Density [$\mu$J/mm$^3$]')
% zaxesLabel = '$V_r$ [V]';
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% colormap(xlsread('colormap.xlsx'));
% caxis([min(z_plot) max(z_plot)])
% colorbar_h = colorbar;
% 
% % set(colorbar_h,'YTick',[10.^[-12:3:0]]);
% % set(colorbar_h,'YTickLabel',{'pF','nF','$\mu$F','mF','F'});
% set(colorbar_h,'YTick',[10.^[0:1:5]]);
% set(colorbar_h,'YTickLabel',{'1 V','10 V','100 V','1 kV','10 kV'})
% set(gca,'ColorScale','log')
% 
% ylabel_colorbar = ylabel(colorbar_h,zaxesLabel,'Rotation',0.0,'Interpreter','latex'); % colorbar label
% % % set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.5, 0.52, 0])
% % set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.3, 0.52, 0])
% set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [2.2, -0.07, 0])
% 
% set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
% set(gcf,'PaperPositionMode','auto')
% movegui(gcf,'center')
% set_figure_style(k_plotscaling);

%% Output

output_hull = [x_hull,y_hull];
output_hullIndices = k;

end


%% func_getPareto.m
% Inline function to compute pareto front based on indicated quandrant(s).
function outputHullIndices = func_getPareto(inputData,inputQuadrants)
%   First input is the xy data.
%   Second input is string indicating the quadrant(s) to include (in
%       counter-clockwise order).
%   Returns the indices of the pareto front (hull).

x_data = inputData(:,1);
y_data = inputData(:,2);

k_tot = [];
% For each quadrant, get the pareto set then sort in counter-clockwise
% order
for i = 1:length(inputQuadrants)
    switch inputQuadrants(i)
        case '1' % Quadrant I
            k = paretoQS([-x_data,-y_data]);
            temp = sortrows([k',inputData(k,:)],2,'descend');
        case '2' % Quadrant II
            k = paretoQS([x_data,-y_data]);
            temp = sortrows([k',inputData(k,:)],2,'descend');
        case '3' % Quadrant III
            k = paretoQS([x_data,y_data]);
            temp = sortrows([k',inputData(k,:)],2);        
        case '4' % Quadrant IV
            k = paretoQS([-x_data,y_data]);
            temp = sortrows([k',inputData(k,:)],2);
    end
    
    % Extract the sorted hull indices (linear indices)
    k = temp(:,1);
    
    % Append the hull indices to the total
    k_tot = [k_tot;k];

end

% Return the indices for the pareto front 
outputHullIndices = k_tot;

end

%% paretoQS.m
% Inline function to compute pareto front.
% Tom R (2021). Find multi-objective Pareto front using modified quicksort
% (https://www.mathworks.com/matlabcentral/fileexchange/73089-find-multi-
% objective-pareto-front-using-modified-quicksort), MATLAB Central File
% Exchange. Retrieved November 21, 2021.
function indPar=paretoQS(sln)
%PARETOQS   Find Pareto optimal front using modified quicksort
%   indPar=paretoQS(sln) returns row indices to the pareto optimal set of 
%   designs, so that for each point x_i in the front no point x_j performs 
%   better (<) in all objective functions. By definition, duplicates do not
%   dominate each other. Note that all objectives are treated as 
%   minimization, so maximize objectives y_max should be passed as
%                       y_min = -y_max; 
%                             or
%                       y_min = 1/y_max;
%
%   Inputs: sln - The solution space to identify pareto optimal designs in,
%                 as a matrix of the shape nPt x nOf
%                 (number of points x number of objectives) 
%
%   Outputs: indPar - Indices of the pareto optimal points of the given
%                     input space
%
%   Example: 
%       nPt=1000;
%       x=linspace(1/5,5,nPt).';
%       paretoQS([x+0.75.*randn(nPt,1),1./x+0.75.*randn(nPt,1)])

%Asset correct shape
assert(ismatrix(sln),'Input must be an nPt x nOF matrix');

%Find size of sln space
[nPt,nOF]=size(sln);

%Special cases
if isempty(sln)
    %Either/Both dimensions empty, return empty of same 'shape'
    indPar=sln;
    return
elseif nPt==1
    %Only one point must be pareto optimal
    indPar=1;
    return
elseif nOF==1
    %Only one OF, minimum must be the pareto optimal
    [~,indPar]=min(sln);
    return
end

%Init the pareto set to full
indPar=1:nPt;
nPar=nPt;

%Decide allowable number of no-improvements at expected O(n lg n) till fallback to brute force
nnImp=0;
exitThresh=2;

%Begin iteration
while true
    %Chose random pivot (quicksort inspired), remove all that are domainated by pivot
    indPar(all(sln(indPar,:) > sln(indPar(randi([1 nPar],1)),:),2))=[];
    
    %Update length
    nParPrev=nPar;
    nPar=length(indPar);
    
    %Keep track of improvement
    if (nPar==nParPrev)
        %No improvement
        nnImp=nnImp+1;
    else
        %Improvement made
        nnImp=0;
    end
    
    %Consider exit
    if nnImp>=exitThresh
        break
    end
end

%We now have a nearly-pareto set, perform final sweep to remove invalid entries
for i=nPar:-1:1 %go backwards so we don't worry about swapping
    if any(all(sln(indPar,:) < sln(indPar(i),:),2))
        indPar(i)=[];
    end
end

end