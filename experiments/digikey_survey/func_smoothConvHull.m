function [output_hull, output_hullIndices, output_smoothHull] = func_smoothConvHull(input_data, input_type, input_plotType, input_removeOutlier)
%% func_smoothConvHull.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 5/2/21
%   Last Revision: 2/8/22
%
%   File Description:
%       This function returns the xy points which form the convex hull (or
%       pareto-front) of a set of input xy data. It also returns the linear
%       indices of the original data which belong to the hull --- 
%       output_hull = input_data(output_hullIndices,:). It also returns an
%       xy interpolated smooth spline curve fit of the pareto-front.
%       Can ignore NaN values which convhull() can not do by default.
%       
%       The hull can be one of two types: 'whole' (looks elliptical),
%       'top' which is the top half of the 'whole' hull, or 'bottom' which
%       is the bottom half of the 'whole' hull.
%
%       There is an optional argument to remove outliers. This computation
%       roughly doubles the computation time. Should be used sparingly in
%       data sets that appear to need it.
%
%       TODO:
%       -   Implement left and right half hulls. A more complete
%           implementation would be quarter hulls.
%       -   Functionalize some of the code to improve
%           readability/usability.
%
%   Inputs:
%       - data          -- all xy coordinate data (data = [x,y])
%       - type          -- type of convex hull (whole, top, or bottom)
%       - plotType      -- is the plot linear or logarithmic
%       - removeOutlier (optional)  -- remove outlier (optionA, optionB,
%                          or false)
%
%   Outputs:
%       - hull          -- convex hull of xy coordinate data (hull = [x,y])
%       - hullIndices   -- indices of data set which form hull
%       - smoothHull    -- smooth curve fit of convex hull ([x,y])
%
%   Other m-files required: set_figure_style.m
%   Other files required: Relevant csv files
%

% Requires MATLAB's Curve Fitting Toolbox and version R2019a or later
%% Debug
% close all
% clear all
% clc
% 
% % Imported data
% input_foldername = 'RawData_Digikey';
% % filename_1 = 'AlumPoly_11082019.csv';
% % filename_1 = 'AlumElec_11152019.csv';
% filename_1 = 'AlumElec_03282021.csv';
% % filename_1 = 'FilmPaper_03282021.csv';
% % filename_1 = 'PowerCeramic_10142021.csv';
% tic
% table_1 = func_ParseCapacitorPages(filename_1,input_foldername);
% % table_1 = input_table;
% % Remove outliers
% outlierFilepath = fullfile(input_foldername,'outlierCaps_03282021.txt');
% table_1 = func_removeOutliers(outlierFilepath, table_1);
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
% x_data_lin = table_1a.CurrentRippleLF(:,1)./table_1a.Volume;
% y_data_lin = table_1a.EnergyDensity;
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
% input_type = 'whole';
% % input_type = 'top';
% % input_removeOutlier = 'true';
% input_removeOutlier = 'false';
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

%% Remove outliers
% Option A: Currently only works with 'top' type because it
% chops off some of the non-outlier bottom data as well. This is mostly
% due to the density of data being concentrated to the top pareto-front.
% It also takes up about half of the computation time of the full function.
% Option B: A bit more robust, but still imperfect. Tends to remove points
% on the pareto-front.
% Notice that outlier identification is applied to the loglog data.
if exist('input_removeOutlier', 'var')
    if strcmp(input_removeOutlier,'optionA')
        [~,~,~,outliers] = robustcov([log10(data)]);
        data_noOutliers = data(~outliers,:);
    elseif strcmp(input_removeOutlier,'optionB')
        unique_x_data = unique(x_data_lin);
        indices_outliers = nan(1);
        Ltot = zeros(length(unique_x_data),1);
        Utot = zeros(length(unique_x_data),1);
        Ctot = zeros(length(unique_x_data),1);
        for i = 1:length(unique_x_data)
            index_match = find(x_data_lin == unique_x_data(i));
            y_data_match = y_data_lin(index_match);
%             outlier = isoutlier(y_data_match); % Linear
%             [outlier,L,U,C] = isoutlier(log10(y_data_match),'quartiles'); % Log
%             [outlier,L,U,C] = isoutlier(log10(y_data_match),'movmean',10,'ThresholdFactor',3); % Log
            outliers_match = isoutlier(log10(y_data_match),'movmean',1000,'ThresholdFactor',4); % Log
