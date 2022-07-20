%% mainCapacitorSurvey.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 11/15/19
%   Last Revision: 3/5/22
%
%   File Description:
%       This file plots capacitor survey data. Also can plot the
%       pareto-fronts of each data set.
%
%   TODO:
%       - Something is funky with C3 ceramics. There are only 14 "power"
%           type. Is this correct?
%       - Finish parsing the ceramic temp. characteristic codes.
%       - Remake all figures with new plotting functions.
%           - Comment new plotting functions. Perhaps convert to .m files.
%
%   Other m-files required: set_figure_style.m, func_ParseCapacitorPages.m,
%                           func_smoothConvHull.m, func_removeOutliers.m
%   Other files required: Relevant csv files, txt file containing outliers
%
%% Debug
% clear all
clear inputFilename
close all
clc


%% Plot Options
k_plotscaling = 1.5; % Set relative size of plot fonts. Recommend 1.5 or 2.
k_plotsize = 1.2;
plot_shape = 'square';
if(strcmp(plot_shape, 'square'))
    k_plot_w = 450;
    k_plot_h = 350;
elseif(strcmp(plot_shape, 'rect'))
    k_plot_w = 850;
    k_plot_h = 385;
end
colormap_MAT = get(groot,'DefaultAxesColorOrder'); % Get defualt plot colors
color0 = [0,0,0]; % black
color1 = colormap_MAT(2,:);
color2 = colormap_MAT(1,:);
color3 = colormap_MAT(4,:);


%% Import Data

% inputFilename_1 = 'AlumElec_11152019.csv';
% outputTable_1 = func_ParseCapacitorPages(fullfile('RawData',inputFilename_1));
% inputFilename_2 = 'AlumPoly_11082019.csv';
% outputTable_2 = func_ParseCapacitorPages(fullfile('RawData',inputFilename_2));
% inputFilename_3 = 'AlumHybrid_11152019.csv';
% outputTable_3 = func_ParseCapacitorPages(fullfile('RawData',inputFilename_3));
% 
% inputFilename_4 = 'AlumPoly_03282021.csv';
% % inputFilename_4 = 'C0GNP0_03222021.csv';
% outputTable_4 = func_ParseCapacitorPages(fullfile('RawData',inputFilename_4));

input_foldername = 'RawData_Digikey';

% Outlier txt file
outlierFilename = 'outlierCaps_03282021.txt';

tic

% Input filenames
inputFilename = ...
    {
... % Electrolytic
        'AlumElec_03282021.csv',...
        'AlumPoly_03282021.csv',...
        'AlumHybrid_03282021.csv',...
        'Tantalum_03282021.csv',...
        'TantalumPoly_03282021.csv',...
        'NbO_03282021.csv',...
... % Ceramic
        'Ceramic_20211111.csv',... % Class I non-power
        ...'C0GNP0_03222021.csv',...
        '',... % Class I power
        '',... % Class II non-power
        ...'MLCC_TDK_20210513.csv'; % This one can't be read normally since the data is from TDK
        '',... % Class II power
        ...'PowerCeramic_10142021.csv',...
        '',... % Class III non-power
        '',... % Class III power
... % Film
        'FilmPP_03282021.csv',...
        'FilmPET_03282021.csv',...
        'FilmPolyester_03282021.csv',...
        'FilmPEN_03282021.csv',...
        'FilmPPS_03282021.csv',...
        'FilmAcrylic_03282021.csv',...
        'FilmPaper_03282021.csv',...
        '',... % Film power
... % Other
        'Mica_03282021.csv',...
        'Silicon_03282021.csv',...
        'ThinFilm(Silicon)_03282021.csv',...
        'EDLC_03282021.csv'
    };


% Input types mapped to every filename. 
% In the current implementation, the "filename" array and "type" array need
% to match one-to-one.
input_types = ...
    {   
... % Electrolytic
        'Al Electrolytic - Wet',...
        'Al Electrolytic - Polymer',...
        'Al Electrolytic - Hybrid',...
        'Ta Electrolytic - Wet',...
        'Ta Electrolytic - Polymer',...
        'Nb Electrolytic - Polymer',...
... % Ceramic
        'Ceramic - Class I - LV',...
        'Ceramic - Class I - HV',...
        'Ceramic - Class II - LV',... % 'Ceramic - Class II - MLCC'
        'Ceramic - Class II - HV',...
        'Ceramic - Class III - LV',... % 'Ceramic - Class III - SLC'
        'Ceramic - Class III - HV',...
... % Film
        'Film - PP',...
        'Film - PET',...
        'Film - Polyester',... % Same as PET?
        'Film - PEN',...
        'Film - PPS',...
        'Film - Acrylic',...
        'Film - Paper',...
        'Film - HP',...
... % Other
        'Mica',...
        'Silicon',...
        'Silicon - Thin Film',...
        'Supercapacitors (EDLC)'
    };
    
% Import data from files and parse
if (~exist('dataTables','var'))
    dataTables = cell(length(inputFilename),1); % This MUST be a column vector for multi-plot functionality
    for j = 1:length(inputFilename)
%         disp(j)
%         if (~isempty(inputFilename{j}))
            disp(['Parsing data from file: ',inputFilename{j},' ...'])
    %         if j == 8  % Handle case for TDK's Class II MLCC's
    %         if strcmp(input_types{j},'Ceramic - Class II - MLCC')  
            if (~isempty(regexp(inputFilename{j},'TDK','once'))) % Handle case for TDK's Class II MLCC's
                dataTables{j} = readtable(fullfile('RawData_TDK',inputFilename{j}));
                % Add type (Temperature coefficient)
                dataTables{j} = addvars(dataTables{j}, dataTables{j}.TChar,'NewVariableNames','Type');
                % Remove outliers from table
                dataTables{j} = func_removeOutliers(fullfile(input_foldername,outlierFilename), dataTables{j});
            else % Digikey data
                dataTables{j} = func_ParseCapacitorPages(inputFilename{j},input_foldername);
                % Remove outliers from table
                dataTables{j} = func_removeOutliers(fullfile(input_foldername,outlierFilename), dataTables{j});

                % Handle case for Class I ceramics (makes later 3D plot look prettier)
                if strcmp(input_types{j},'Ceramic - Class I') 
                    dataTables{j} = sortrows(dataTables{j},{'Capacitance'},{'ascend'});
    %                 dataTables{j} = sortrows(dataTables{j},{'Voltage'},{'ascend'});
                end
                % Handle case for (wet) Aluminium Electrolytics (makes later 3D plot look prettier)
                if strcmp(input_types{j},'Al Electrolytic - Wet') 
    %                 dataTables{j} = sortrows(dataTables{j},{'Capacitance'},{'ascend'});
                    dataTables{j} = sortrows(dataTables{j},{'VoltageRatedDC'},{'ascend'});
                end
            end
%         else
%             x = 1;
%         end
    end
    disp('Parsing complete.')
    
    %% Reconfigure tantulum data
    
    disp(' ')
    disp('Reconfiguring data...')

    % Remove non-wet (polymer) sub-type tantalums from (wet) tantalum
    % data table and append to tantalum polymer data table.
    i1 = find(strcmp(input_types, 'Ta Electrolytic - Wet'));
    i2 = find(strcmp(input_types, 'Ta Electrolytic - Polymer'));
    i = strcmp(dataTables{i1}.Type,'TANT_POLY');
    dataTables{i2} = [dataTables{i2}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    
    % Remove 'wet' sub-type tantalums from polymer tantalum
    % data table and append to tantalum (wet) data table.
    i1 = find(strcmp(input_types, 'Ta Electrolytic - Polymer'));
    i2 = find(strcmp(input_types, 'Ta Electrolytic - Wet'));
    i = strcmp(dataTables{i1}.Type,'TANT_WET');
    dataTables{i2} = [dataTables{i2}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    
    
    %% Reconfigure ceramic data

    % In the case that all the ceramic capacitor data is stored in one
    % file, parse and reconfigure relevant data into smaller tables based
    % on type.
    i1 = find(strcmp(input_types, 'Ceramic - Class I - LV'));
    i2 = find(strcmp(input_types, 'Ceramic - Class I - HV'));
    i3 = find(strcmp(input_types, 'Ceramic - Class II - LV'));
    i4 = find(strcmp(input_types, 'Ceramic - Class II - HV'));
    i5 = find(strcmp(input_types, 'Ceramic - Class III - LV'));
    i6 = find(strcmp(input_types, 'Ceramic - Class III - HV'));
    
    % Parse out and move the power capacitors first
    % Class 1 power capacitors
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'POWER_C1'));
    dataTables{i2} = [dataTables{i2}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    % Class 2 power capacitors
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'POWER_C2'));
    dataTables{i4} = [dataTables{i4}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    % Class 3 power capacitors
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'POWER_C3'));
    dataTables{i6} = [dataTables{i6}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    
    % Parse out remaining non-"Class I LV" capacitors from total file
    % Class 2 LV capacitors
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'C2'));
    dataTables{i3} = [dataTables{i3}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    % Class 3 LV capacitors
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'C3'));
    dataTables{i5} = [dataTables{i5}; dataTables{i1}(i,:)]; % Add from first table to second
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    
    % Remove capacitors without a 'Class' completely
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'C1'));
    dataTables{i1} = dataTables{i1}(i,:); % Remove from first table
    i = ~cellfun(@isempty,regexpi(dataTables{i1}.Type,'NA'));
    dataTables{i1} = dataTables{i1}(~i,:); % Remove from first table
    
    disp('Data reconfigured.')
    
    %% Compute estimated variables
    disp(' ')
    disp('Computing estimated variables...')
    dataTables = func_ComputeMass(dataTables); % Compute mass
    dataTables = func_ComputeEnergyDC(dataTables); % Compute dc energy
    disp('Estimated variables computed.')

else
    % If data has already been imported, then only reapply outlier removal
    for j = 1:length(inputFilename)
        dataTables{j} = func_removeOutliers(fullfile(input_foldername,outlierFilename), dataTables{j});
    end

    clear structData
end
disp(' ')
disp('Done parsing data.')
toc


%% Assign appropriate imported data to variables

% TODO: Do this after creating and populating structure
structData.datafields = ...
    {   'voltage',...
        'capacitance',...
        'volume',...
        'unitCost',...
        'ESR',...
        'currLF',...
        'currHF',...
        'tech',...
        'types',...
        'package',...
        'mfr',...
        'mfrPartName',...
        'mass',...
        'energyDC',...
        'energyVolDensity',...
        'energyMassDensity',...
        'powerRated',...
        'powerDensity',...
        'DF_LF',...
        'DF_HF',...
        'Q_LF',...
        'Q_HF',...
        'faradDollar',...
        'costDensity'
    };


% Unit conversion
structData.units.voltage.varName = 'Rated DC Voltage';
structData.units.voltage.unitName = 'V';
structData.units.voltage.value = 1;

structData.units.capacitance.varName = 'Capacitance'; % At rated voltage?
structData.units.capacitance.unitName = 'F';
structData.units.capacitance.value = 1;

% What about the case of non-SI units?
structData.units.volume.varName = 'Volume';
structData.units.volume.unitName = 'mm$^3$';
structData.units.volume.value = 1e9; % Conversion from [m^3] to [mm^3]
% structData.units.volume.unitName = 'cm$^3$';
% structData.units.volume.value = 1e6; % Conversion from [m^3] to [cm^3]
% structData.units.volume.unitName = 'in$^3$';
% structData.units.volume.value = 61023.74; % Conversion from [m^3] to [in^3]

structData.units.unitCost.varName = 'Rated DC Voltage';
structData.units.unitCost.unitName = '\$';
structData.units.unitCost.value = 1;

