function output_dataTable = func_ComputeMass(input_dataTables)
%% func_ComputeMass.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 1/27/21
%   Last Revision: 1/31/21
%
%   File Description:
%       This function estimates the mass of each component based on a
%       volume to mass transformation which varies slightly with
%       capacitance and voltage based on a 2D logarithmic surface fit.
%
%       Currently only converts ceramic capacitors and seperates by
%       dielectric material (Class 1 or Class 2/3).
%
%       TODO: Introduce transformations for other capacitor technologies.
%
%   Inputs:
%       - dataTable     --  table of data or cell array of tables where
%                               each table is associated with a particular
%                               technology
%
%   Outputs:
%       - dataTable     --  table of data including appended estimation of
%                               mass in [g]
%
%   Other m-files required:
%   Other files required: 
%
%% Debug
% % close all
% % clear all
% % clc
% 
% % Supress warning messages
% warning('off','MATLAB:table:PreallocateCharWarning');
% 
% % Manually specificy function inputs for debugging
% % input_filename = 'Alumpoly_11082019.csv';
% % input_filename = 'Alumelec_11152019.csv';
% % input_filename = 'C0GNP0_03222021.csv';
% % inputFilename = 'Test.csv';
% % input_filename = 'FilmAcrylic_03282021.csv';
% % input_filename = 'Tantalum_03282021.csv';
% % input_filename = 'TantalumPoly_03282021.csv';
% % input_filename = 'AlumPoly_03282021.csv';
% input_filename = 'AlumElec_03282021.csv';
% % input_filename = 'C0GNP0_03222021.csv';
% % input_filename = 'Ceramic_20211111_b.csv';
% % input_filename = 'PowerCeramic_10142021.csv';
% % input_filename = 'FilmPolyester_03282021.csv';
% % input_filename = '';
% % 
% input_foldername = 'RawData_Digikey';
% 
% % inputTables = cell(2,1);
% % inputTables{1} = func_ParseCapacitorPages(input_filename,input_foldername);
% % inputTables{2} = func_ParseCapacitorPages('',input_foldername);
% 
% inputTables = func_ParseCapacitorPages(input_filename,input_foldername);
% 
% input_dataTables = inputTables;


%% Initialize data

inputTables = input_dataTables;


%% Import measured data and compute best fit surface
% func_DensityFit_CV(); % Debug curve fitting


%% Sort by manufacturer
% i = ~cellfun(@isempty,regexpi(outputTables.Manufacturer, 'KEMET'));
% % i = func_matchPartialStringInCell(outputTables.Manufacturer, 'KEMET');

% for j = 1:height(outputTables) 
% %     Class 1
% %     switch outputTables.Manufacturer(j) 
% %         case 'KEMET'
% %             K = 5.1894; % [mg/mm^3]
% %         case 'TDK Corporation'
% %             K = 4.4521; % [mg/mm^3]
% %     end
% % 
% end


%% Sort by dielectric material

% Determine quantity of data tables from the variable type
if isa(inputTables,'cell')
    Njj = length(inputTables);
elseif isa(inputTables,'table')
    Njj = 1;
end

for jj = 1:Njj

    % Extract data table from input structure
    if isa(inputTables,'cell')
        inputData = inputTables{jj};
    elseif isa(inputTables,'table')
        inputData = inputTables;
    end
    
    % Check if table variables exist    
    if ismember('Capacitance', inputData.Properties.VariableNames)
        capacitance = inputData.Capacitance;
        voltage = inputData.VoltageRatedDC;
        density = nan(size(inputData,1),1); % mass per volume [mg/mm^3]
    else
        capacitance = nan(size(inputData,1),1);
        voltage = nan(size(inputData,1),1);
        density = nan(size(inputData,1),1);        
    end
    
    if ismember('Tech', inputData.Properties.VariableNames)
        if ~isempty(inputData.Tech)
            % Sort by capacitor technology
            if strcmp('Ceramic', inputData.Tech(max(end,1)))
                
                % Class 1 ceramics
                i = ~cellfun(@isempty,regexpi(inputData.Type, '_C1'));
                % density = 0.2384*log(capacitance) + 8.8972
                b = [2.4563,0.0558,0.0665]; % R^2 = 0.6182
                density(i) = exp(b(1) + b(2)*log(voltage(i)) + b(3)*log(capacitance(i))); % [mg/mm^3]
        
                % Class 2 ceramics (and Class 3)
                i1 = ~cellfun(@isempty,regexpi(inputData.Type, '_C2'));
                i2 = ~cellfun(@isempty,regexpi(inputData.Type, '_C3'));
                i = i1|i2;
                % density = 0.1492*log(capacitance) + 7.7531
                b = [2.1289,-0.0045,0.0272]; % R^2 = 0.2474
                density(i) = exp(b(1) + b(2)*log(voltage(i)) + b(3)*log(capacitance(i))); % [mg/mm^3]
                
            elseif strcmp('AlumElec', inputData.Tech(max(end,1)))
                % All Al electrolytic (including big screw terminal caps)
                i = true(height(inputData),1);
                b = [0.2621,-0.1185,-0.0707]; % R^2 = 0.6655
                density(i) = exp(b(1) + b(2)*log(voltage(i)) + b(3)*log(capacitance(i))); % [mg/mm^3]
            else
                % Do nothing
            end
        else
            % Invalid filename (empty)
        end
    else
        % Skip case for inductors
    end
    

    % Create a new variable in the table for mass
    volume = inputData.Volume*1e9; % [m^3] to [mm^3]
    mass = volume.*density;% [mm^3] to [mg]
    inputData.mass = mass*1e-3; % [mg] to [g]
    
    % Reassign data table to input structure
    if isa(inputTables,'cell')
        inputTables{jj} = inputData;
    elseif isa(inputTables,'table')
        inputTables = inputData;
    end
    
