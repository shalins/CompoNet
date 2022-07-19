  function output_table = func_ParseInductorPages(input_filename,input_foldername)
%% funcParseCapacitorPages.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 10/15/21
%   Last Revision: 10/15/21
%
%   File Description:
%       This function parses component data from digikey file export. It
%       also computes relevant metrics (type, manufacturer part number,
%       inductance, rated current, saturation current, volume, and
%       energy density (both rated and sat).
%       Currently only parses inductor components.
%
%   Inputs:
%       - filename  --  local path of folder for data import and parse
%
%   Outputs:
%       - table     --  table of parsed data
%
%   Other m-files required:
%   Other files required:
%
%% Debug
% close all
% clear all
% clc
% 
% % Supress warning messages
% warning('off','MATLAB:table:PreallocateCharWarning');
% 
% % Manually specificy function inputs for debugging
% % inputFilename = 'Alumpoly_11082019.csv';
% % inputFilename = 'Alumelec_11152019.csv';
% % input_filename = 'C0GNP0_03222021.csv';
% % inputFilename = 'Test.csv';
% % input_filename = 'FilmAcrylic_03282021.csv';
% % input_filename = 'Tantalum_03282021.csv';
% % input_filename = 'TantalumPoly_03282021.csv';
% % input_filename = 'Inductor_20211014.csv';
% % input_foldername = 'RawData_Digikey';
% 
% input_foldername = 'RawData_Digikey\Inductor_20211014';
% input_filename = 'fixed_inductors.csv';


%% Import data from .csv

% Supress warning messages
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

% Determine if  write and read paths
if ~exist('input_foldername','var')
    parentPath = pwd;
else
    parentPath = fullfile(pwd,input_foldername);
end

inputFilepath = fullfile(parentPath,input_filename);

filename = inputFilepath;
filedata = readtable(filename);

[n_rows, n_vars] = size(filedata);

% Only works with R2018a or later
% Pre-allocation of table and variables
% new_filedata = table('Size',[n_rows, 3],...
%     'VariableTypes',{'char','double','double'},...
%     'VariableNames',{'Tech','Capacitance','Voltage'});


%% Parse inductor type
% Currently tech information is pre-parsed with the user-defined filename.

% Initialize final character string identifiers for concatenation
data_tech = cell(n_rows, 1);
data_tech(:) = {''};

% Determine type based off of the user-defined aggregated file names for
% each type (roughly 10 or so from digikey). Assumes a specific filenaming
% convention from user: "######\type_########.csv"
filedata_tech = input_filename(1:regexp(input_filename,'_') - 1);
% filedata_tech_1 = regexprep(inputFilename,'\.csv','');
% filedata_tech_1 = regexprep(filedata_tech_1,'_','');
% filedata_tech_1 = regexprep(filedata_tech_1,'\d','');

% Write tech values to final data table
data_tech(:) = {filedata_tech};
new_filedata = table(data_tech,'VariableNames',{'Tech'});


%% Unused capacitor type implementation
% The string denoting the capacitor type is always within the digikey
% variable "Description" and sometimes "Type" , "Features", and
% "Temperature Coefficient". "Type", "Features", "Temperature Coefficient"
% may not exist for certain capacitor types (e.g., aluminum electrolytic).
% 
% Ended up scrapping the generalized implementation b/c some
% electrolyctic capacitors do not include any identifiers besides being
% associated with the search results in digikey (and thus the aggregated 
% "Alumelec" file). Plus, some capacitors have bad descriptions.

% Main "Description" identifier
filedata_type_1 = filedata.Description;

% "Type" identifier (aluminum polymer, aluminum polymer hybrid, tantalum)
if ismember('Type', filedata.Properties.VariableNames)
    filedata_type_2 = filedata.Type;
else
    filedata_type_2 = cell(n_rows, 1);
    filedata_type_2(:) = {''};
end
% Options are "-", "Ceramic", "Ceramic Core, Wirewound", "Molded",
% "Multilayer", "Planar", "Thick Film", "Thin Film", "Toroidal",
% "Wirewound".

% "Features" identifier
if ismember('Features', filedata.Properties.VariableNames)
    filedata_type_3 = filedata.Features;
else
    filedata_type_3 = cell(n_rows, 1);
    filedata_type_3(:) = {''};
end

% "Material_Core" identifier
if ismember('Material_Core', filedata.Properties.VariableNames)
    filedata_type_4 = filedata.Material_Core;
else
    filedata_type_4 = cell(n_rows, 1);
    filedata_type_4(:) = {''};
end
% Options are "-", "Air", "Alloy Powder", "Alumina", "Carbonyl Powder",
% "Ceramic", "Ceramic, Ferrite", "Ceramic, Non-Magnetic", "Drum" (only 1),
% "Ferrite", "Ferrite Drum", "High Saturation", "Iron", "Iron Powder",
% "Manganese Zinc Ferrite (MnZn)", "Metal", "Metal Composite", "Molybdenum
% Permalloy(MPP)" (not a typo), "Nickel Zinc Ferrite (NiZn)",
% "Non-Magnetic", "Phenolic", "Polymer" (only 1), "Sendust".

% Initialize type and sub-type identifiers
data_type_a = cell(n_rows, 1);
data_type_a(:) = {''};
data_type_b = cell(n_rows, 1);
data_type_b(:) = {''};

% % Remove all redundant character strings (i.e., "CAP", "CAPACITOR", "SMD", 
% % "T/H", "RADIAL", "%", ".", "", any "#"). These lines aren't really
% % necessary for the later selection to take place.
% % filedata_type_1 = regexprep(filedata_type_1,'CAPACITOR','');
% filedata_type_1 = regexprep(filedata_type_1,'CAP*','');
% filedata_type_1 = regexprep(filedata_type_1,'SMD','');
% filedata_type_1 = regexprep(filedata_type_1,'T/H','');
% filedata_type_1 = regexprep(filedata_type_1,'RADIAL','');
% filedata_type_1 = regexprep(filedata_type_1,'\%','');
% filedata_type_1 = regexprep(filedata_type_1,'\.','');
% filedata_type_1 = regexprep(filedata_type_1,'\d',''); % Remove numerics
% filedata_type_1 = regexprep(filedata_type_1,' UF','');
% filedata_type_1 = regexprep(filedata_type_1,' V','');
% filedata_type_1 = regexprep(filedata_type_1,'\s',''); % Remove whitespace

% Narrow down to molded sub-type
% Check #1 (in "Type")
% Options are "-", "Ceramic", "Ceramic Core, Wirewound", "Molded",
% "Multilayer", "Planar", "Thick Film", "Thin Film", "Toroidal",
% "Wirewound".
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Molded'));
data_type_b(i) = {'Molded'};
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Wirewound')); 
data_type_b(i) = {'Wirewound'};
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Ceramic')); % After 'Wirewound'
data_type_b(i) = {'Ceramic'};
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Multilayer'));
data_type_b(i) = {'Multilayer'};
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Thick Film'));
data_type_b(i) = {'ThickFilm'};
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Thin Film'));
data_type_b(i) = {'ThinFilm'};
i = ~cellfun(@isempty,regexpi(filedata_type_2,'Toroidal'));
data_type_b(i) = {'Toroidal'};

% Concatenate full type string
char_mid = cell(n_rows, 1);
char_mid(:) = {''};
i = ~(cellfun(@isempty,data_type_a)|cellfun(@isempty,data_type_b));
char_mid(i) = {'_'};
data_type = strcat(data_type_a,char_mid,data_type_b);

% Write capacitor type to final data table
new_filedata = addvars(new_filedata, data_type,'NewVariableNames','Type');


%% Parse manufacturer name
% Get manufacturer name data from 'Mfr' (or 'Manufacturer') variable in imported data table
% filedata_manufacturer = filedata.Mfr;
if (sum(strcmp('Mfr',filedata.Properties.VariableNames)) == 1)
    filedata_manufacturer = filedata.Mfr;
end
if (sum(strcmp('Manufacturer',filedata.Properties.VariableNames)) == 1)
    filedata_manufacturer = filedata.Manufacturer;
end

% Write manufacturer name to final data table
new_filedata = addvars(new_filedata, filedata_manufacturer,'NewVariableNames','Manufacturer');


%% Parse manufacturer part number
% Get manufacturer part number data from 'MfrPart_' (or 'ManufacturerPartNumber')
% variable in imported data table
if (sum(strcmp('MfrPart_',filedata.Properties.VariableNames)) == 1)
    filedata_part = filedata.MfrPart_;
end
if (sum(strcmp('ManufacturerPartNumber',filedata.Properties.VariableNames)) == 1)
    filedata_part = filedata.ManufacturerPartNumber;
end

% Write manufacturer part number to final data table
new_filedata = addvars(new_filedata, filedata_part,'NewVariableNames','MfrPartName');


%% Parse inductance value
% The value of inductance is contained within the single digikey variable
% "Inductance". Need to separate the numerical value from the units and
% convert to Henrys.

% Get capacitance data from 'Inductance' variable in imported data table
filedata_inductance = filedata.Inductance;
% Remove potential empty spaces
filedata_inductance = regexprep(filedata_inductance,'\s','');

% Extract numerical values from inductance data
data_ind_num = regexprep(filedata_inductance,'[^\d\.]','');
data_ind_num = str2double(data_ind_num);

% Extract letter values (the units) from inductance data
data_ind_unit = regexprep(filedata_inductance,'[\d\.]','');

% Scale the numerical inductance value based on the units
data_ind_multiplier = zeros(n_rows,1);
k_ind = 1E-12;
data_ind_multiplier = data_ind_multiplier + strcmp(data_ind_unit,'pH')*k_ind;
k_ind = 1E-9;
data_ind_multiplier = data_ind_multiplier + strcmp(data_ind_unit,'nH')*k_ind;
k_ind = 1E-6;
data_ind_multiplier = data_ind_multiplier + (strcmp(data_ind_unit,'µH')|strcmp(data_ind_unit, 'ÂµH'))*k_ind;
k_ind = 1E-3;
data_ind_multiplier = data_ind_multiplier + strcmp(data_ind_unit,'mH')*k_ind;
k_ind = 1;
data_ind_multiplier = data_ind_multiplier + strcmp(data_ind_unit,'H')*k_ind;

% Write inductance values to final data table
new_filedata = addvars(new_filedata,data_ind_num.*data_ind_multiplier,'NewVariableNames','Inductance');
% new_filedata.Capacitance = data_cap_num.*data_cap_multiplier;


%% Parse rated and saturation current value
% Parse rated current value. Is contained within 'CurrentRating_Amps_'
% variable.
if (sum(strcmp('CurrentRating_Amps_',filedata.Properties.VariableNames)) == 1)
    filedata_current_rated = filedata.CurrentRating_Amps_;
end
% Remove potential empty spaces
filedata_current_rated = regexprep(filedata_current_rated,'\s','');
% % There might be multiple (equivalent) values formatted as: 1000V (1kV)
% filedata_voltage = cellfun(@(x)x(:,1),regexp(filedata_voltage,'[^()]*','match')); % Extract and use first value

% Extract numerical values from voltage data
data_amp_num = regexprep(filedata_current_rated,'[^\d\.]','');
data_amp_num = str2double(data_amp_num);

% Extract letter values (the units) from voltage data
data_amp_unit = regexprep(filedata_current_rated,'[\d\.]','');

% Scale the numerical current value based on the units
data_amp_multiplier = zeros(n_rows,1);
k_ind = 1E-6;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'µA')*k_ind;
k_ind = 1E-3;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'mA')*k_ind;
k_ind = 1E0;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'A')*k_ind;
k_ind = 1E3;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'kA')*k_ind;