structData.units.unitCost.varName = {'ESR', 'Frequency'};
structData.units.ESR.unitName = {'$\Omega$', 'Hz'};
structData.units.ESR.value = {1, 1};

% structData.units.currLF.varName = {'Rated RMS Current (LF)', 'Frequency'};
% structData.units.currLF.unitName = {'A', 'Hz'};
% structData.units.currLF.value = {1, 1};
structData.units.currLF.varName = 'Rated RMS Current (LF)';
structData.units.currLF.unitName = 'A';
structData.units.currLF.value = 1;

% structData.units.currHF.varName = {'Rated RMS Current (HF)', 'Frequency'};
% structData.units.currHF.unitName = {'A', 'Hz'};
% structData.units.currHF.value = {1, 1};
structData.units.currHF.varName = 'Rated RMS Current (HF)';
structData.units.currHF.unitName = 'A';
structData.units.currHF.value = 1;

structData.units.mass.varName = 'Mass';
structData.units.mass.unitName = 'mg';
structData.units.mass.value = 1e3; % Conversion from [g] to [mg]

structData.units.energyDC.varName = 'DC Energy';
% structData.units.energyDC.unitName = '$\mu$J';
% structData.units.energyDC.value = 1e6; % Conversion from [J] to [uJ]
structData.units.energyDC.unitName = 'J';
structData.units.energyDC.value = 1;

structData.units.energyVolDensity.varName = 'Volumetric Energy Density';
structData.units.energyVolDensity.unitName = '$\mu$J/mm$^3$';
% structData.units.energyVolDensity.value = 1e-9*1e3; % Conversion from [J/m^3] to [mJ/mm^3]
% structData.units.energyVolDensity.value = 1e-6*1e3; % Conversion from [J/m^3] to [mJ/cm^3]
structData.units.energyVolDensity.value = 1e-9*1e6; % Conversion from [J/m^3] to [uJ/mm^3]
% structData.units.energyVolDensity.value = structData.units.energyDC.value/structData.units.volume.value;

structData.units.energyMassDensity.varName = 'Gravimetric Energy Density';
structData.units.energyMassDensity.unitName = '$\mu$J/mg';
structData.units.energyMassDensity.value = 1e-3*1e6; % Conversion from [J/g] to [uJ/mg]

structData.units.powerRated.varName = 'Rated Power';
% structData.units.powerRated.unitName = 'mW';
% structData.units.powerRated.value = 1e3; % Conversion from [W] to [mW]
structData.units.powerRated.unitName = 'W';
structData.units.powerRated.value = 1;

% structData.units.powerDensity.varName = 'Rated Power Density';
structData.units.powerDensity.varName = 'Volumetric Power Density';
structData.units.powerDensity.unitName = 'mW/mm$^3$';
structData.units.powerDensity.value = 1e-9*1e3; % Conversion from [W/m^3] to [mW/mm^3]
% structData.units.powerDensity.value = structData.units.powerRated.value/structData.units.volume.value;

structData.units.costDensity.varName = 'Cost Density';
structData.units.costDensity.unitName = '\$/mm$^3$';
structData.units.costDensity.value = 1e-9; % Conversion from [$/m^3] to [$/mm^3]

% b.varName = 'Cost Density';
% b.unitName = '\$/mm$^3$';
% b.value = 1e-9; % Conversion from [$/m^3] to [$/mm^3]
% structData.units = setfield(structData.units,structData.datafields{23},b)


% Assign data
disp(' '); % Line break
disp('Assigning data to MATLAB variables...')

% Pre-allocate loopvariables
temp = structData.datafields; temp{2,1} = 0; % [structData.datafields; cell(size(structData.datafields))]
structData.data = struct(temp{:});
for ii = 1:length(structData.datafields)
    structData.data = setfield(structData.data, structData.datafields{ii}, cell(size(dataTables)));
end

for j = 1:length(inputFilename)
%     disp(j)
     if (~isempty(regexp(inputFilename{j},'TDK','once')))  % Handle case for TDK's Class II MLCC's