%             [outlier,L,U,C] = isoutlier(log10(y_data_match),'movmedian',7); % Log
            index_outlier = index_match(outliers_match);
            indices_outliers = [indices_outliers, index_outlier'];
        end
%         data_noOutliers = data_noOutliers(indices_outliers,:) 
        data_noOutliers = data(setdiff(1:size(data,1),indices_outliers),:);
    elseif strcmp(input_removeOutlier,'false')
        data_noOutliers = data;
    end
else
    data_noOutliers = data;
end

% % Debug plot
% figure;
% x_plot_1 = data(:,1);
% y_plot_1 = data(:,2);
% x_plot_2 = data_noOutliers(:,1);
% y_plot_2 = data_noOutliers(:,2);
% % x_plot_3 = unique_x_data;
% % y_plot_3 = [Ltot,Utot,Ctot];
% x_plot_1 = log10(x_plot_1);
% y_plot_1 = log10(y_plot_1);
% x_plot_2 = log10(x_plot_2);
% y_plot_2 = log10(y_plot_2);
% % x_plot_3 = log10(x_plot_3);
% % y_plot_3 = y_plot_3;
% plot(x_plot_1*1,y_plot_1,'+');
% hold on;
% plot(x_plot_2*1,y_plot_2,'.');
% % plot(x_plot_3,y_plot_3,'o');
% % set(gca, 'YScale', 'log')
% % set(gca, 'XScale', 'log')


% Apply outlier removal
data = data_noOutliers;

% Recompute data after outliers
x_data_lin = data(:,1);
y_data_lin = data(:,2);
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
    k_omitnan_linearIndex = convhull(x_data_omitnan, y_data_omitnan,'simplify',true);
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

% Find the indices of the data set which define the convex hull
% k = convhull(x_data, y_data,'simplify',true);

% Debug plot
% figure;
% plot(x_data_lin,y_data_lin,'.');
% hold on;
% plot(x_data_lin(k),y_data_lin(k));
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% 
% figure;
% plot(x_data_log,y_data_log,'.');
% hold on;
% plot(x_data_log(k),y_data_log(k));

%% Seperate convex hull into top/bottom halves

% Number of points in hull
nk = length(k);

% First find indices of minimum and maximum x-values (could be 1 or 2 of each)
ix_min = find(x_data_lin(k) == min(x_data_lin(k)));
ix_max = find(x_data_lin(k) == max(x_data_lin(k)));
if(diff(ix_min)>1)
    ix_min(1) = ix_min(1) + nk;
end
if(diff(ix_max)>1)
    ix_max(1) = ix_max(1) + nk;
end

% Next define the indices seperating the 1st and 2nd half hulls (top and
% bottom). Then define the indices of each hull
a1 = abs(max(ix_min)-min(ix_max));
a2 = abs(min(ix_min)-max(ix_max));
if (a1 <= a2)
%    convhalf_1_i = max(ix_min):min(ix_max)
    convhalf_1_i = linspace(max(ix_min),min(ix_max),a1+1);
elseif (a2 < a1)
%    convhalf_1_i = min(ix_min):max(ix_max)
    convhalf_1_i = linspace(min(ix_min),max(ix_max),a2+1);
else % If hull is empty
    convhalf_1_i = [];
end
% Readjust for wrapping
convhalf_1_i = mod(convhalf_1_i-1,nk) + 1;

% Define 1st half of convex hull
convhalf_1 = k(convhalf_1_i);
% Define 2nd half of convex hull as points not belonging to first half
convhalf_2_i = setdiff(1:length(k),convhalf_1_i);

% Circular shift the half hull to be in ascending order
b1 = find(diff(convhalf_2_i)>1);
if isempty(b1)
	convhalf_2_i = convhalf_2_i;
else
	convhalf_2_i = circshift(convhalf_2_i, -b1);
end
% Next, adjust other half for the case where the max and min only have one
% component.
if ~isempty(convhalf_2_i) % If half hull is empty, skip.
    if (length(ix_max) == 1)
    %     convhalf_2_i = [convhalf_2_i, convhalf_1_i(end)];
    %     convhalf_2_i = [convhalf_2_i, mod(convhalf_2_i(end)+1,nk)];
        if (x_data_lin(k(convhalf_2_i(1))) > x_data_lin(k(convhalf_2_i(end))))
            convhalf_2_i = [ix_max, convhalf_2_i];
        else
            convhalf_2_i = [convhalf_2_i, ix_max];
        end
    end
    if (length(ix_min) == 1)
    %     convhalf_2_i = [convhalf_1_i(1), convhalf_2_i];
    %     convhalf_2_i = [mod(convhalf_2_i(end)-1,nk), convhalf_2_i];
        if (x_data_lin(k(convhalf_2_i(1))) > x_data_lin(k(convhalf_2_i(end))))
            convhalf_2_i = [convhalf_2_i, ix_min];
        else
            convhalf_2_i = [ix_min, convhalf_2_i];
        end
    end
end

% convhalf_2_i = circshift(convhalf_2_i,-find(diff(convhalf_2_i)>1))
convhalf_2 = k(convhalf_2_i);
% Although potentially not necessary, remove duplicate points from half
% hulls
convhalf_1 = unique(convhalf_1,'stable');
convhalf_2 = unique(convhalf_2,'stable');

% Identify the top and bottom hull halves
if (mean(y_data_lin(convhalf_1)) > mean(y_data_lin(k)))
    conv_top = convhalf_1;
    conv_bottom = convhalf_2;
else
    conv_top = convhalf_2;
    conv_bottom = convhalf_1;
end
% Alternative implementation. Doesn't work when endpoints are the max.
% if (max(y_data(convhalf_1)) > max(y_data(convhalf_2)))
%     conv_top = convhalf_1;
%     conv_bottom = convhalf_2;
% elseif (max(y_data(convhalf_1)) < max(y_data(convhalf_2)))
%     conv_top = convhalf_2;
%     conv_bottom = convhalf_1;
% end

% Debug plot
% figure;
% hold on;
% plot(x_data_lin(convhalf_1,:),y_data_lin(convhalf_1,:),'-');
% plot(x_data_lin(convhalf_2,:),y_data_lin(convhalf_2,:),'-');
% plot(x_data_lin(conv_top,:),y_data_lin(conv_top,:),'-');
% plot(x_data_lin(conv_bottom,:),y_data_lin(conv_bottom,:),'-');
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')


%% Refine the convex hull type

% Determine convex hull type
if strcmp(input_type,'whole')
    k = k; % Grab all hull data
%     k = [conv_bottom; flipud(conv_top)];
elseif strcmp(input_type,'top')
    k = conv_top; % Grab top hull data
elseif strcmp(input_type,'bottom')
    k = conv_bottom; % Grab bottom hull data
end

% Could be linear or logarithmic data for curve fitting
x_hull = x_data(k,:);
y_hull = y_data(k,:);

%% Smooth curve fit of convex hull

x = x_hull';
y = y_hull';
% n = 4;
% x = [circshift(x(1:end-1),n),x(end-n)];
% y = [circshift(y(1:end-1),n),y(end-n)];
% x = [x, x(1:2)];
% y = [y, y(1:2)];
% Unique method for spline fitting closed curve
if strcmp(input_type,'whole')
    x = [x, x];
    y = [y, y];
end

% Skip curve-fitting if hull is empty
if (nk ~= 0)
    % Begin curve fitting parameterization
    t = [0,cumsum(sqrt(diff(x).^2 + diff(y).^2))];
    % Choose interpolation type. Makima (only in R2019a or later)
    % Makima looks best for half and whole convex hull. Spline and pchip only
    % look good for half.
    % x_t = pchip(t,x);
    % y_t = pchip(t,y);
    % x_t = spline(t,x);
    % y_t = spline(t,y);
    x_t = makima(t,x);
    y_t = makima(t,y);
    n_i = 20; % Number of interpolated points between segments + 1
    t_i = cumsum([0,repelem(diff(t)/n_i,n_i)]);
    x_i = ppval(x_t,t_i)';
    y_i = ppval(y_t,t_i)';

    % Unique method for spline fitting closed curve
    if strcmp(input_type,'whole')
        % Pull out middle of [x,x] and [y,y]
        n_x = round(length(x)/2); % Shouldn't need to be rounded by definition
        x_i2 = x_i(n_i*round(1/2*n_x)+(0:n_i*n_x));
        y_i2 = y_i(n_i*round(1/2*n_x)+(0:n_i*n_x));
        x2 = x(round(1/2*n_x)+(0:n_x));
        y2 = y(round(1/2*n_x)+(0:n_x));
    %     t2 = t(round(1/2*n_x)+(0:n_x));
    %     t_i2 = t_i(round(1/2*n_x)+(0:n_x));
    else
        x2 = x;
        y2 = y;
        x_i2 = x_i;
        y_i2 = y_i;
    end

    % Debug plots
%     figure;
%     plot(x2,y2,'-ok')
%     hold on
%     plot(x_i2,y_i2,'--r.')
%     % set(gca, 'YScale', 'log')
%     % set(gca, 'XScale', 'log')
%     figure;
%     hold on;
%     plot(t,x,'-ok');
%     plot(t,y,'-ok');
%     plot(t_i,x_i,'--r.');
%     plot(t_i,y_i,'--r.');
%     if strcmp(input_type,'whole')
%         xline(t(round(1/2*n_x)),'--k');
%         xline(t(round(1/2*n_x)+(n_x)),'--k');
%         xline(t_i(n_i*round(1/2*n_x)),'--r');
%         xline(t_i(n_i*round(1/2*n_x)+n_i*(n_x)),'--r');
%     end

else
%     x_i2 = [];
%     y_i2 = [];
    x_i2 = x_hull;
    y_i2 = y_hull;
end

%% Plot Options
% k_plotscaling = 1.5; % Set relative size of plot fonts. Recommend 1.5 or 2.
% k_plotsize = 1.2;
% plot_shape = 'square';
% if(strcmp(plot_shape, 'square'))
%     k_plot_w = 450;
%     k_plot_h = 350;
% end
% colormap_MAT = get(groot,'DefaultAxesColorOrder'); % Get defualt plot colors
% color0 = [0,0,0]; % black
% color1 = colormap_MAT(2,:);
% color2 = colormap_MAT(1,:);
% color3 = colormap_MAT(4,:);

%% Plot (final)
% figure;
% hold on;
% x_plot_1 = x_data;
% y_plot_1 = y_data;
% x_plot_2 = x_hull;
% y_plot_2 = y_hull;
% x_plot_3 = x_data(isoutlier(y_data2));
% y_plot_3 = y_data(isoutlier(y_data2));
% 
% plot(x_plot_1*1.01,y_plot_1,'.', 'MarkerSize',5)
% % plot(x_plot_3*0.99,y_plot_3,'.', 'MarkerSize',5)
% plot(x_i,y_i,'--r.')
% 
% xlim([1 2000])
% 
% xlabel('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
% % legend({'Aluminum Electrolytic - 11/2019', 'Aluminum Electrolytic - 03/2021'},'Location','Best');
% % set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% set_figure_style(k_plotscaling);

%% Plot (outlier removal)
% figure;
% hold on;
% x_plot_1 = x_data2;
% y_plot_1 = y_data2;
% x_plot_2 = x_hull;
% y_plot_2 = y_hull;
% x_plot_3 = x_data2(isoutlier(y_data2));
% y_plot_3 = y_data2(isoutlier(y_data2));
% 
% % [TF,L,U,C] = isoutlier(y_data2.*x_data2,'ThresholdFactor',4)
% cov([x_data2,y_data2])
% % robustcov([x_data2,y_data2])
% [sig,mu,mah,outliers] = robustcov([x_data2,y_data2],'Method','fmcd','OutlierFraction',0.2);
% 
% x_plot_4 =  x_data2(outliers);
% y_plot_4 =  y_data2(outliers);
% 
% plot(x_plot_1*1.01,y_plot_1,'.', 'MarkerSize',5)
% plot(x_plot_4*0.99,y_plot_4,'.', 'MarkerSize',5)
% plot(x_i,y_i,'--r.')
% 
% % xlim([1 2000])
% 
% xlabel('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
% % legend({'Aluminum Electrolytic - 11/2019', 'Aluminum Electrolytic - 03/2021'},'Location','Best');
% % set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
% % set(gca, 'YScale', 'log')
% % set(gca, 'XScale', 'log')
% set_figure_style(k_plotscaling);

%% Plot (curve fitting)
% c = cscvn([x_hull,y_hull]');
% figure;
% fnplt(c);

%% Complete some final post-processing steps

x_hull = x_data_lin(k,:);
y_hull = y_data_lin(k,:);

% Connect the closed hull if necessary
if strcmp(input_type,'whole')
    try
        % Handle case where hull is completely empty
        x_hull = [x_hull; x_hull(1)];
        y_hull = [y_hull; y_hull(1)];
    catch
        % Do nothing
    end
elseif strcmp(input_type,'top')
    % Do nothing
elseif strcmp(input_type,'bottom')
    % Do nothing
end

% Convert hull and its smooth curve fit to linear data if logarithmic
if strcmp(input_plotType,'linear')
    % Do nothing.
    x_fit = x_i2;
    y_fit = y_i2;
elseif strcmp(input_plotType,'log')
    x_fit = 10.^(x_i2);
    y_fit = 10.^(y_i2);
end


%% Output

output_hull = [x_hull,y_hull];
output_hullIndices = k;
output_smoothHull = [x_fit,y_fit];

end