% Write current values to final data table
new_filedata = addvars(new_filedata,data_amp_num.*data_amp_multiplier,'NewVariableNames','Current_Rated');


%% Parse rated and saturation current value
% Parse saturation current value. Is contained within
% 'Current_Saturation_Isat_' variable.
if (sum(strcmp('Current_Saturation_Isat_',filedata.Properties.VariableNames)) == 1)
    filedata_current_sat = filedata.Current_Saturation_Isat_;
end
% Remove potential empty spaces
filedata_current_sat = regexprep(filedata_current_sat,'\s','');
% % There might be multiple (equivalent) values formatted as: 1000V (1kV)
% filedata_voltage = cellfun(@(x)x(:,1),regexp(filedata_voltage,'[^()]*','match')); % Extract and use first value

% Extract numerical values from voltage data
data_amp_num = regexprep(filedata_current_sat,'[^\d\.]','');
data_amp_num = str2double(data_amp_num);

% Extract letter values (the units) from voltage data
data_amp_unit = regexprep(filedata_current_sat,'[\d\.]','');

% Scale the numerical current value based on the units
data_amp_multiplier = zeros(n_rows,1);
k_ind = 1E-6;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'µA')*k_ind;
k_ind = 1E-3;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'mA')*k_ind;
k_ind = 1E0;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'A')*k_ind;
k_ind = 1E3;
data_amp_multiplier = data_amp_multiplier + strcmp(data_amp_unit,'kA')*k_ind;