%             structData.data.voltage{j} = dataTables{j}.VoltageRatedDC; % Rated voltage
        structData.data.voltage{j} = dataTables{j}.Vr; % Max voltage on C(v) curve
        % Volumetric energy density
        structData.data.energyVolDensity{j} = dataTables{j}.EnergyDensity; % dc energy density at rated voltage
        structData.data.capacitance{j} = dataTables{j}.Cr; % Capacitance at rated voltage on C(v) curve
        structData.data.volume{j} = dataTables{j}.Volume;
        structData.data.DF_LF{j} = nan(height(dataTables{j}),1);
        structData.data.faradDollar{j} = nan(height(dataTables{j}),1);
        structData.data.unitCost{j} = nan(height(dataTables{j}),1);
        structData.data.costDensity{j} = nan(height(dataTables{j}),1);
     else
        %% Parsed variables
        structData.data.voltage{j} = dataTables{j}.VoltageRatedDC; % [V]
        structData.data.capacitance{j} = dataTables{j}.Capacitance; % [F]
        structData.data.volume{j} = dataTables{j}.Volume; % [m^3]
        structData.data.unitCost{j} = dataTables{j}.UnitCost; % [$]
        structData.data.ESR{j} = dataTables{j}.ESR; % ([Ohms],[Hz])
        % Maximum rms current at high frequency
        structData.data.currHF{j} = dataTables{j}.CurrentRatedHF; % ([A],[Hz[)
        % Maximum rms current at low frequency (120 Hz)
        structData.data.currLF{j} = dataTables{j}.CurrentRatedLF; % ([A],[Hz])
        
        %% Estimated variables
        structData.data.mass{j} = dataTables{j}.mass; % [g]
        structData.data.energyDC{j} = dataTables{j}.energyDC; % [J]
        
        %% Computed variables

        % Volumetric energy density (W/Vol)
%         structData.data.energyVolDensity{j} = dataTables{j}.EnergyDensity*structData.units.value.energyVolDensity; % Convert units
        structData.data.energyVolDensity{j} = structData.data.energyDC{j}./structData.data.volume{j}; % [J/m^3]

        % Gravimetric energy density (W/m)
        structData.data.energyMassDensity{j} = structData.data.energyDC{j}./structData.data.mass{j}; % [J/g^3]
        
        % Rated power (Vr*Ir)
        structData.data.powerRated{j} = structData.data.voltage{j}.*structData.data.currLF{j}(:,1); % [W]

        % Power density (Vr*Ir/Vol)
%         structData.data.powerDensity{j} = structData.data.voltage{j}.*structData.data.currLF{j}(:,1)./structData.data.volume{j}; % [W/m^3]
        structData.data.powerDensity{j} = structData.data.powerRated{j}./structData.data.volume{j}; % [W/m^3]

        % Dissipation factor (C*ESR)
%         structData.data.DF_LF{j} = dataTables{j}.tanD.*(dataTables{j}.ESR(:,2)<=120); % [s]
        structData.data.DF_LF{j} = (2*pi*structData.data.ESR{j}(:,2)).*(structData.data.ESR{j}(:,1).*structData.data.capacitance{j}); % tanD = 2*pi*f*ESR*C []
        structData.data.DF_LF{j} = (structData.data.ESR{j}(:,2)<=120).*structData.data.DF_LF{j};
        structData.data.Q_LF{j} = 1./structData.data.DF_LF{j};
%         structData.data.DF_HF{j} = dataTables{j}.tanD.*(dataTables{j}.ESR(:,2)==100e3);
        structData.data.DF_HF{j} = (2*pi*structData.data.ESR{j}(:,2)).*(structData.data.ESR{j}(:,1).*structData.data.capacitance{j}); % tanD = 2*pi*f*ESR*C []
        structData.data.DF_HF{j} = (structData.data.ESR{j}(:,2)>500).*structData.data.DF_HF{j};
        structData.data.Q_HF{j} = 1./structData.data.DF_HF{j};

        % Farad/cost (C/Cost)
%         structData.data.faradDollar{j} = dataTables{j}.FaradDollar;
        structData.data.faradDollar{j} = structData.data.capacitance{j}./structData.data.unitCost{j}; % [F/$]

        % Cost density (Cost/Vol)
%         structData.data.costDensity{j} = dataTables{j}.UnitCost./dataTables{j}.Volume; % Convert units
        structData.data.costDensity{j} = structData.data.unitCost{j}./structData.data.volume{j}; % [$/m^3]
        
    end
   
    % Capacitor package (currently only useful for SMD components)
    structData.data.package{j} = dataTables{j}.Package;
    
    % Capacitor technology
    structData.data.tech{j} = input_types{j}; % Custom type labels

    % Capacitor type
    structData.data.types{j} = dataTables{j}.Type;
    
    % Capacitor manufacturer
    structData.data.mfr{j} = dataTables{j}.Manufacturer;
    
    % Manufacturer part name
    structData.data.mfrPartName{j} = dataTables{j}.MfrPartName;

    % Perform unit conversions
    % TODO: Can loop this over all data fields
    structData.data.volume{j} = structData.data.volume{j}*structData.units.volume.value; % Conversion from [m^3] to [mm^3]
    structData.data.energyDC{j} = structData.data.energyDC{j}*structData.units.energyDC.value; % Conversion from [W] to [mW]
    structData.data.energyVolDensity{j} = structData.data.energyVolDensity{j}*structData.units.energyVolDensity.value; % Conversion from [J/m^3] to [uJ/mm^3]
    structData.data.energyMassDensity{j} = structData.data.energyMassDensity{j}*structData.units.energyMassDensity.value; % Conversion from [J/g^3] to [uJ/mg^3]
    structData.data.powerRated{j} = structData.data.powerRated{j}*structData.units.powerRated.value; % Conversion from [W] to [mW]
    structData.data.powerDensity{j} = structData.data.powerDensity{j}*structData.units.powerDensity.value; % Conversion from [W/m^3] to [mW/mm^3]
    structData.data.costDensity{j} = structData.data.costDensity{j}*structData.units.costDensity.value; % Conversion from [$/m^3] to [$/mm^3]

end
disp('Done assigning data.')
toc

% Debugging
% structData2(1).data.voltage = structData.data.voltage{1}
% structData2(2).data.voltage = structData.data.voltage{2}
% structData2{1}.data.voltage = structData.data.voltage{1}
% structData2{2}.data.voltage = structData.data.voltage{2}


%% Plot everything - Voltage vs Energy Density
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Construct pareto-fronts based on data to be plotted
straightHull = cell(size(dataTables));
smoothHull = cell(size(dataTables));
structPlot.x_plot = cell(size(dataTables));
structPlot.y_plot = cell(size(dataTables));
structPlot.smoothHull = cell(size(dataTables));
for j = 1:length(dataTables)
    structPlot.x_plot{j} = structData.data.voltage{j};
    structPlot.y_plot{j} = structData.data.energyVolDensity{j};
    [~, ~, smoothHull_i] = func_smoothConvHull([structPlot.x_plot{j},structPlot.y_plot{j}], 'whole', 'log');
    structPlot.smoothHull{j} = smoothHull_i;
end

% Plot curves
for j = 1:length(dataTables)
    if (j <= size(colormap_MAT,1))
        linestyle = '-';
    elseif (j <= 2*size(colormap_MAT,1))
        linestyle = '--';
    else
        linestyle = '-.';
    end
    smoothHull_plot = structPlot.smoothHull{j};
    plot(smoothHull_plot(:,1),smoothHull_plot(:,2),'LineStyle',linestyle,'LineWidth',2)
end

xlim([5e-1 2E5])
ylim([2E-4 5E9]*structData.units.energyVolDensity.value)
xticks(10.^(0:1:5))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV'})
yticks(10.^(-15:3:15))

xlabel('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
legend({char(structData.data.tech)},'Location','bestoutside');
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*(k_plot_w+200) k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot everything - Voltage vs CV Density
% figure;
% hold on;
% clear x_plot y_plot smoothHull_plot % Clear plot variables
% 
% % Unit conversion
% units_temp = 1e6; % Conversion from [C/mm^3] to [uC/mm^3]
% 
% % Construct pareto-fronts based on data to be plotted
% straightHull = cell(size(dataTables));
% smoothHull = cell(size(dataTables));
% for j = 1:length(dataTables)
%     x_plot{j} = structData.data.voltage{j};
%     y_plot{j} = structData.data.capacitance{j}.*structData.data.voltage{j}./structData.data.volume{j}*units_temp; 
%     [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
%     smoothHull{j} = smoothHull_i;
% end
% 
% % Plot curves
% for j = 1:length(dataTables)
%     if (j <= size(colormap_MAT,1))
%         linestyle = '-';
%     elseif (j <= 2*size(colormap_MAT,1))
%         linestyle = '--';
%     else
%         linestyle = '-.';
%     end
%     smoothHull_plot = smoothHull{j};
%     plot(smoothHull_plot(:,1),smoothHull_plot(:,2),'LineStyle',linestyle,'LineWidth',2)
% end
% 
% xlim([5e-1 2E5])
% ylim([2E-15 5E0]*units_temp)
% xticks(10.^(0:1:5))
% set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV'})
% yticks(10.^[-15:3:15])
% 
% xlabel('DC Voltage [V]')
% ylabel('CV Density [$\mu$C/mm$^3$]')
% legend({char(structData.data.tech)},'Location','bestoutside');
% % set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% 
% set(gcf, 'Position', [1000 500 k_plotsize*(k_plot_w+200) k_plotsize*k_plot_h]) % set figure size and position
% set(gcf,'PaperPositionMode','auto')
% movegui(gcf,'center')
% set_figure_style(k_plotscaling);
% 
% 
%% Plot everything - Voltage vs Capacitive Density
% figure;
% hold on;
% clear x_plot y_plot smoothHull_plot % Clear plot variables
% 
% % Unit conversion
% units_temp = 1e6; % Conversion from [F/mm^3] to [uF/mm^3]
% 
% % Construct pareto-fronts based on data to be plotted
% straightHull = cell(size(dataTables));
% smoothHull = cell(size(dataTables));
% for j = 1:length(dataTables)
%     x_plot{j} = structData.data.voltage{j};
%     y_plot{j} = structData.data.capacitance{j}./structData.data.volume{j}*units_temp;
%     [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
%     smoothHull{j} = smoothHull_i;
% end
% 
% % Plot curves
% for j = 1:length(dataTables)
%     if (j <= size(colormap_MAT,1))
%         linestyle = '-';
%     elseif (j <= 2*size(colormap_MAT,1))
%         linestyle = '--';
%     else
%         linestyle = '-.';
%     end
%     smoothHull_plot = smoothHull{j};
%     plot(smoothHull_plot(:,1),smoothHull_plot(:,2),'LineStyle',linestyle,'LineWidth',2)
% end
% 
% xlim([5e-1 2E5])
% ylim([1e-17 1e0]*units_temp)
% xticks(10.^(0:1:5))
% set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV'})
% yticks(10.^[-15:3:15])
% 
% xlabel('DC Voltage [V]')
% ylabel('Capacitance Density [$\mu$F/mm$^3$]')
% legend({char(structData.data.tech)},'Location','bestoutside');
% % set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% 
% set(gcf, 'Position', [1000 500 k_plotsize*(k_plot_w+200) k_plotsize*k_plot_h]) % set figure size and position
% set(gcf,'PaperPositionMode','auto')
% movegui(gcf,'center')
% set_figure_style(k_plotscaling);
% 

%% Plot single - Voltage vs Energy Density
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.energyVolDensity;
% k = 9; % Pick something to plot
k = 1;
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, i_hull, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'top', 'log');
%     [smoothHull_i, i_hull, ~] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Display components of data table which belong to pareto-front
% disp(['Pareto-front of ', inputFilename{k}, ':'])
% disp(dataTables{k}(i_hull,:))
% Write table to file
% writetable(dataTables{k}(i_hull,:),'Pareto_Data/ClassII_pareto.csv');

% Plot curves
plot(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),'color',color0,'LineStyle','-','LineWidth',2)
set(gca,'ColorOrderIndex',1)
plot(x_plot{1},y_plot{1},'.', 'MarkerSize',5)

% Include Enphase capacitor (UVZ1H332MHD)
plot(50,438,'x','Color',[1 0 0],'MarkerSize',10,'LineWidth',2);

xlim([1 2E3])
% xlim([0.5E3 2E5]) % Power capacitors
% ylim([2E-4 5E9]*structData.units.energyVolDensity.value) % All
ylim([2E2 5E6]*structData.units.energyVolDensity.value) % Alum Elec (Wet)
% xlim([-inf inf]); ylim([-inf inf])
xticks(10.^(0:1:8))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV','1 MV'})
yticks(10.^(-15:1:15))

xlabel ('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
% legend({'Aluminum Electrolytic'},'Location','Best');
title(input_types{k})
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot single - Voltage vs Power Density
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.powerDensity;
% k = 9; % Pick something to plot
k = 1;
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, i_hull, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'top', 'log');
%     [smoothHull_i, i_hull, ~] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Display components of data table which belong to pareto-front
disp(['Pareto-front of ', inputFilename{k}, ':'])
disp(dataTables{k}(i_hull,:))
% Write table to file
% writetable(dataTables{k}(i_hull,:),'Pareto_Data/ClassII_pareto.csv');

% Plot curves
plot(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),'color',color0,'LineStyle','-','LineWidth',2)
set(gca,'ColorOrderIndex',1)
plot(x_plot{1},y_plot{1},'.', 'MarkerSize',5)

% Include Enphase capacitor (UVZ1H332MHD)
% temp_i = find(~cellfun(@isempty, regexp(dataTables{1}.MfrPartName,'UVZ1H332MHD')));
temp_PrDensity = 50*1.77/(pi*(18e-3/2)^2*37e-3)*structData.units.powerDensity.value; % = 9.3995 [mW/mm^3]
plot(50,temp_PrDensity,'x','Color',[1 0 0],'MarkerSize',10,'LineWidth',2);

xlim([1 2E3])
% xlim([0.5E3 2E5]) % Power capacitors
ylim([5E4 5E8]*structData.units.powerDensity.value)
% xlim([-inf inf]); ylim([-inf inf])
xticks(10.^(0:1:8))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV','1 MV'})
yticks(10.^(-15:1:15))

xlabel ('DC Voltage [V]')
ylabel ('Power Density (at 120 Hz) [mW/mm$^3$]')
% legend({'Aluminum Electrolytic'},'Location','Best');
title(input_types{k})
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot single - Voltage vs tanD (at 120 Hz)
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.DF_LF;
y2_plot_data = structData.data.DF_HF;
k = 1; % Pick something to plot
% k = 1:3;
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
y2_plot{1} = vertcat(y2_plot_data{k});
k = 2;
x_plot{2} = vertcat(x_plot_data{k});
y_plot{2} = vertcat(y_plot_data{k});
y2_plot{2} = vertcat(y2_plot_data{k});
k = 3;
x_plot{3} = vertcat(x_plot_data{k});
y_plot{3} = vertcat(y_plot_data{k});
y2_plot{3} = vertcat(y2_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, i_hull, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
%     [smoothHull_i, i_hull, ~] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end
Nplot = length(x_plot);
smoothHull2_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, i2_hull, smoothHull2_i] = func_smoothConvHull([x_plot{j},y2_plot{j}], 'whole', 'log');
%     [smoothHull_i, i_hull, ~] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull2_plot{j} = smoothHull2_i;
end

% % Display components of data table which belong to pareto-front
% disp(['Pareto-front of ', inputFilename{k}, ':'])
% disp(dataTables{k}(i_hull,:))
% % Write table to file
% % writetable(dataTables{k}(i_hull,:),'Pareto_Data/ClassII_pareto.csv');

% Plot curves
% plot(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),'color',color0,'LineStyle','-','LineWidth',2)
plot(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),'LineStyle','-','LineWidth',2)
plot(smoothHull2_plot{1}(:,1),smoothHull2_plot{1}(:,2),'LineStyle','-','LineWidth',2)
plot(smoothHull2_plot{2}(:,1),smoothHull2_plot{2}(:,2),'LineStyle','-','LineWidth',2)
plot(smoothHull2_plot{3}(:,1),smoothHull2_plot{3}(:,2),'LineStyle','-','LineWidth',2)
set(gca,'ColorOrderIndex',1)
plot(x_plot{1},y_plot{1},'.', 'MarkerSize',5)
plot(x_plot{1},y2_plot{1},'.', 'MarkerSize',5)
plot(x_plot{2},y2_plot{2},'.', 'MarkerSize',5)
plot(x_plot{3},y2_plot{3},'.', 'MarkerSize',5)

% Curve fit
x_plot_fit = logspace(0,3,1e1);
y_plot_fit = x_plot_fit.^(-0.5);
plot(x_plot_fit,y_plot_fit*2e-3,'color',color0,'LineStyle','--','LineWidth',2)

% xlim([1 2E3])
% xlim([0.5E3 2E5]) % Power capacitors
% ylim([2E-4 5E9]*structData.units.energyVolDensity.value)
xlim([-inf inf]); % ylim([-inf inf]);
ylim([1e-7 1e0]);
xticks(10.^(0:1:8))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV','1 MV'})
yticks(10.^(-15:1:15))