end

%% Output
output_dataTable = inputTables;


end


%% func_DensityFit_CV.m
% Inline function which fits a 2D surface to the capacitance/voltage vs density measured data.
function func_DensityFit_CV()
%   No inputs
%   No outputs

%   Curve fit is of the form:
%       density = exp(b(1) + b(2)*log(voltage(i)) + b(3)*log(capacitance(i))); % [mg/mm^3]
%   which is a case of the translog production function but with no xy coupling 

    %% Initialize parameters

    % File to import
%     filename_meas = 'Ceramics';
    filename_meas = 'AlumElecs';

    % Select which data to fit
%     id_Type = 'Class 1';
%     id_Type = 'Class 2';
    id_Type = 'Alum Elec';

    %% Import Measured Data
    measTable = readtable(fullfile('MeasData',[filename_meas,'.xlsx']));
    % Remove the first row from the table which contains units
    measTable = measTable(2:end,:);

    % Convert relevant data to the correct type
%     measTable.Capacitance = str2double(measTable.Capacitance);
%     measTable.Voltage = str2double(measTable.Voltage);
%     measTable.Volume = str2double(measTable.Volume);
%     measTable.PerMass = str2double(measTable.PerMass);
%     measTable.Density = str2double(measTable.Density);

    % Find the table indices which correspond to specified capacitor types
    index_measTable{1} = ~cellfun(@isempty,regexpi(measTable.Type, 'Class 1'));
    index_measTable{2} = ~cellfun(@isempty,regexpi(measTable.Type, 'Class 2'));
    
    % Select which data to fit
    if strcmp(id_Type,'Class 1')
        measTable_plot{1} = measTable(index_measTable{1},:);
    elseif strcmp(id_Type,'Class 2')
        measTable_plot{1} = measTable(index_measTable{2},:);
    else
        measTable_plot{1} = measTable; % All capacitors
    end
    
    x_data = measTable_plot{1}.Voltage;
    y_data = measTable_plot{1}.Capacitance;
    z_data = measTable_plot{1}.Density;

    % https://www.mathworks.com/help/stats/regress.html
    x1 = x_data;
    x2 = y_data;
    y = z_data;
    X = [ones(size(x1)) x1 x2 x1.*x2];
    [b,~,~,~,stats] = regress(y,X)    % Removes NaN data
    figure;
    scatter3(x1,x2,y,'filled')
    hold on
    x1fit = min(x1):10:max(x1);
    x2fit = min(x2):1E-7:max(x2);
    [X1FIT,X2FIT] = meshgrid(x1fit,x2fit);
    YFIT = b(1) + b(2)*X1FIT + b(3)*X2FIT + b(4)*X1FIT.*X2FIT;
    mesh(X1FIT,X2FIT,YFIT)
    xlabel('Voltage')
    ylabel('Capacitance')
    zlabel('Density')
    view(50,10)
    hold off

    %%