% Write voltage values to final data table
new_filedata = addvars(new_filedata,data_amp_num.*data_amp_multiplier,'NewVariableNames','Current_Sat');


%% Parse length, width, diameter, and height dimensional parameters and compute volume

% Get length/width or diameter/height or diameter dimensional
% parameter data from 'Size_Dimension' variable in imported data table
filedata_vol_1 = filedata.Size_Dimension;
% filedata_vol_1 = [{'0.315" Dia (5.00mm)'};{'0.315" Dia (8.010mm)'};{'0.287" L x 0.169" W (7.30mm x 4.30mm)'}]
 
% Parse height dimensional parameter from both 'Height_Seated_Max_',
% 'Thickness_Max_', and 'Height' variables in imported data table.
% A combination of these variables might be defined but only one (or
% neither) contains a valid height parameter.
if (sum(strcmp('Height_Seated_Max_',filedata.Properties.VariableNames)) == 1)
    if (exist('filedata_vol_2','var'))
        filedata_vol_2 = [filedata_vol_2, filedata.Height_Seated_Max_];
    else
        filedata_vol_2 = filedata.Height_Seated_Max_;
    end
end
if (sum(strcmp('Thickness_Max_',filedata.Properties.VariableNames)) == 1)
    if (exist('filedata_vol_2','var'))
        filedata_vol_2 = [filedata_vol_2, filedata.Thickness_Max_];
    else
        filedata_vol_2 = filedata.Thickness_Max_;
    end