xlabel ('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
% ylabel('tan $\delta$ [ ]')
ylabel('ESR $\cdot$ $C$ [s]')
% ylabel('$Q$ (at $f=120$~Hz) [ ]')
% legend({'Aluminum Electrolytic'},'Location','Best');
% legend({'$f=120$ Hz','$f=100$ kHz'},'Location','Best');
legend({'Alum Wet ($f=120$ Hz)','Alum Wet ($f=100$ kHz)','Alum Poly ($f=100$ kHz)', 'Alum Hybrid ($f=100$ kHz)'},'Location','Best');
% title(input_types{k})
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Capacitance vs Energy Density
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.capacitance;
y_plot_data = structData.data.energyVolDensity;
k = 1:3; % Aluminum electrolytics
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
k = 4:5; % Tantalum electrolytics
x_plot{2} = vertcat(x_plot_data{k});
y_plot{2} = vertcat(y_plot_data{k});
k = 7:8; % Class I ceramic
x_plot{3} = vertcat(x_plot_data{k});
y_plot{3} = vertcat(y_plot_data{k});
k = 9:10; % Class II ceramic
% k = 9:12; % Class II & III ceramic
x_plot{4} = vertcat(x_plot_data{k});
y_plot{4} = vertcat(y_plot_data{k});
k = 11:12; % Class III ceramic
x_plot{5} = vertcat(x_plot_data{k});
y_plot{5} = vertcat(y_plot_data{k});
k = 13:20; % Film
x_plot{6} = vertcat(x_plot_data{k});
y_plot{6} = vertcat(y_plot_data{k});
k = 24; % EDLC
x_plot{7} = vertcat(x_plot_data{k});
y_plot{7} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Plot curves
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
end
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','Color',linecolor_plot,'LineWidth',2)
end

xlim([2e-14 8e4]); ylim([2E-4 5E9]*structData.units.energyVolDensity.value)

% xticks(10.^[-13:1:0])
% set(gca,'xticklabel',{'100 fF','1 pF',' 10 pF','100 pF','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F'})
xticks(10.^(-15:3:3))
set(gca,'xticklabel',{'1 fF','1 pF','1 nF','1 $\mu$F','1 mF','1 F','1 kF'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Ceramic - Power','Film','EDLC'},'Location','Best');

xlabel ('Capacitance [F]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
% legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% title('Ceramic - Class I (C0G/NP0)')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Capacitance vs Volume
% figure;
% hold on;
% clear x_plot y_plot smoothHull_plot % Clear plot variables
% 
% % Set data to plot
% x_plot_data = structData.data.capacitance;
% y_plot_data = structData.data.volume;
% k = 1:3; % Aluminum electrolytics
% x_plot{1} = vertcat(x_plot_data{k});
% y_plot{1} = vertcat(y_plot_data{k});
% k = 4:5; % Tantalum electrolytics
% x_plot{2} = vertcat(x_plot_data{k});
% y_plot{2} = vertcat(y_plot_data{k});
% k = 7:8; % Class I ceramic
% x_plot{3} = vertcat(x_plot_data{k});
% y_plot{3} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
% % k = 9:12; % Class II & III ceramic
% x_plot{4} = vertcat(x_plot_data{k});
% y_plot{4} = vertcat(y_plot_data{k});
% k = 11:12; % Class III ceramic
% x_plot{5} = vertcat(x_plot_data{k});
% y_plot{5} = vertcat(y_plot_data{k});
% k = 13:20; % Film
% x_plot{6} = vertcat(x_plot_data{k});
% y_plot{6} = vertcat(y_plot_data{k});
% k = 24; % EDLC
% x_plot{7} = vertcat(x_plot_data{k});
% y_plot{7} = vertcat(y_plot_data{k});
% 
% % Construct pareto-fronts based on data to be plotted
% Nplot = length(x_plot);
% smoothHull_plot = cell(1,Nplot);
% for j = 1:Nplot
%     [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
%     smoothHull_plot{j} = smoothHull_i;
% end
% 
% % Plot curves
% set(gca,'ColorOrderIndex',1)
% for j = 1:Nplot
%     linecolor_plot = colormap_MAT(j,:);
%     plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
% end
% set(gca,'ColorOrderIndex',1)
% for j = 1:Nplot
%     linecolor_plot = colormap_MAT(j,:);
%     plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','Color',linecolor_plot,'LineWidth',2)
% end
% 
% xlim([2e-14 8e4]); ylim([2E-13 5E0]*structData.units.volume.value)
% 
% % xticks(10.^[-13:1:0])
% % set(gca,'xticklabel',{'100 fF','1 pF',' 10 pF','100 pF','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F'})
% xticks(10.^[-15:3:3])
% set(gca,'xticklabel',{'1 fF','1 pF','1 nF','1 $\mu$F','1 mF','1 F','1 kF'})
% yticks(10.^[-15:3:15])
% 
% % Configure legend
% h = gobjects(1,Nplot); 
% for j = 1:length(h)
%     linecolor_plot = colormap_MAT(j,:);
%     h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
% end
% legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Power','Film','EDLC'},'Location','Best');
% 
% xlabel ('Capacitance [F]')
% ylabel ('Volume [mm$^3$]')
% % legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% % title('Ceramic - Class I (C0G/NP0)')
% % set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% 
% set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
% set(gcf,'PaperPositionMode','auto')
% movegui(gcf,'center')
% set_figure_style(k_plotscaling);


%% Plot multiple - Capacitance vs Voltage
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.capacitance;
y_plot_data = structData.data.voltage;
k = 1:3; % Aluminum electrolytics
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
k = 4:5; % Tantalum electrolytics
x_plot{2} = vertcat(x_plot_data{k});
y_plot{2} = vertcat(y_plot_data{k});
k = 7; % Class I ceramic
x_plot{3} = vertcat(x_plot_data{k});
y_plot{3} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
% k = 11:12; % Class III ceramic
k = 9:12; % Class II & III ceramic
x_plot{4} = vertcat(x_plot_data{k});
y_plot{4} = vertcat(y_plot_data{k});
k = 13:20; % Film
x_plot{5} = vertcat(x_plot_data{k});
y_plot{5} = vertcat(y_plot_data{k});
k = 24; % EDLC
x_plot{6} = vertcat(x_plot_data{k});
y_plot{6} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Plot curves
% set(gca,'ColorOrderIndex',1)
% for j = 1:Nplot
%     linecolor_plot = colormap_MAT(j,:);
%     plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
% end
% set(gca,'ColorOrderIndex',1)
% for j = 1:Nplot
%     linecolor_plot = colormap_MAT(j,:);
%     plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','Color',linecolor_plot,'LineWidth',2)
% end
% Filled pareto-fronts
for j = 1:Nplot
    fillcolor_plot = colormap_MAT(j,:);
%     fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),fillcolor_plot)
    fill(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),fillcolor_plot,'FaceAlpha',0.5,'EdgeColor',fillcolor_plot,'LineStyle','-','LineWidth',2);
end
% Debugging
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor','none'); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor',colormap_MAT(1,:),'LineStyle','-','LineWidth',2); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');

xlim([1e-14 1e5]);
ylim([0.5e0 1e5]); 

% xticks(10.^(-13:1:0))
% set(gca,'xticklabel',{'100 fF','1 pF',' 10 pF','100 pF','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F'})
xticks(10.^(-15:3:3))
set(gca,'xticklabel',{'1 fF','1 pF','1 nF','1 $\mu$F','1 mF','1 F','1 kF'})
yticks(10.^(0:1:6))
set(gca,'yticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV'})

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Film','EDLC'},'Location','Best');

xlabel ('Capacitance [F]')
ylabel ('Voltage [V]')
% legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% title('Ceramic - Class I (C0G/NP0)')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Voltage vs Energy Density (Volume or Mass)
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.energyVolDensity;
% y_plot_data = structData.data.energyMassDensity;

% k = 1:3; % Aluminum electrolytics
% x_plot{1} = vertcat(x_plot_data{k});
% y_plot{1} = vertcat(y_plot_data{k});
% k = 4:5; % Tantalum electrolytics
% x_plot{2} = vertcat(x_plot_data{k});
% y_plot{2} = vertcat(y_plot_data{k});
% k = 7:8; % Class I ceramic
% x_plot{3} = vertcat(x_plot_data{k});
% y_plot{3} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
% % k = 9:12; % Class II & III ceramic
% x_plot{4} = vertcat(x_plot_data{k});
% y_plot{4} = vertcat(y_plot_data{k});
% k = 11:12; % Class III ceramic
% x_plot{5} = vertcat(x_plot_data{k});
% y_plot{5} = vertcat(y_plot_data{k});
% k = 13:20; % Film
% x_plot{6} = vertcat(x_plot_data{k});
% y_plot{6} = vertcat(y_plot_data{k});
% k = 24; % EDLC
% x_plot{7} = vertcat(x_plot_data{k});
% y_plot{7} = vertcat(y_plot_data{k});

% k = 7; % Class I ceramic
% x_plot{1} = vertcat(x_plot_data{k});
% y_plot{1} = vertcat(y_plot_data{k});
% k = 8; % Class I ceramic (power)
% x_plot{2} = vertcat(x_plot_data{k});
% y_plot{2} = vertcat(y_plot_data{k});
% k = 9; % Class II ceramic
% x_plot{3} = vertcat(x_plot_data{k});
% y_plot{3} = vertcat(y_plot_data{k});
% k = 10; % Class II ceramic (power)
% x_plot{4} = vertcat(x_plot_data{k});
% y_plot{4} = vertcat(y_plot_data{k});
% k = 11; % Class III ceramic
% x_plot{3} = vertcat(x_plot_data{k});
% y_plot{3} = vertcat(y_plot_data{k});
% k = 12; % Class III ceramic (power)
% x_plot{4} = vertcat(x_plot_data{k});
% y_plot{4} = vertcat(y_plot_data{k});

k = 7:8; % Class I ceramic
x_plot{1} = vertcat(x_plot_data{k})*0.98;
y_plot{1} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
k = 9:12; % Class II & III ceramic
x_plot{2} = vertcat(x_plot_data{k})*1.0;
y_plot{2} = vertcat(y_plot_data{k});
k = 1; % Aluminum electrolytic (wet)
% k = 1:3; % Aluminum electrolytic (all)
x_plot{3} = vertcat(x_plot_data{k})*1.02;
y_plot{3} = vertcat(y_plot_data{k});
k = 13:20; % Film
x_plot{4} = vertcat(x_plot_data{k})*1.04;
y_plot{4} = vertcat(y_plot_data{k});
% k = 4:5; % Tantalum electrolytics
% x_plot{4} = vertcat(x_plot_data{k})*1.04;
% y_plot{4} = vertcat(y_plot_data{k});
% k = 11:12; % Class III ceramic
% x_plot{3} = vertcat(x_plot_data{k})*1.02;
% y_plot{3} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Plot curves
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
end
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','Color',linecolor_plot,'LineWidth',2)
end
% Filled pareto-fronts
% for j = 1:Nplot
%     fillcolor_plot = colormap_MAT(j,:);
% %     fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),fillcolor_plot)
%     fill(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),fillcolor_plot,'FaceAlpha',0.5,'EdgeColor',fillcolor_plot,'LineStyle','-','LineWidth',2);
% end
% Debugging
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor','none'); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor',colormap_MAT(1,:),'LineStyle','-','LineWidth',2); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');

xlim([5e-1 2E5])
ylim([2E-4 5E8]*structData.units.energyVolDensity.value)
% ylim(1e-6*[2E-4 5E8]*structData.units.energyMassDensity.value)
% xlim([-inf inf]); ylim([-inf inf])
xticks(10.^(0:1:8))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV','1 MV'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
% legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Ceramic - Power','Film','EDLC'},'Location','Best');
% legend(h,{'Class I LV','Class I (power)','Class II LV','Class II (power)'},'Location','Best');
% legend(h,{'Class I','Class II','Class III'},'Location','Best');
% legend(h,{'Class I','Class II','Alum Elec'},'Location','Best');
% legend(h,{'Class I','Class II','Alum Elec','Tantalum'},'Location','Best');
legend(h,{'Class I','Class II','Alum Elec','Film'},'Location','Best');

xlabel ('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Volumetric Energy Density [$\mu$J/mm$^3$]')
% ylabel('Gravimetric Energy Density [$\mu$J/mg]')
% legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% title('Ceramic - Class I (C0G/NP0)')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);

%% Plot multiple - Capacitance vs Energy Density (Volume or Mass)
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.capacitance;
% y_plot_data = structData.data.energyVolDensity;
y_plot_data = structData.data.energyMassDensity;

k = 7:8; % Class I ceramic
x_plot{1} = vertcat(x_plot_data{k})*0.98;
y_plot{1} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
k = 9:12; % Class II & III ceramic
x_plot{2} = vertcat(x_plot_data{k})*1.0;
y_plot{2} = vertcat(y_plot_data{k});
k = 1; % Aluminum electrolytic (wet)
x_plot{3} = vertcat(x_plot_data{k})*1.02;
y_plot{3} = vertcat(y_plot_data{k});
% k = 11:12; % Class III ceramic
% x_plot{3} = vertcat(x_plot_data{k})*1.02;
% y_plot{3} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Plot curves
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
end
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','Color',linecolor_plot,'LineWidth',2)
end
% Filled pareto-fronts
% for j = 1:Nplot
%     fillcolor_plot = colormap_MAT(j,:);
% %     fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),fillcolor_plot)
%     fill(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),fillcolor_plot,'FaceAlpha',0.5,'EdgeColor',fillcolor_plot,'LineStyle','-','LineWidth',2);
% end
% Debugging
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor','none'); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor',colormap_MAT(1,:),'LineStyle','-','LineWidth',2); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');