%     % https://stackoverflow.com/questions/21651261/linear-logarithmic-regression-in-matlab-2-input-parameters
%     % https://en.wikipedia.org/wiki/Cobb%E2%80%93Douglas_production_function
%     % https://www.mathworks.com/matlabcentral/answers/171718-how-can-write-this-in-matlab#comment_262537
% 
%     P = @(b,x) b(1).*(x(1).^b(2)).*(x(2).^(1-b(2))); 
%     SSECF = @(b) sum((y - m(b,P)).^2);
% 
%     % TODO: Preparse NaNs from data
%     x1 = x_data;
%     x2 = y_data;
%     y = z_data;
%     % f_YFIT_log = @(b,X1,X2) b(1) + b(2)*log(X1) + (1-b(2))*log(X2) + 0.5*0*b(2)*(1-b(2))*(log(X1)-log(X2)).^2; % Translog production function
%     % f_YFIT_log = @(b,X1,X2) b(1)*(X1.^b(2)).*(X2.^(1-b(2))); % Cobb-Douglas function
%     f_YFIT_log = @(b,X1,X2) b(1)*(X1.^b(2)).*(X2.^b(3)); % Cobb-Douglas function
% 
%     SSECF = @(b) sum((y - f_YFIT_log(b,x1,x2)).^2);  % Sum-Squared-Error Cost Function
%     B0 = [1, 0.1,1E-4];                             % Initial Paremeter Estimates
%     options = optimset('PlotFcns','optimplotfval','TolX',1e-7);
%     [B, SSE,~,OUTPUT] = fminsearch(SSECF, B0, options)
% 
%     figure;
%     scatter3(x1,x2,y,'filled')
%     hold on
%     % x1fit = min(x1):100:max(x1);
%     % x2fit = min(x2):1E-8:max(x2);
%     x1fit = logspace(log10(min(x1)),log10(max(x1)),2e1)
%     x2fit = logspace(log10(min(x2)),log10(max(x2)),2e1)
%     [X1FIT,X2FIT] = meshgrid(x1fit,x2fit);
%     YFIT = exp(f_YFIT_log(B,X1FIT,X2FIT));
%     mesh(X1FIT,X2FIT,YFIT)
%     xlabel('Voltage')
%     ylabel('Capacitance')
%     zlabel('Density')
%     view(50,10)
%     % set(gca, 'YScale', 'log')
%     % set(gca, 'XScale', 'log')
%     % zlim([0 10])
%     hold off

    %% This one works the best
    x1 = x_data;
    x2 = y_data;
    y = z_data;
    X = [ones(size(x1)) log(x1) log(x2)];
    [b,~,~,~,stats] = regress(log(y),X)    % Removes NaN data
    % Fit: density = exp(b(1) + b(2)*log(voltage(i)) + b(3)*log(capacitance(i))); % [mg/mm^3]
    
    % Plot
    figure;
    scatter3(x1,x2,y,'filled')
    hold on
    % x1fit = min(x1):100:max(x1);
    % x2fit = min(x2):1E-8:max(x2);
    x1fit = logspace(log10(min(x1)),log10(max(x1)),2e1);
    x2fit = logspace(log10(min(x2)),log10(max(x2)),2e1);
    [X1FIT,X2FIT] = meshgrid(x1fit,x2fit);
    YFIT = exp(b(1) + b(2)*log(X1FIT) + b(3)*log(X2FIT));
%     mesh(X1FIT,X2FIT,YFIT)

    xticks(10.^(0:1:8))
    set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV','1 MV'});
%     yticks(10.^[-15:3:3])
%     set(gca,'yticklabel',{'1 fF','1 pF',' 1 nF','1 $\mu$F','1 mF','1 F','1 kF'})
    yticks(10.^[-12:1:0])
    set(gca,'yticklabel',{'1 pF','10 pF','100 pf','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F','100 $\mu$F','1 mF','10 mF','100 mF','1 F'})

    xlabel('Voltage [V]')
    ylabel('Capacitance [F]')
    zlabel('Density [mg/mm$^3$]')
    title(['Density vs Capacitance \& Voltage: ',id_Type])
    view(50,10)
    set(gca, 'YScale', 'log')
    set(gca, 'XScale', 'log')
    hold off

    k_plotscaling = 1.5; % Set relative size of plot fonts. Recommend 1.5 or 2.
    k_plotsize = 1.2;
    k_plot_w = 450;
    k_plot_h = 350;
    set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
    set(gcf,'PaperPositionMode','auto')
    movegui(gcf,'center')
    set_figure_style(k_plotscaling);


    %% Save figure
%     figure_folder = 'Pareto_Data';
%     figure_name = 'test';
%     figure_fullpath = fullfile(figure_folder,figure_name);
%     set(gcf,'Units','Inches');
%     pos = get(gcf,'Position');
%     set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
%     % print(gcf,figure_fullpath,'-dpdf','-r600')
%     % print(gcf,figure_fullpath,'-dpdf','-r0')
% %     print(gcf,figure_fullpath,'-dpng','-r600')
%     exportgraphics(gcf,[figure_fullpath,'.png'],'Resolution',600,'BackgroundColor','none'); % v2020b 
%     % saveas(gcf,figure_fullpath,'png')


end