end
if (sum(strcmp('Height',filedata.Properties.VariableNames)) == 1)
    if (exist('filedata_vol_2','var'))
        filedata_vol_2 = [filedata_vol_2, filedata.Height];
    else
        filedata_vol_2 = filedata.Height;
    end
end

% Check existence of different dimensional parameters to determine how to
% parse the imported data structure.
id_type_L = ~cellfun(@isempty,regexpi(filedata_vol_1,'L'));
id_type_W = ~cellfun(@isempty,regexpi(filedata_vol_1,'W'));
id_type_Dia = ~cellfun(@isempty,regexpi(filedata_vol_1,'Dia'));
% Define and identify different structure types for dimensional data
id_type_vol_a = logical(id_type_L.*id_type_W); % (L x W)
id_type_vol_b = logical(id_type_Dia.*id_type_L); % (Dia x L)
id_type_vol_c = logical(id_type_Dia.*(~id_type_L)); % (Dia)
% Define shapes (for use in volume computation)
data_shape = cell(size(filedata_vol_1));
data_shape(id_type_vol_a) = {'rect'}; % 2 parameters for rectangular prism (L x W)
data_shape(id_type_vol_b) = {'cyl'}; % 2 parameters for cylinder (Dia x L)
data_shape(id_type_vol_c) = {'cyl'}; % 1 parameter for cylinder (Dia)

% Determine the numerical data enclosed by parenthesis. These represent
% either length/width or diameter/height or diameter parameter in units of mm.
data_vol_1 = regexpi(filedata_vol_1,'(?<=\()[^)]*','match','once');
% Assume units are mm and remove "mm" string
data_vol_1 = regexprep(data_vol_1,'mm','');
% Remove extra spaces
data_vol_1 = regexprep(data_vol_1,'\s','');

% Determine the numerical data enclosed by parenthesis. These represent
% the height parameter in units of mm.
data_vol_2 = regexpi(filedata_vol_2,'(?<=\()[^)]*','match','once');
% Assume units are mm and remove "mm" string
data_vol_2 = regexprep(data_vol_2,'mm','');
% Remove extra spaces
data_vol_2 = regexprep(data_vol_2,'\s','');