xlim([2e-15 8e1]);
% ylim([2E-4 5E8]*structData.units.energyVolDensity.value)
ylim(1e-6*[2E-4 5E8]*structData.units.energyMassDensity.value)
% xlim([-inf inf]); ylim([-inf inf])
xticks(10.^(-15:3:3))
set(gca,'xticklabel',{'1 fF','1 pF','1 nF','1 $\mu$F','1 mF','1 F','1 kF'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
% legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Ceramic - Power','Film','EDLC'},'Location','Best');
% legend(h,{'Class I LV','Class I (power)','Class II LV','Class II (power)'},'Location','Best');
% legend(h,{'Class I','Class II','Class III'},'Location','Best');
legend(h,{'Class I','Class II','Alum Elec'},'Location','Best');

xlabel ('Capacitance [F]')
% ylabel('Energy Density [mJ/mm$^3$]')
% ylabel('Volumetric Energy Density [$\mu$J/mm$^3$]')
ylabel('Gravimetric Energy Density [$\mu$J/mg]')
% legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% title('Ceramic - Class I (C0G/NP0)')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Capacitance/Cost vs Voltage
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.faradDollar;
k = 1:3; % Aluminum electrolytics
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
k = 4:5; % Tantalum electrolytics
x_plot{2} = vertcat(x_plot_data{k});
y_plot{2} = vertcat(y_plot_data{k});
k = 7:8; % Class I ceramic
x_plot{3} = vertcat(x_plot_data{k});
y_plot{3} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
k = 9:12; % Class II & III ceramic
x_plot{4} = vertcat(x_plot_data{k});
y_plot{4} = vertcat(y_plot_data{k});
k = 13:20; % Film
x_plot{5} = vertcat(x_plot_data{k});
y_plot{5} = vertcat(y_plot_data{k});
k = 24; % EDLC
x_plot{6} = vertcat(x_plot_data{k});
y_plot{6} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Plot curves
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
end
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'Color',linecolor_plot,'LineStyle','-','LineWidth',2)
end
% Filled pareto-fronts
% for j = 1:Nplot
%     fillcolor_plot = colormap_MAT(j,:);
% %     fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),fillcolor_plot)
%     fill(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),fillcolor_plot,'FaceAlpha',0.5,'EdgeColor',fillcolor_plot,'LineStyle','-','LineWidth',2);
% end
% Debugging
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor','none'); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');
% fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor',colormap_MAT(1,:),'LineStyle','-','LineWidth',2); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');

% Curve fit
x_plot_fit = logspace(0,5,1e1);
y_plot_fit = x_plot_fit.^(-3);
plot(x_plot_fit,y_plot_fit*1e5,'color',color0,'LineStyle','--','LineWidth',2)

xlim([1e0 1e5]);
ylim([1e-15 1e4]);

% xticks(10.^[-13:1:0])
% set(gca,'xticklabel',{'100 fF','1 pF',' 10 pF','100 pF','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F'})
xticks(10.^(0:1:6))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV','100 kV'})

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
% legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Power','Film','EDLC'},'Location','Best');
% legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Power','Film','EDLC'},'Location','Best');
legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Film','EDLC'},'Location','Best');

xlabel ('Voltage [V]')
ylabel ('Capacitance/Cost [F/\$]')
% legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% title('Ceramic - Class I (C0G/NP0)')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Voltage vs Energy Density
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.energyVolDensity;
k = 1; % Aluminum electrolytic (wet)
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
k = 2; % Aluminum electrolytic (polymer)
x_plot{2} = vertcat(x_plot_data{k});
y_plot{2} = vertcat(y_plot_data{k});
k = 3; % Aluminum electrolytic (hybrid)
x_plot{3} = vertcat(x_plot_data{k});
y_plot{3} = vertcat(y_plot_data{k});

Nplot = length(x_plot);
plot(x_plot{1}*1.02,y_plot{1},'.', 'MarkerSize',5)
plot(x_plot{2}*1.00,y_plot{2},'.', 'MarkerSize',5)
plot(x_plot{3}*0.98,y_plot{3},'.', 'MarkerSize',5)

% Include Enphase capacitor (UVZ1H332MHD)
plot(50*1.02,438,'x','Color',[1 0 0],'MarkerSize',10,'LineWidth',2);

xlim([5E-1 2E3])
ylim([2E2 5E7]*structData.units.energyVolDensity.value)
xticks(10.^(0:1:5))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
legend(h,{'Al Electrolytic (Wet)','Al Electrolytic (Polymer)','Al Electrolytic (Hybrid)'},'Location','Best');

xlabel ('DC Voltage [V]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Current Ripple Density vs Energy Density (Alum's only)
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Unit conversion
units_temp1 = 1e3*1e0; % Conversion from [A/mm^3] to [A/cm^3]
units_temp1 = 1e3*1e0; % Conversion from [A/mm^3] to [mA/mm^3]
units_temp2 = 1e-3; % Conversion from [uJ/mm^3] to [uJ/cm^3]
units_temp2 = 1;

% Set data to plot
for j = 1:length(dataTables)
    x_plot_data{j} = structData.data.currLF{j}(:,1)./structData.data.volume{j}*units_temp1; % [A/mm^3]
    x_plot_data{j}(structData.data.volume{j} == 0) = NaN;
    y_plot_data{j} = structData.data.energyVolDensity{j}*units_temp2; % [uJ/mm^3]
end
k = 1; % Aluminum electrolytic (wet)
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
% k = 2; % Aluminum electrolytic (polymer)
% x_plot{2} = vertcat(x_plot_data{k});
% y_plot{2} = vertcat(y_plot_data{k});
% k = 3; % Aluminum electrolytic (hybrid)
% x_plot{3} = vertcat(x_plot_data{k});
% y_plot{3} = vertcat(y_plot_data{k});

% % Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
%     [~, i_hull, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    [smoothHull_i, i_hull, ~] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Display components of data table which belong to pareto-front
disp(['Pareto-front of ', inputFilename{k}, ':'])
disp(dataTables{k}(i_hull,:))

% Plot curves
plot(x_plot{1}*1.02,y_plot{1},'.', 'MarkerSize',5)
% plot(x_plot{2}*1.00,y_plot{2},'.', 'MarkerSize',5)
% plot(x_plot{3}*0.98,y_plot{3},'.', 'MarkerSize',5)
% set(gca,'ColorOrderIndex',1)
% for j = 1:Nplot
%     plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','LineWidth',2)
% end

% Include Enphase capacitor (UVZ1H332MHD)
plot(0.188,438,'x','Color',[1 0 0],'MarkerSize',10,'LineWidth',2);

xlim([5E-7 2E-2]*units_temp1)
ylim([2E2 5E6]*structData.units.energyVolDensity.value*units_temp2)
xticks(10.^(-15:1:5))
% set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
% legend(h,{'Al Electrolytic (Wet)','Al Electrolytic (Polymer)','Al Electrolytic (Hybrid)'},'Location','Best');

title(input_types{k})
xlabel ('120Hz Current Ripple Density [mA/mm$^3$]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Power Density vs Energy Density (Alum's only)
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

x_plot_data = structData.data.powerDensity;
y_plot_data = structData.data.energyVolDensity;

k = 1; % Aluminum electrolytic (wet)
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
% k = 2; % Aluminum electrolytic (polymer)
% x_plot{2} = vertcat(x_plot_data{k});
% y_plot{2} = vertcat(y_plot_data{k});
% k = 3; % Aluminum electrolytic (hybrid)
% x_plot{3} = vertcat(x_plot_data{k});
% y_plot{3} = vertcat(y_plot_data{k});

% % Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
%     [~, i_hull, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    [smoothHull_i, i_hull, ~] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Display components of data table which belong to pareto-front
disp(['Pareto-front of ', inputFilename{k}, ':'])
disp(dataTables{k}(i_hull,:))

% Plot curves
plot(x_plot{1}*1.02,y_plot{1},'.', 'MarkerSize',5)
% plot(x_plot{2}*1.00,y_plot{2},'.', 'MarkerSize',5)
% plot(x_plot{3}*0.98,y_plot{3},'.', 'MarkerSize',5)
% set(gca,'ColorOrderIndex',1)
% for j = 1:Nplot
%     plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'LineStyle','-','LineWidth',2)
% end

% Include Enphase capacitor (UVZ1H332MHD)
plot(sqrt(2)*50*0.188,438,'x','Color',[1 0 0],'MarkerSize',10,'LineWidth',2);

xlim([5E-5 2E-1]*units_temp1)
ylim([2E2 5E6]*structData.units.energyVolDensity.value*units_temp2)
xticks(10.^(-15:1:5))
% set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
% legend(h,{'Al Electrolytic (Wet)','Al Electrolytic (Polymer)','Al Electrolytic (Hybrid)'},'Location','Best');

title(input_types{k})
xlabel ('Power Density (at 120 Hz) [mW/mm$^3$]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Plot multiple - Volume vs Energy Density
% figure;
% hold on;
% clear x_plot y_plot smoothHull_plot % Clear plot variables
% 
% % Set data to plot
% x_plot_data = structData.data.volume;
% y_plot_data = structData.data.energyVolDensity;
% k = 7; % Ceramic (Class I)
% x_plot{1} = vertcat(x_plot_data{k});
% y_plot{1} = vertcat(y_plot_data{k});
% k = 9; % Ceramic (Class II)
% x_plot{2} = vertcat(x_plot_data{k});
% y_plot{2} = vertcat(y_plot_data{k});
% 
% % Extra sorting for 400 < Vr < 450
% var_sort1 = structData.data.voltage{7};
% i_sort1 = ((var_sort1 > 399) & (var_sort1 < 501));
% var_sort2 = structData.data.package{7};
% i_sort2 = strcmp(var_sort2,'0805'); % Extra sorting for 0805 package
% % i_sort2 = i_sort1; % Uncomment to exclude package sorting
% x_plot{1} = x_plot{1}(i_sort1 & i_sort2);
% y_plot{1} = y_plot{1}(i_sort1 & i_sort2);
% var_sort1 = structData.data.voltage{9};
% i_sort1 = ((var_sort1 > 399) & (var_sort1 < 501));
% % var_sort2 = cellstr(num2str(structData.data.package{8}));
% var_sort2 = structData.data.package{9};
% i_sort2 = (var_sort2 == 805); % Extra sorting for 0805 package
% % i_sort2 = i_sort1; % Uncomment to exclude package sorting
% x_plot{2} = x_plot{2}(i_sort1 & i_sort2);
% y_plot{2} = y_plot{2}(i_sort1 & i_sort2);
% 
% % Plot data
% Nplot = length(x_plot);
% plot(x_plot{1}*0.99,y_plot{1},'.', 'MarkerSize',5)
% plot(x_plot{2}*1.01,y_plot{2},'.', 'MarkerSize',5)
% 
% xlim([2E-10 5E-5]*structData.units.value.volume)
% ylim([2E-4 5E9]*structData.units.value.energyVolDensity)
% xticks(10.^[-15:3:15])
% yticks(10.^[-15:3:15])
% 
% % Configure legend
% h = gobjects(1,Nplot); 
% for j = 1:length(h)
%     linecolor_plot = colormap_MAT(j,:);
%     h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
% end
% legend(h,{'Class I','Class II'},'Location','Best');
% 
% xlabel ('Volume [mm$^3$]')
% % ylabel('Energy Density [mJ/mm$^3$]')
% ylabel('Energy Density [$\mu$J/mm$^3$]')
% % set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% 
% set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
% set(gcf,'PaperPositionMode','auto')
% movegui(gcf,'center')
% set_figure_style(k_plotscaling);

%% Plot multiple - Cost Density vs Energy Density
figure;
hold on;
clear x_plot y_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.costDensity;
y_plot_data = structData.data.energyVolDensity;
k = 1:3; % Aluminum electrolytics
x_plot{1} = vertcat(x_plot_data{k});
y_plot{1} = vertcat(y_plot_data{k});
k = 4:5; % Tantalum electrolytics
x_plot{2} = vertcat(x_plot_data{k});
y_plot{2} = vertcat(y_plot_data{k});
k = 7:8; % Class I ceramic
x_plot{3} = vertcat(x_plot_data{k});
y_plot{3} = vertcat(y_plot_data{k});
% k = 9:10; % Class II ceramic
% k = 11:12; % Class III ceramic
k = 9:12; % Class II & III ceramic
x_plot{4} = vertcat(x_plot_data{k});
y_plot{4} = vertcat(y_plot_data{k});
k = 13:20; % Film
x_plot{5} = vertcat(x_plot_data{k});
y_plot{5} = vertcat(y_plot_data{k});
k = 24; % EDLC
x_plot{6} = vertcat(x_plot_data{k});
y_plot{6} = vertcat(y_plot_data{k});

% Construct pareto-fronts based on data to be plotted
Nplot = length(x_plot);
smoothHull_plot = cell(1,Nplot);
for j = 1:Nplot
    [~, ~, smoothHull_i] = func_smoothConvHull([x_plot{j},y_plot{j}], 'whole', 'log');
    smoothHull_plot{j} = smoothHull_i;
end

% Display components of data table which belong to pareto-front
k = 1:3; % Aluminum electrolytics
% disp(['Pareto-front of ', inputFilename{k}, ':'])
x = vertcat(dataTables{k});
disp(x(i_hull,:))
% Write table to file
% writetable(dataTables{k}(i_hull,:),'Pareto_Data/ClassII_pareto.csv');

% Plot curves
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(x_plot{j},y_plot{j},'.','Color',linecolor_plot,'MarkerSize',5)
end
set(gca,'ColorOrderIndex',1)
for j = 1:Nplot
    linecolor_plot = colormap_MAT(j,:);
    plot(smoothHull_plot{j}(:,1),smoothHull_plot{j}(:,2),'Color',linecolor_plot,'LineStyle','-','LineWidth',2)
end

% xlim([2e3 8e11]*structData.units.value.costDensity); ylim([2E-4 5E9]*structData.units.value.energyVolDensity)
xlim([2e3 8e13]*structData.units.costDensity.value); ylim([2E-4 5E12]*structData.units.energyVolDensity.value)

% xticks(10.^[-13:1:0])
% set(gca,'xticklabel',{'100 fF','1 pF',' 10 pF','100 pF','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F'})
xticks(10.^(-15:3:3))
% set(gca,'xticklabel',{'1 fF','1 pF','1 nF','1 $\mu$F','1 mF','1 F','1 kF'})
yticks(10.^(-15:3:15))

% Configure legend
h = gobjects(1,Nplot); 
for j = 1:length(h)
    linecolor_plot = colormap_MAT(j,:);
    h(j) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
end
legend(h,{'Al Electrolytic','Ta Electrolytic','Ceramic - Class I','Ceramic - Class II','Film','EDLC'},'Location','Best');

% xlabel ('Cost Density [mm$^3$/\$]')
xlabel ('Cost Density [\$/mm$^3$]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
% legend({'Al Electrolytic (Wet)','Ceramic - Class I'},'Location','Best');
% title('Ceramic - Class I (C0G/NP0)')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Scatter plot - Voltage versus Energy Density versus Capacitance
figure;
hold on;
clear x_plot y_plot z_plot smoothHull_plot % Clear plot variables

% Set data to plot
x_plot_data = structData.data.voltage;
y_plot_data = structData.data.energyVolDensity;
z_plot_data = structData.data.capacitance;
k = 7;
x_plot{1} = vertcat(x_plot_data{k});
x_plot{1} = x_plot{1}.*(0.1*rand(length(x_plot{1}),1)+0.95); % Spread out the data in the voltage axis
y_plot{1} = vertcat(y_plot_data{k});
z_plot{1} = vertcat(z_plot_data{k});

Nplot = length(x_plot);
scatter(x_plot{1},y_plot{1},5,z_plot{1},'filled')
% scatter(x_plot_1,y_plot_1,10,z_plot_1)

xlim([2e0 2e4])
ylim([2E-3 5E6]*structData.units.energyVolDensity.value)
xticks(10.^(0:1:5))
set(gca,'xticklabel',{'1 V','10 V','100 V','1 kV','10 kV'})
yticks(10.^(-15:3:15))

xlabel ('DC Voltage [V]')
ylabel ('Energy Density [mJ/cm$^3$]')
zaxesLabel = '$C$ [F]';
% legend({'Ceramic - Class I'},'Location','northwest');
title('Ceramic - Class I')
% set(gca,'xticklabel',num2str(get(gca,'xtick')','%1.f'))
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
colormap(xlsread('colormap.xlsx'));
caxis([min(z_plot{1}) max(z_plot{1})])
colorbar_h = colorbar;

% set(colorbar_h,'YTick',[10.^(-12:3:0)]);
% set(colorbar_h,'YTickLabel',{'pF','nF','$\mu$F','mF','F'});
set(colorbar_h,'YTick', 10.^(-13:1:0));
set(colorbar_h,'YTickLabel',{'100 fF','1 pF',' 10 pF','100 pF','1 nF','10 nF','100 nF','1 $\mu$F','10 $\mu$F'});
set(gca,'ColorScale','log')

ylabel_colorbar = ylabel(colorbar_h,zaxesLabel,'Rotation',0.0,'Interpreter','latex'); % colorbar label
% % set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.5, 0.52, 0])
% set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.3, 0.52, 0])
set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [2.2, -0.07, 0])

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% Scatter plot - Power Density versus Energy Density versus Voltage
figure;
hold on;
clear x_plot y_plot z_plot smoothHull_plot % Clear plot variables

x_plot_data = structData.data.powerDensity;
y_plot_data = structData.data.energyVolDensity;
z_plot_data = structData.data.voltage;
k = 1;
x_plot{1} = vertcat(x_plot_data{k});
% x_plot{1} = x_plot{1}.*(0.1*rand(length(x_plot{1}),1)+0.95); % Spread out the data in the voltage axis
y_plot{1} = vertcat(y_plot_data{k});
z_plot{1} = vertcat(z_plot_data{k});

Nplot = length(x_plot);
scatter(x_plot{1},y_plot{1},5,z_plot{1},'filled')
% scatter(x_plot_1,y_plot_1,10,z_plot_1)

% Include Enphase capacitor (UVZ1H332MHD)
% Include Enphase capacitor (UVZ1H332MHD)
% temp_i = find(~cellfun(@isempty, regexp(dataTables{1}.MfrPartName,'UVZ1H332MHD')));
temp_PrDensity = 50*1.77/(pi*(18e-3/2)^2*37e-3)*structData.units.powerDensity.value; % = 9.3995 [mW/mm^3]
plot(temp_PrDensity,438,'x','Color',color0,'MarkerSize',10,'LineWidth',2);

% xlim([5E-5 2E-1]*units_temp1)
% ylim([2E2 5E6]*structData.units.energyVolDensity.value*units_temp2)
xlim([5E4 5E8]*structData.units.powerDensity.value)
ylim([2E2 5E6]*structData.units.energyVolDensity.value)
xticks(10.^(-15:1:5))
yticks(10.^(-15:1:15))

title(input_types{k})
xlabel ('Power Density (at 120 Hz) [mW/mm$^3$]')
% ylabel('Energy Density [mJ/mm$^3$]')
ylabel('Energy Density [$\mu$J/mm$^3$]')
zaxesLabel = '$V_r$ [V]';
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
colormap(readmatrix('colormap.xlsx'));
caxis([min(z_plot{1}) max(z_plot{1})])
colorbar_h = colorbar;

% set(colorbar_h,'YTick',[10.^[-12:3:0]]);
% set(colorbar_h,'YTickLabel',{'pF','nF','$\mu$F','mF','F'});
set(colorbar_h,'YTick', 10.^(0:1:5));
set(colorbar_h,'YTickLabel',{'1 V','10 V','100 V','1 kV','10 kV'})
set(gca,'ColorScale','log')

ylabel_colorbar = ylabel(colorbar_h,zaxesLabel,'Rotation',0.0,'Interpreter','latex'); % colorbar label
% % set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.5, 0.52, 0])
% set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.3, 0.52, 0])
set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [2.2, -0.07, 0])

set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
set(gcf,'PaperPositionMode','auto')
movegui(gcf,'center')
set_figure_style(k_plotscaling);


%% The ultimate plot test

clear structPlot
clear x_plot y_plot z_plot smoothHull_plot % Clear plot variables

% Specify plot inputs
% x_plot.name = 'energyVolDensity';
x_plot.name = 'voltage';
% y_plot.name = 'powerDensity';
y_plot.name = 'energyVolDensity';
% y_plot.name = 'energyMassDensity';
structPlot.pareto.fill = 'true';
structPlot.pareto.fill = 'false';
structPlot.pareto.quadrants = 'all'; % TODO: Specify specific quadrants
structPlot.pareto.type = 'hull';
structPlot.pareto.type = 'smoothHull';
% structPlot.pareto.type = 'tight';
% Set custom axes limits
% structPlot.x.limits = [2e0 5e3]; 
% structPlot.y.limits = [1e-1 2e5];

% Vector of data to plot
k_plot = ...
    {   7:8,        'Class I';...
        9:12,       'Class II';... % Combine Class II and III
        ...9:10,       'Class II';... % Only Class II
        ...11:12,      'Class III';... % Only Class III
        1,          'Alum Elec';...
        ...1:3,        'Alum Elec';... % Combine all Alum Elec
        ...13:20,      'Film';...   % Combine all Film
        ...4:5,        'Tantalum';...
    }';

% Plot data
axesNames = {x_plot.name, y_plot.name};
figureHandle = func_generatePlot(structPlot, axesNames, structData, k_plot);


%% Plot: Power Density versus Energy Density

clear structPlot
clear x_plot y_plot z_plot smoothHull_plot % Clear plot variables