% Manually apply "if" statements to cell array to parse data based on
% structure of data string.
string_before_x_Pattern = '[^x]*(?=[^\d\.])'; % Get numerical data before "x"
string_after_x_Pattern = '(?<=[^\d\.])[^x]*'; % Get numerical data after "x"
string_none_Pattern = 'XXX'; % Get no numerical data
string_any_Pattern = '[\S]*'; % Get all numerical data
% Parse "length" dimensional parameter
data_length = cell(size(filedata_vol_1));
data_length(id_type_vol_a) = regexpi(data_vol_1(id_type_vol_a),string_before_x_Pattern,'match','once'); 
data_length(id_type_vol_b) = regexpi(data_vol_1(id_type_vol_b),string_none_Pattern,'match','once'); 
data_length(id_type_vol_c) = regexpi(data_vol_1(id_type_vol_c),string_none_Pattern,'match','once');
% Parse "width" dimensional parameter
data_width = cell(size(filedata_vol_1));
data_width(id_type_vol_a) = regexpi(data_vol_1(id_type_vol_a),string_after_x_Pattern,'match','once'); 
data_width(id_type_vol_b) = regexpi(data_vol_1(id_type_vol_b),string_none_Pattern,'match','once'); 
data_width(id_type_vol_c) = regexpi(data_vol_1(id_type_vol_c),string_none_Pattern,'match','once');
% Parse "diameter" dimensional parameter
data_dia = cell(size(filedata_vol_1));
data_dia(id_type_vol_a) = regexpi(data_vol_1(id_type_vol_a),string_none_Pattern,'match','once'); 
data_dia(id_type_vol_b) = regexpi(data_vol_1(id_type_vol_b),string_before_x_Pattern,'match','once'); 
data_dia(id_type_vol_c) = regexpi(data_vol_1(id_type_vol_c),string_any_Pattern,'match','once');
% Parse "height" dimensional parameter
data_height = cell(size(filedata_vol_2));
data_height(id_type_vol_a,:) = regexpi(data_vol_2(id_type_vol_a,:),string_any_Pattern,'match','once');
data_height(id_type_vol_b,1) = regexpi(data_vol_1(id_type_vol_b),string_after_x_Pattern,'match','once');
data_height(id_type_vol_c,:) = regexpi(data_vol_2(id_type_vol_c,:),string_any_Pattern,'match','once');

% Reformat dimensional parameters into usable units
% Length
data_length = str2double(data_length);
data_length = data_length*1E-3; % Convert to meters
data_length(isnan(data_length)) = 0;
% Width
data_width = str2double(data_width);
data_width = data_width*1E-3; % Convert to meters
data_width(isnan(data_width)) = 0;
% Diameter
data_dia = str2double(data_dia);
data_dia = data_dia*1E-3; % Convert to meters
data_dia(isnan(data_dia)) = 0;
% Height
data_height = str2double(data_height);
data_height = data_height*1E-3; % Convert to meters
data_height(isnan(data_height)) = 0;
% Take (potentially) multi-column array (for height and thickness) and
% condense it down to a 1 column vector because there is only one (or no)
% nonzero height or thickness parameter.
data_height = sum(data_height,2);

% Compute volume from dimensional parameters and component shape
data_vol = cellfun(@func_ComputeCapacitorVolume, data_shape,...
    mat2cell([data_height,data_length,data_width,data_dia],ones(1,length(filedata_vol_2))));

% Write volume value to final data table
new_filedata = addvars(new_filedata,data_vol,'NewVariableNames','Volume');


%% Parse package identifier
% The package idenitifier is contained within the single digikey variable
% "Package_Case".
% Currently only compatible for SMD type components.
% Need to separate the numerical value from the metric value in parenthesis.

% Get package data from 'Package_Case' variable in imported data table
filedata_package = filedata.Package_Case;
% Remove empty spaces and contents of parenthesis (if present)
% data_package = regexpi(filedata_package,'[^(]*(?=\()','match','once');
data_package = regexpi(filedata_package,'[\w]*(?=\s\()','match','once');

% Write package identifier to final data table
new_filedata = addvars(new_filedata,data_package,'NewVariableNames','Package');


%% Parse unit cost
% The value of per unit cost is contained within the single digikey
% variable "Price" or "UnitPrice_USD_". For fairness, should account for
% bulk costs. This information is contained within the digikey variable
% "MinQty" or "Minimum Quantity".