% Specify plot inputs
x_plot.name = 'energyVolDensity';
y_plot.name = 'powerDensity';
z_plot.name = 'voltage';
structPlot.pareto.fill = 'false';
structPlot.pareto.quadrants = 'all'; % TODO: Specify specific quadrants
structPlot.pareto.type = 'smoothHull';
% Manual override of axis limits
% structPlot.x.limits = [2e-1 2e4]; 
% structPlot.y.limits = [2e-2 2e2];
% structPlot.x.limits = [2e0 2e4]; 
% structPlot.y.limits = [2e-1 5e2];
structPlot.x.limits = [2e0 5e3]; 
structPlot.y.limits = [2e-1 2e2];
% Manually set colorbar ticks
colorbar_ticks = [1, 6.3, 10, 16, 25, 35, 50, 63, 100, 160 , 250, 450, 630]; % Other common values: 200
colorbar_ticklabels = cellstr([num2str(colorbar_ticks'),repmat(' V',length(colorbar_ticks),1)])';
structPlot.z.ticks = colorbar_ticks;
structPlot.z.ticklabels = colorbar_ticklabels;

% Vector of data to plot
k_plot = {1,  'Alum Elec'}';

% Plot data
% axesNames = {x_plot.name, y_plot.name};
% figureHandle = func_generatePlot(structPlot, axesNames, structData, k_plot);
% 3D version
axesNames = {x_plot.name, y_plot.name, z_plot.name};
[figureHandle, structPlot] = func_generatePlot(structPlot, axesNames, structData, k_plot);

% Reconfigure the colorbar ticks
colorbar_h = figureHandle.Children(2);
% colorbar_ticks = [1, 6.3, 10, 16, 25, 35, 50, 63, 100, 160 , 250, 450, 630]; % Other common values: 200
% colorbar_ticklabels = cellstr([num2str(colorbar_ticks'),repmat(' V',length(colorbar_ticks),1)])';
% colorbar_h.Ticks = colorbar_ticks;
% colorbar_h.TickLabels = colorbar_ticklabels;
colorbar_h.Ruler.MinorTick = 'off'; % Removes ticks between those manually set
% Label the colorbar
zaxesLabel = '$V_r$ [V]';
ylabel_colorbar = ylabel(colorbar_h,zaxesLabel,'Rotation',0.0,'Interpreter','latex'); % colorbar label
% % set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.5, 0.52, 0])
% set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [3.3, 0.52, 0])
set(ylabel_colorbar, 'Units', 'Normalized', 'Position', [2.2, -0.07, 0])

% Curve-fitting ideas
% % Option #1
% x_temp = structPlot.data.xPlot{:};
% y_temp = structPlot.data.yPlot{:};
% % More curve fitting ideas (log-friendly)
% func = @(b,x) exp(b(1) + b(2)*log(x)); % Similar in form to y = b(1)*x.^b(2)
% X = [ones(size(x_temp)) log(x_temp)];
% [bf,~,~,~,stats] = regress(log(y_temp),X)    % Removes NaN data
% x_temp_fit = logspace(log10(min(x_temp)),log10(max(x_temp)),2e1);
% % Plot curve-fitting ideas
% % P_r = func(bf,W_dc); % Fit of all data
% temp = [150;20];
% W_dc = logspace(-6,5,1e2);
% P_r = temp.*W_dc.^bf(2);
% plot(W_dc,P_r,'-','Color',color0,'LineWidth',1)
% w = 2*pi*60;
% alpha_lims = sqrt((w+2*sqrt(2)*temp)/w) - 1 % This relationship only holds when bf(2) = 1 (linear relationship between W_dc and P_r)

% Option #2
% W_dc = logspace(-6,5,1e2);
% % alpha = 10.^(-4:1:-1)';
% alpha = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2]';
% w = 2*pi*60;
% % phi = 1/sqrt(2)*(1+alpha/2).*(8*alpha./(alpha+2).^2)*w;
% phi = 4/sqrt(2)*(alpha./(alpha+2))*w; % Simplified
% % phi = 1/sqrt(2)*2*alpha*w; % Small-ripple approximation
% set(gca,'ColorOrderIndex',2);
% % plot(W_dc,phi*W_dc,'-','LineWidth',1)
% h_a = plot(W_dc,phi*W_dc*1e-3,'-','LineWidth',1.2); % For density case (to get right units)
% % Custom legend
% alpha_label = {'$\alpha$ = 0.5\%','$\alpha$ = 1\%','$\alpha$ = 2\%','$\alpha$ = 5\%','$\alpha$ = 10\%','$\alpha$ = 20\%'};
% legend(h_a,alpha_label,'Location','Best');
% legend(flipud(h_a));


% Option #3
W_dc = logspace(-6,5,1e2);
% alpha = 10.^(-4:1:-1)';
% alpha = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2]';
alpha = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1]';
alpha = [0.005, 0.01, 0.025 0.05, 0.1, 0.2, 0.5, 1]';
w = 2*pi*50;
% phi = 1/sqrt(2)*(1+alpha/2).*(8*alpha./(alpha+2).^2)*w;
phi = 4/sqrt(2)*(alpha./(alpha+2))*w; % Simplified
phi = phi.*(1+0.5*alpha); % Guess in shaping Irms from alpha = 0 to 2
% phi = 1/sqrt(2)*2*alpha*w; % Small-ripple approximation
set(gca,'ColorOrderIndex',2);
% plot(W_dc,phi*W_dc,'-','LineWidth',1)
h_a = plot(W_dc,phi*W_dc*1e-3,'-','LineWidth',1.2,'Color',color0+0.3); % For density case (to get right units)

% xp_v = 0.8*[3e3, 3.5e3, 4e3, 3.5e3, 2.5e3, 1.5e3, 0.61e3, 0.28e3];
xp_v = 0.6*[3e3, 3.5e3, 4.2e3, 4e3, 3.5e3, 1.8e3, 0.7e3, 0.3e3]; xlim([2e0 5e3]); ylim([2e-1 2e2]);
for ii = 1:length(alpha)
    str = ['$\alpha = $ ',num2str(alpha(ii)*100),'$\%$'];
%     xp = 8e3*(1-0.18*log(phi(ii)));
%     xp = 5e3*(1-0.2*log(phi(ii)./phi(1)));
    xp = xp_v(ii);
    text(xp,phi(ii)*xp*1e-3,str,...
        'Rotation',45,'VerticalAlignment','middle','BackgroundColor',[1 1 1],...
        'Interpreter','latex')
end

% Turn off legend
figureHandle.Children(1).Visible = 'off';

% Custom legend
% alpha_label = {'$\alpha$ = 0.5\%','$\alpha$ = 1\%','$\alpha$ = 2\%','$\alpha$ = 5\%','$\alpha$ = 10\%','$\alpha$ = 20\%'};
% legend(h_a,alpha_label,'Location','Best');
% legend(flipud(h_a));

% Plot capacitors from Neumayr and Kolar, JESTPE 2020
% temp_MfrPartName = 'B43630*'; 
% temp_Vdc = 450;
% temp_dataTable = dataTables{1};
% temp_dataTable2 = structData.data.mfrPartName{1};
% i1 = ~cellfun(@isempty, regexpi(temp_dataTable.MfrPartName,['^',temp_MfrPartName])); % Matching part name
% % i1b = ~cellfun(@isempty, regexpi(temp_dataTable2,['^',temp_MfrPartName])); % Matching part name (Option #2)
% i2 = (temp_dataTable.VoltageRatedDC==temp_Vdc); % Matching voltage
% % i2 = ones(size(i1));
% itot = i1&i2;
% temp_dataTable_filtered = temp_dataTable(itot,:);
% plot(structData.data.energyVolDensity{1}(itot,:),structData.data.powerDensity{1}(itot,:),'x','color','k')
% xlim([2e2, 5e3]); ylim([2e0 2e2]);

% % Option #3
% alpha = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2];
% % alpha = [0.001, 0.1];
% x = logspace(-2,5,1e2);
% y = logspace(-2,5,1e2);
% [X,Y] = meshgrid(x,y);
% Z = 2*Y./(2*sqrt(2)*w*(X*1e-3) - Y); % Solved equation for alpha
% Z(Y>2*sqrt(2)*w*(X*1e-3)) = NaN;
% [C,h] = contour(X,Y,Z,alpha,'-k','LabelSpacing',250,'LineWidth',1.2);
% clabel(C,h,'BackgroundColor','white')



%% Export figures
% % figure_folder = 'Figures';
% figure_folder = 'Pareto_Data';
% % figure_name = 'rho_all';
% % figure_name = 'rho_Alum1';
% % figure_name = 'rho_Alum3';
% % figure_name = 'rhoC';
% % figure_name = 'rhoVC';
% % figure_name = 'ClassII_pareto';
% figure_name = 'test';
% % figure_name = 'MLCC_VolumeSurvey_450-500V';
% % figure_name = 'MLCC_VolumeSurvey_450-500V_0805';
% figure_fullpath = fullfile(figure_folder,figure_name);
% set(gcf,'Units','Inches');
% pos = get(gcf,'Position');
% set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
% % print(gcf,figure_fullpath,'-dpdf','-r600')
% % print(gcf,figure_fullpath,'-dpdf','-r0')
% % print(gcf,figure_fullpath,'-dpng','-r600')
% % exportgraphics(gcf,[figure_fullpath,'.png'],'Resolution',600,'BackgroundColor','none'); % v2020b 
% saveas(gcf,figure_fullpath,'pdf')

%% Extracting out specific data

k = 9; % Class II ceramics
k = 13:20; % Film
T = dataTables{k};
% [~,maxidx] = max(T.EnergyDensity);
% [~,maxidx] = (T.EnergyDensity*1e-9*1e3>0.4);
% m = (vertcat(structData.data.energyVolDensity{k})>1e3)&(vertcat(structData.data.voltage{k})==1000);
m = (vertcat(structData.data.energyVolDensity{k})>4e2);
% m = (vertcat(structData.data.voltage{k})==1000);
Tx = T(m,:)
temp = vertcat(structData.data.mfrPartName{k});

Ta = dataTables{1};
% Sort by voltage
m = (Ta.VoltageRatedDC>399&Ta.VoltageRatedDC<501);
% Sort by package
% m2 = strcmp(T.Package,'0805');
% m = m&m2;
% Final table
Ta = Ta(m,:);

Tb = dataTables{8};
% Sort by voltage
m = (Tb.VoltageRatedDC>399&Tb.VoltageRatedDC<501);
% Final table
Tb = Tb(m,:);

% % Write tables to file
% writetable(Ta,'ClassI_450-500V_0805.csv');
% % writetable(Ta,'ClassI_450-500V.csv');
% writetable(Tb,'ClassII(TDK)_450-500V.csv');



%% func_generatePlot.m
% Inline function to generate plots for component survey data.
function [output_figureHandle, output_structPlot] = func_generatePlot(input_structPlot, input_axesNames, input_structData, input_k_plot)
%   First input is a special plot structure containing all necessary data
%       information. (TODO: Can be empty by default?)
%   Second input are the names of the axes.
%   Third input is a structure containing the data information of all the survey data.
%   Fourth input is a special cell array indicating which groupings of survey data
%       to plot.
%   Returns the figure handle and returns the fully populated (axes options and data) plot structure.

%   Any fields specified in the input plot structure are used to manually
%       override the defaults. Can be empty by default?
%   Can currently roughly support 2D and 2D plot with colorbar.

    %% Assign input(s)
    structPlot = input_structPlot;
    axesNames = input_axesNames;
    structData = input_structData;
    k_plot = input_k_plot;

    % Check if specified plot variables are valid   
    if all(ismember(axesNames,structData.datafields))
        % Do nothing
    else
        disp('Invalid plot variable names.')
        return;
    end

    %% Extract data and variable names to plot
    xData = structData.data.(axesNames{1});
    yData = structData.data.(axesNames{2});
    % Construct figure title
    xAxis_label = structData.units.(axesNames{1}).varName;
    yAxis_label = structData.units.(axesNames{2}).varName;    
    if (length(axesNames) == 2) % 2D plot
        structPlot.title = [xAxis_label, ' vs ', yAxis_label];
    elseif (length(axesNames) == 3) % 3D plot
        zAxis_label = structData.units.(axesNames{3}).varName;
        structPlot.title = [xAxis_label, ' vs ', yAxis_label, ' vs ', zAxis_label];
        zData = structData.data.(axesNames{3});
    end
    % Configure the plot legend based on specified inputs (requires a
    % particular cell array structure)
    structPlot.legend = k_plot(2,:); % {k_plot{2,:}}
    
    %% Instantiate figure
    figure('Name',structPlot.title);
    hold on;

    %% 
    N_plot = size(k_plot,2);
    N_axes = length(axesNames); % Number of axes
    for ii = 1:N_plot
        k = k_plot{1,ii};
        for jj = 1:N_axes 
            
            % Only apply to 'voltage' variable on either x or y axes
            if strcmp(axesNames{jj},'voltage')&&(jj<3) 
                shift = 1 + 0.02*(ii-(N_plot+1)/2); % Horizontally offset data
            else
                shift = 1;
            end
            
            % Reassaign manipulated axes to plot structure
            switch jj
                case 1 % x axis
                    structPlot.data.xPlot{ii} = vertcat(xData{k})*shift;
                case 2 % y axis
                    structPlot.data.yPlot{ii} = vertcat(yData{k})*shift;
                case 3 % z axis
                    structPlot.data.zPlot{ii} = vertcat(zData{k})*shift;
            end
            
        end
    end


    %% Set the axes info based on the specified variables
    structPlot = func_setPlotAxisInfo(structPlot, axesNames, structData.units);


    %% Construct pareto-fronts based on data to be plotted
    N_plot = size(k_plot,2);
    structPlot.data.hull_plot = cell(1,N_plot);
    structPlot.data.smoothHull_plot = cell(1,N_plot);
    for ii = 1:N_plot
        [hull, ~, smoothHull] = func_smoothConvHull([structPlot.data.xPlot{ii},structPlot.data.yPlot{ii}], 'whole', 'log');
        structPlot.data.hull_plot{ii} = hull; % Convex hull
        structPlot.data.smoothHull_plot{ii} = smoothHull; % Smooth (interpolation) of convex hull
    end

    %% Plot data
    colormap_MAT = get(groot,'DefaultAxesColorOrder'); % Get defualt plot colors
%     set(gca,'ColorOrderIndex',1)

    % Plot pareto-fronts
    if strcmp(structPlot.pareto.fill,'true') % Filled pareto-fronts
        for ii = 1:N_plot
            fillcolor_plot = colormap_MAT(ii,:);
        %     fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),fillcolor_plot)
            fill(structPlot.data.smoothHull_plot{ii}(:,1),structPlot.data.smoothHull_plot{ii}(:,2),...
                    fillcolor_plot,'FaceAlpha',0.5,'EdgeColor',fillcolor_plot,'LineStyle','-','LineWidth',2);
        end
        % Debugging
        % fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor','none'); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');
        % fill(smoothHull_plot{1}(:,1),smoothHull_plot{1}(:,2),colormap_MAT(1,:),'FaceAlpha',0.5,'EdgeColor',colormap_MAT(1,:),'LineStyle','-','LineWidth',2); set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log');
    else % Empty pareto-fronts
        for ii = 1:N_plot
            linecolor_plot = colormap_MAT(ii,:);
%             linecolor_plot = [0 0 0];
            plot(structPlot.data.smoothHull_plot{ii}(:,1),structPlot.data.smoothHull_plot{ii}(:,2),...
                    'LineStyle','-','Color',linecolor_plot,'LineWidth',2)
        end    
    end

    % Plot data points
    for ii = 1:N_plot
        linecolor_plot = colormap_MAT(ii,:);
        if N_axes == 2
            plot(structPlot.data.xPlot{ii},structPlot.data.yPlot{ii},...
                    '.','Color',linecolor_plot, 'MarkerSize',5)
        %     plot(structPlot.data.x_plot{j}./vertcat(structData.data.voltage{k}),structPlot.data.y_plot{j},'.','Color',linecolor_plot, 'MarkerSize',5)
        elseif N_axes == 3
            scatter(structPlot.data.xPlot{ii},structPlot.data.yPlot{ii},5,structPlot.data.zPlot{ii},'filled') % 3D plot
        end
    end

    %% Set axes options
    % Axes limits
    xlim(structPlot.x.limits)
    ylim(structPlot.y.limits)
    % Axes ticks
    xticks(structPlot.x.ticks)
    xticklabels(structPlot.x.ticklabels);
    % Axes tick labels
    yticks(structPlot.y.ticks)
    yticklabels(structPlot.y.ticklabels);
    % Set axes labels 
    xlabel(structPlot.x.label)
    ylabel(structPlot.y.label)
    
    %% Configure colorbar
    if N_axes == 3
        colormap(readmatrix('colormap.xlsx'));
        caxis([min(structPlot.data.zPlot{1}) max(structPlot.data.zPlot{1})])
        colorbar_h = colorbar;

        set(colorbar_h,'YTick', structPlot.z.ticks);
        set(colorbar_h,'YTickLabel',structPlot.z.ticklabels)
        set(gca,'ColorScale','log')
    end

    %% Configure legend
    h = gobjects(1,N_plot); 
    for ii = 1:length(h)
        linecolor_plot = colormap_MAT(ii,:);
        h(ii) = plot(0,0,'.','Color',linecolor_plot,'LineWidth',2,'MarkerSize',20,'visible','on');
    end
    legend(h,structPlot.legend,'Location','Best','AutoUpdate','off')


    %% Final plot configuration
    % Logarithmic plot
    set(gca, 'YScale', 'log')
    set(gca, 'XScale', 'log')
    % Set the figure size and font sizes
    k_plotscaling = 1.5; % Set relative size of plot fonts. Recommend 1.5 or 2.
    k_plotsize = 1.2;
    plot_shape = 'square';
    if(strcmp(plot_shape, 'square'))
        k_plot_w = 450;
        k_plot_h = 350;
    elseif(strcmp(plot_shape, 'rect'))
        k_plot_w = 850;
        k_plot_h = 385;
    end
    set(gcf, 'Position', [1000 500 k_plotsize*k_plot_w k_plotsize*k_plot_h]) % set figure size and position
    set(gcf,'PaperPositionMode','auto')
    movegui(gcf,'center')
    set_figure_style(k_plotscaling);
    grid off; grid on; % removes minor gridlines
    
    %% Return output(s)
    output_figureHandle = get(groot,'CurrentFigure');
    output_structPlot = structPlot;

end



%% func_setPlotAxisInfo.m
% Inline function to set the axis info (ticks, labels, etc.) for the
% component survey data.
function output_structPlot = func_setPlotAxisInfo(input_structPlot, input_axesNames, input_structDataUnits)
%   First input is a special plot structure containing all necessary data information.
%   Second input are the names of the axes.
%   Third input is a structure containing the units information of all the survey data.
%   Returns the modified plot structure populated with all the axes options.

%   Any fields specified in the input plot structure are used to manually
%   override the defaults.

    %% Initialize input(s)
    structPlot = input_structPlot;
    axesNames = input_axesNames;
    structDataUnits = input_structDataUnits;
    
    %% Iterate for each plot axis to determine axis options from data
    N_axes = length(axesNames); % Number of axes
    for ii = 1:N_axes
        
        % Get variable unit info for the specified plot variables
        try
            axis_plotName = axesNames{ii};
            axis_plotUnits = structDataUnits.(axis_plotName);
        catch
            disp(['Input data structure''s units are not correctly defined for the specified variable name: ''', axis_plotName,''''])
            return
        end
        
        axis_plot = struct('ticks',[],'ticklabels',[],'limits',[],'label',[]);
        switch axis_plotName
            case 'voltage'
                axis_plot.ticks = (10.^(-3:1:8));
                axis_plot.ticklabels = {'1 mV','10 mV','100 mV',...
                                        '1 V','10 V','100 V',...
                                        '1 kV','10 kV','100 kV',...
                                        '1 MV'};
                axis_plot.limits = [5e-1 2E5]*axis_plotUnits.value;
            case 'capacitance'
                axis_plot.ticks = (10.^(-15:3:3));
                axis_plot.ticklabels = {'1 fF','1 pF','1 nF','1 $\mu$F','1 mF','1 F','1 kF'};
                axis_plot.limits = [2e-15 8e1]*axis_plotUnits.value;
            case 'currLF'
                axis_plot.ticks = (10.^(-6:1:3));
                axis_plot.ticklabels = {'1 $\mu$A','10 $\mu$A','100 $\mu$A',...
                                        '1 mA','10 mA','100 mA',...
                                        '1 A','10 A','100 A',...
                                        '1 kA'};
                axis_plot.limits = [1e-6 1e3]*axis_plotUnits.value;
            case 'energyDC'
                axis_plot.ticks = (10.^(-15:1:15));
                axis_plot.ticklabels = 'auto';
                axis_plot.limits = [2E-6 5E4]*axis_plotUnits.value;
            case 'energyVolDensity'
                axis_plot.ticks = (10.^(-15:1:15));
                axis_plot.ticklabels = 'auto';
                axis_plot.limits = [2E-5 5E7]*axis_plotUnits.value;
%                 axis_plot.limits = [2E2 5E6]*axis_plotUnits.value;
            case 'energyMassDensity'
                axis_plot.ticks = (10.^(-15:1:15));
                axis_plot.ticklabels = 'auto';
                axis_plot.limits = [2E-11 5E1]*axis_plotUnits.value;
            case 'powerRated'
                axis_plot.ticks = (10.^(-15:1:15));
                axis_plot.ticklabels = 'auto';
                axis_plot.limits = [2E-3 5E6]*axis_plotUnits.value;
            case 'powerDensity'
                axis_plot.ticks = (10.^(-15:1:15));
                axis_plot.ticklabels = 'auto';
                axis_plot.limits = [5E4 2E8]*axis_plotUnits.value;
            case 'volume'
                axis_plot.ticks = (10.^(-9:1:0));
                axis_plot.ticklabels = {'1 mm$^3$','10 mm$^3$','100 mm$^3$',...
                                        '1 cm$^3$','10 cm$^3$','100 cm$^3$',...
                                        '1 dm$^3$','10 dm$^3$','100 dm$^3$',...
                                        '1 m$^3$'};
    %             axis_plot.ticklabels = {'1 $\mu$L','1 mL','1 L','1 kL'};
        %         axis_plot.ticklabels = {'in$^3$'}; % Imperial units?
            otherwise
        end
        % Set axis label
        axis_plot.label = [axis_plotUnits.varName, ' [', axis_plotUnits.unitName, ']'];

        %% Reassaign manipulated axes to plot structure
        % Select axis name
        switch ii
            case 1 % x axis
                axisVar = 'x';
            case 2 % y axis
                axisVar = 'y';
            case 3 % z axis
                axisVar = 'z';
        end

        % Perform manual override of default options (if present in input plot structure)
        if isfield(structPlot,axisVar)
            % Get the defualt defined fields of the axis setting structure
            temp_fields = fieldnames(axis_plot);
            % Check if the plot structure input contains any
            % matching fieldnames (manual over-ride)
            temp_fields_i = ismember(temp_fields,fieldnames(structPlot.(axisVar)));
            % Over-write the default fields with the manual inputs
            for jj = 1:length(temp_fields_i)
                if temp_fields_i(jj) % Check if is a manually specified option
                    axis_plot.(temp_fields{jj}) = structPlot.(axisVar).(temp_fields{jj});
                end
            end
%             axis_plot.(temp_fields{temp_fields_i}) = structPlot.(axisVar).(temp_fields{temp_fields_i}); % Works for single overwrite, not multiple
        end

        % Determine how many ticks will be on the axis and make sparser if too many
        if ~strcmp(axisVar, 'z') % Don't apply to colorbar axis (TODO: fix)
            num_ticks = sum((axis_plot.ticks >= axis_plot.limits(1)) & (axis_plot.ticks < axis_plot.limits(2)));
            if num_ticks > 7 % 7 or less ticks on an axis is a decent aesthetic choice
                axis_plot.ticks = axis_plot.ticks(1:3:end); % Sparser ticks
                if ~strcmp(axis_plot.ticklabels,'auto')
                    axis_plot.ticklabels = axis_plot.ticklabels(1:3:end); % Sparser tick labels
                end
            end
        end

        % Assign axis options to overall plot structure
        structPlot.(axisVar) = axis_plot;

    end
    
    %% Return output(s)
    output_structPlot = structPlot;
    
end