% Get unit cost data from 'Price' (or 'UnitPrice_USD_) variable in imported
% data table
if (sum(strcmp('Price',filedata.Properties.VariableNames)) == 1)
    filedata_unitcost = filedata.Price;
end
if (sum(strcmp('UnitPrice_USD_',filedata.Properties.VariableNames)) == 1)
    filedata_unitcost = filedata.UnitPrice_USD_;
end
% filedata_unitcost = cellstr(num2str(filedata_unitcost)); % Convert to cell array of character strings
% Extract numerical values from cost data. Sometimes contains useless
% strings which makes data a cell array of character strings.
if isa(filedata_unitcost,'double')
    data_unitcost_num = filedata_unitcost;
elseif isa(filedata_unitcost,'cell')
    data_unitcost_num = regexprep(filedata_unitcost,'[^\d\.]','');
    data_unitcost_num = str2double(data_unitcost_num);
end

% Get minimum purchase quantity from 'MinQty' (or 'MinimumQuantity')
% variable in imported data table
if (sum(strcmp('MinQty',filedata.Properties.VariableNames)) == 1)
    filedata_minqty = filedata.MinQty;
end
if (sum(strcmp('MinimumQuantity',filedata.Properties.VariableNames)) == 1)
    filedata_minqty = filedata.MinimumQuantity;
end
% Extract numerical values from min quantity data. Sometimes contains
% useless strings which makes data a cell array of character strings.
if isa(filedata_minqty,'double')
    data_minqty_num = filedata_minqty;
elseif isa(filedata_minqty,'cell')
    data_minqty_num = regexprep(filedata_minqty,'[^\d\.]','');
    data_minqty_num = str2double(data_minqty_num);
end

% Only include components below the specified minimum quantity. Do not want
% to include bulk prices.
i = (data_minqty_num<=1);
data_unitcost_num(~i) = NaN;

% Write cost values to final data table
new_filedata = addvars(new_filedata,data_unitcost_num,'NewVariableNames','UnitCost');


%% Computed variables

% Minimum operational current (min of rated and saturated current)
current_min = min(new_filedata.Current_Rated,new_filedata.Current_Sat,'omitnan');
new_filedata = addvars(new_filedata,current_min,'NewVariableNames','Current_Min');

% Energy (rated current) in units of (J)
data_energy = 1/2*new_filedata.Inductance.*(new_filedata.Current_Rated).^2;
new_filedata = addvars(new_filedata,data_energy,'NewVariableNames','Energy_Rated');
% Energy (saturated current) in units of (J)
data_energy = 1/2*new_filedata.Inductance.*(new_filedata.Current_Sat).^2;
new_filedata = addvars(new_filedata,data_energy,'NewVariableNames','Energy_Sat');
% Energy (min current) in units of (J)
data_energy = 1/2*new_filedata.Inductance.*(new_filedata.Current_Min).^2;
new_filedata = addvars(new_filedata,data_energy,'NewVariableNames','Energy_Min');

% Energy density (energy/volume) in units of (J/m^3)
% data_energydensity = new_filedata.Energy_Rated./new_filedata.Volume;
% data_energydensity = new_filedata.Energy_Sat./new_filedata.Volume;
data_energydensity = new_filedata.Energy_Min./new_filedata.Volume;
data_energydensity(new_filedata.Volume == 0) = NaN;
new_filedata = addvars(new_filedata,data_energydensity,'NewVariableNames','EnergyDensity');

% % Farad density (farads/volume) in units of (F/m^3)
% data_faraddensity = new_filedata.Capacitance./new_filedata.Volume;
% data_faraddensity(new_filedata.Volume == 0) = NaN;
% new_filedata = addvars(new_filedata,data_faraddensity,'NewVariableNames','FaradDensity');


%% Refine Data (remove invalid components)
% Remove NaN
m = (~isnan(new_filedata.EnergyDensity));
new_filedata = new_filedata(m,:);
% Remove zeros
m = (~(new_filedata.EnergyDensity == 0));
new_filedata = new_filedata(m,:);


%% Output
output_table = new_filedata;


end


%% func_ComputeCapacitorVolume.m
% Inline function for use in cellfun applied to cell array.
% Computes volume of components from dimensional parameters and shape.
function outputVolume = func_ComputeCapacitorVolume(inputShape,inputParams)
%   First input is the shape of the capacitor. Two options are character
%       arrays 'rect' for rectangular prism or 'cyl' for cylinder.
%   Second input is an array of doubles which contains all possible
%   parameters in the following order:
%       - inputParams = [height, length, width, diameter]
%   Returns the volume of the shape based on the given parameters.

if (strcmp(inputShape,'rect'))
    height = inputParams(1);
    length = inputParams(2);
    width = inputParams(3);
    volume = height*length*width;
elseif (strcmp(inputShape,'cyl'))
    height = inputParams(1);
    diameter = inputParams(4);
    volume = height*pi*(diameter/2).^2;
else % Undefined shape (not enough dimensional data)
    volume = NaN;
end

outputVolume = volume;

end