function output_table = func_ParseCapacitorPages(input_filename, input_foldername)
%% funcParseCapacitorPages.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 11/15/19
%   Last Revision: 3/6/22
%
%   File Description:
%       This function parses component data from digikey file export. It
%       also computes relevant metrics (type, manufacturer part number,
%       capacitance, rated voltage, volume, energy density, and farad
%       density).
%       Currently only parses capacitor components. Specifically tested
%       with aluminum-type and C0G/NP0-type capacitors.
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
% % input_filename = 'Alumpoly_11082019.csv';
% % input_filename = 'Alumelec_11152019.csv';
% % input_filename = 'C0GNP0_03222021.csv';
% % inputFilename = 'Test.csv';
% % input_filename = 'FilmAcrylic_03282021.csv';
% % input_filename = 'Tantalum_03282021.csv';
% % input_filename = 'TantalumPoly_03282021.csv';
% % input_filename = 'AlumPoly_03282021.csv';
% % input_filename = 'AlumElec_03282021.csv';
% % input_filename = 'C0GNP0_03222021.csv';
% input_filename = 'Ceramic_20211111.csv';
% % input_filename = 'PowerCeramic_10142021.csv';
% % input_filename = 'FilmPolyester_03282021.csv';
% % input_filename = '';
% 
% input_foldername = 'RawData_Digikey';
% 
% % profile on
% % profile viewer
% % profsave
% % profile off

%% Import data from .csv
% Determine if write and read paths are valid
if ~exist('input_foldername','var')
    parentPath = pwd;
else
    parentPath = fullfile(pwd,input_foldername);
end

inputFilepath = fullfile(parentPath,input_filename);

% Try to read data from csv file if exists
filepath = inputFilepath;
try % Valid filename
    filedata = readtable(filepath);
    [n_rows, n_vars] = size(filedata);
    error_filename = 'valid';
catch % Invalid filename
    n_rows = 1;
    error_filename = 'invalid';
end

% Only works with R2018a or later
% Pre-allocation of table and variables
% new_filedata = table('Size',[n_rows, 3],...
%     'VariableTypes',{'char','double','double'},...
%     'VariableNames',{'Tech','Capacitance','Voltage'});

% Configure file which converts temperature characteristics to class
% identifiers. Assume it's in the same folder as the main raw data.
filename_tempChar = 'Ceramic_TC.csv';
filename_tempChar = fullfile(parentPath,filename_tempChar);


%% Parse capacitor data

if strcmp(error_filename, 'valid') % Valid filename
    % Parse capacitor technology names from input file name
    data_tech = func_parseCapacitor_Tech(filedata, input_filename);
    filedata_tech = data_tech{1};
    % Parse custom type identifiers from filename and internal file data
    % (e.g., Description, Type, Features, Package, etc.)
    data_type = func_parseCapacitor_Type(filedata, filedata_tech, filename_tempChar);
    % Parse manufacturer names from file data
    data_manufacturer = func_parseCapacitor_Manufacturer(filedata);
    % Parse manufacturer part names from file data
    data_part = func_parseCapacitor_MfrPartName(filedata);
    % Parse capacitance value from file data
    data_capacitance = func_parseCapacitor_Capacitance(filedata);
    % Parse rated dc voltage value from file data
    data_voltage = func_parseCapacitor_VoltageRatedDC(filedata);
    % Parse ESR (and frequency) from file data
    data_ESR = func_parseCapacitor_ESR(filedata, filedata_tech, data_type);
    % Parse rated rms current (and frequency) at low and high frequency from file data
    [data_currLF, data_currHF] = func_parseCapacitor_CurrentRatedRMS(filedata, filedata_tech);
    % Parse dimensional parameters and compute volume from file data
    data_vol = func_parseCapacitor_Volume(filedata);
    % Parse package identifier from file data
    data_package = func_parseCapacitor_Package(filedata);
    % Parse per unit cost from file data
    data_unitcost = func_parseCapacitor_UnitCost(filedata);
else % Invalid filename
    % Create empty table entries
    data_tech = repmat({''},n_rows,1);
    data_type = repmat({''},n_rows,1);
    data_manufacturer = repmat({''},n_rows,1);
    data_part = repmat({''},n_rows,1);
    data_capacitance = nan(n_rows, 1);
    data_voltage = nan(n_rows, 1);
    data_ESR = nan(n_rows, 2);
    data_currLF = nan(n_rows, 2);
    data_currHF = nan(n_rows, 2);
    data_vol = nan(n_rows, 1);
    data_package = repmat({''},n_rows,1);
    data_unitcost = nan(n_rows, 1);
end

%% Construct new data table from parsed file data

new_filedata = table(data_tech, 'VariableNames', {'Tech'});
new_filedata = addvars(new_filedata, data_type, 'NewVariableNames', 'Type');
new_filedata = addvars(new_filedata, data_manufacturer, 'NewVariableNames', 'Manufacturer');
new_filedata = addvars(new_filedata, data_part, 'NewVariableNames', 'MfrPartName');
new_filedata = addvars(new_filedata, data_capacitance, 'NewVariableNames', 'Capacitance');
new_filedata = addvars(new_filedata, data_voltage, 'NewVariableNames', 'VoltageRatedDC');
new_filedata = addvars(new_filedata, data_ESR, 'NewVariableNames', 'ESR');
new_filedata = addvars(new_filedata, data_currLF, 'NewVariableNames', 'CurrentRatedLF');
new_filedata = addvars(new_filedata, data_currHF, 'NewVariableNames', 'CurrentRatedHF');
new_filedata = addvars(new_filedata, data_vol, 'NewVariableNames', 'Volume');
new_filedata = addvars(new_filedata, data_package, 'NewVariableNames', 'Package');
new_filedata = addvars(new_filedata, data_unitcost, 'NewVariableNames', 'UnitCost');


%% Computed variables

% % TODO: Derate the dc energy of Class 2 ceramics
% % k = C(Vr)/C(0) derating ratio; k2 = Ce(Vr)/C(0)
% % -> k=0.8, k2=0.89; k=0.6, k2=0.76; k=0.4, k2=0.6; k=0.2, k=0.38
% 
% % Energy units of (J)
% data_energy = 1/2*new_filedata.Capacitance.*(new_filedata.VoltageRatedDC).^2;
% new_filedata = addvars(new_filedata,data_energy,'NewVariableNames','Energy');
% % new_filedata.Energy = 
% 
% % Energy density (energy/volume) in units of (J/m^3)
% data_energyDensity = new_filedata.Energy./new_filedata.Volume;
% data_energyDensity(new_filedata.Volume == 0) = NaN;
% new_filedata = addvars(new_filedata,data_energyDensity,'NewVariableNames','EnergyDensity');
% 
% % Farad density (farads/volume) in units of (F/m^3)
% data_faradDensity = new_filedata.Capacitance./new_filedata.Volume;
% data_faradDensity(new_filedata.Volume == 0) = NaN;
% new_filedata = addvars(new_filedata,data_faradDensity,'NewVariableNames','FaradDensity');
% 
% % Farad per cost (farads/cost) in units of (F/$)
% data_faradDollar = new_filedata.Capacitance./new_filedata.UnitCost;
% new_filedata = addvars(new_filedata,data_faradDollar,'NewVariableNames','FaradDollar');
% 
% % Dissipation factor (tan \delta) in units of [unitless]
% % Normalize the ESR to 120 Hz at low frequencies (buffering applications). Custom function.
% % Only normalize for tanD for ESR defined below 120 Hz.
% ESR_R_adjusted = new_filedata.ESR(:,1);
% ESR_f_adjusted = new_filedata.ESR(:,2);
% % ESR_R_adjusted(ESR_f_adjusted<=120) = ESR_R_adjusted(ESR_f_adjusted<=120).*((120./ESR_f_adjusted(ESR_f_adjusted<=120)).^(0.5)); 
% % ESR_f_adjusted(ESR_f_adjusted<=120) = 120; % Saturate to the normalized frequency
% % ESR_f_adjusted(ESR_f_adjusted>120) = 100e3; % Saturate to a normalized switching frequency
% % data_tanD = (2*pi*ESR_f_adjusted).*ESR_R_adjusted.*new_filedata.Capacitance;
% data_tanD = ESR_R_adjusted.*new_filedata.Capacitance; % Do not include frequency
% new_filedata = addvars(new_filedata,data_tanD,'NewVariableNames','tanD');


%% Refine Data (remove invalid components)
% % Remove NaN
% m = (~isnan(new_filedata.EnergyDensity));
% new_filedata = new_filedata(m,:);
% % Remove zeros
% m = (~(new_filedata.EnergyDensity == 0));
% new_filedata = new_filedata(m,:);


%% Output
output_table = new_filedata;


end


%% func_parseCapacitor_Tech.m
% Inline function which parses capacitor technology from filename data.
function output_data_tech = func_parseCapacitor_Tech(input_filedata, input_filename)
%   First input is the imported table of data from digikey.
%   Second input is the filename.
%   Returns an array containing the manufacturer name for each component.

%   Currently tech information is pre-parsed with the user-defined filename.

    % Initialize input(s)
    filedata = input_filedata;
    filename = input_filename;
    [n_rows, ~] = size(filedata);
    
    % Initialize final character string identifiers for concatenation
    data_tech = cell(n_rows, 1);
    data_tech(:) = {''};

    % Determine type based off of the user-defined aggregated file names for
    % each type (roughly 10 or so from digikey). Assumes a specific filenaming
    % convention from user: "######\type_########.csv"
    filedata_tech = input_filename(1:regexp(filename,'_') - 1);
    % filedata_tech_1 = regexprep(inputFilename,'\.csv','');
    % filedata_tech_1 = regexprep(filedata_tech_1,'_','');
    % filedata_tech_1 = regexprep(filedata_tech_1,'\d','');

    % Write tech values to final data table
    data_tech(:) = {filedata_tech};
    
    % Return output(s)
    output_data_tech = data_tech;

end

%% func_parseCapacitor_Type.m
% Inline function which parses capacitor type from imported data.
function output_data_type = func_parseCapacitor_Type(input_filedata, input_filedata_tech, input_filename_tempChar)
%   First input is the imported table of data from digikey.
%   Second input is the technology identifier (taken from filename).
%   Third input is the filename of the csv temperature characteristic to
%       class conversion (only applicable to ceramic capacitors).
%   Returns an array containing a custom type identifier for each component.
% 
%   Type determination is very dependent on the capacitor technology.
%   Each technology has sub-type information stashed away in various and
%   differed locations within the data table.
%     
%   The string denoting the capacitor type is always within the digikey
%   variable "Description" and sometimes "Type" , "Features",
%   "Temperature Coefficient", and "Package_Case". "Type", "Features",
%   "Temperature Coefficient" may not exist for certain capacitor types
%   (e.g., aluminum electrolytic).
% 
%   Ended up scrapping the generalized implementation b/c some
%   electrolyctic capacitors do not include any identifiers besides being
%   associated with the search results in digikey (and thus the aggregated 
%   "Alumelec" file). Plus, some capacitors have bad descriptions.

    % Initialize input(s)
    filedata = input_filedata;
    filedata_tech = input_filedata_tech;
    filename_tempChar = input_filename_tempChar;
    [n_rows, ~] = size(filedata);
    
    % Main "Description" identifier
    filedata_type_1 = filedata.Description;
    % Identify unique character strings from the capacitor "Description" by
    % removing all redundant character strings (i.e., "CAP", "CAPACITOR",
    % "SMD", "T/H", "RADIAL", "%", ".", " ") parameter numerics and
    % units. These lines of code aren't really necessary for the later
    % selection to take place.
    % filedata_type_1 = regexprep(filedata_type_1,'CAPACITOR','');
    filedata_type_1 = regexprep(filedata_type_1, 'CAP*', '');
    filedata_type_1 = regexprep(filedata_type_1, 'SMD', '');
    filedata_type_1 = regexprep(filedata_type_1, 'T/H', '');
    filedata_type_1 = regexprep(filedata_type_1, 'RADIAL', '');
    filedata_type_1 = regexprep(filedata_type_1, '\%', '');
    filedata_type_1 = regexprep(filedata_type_1, '\.', '');
    filedata_type_1 = regexprep(filedata_type_1, '\d', ''); % Remove numerics
    filedata_type_1 = regexprep(filedata_type_1, ' UF', '');
    filedata_type_1 = regexprep(filedata_type_1, ' V', '');
    filedata_type_1 = regexprep(filedata_type_1, '\s', ''); % Remove whitespace
    
    
    % "Type" identifier (aluminum polymer, aluminum polymer hybrid, tantalum)
    if ismember('Type', filedata.Properties.VariableNames)
        filedata_type_2 = filedata.Type;
    else
        filedata_type_2 = cell(n_rows, 1);
        filedata_type_2(:) = {''};
    end

    % "Features" identifier (tantalum, tantalum polymer)
    if ismember('Features', filedata.Properties.VariableNames)
        filedata_type_3 = filedata.Features;
    else
        filedata_type_3 = cell(n_rows, 1);
        filedata_type_3(:) = {''};
    end

    % "TemperatureCoefficient" identifier (ceramic)
    if ismember('TemperatureCoefficient', filedata.Properties.VariableNames)
        filedata_type_4 = filedata.TemperatureCoefficient;
        % Convert temperature characteristic to a 'Class' identifier
        filedata_type_4b = func_parseCapacitor_TempChar(filedata, filedata_type_4, filename_tempChar);
        filedata_type_4 = filedata_type_4b; % Overwrite the existing TC data
        
%         % Grab only the primary temperature characteristic and neglect additional
%         % identifiers contained within parenthesis or after comma.
%         i = ~cellfun(@isempty, regexp(filedata_type_4, '\(')); % Exclude parenthesis  
%         filedata_type_4(i) = regexp(filedata_type_4(i), '.*(?=\()', 'match', 'once');   
%         i = ~cellfun(@isempty, regexp(filedata_type_4, '\,')); % Exclude comma
%         filedata_type_4(i) = regexp(filedata_type_4(i), '.*(?=\,)', 'match', 'once');
%         filedata_type_4 = regexprep(filedata_type_4, '\s', ''); % Remove whitespace
%         i = ~cellfun(@isempty, regexp(filedata_type_4, '\-')); % Treat '-' as empty
%         filedata_type_4(i) = regexprep(filedata_type_4(i), '\-', '');
    else
        filedata_type_4 = cell(n_rows, 1);
        filedata_type_4(:) = {''};
    end
    
    % "Package_Case" identifier (for sorting power ceramics)
    if ismember('Package_Case', filedata.Properties.VariableNames)
        filedata_type_5 = filedata.Package_Case;
    else
        filedata_type_5 = cell(n_rows, 1);
        filedata_type_5(:) = {''};
    end
    
    % Initialize type and sub-type identifiers
    data_type_a = cell(n_rows, 1);
    data_type_a(:) = {''};
    data_type_b = cell(n_rows, 1);
    data_type_b(:) = {''};
    data_type_c = cell(n_rows, 1);
    data_type_c(:) = {''};

    %% Parse primary capacitor type identifier and sub-type(s)
    % Narrow down to primary capacitor type
    i = ~cellfun(@isempty,regexpi(filedata_type_1, 'ALUM'));
    data_type_a(i) = {'ALUM'};
    i = ~cellfun(@isempty,regexpi(filedata_type_1, 'TANT'));
    data_type_a(i) = {'TANT'};
    i = ~cellfun(@isempty,regexpi(filedata_type_1, 'CER'));
    data_type_a(i) = {'CER'};
    % Overwrite type if technology specifier (from filename) is ceramic
    if strcmp(filedata_tech, 'Ceramic')
        data_type_a(:) = {'CER'};
    end

    % Narrow down to sub-type
    % Check #1 (in "Description")
    i = ~cellfun(@isempty,regexpi(filedata_type_1, 'POLY'));
    data_type_b(i) = {'POLY'};
    % % Check #2 (in "Type")
    % i = ~cellfun(@isempty,regexpi(filedata_type_2, 'POLY'));
    % data_type_b(i) = {'POLY'};

    % Isolate 'polymer' from 'wet' sub-type in digi-key's "Tantalum" (and
    % perhaps "TantalumPoly") product search category.
    if (strcmp(filedata_tech, 'Tantalum') | strcmp(filedata_tech, 'TantalumPoly'))
        % The "Wet Tantalum" identifier in the "Features" variable always
        % corresponds to the 'wet' sub-type. The "High Reliability" identifier
        % in the "Features" variable with the "Hermetically Sealed" identifier
        % in the "Type" variable always corresponds to the 'wet' sub-type.
        % Everything else is of the 'polymer' sub-type.
        i1 = ~cellfun(@isempty,regexpi(filedata_type_3, 'Wet Tantalum'));
        i2 = ~cellfun(@isempty,regexpi(filedata_type_3, 'High Reliability'));
        i3 = ~cellfun(@isempty,regexpi(filedata_type_2, 'Hermetically Sealed'));
        i = i1|(i2&i3);
        data_type_b(i) = {'WET'};
        data_type_b(~i) = {'POLY'};
    end

    % Narrow down to hybrid sub-type
    i = ~cellfun(@isempty,regexpi(filedata_type_2, 'HYBRID'));
    data_type_b(i) = {'HYB'};
    % For 'ALUM' type, if not 'polymer' or 'hybrid' sub-type, then 'wet' sub-type
    i = (strcmp(data_type_a, 'ALUM') & cellfun(@isempty,data_type_b));
    data_type_b(i) = {'WET'};

    % Isolate 'power' sub-type in digi-key's "Ceramic" product search category.
    % Method #1:
    % Archaic now. Relies on files being pre-parsed into power
    % (and non-power) ceramics.
    if (strcmp(filedata_tech, 'PowerCeramic'))
        data_type_b(:) = {'POWER'};
    end
    % Method #2:
    % Exclusive list of all of the package identifiers which define 'power'
    % sub-type ceramic capacitors.
%     'Axial' and 'Axial, Can' but above 500 V 
    id_powerCeramic = {'Axial, Can - Threaded',...
        'Disk, Metal Fitting', 'Disk, Metal Fitting - Threaded',...
        'Nonstandard, Screw Terminals', 'Nonstandard, Tabbed'};
    % Identify ceramic capacitors which are 'power' sub-type
    i = ismember(filedata_type_5, id_powerCeramic);
    data_type_b(i) = {'POWER'};
%     data_type_b(~i) = {''};

    % Assign temperature characteristic to type variable
    i = ~cellfun(@isempty,regexpi(data_type_a, 'CER'));
    data_type_c(i) = filedata_type_4(i);
    
    %% Concatenate full type string. Presumes a is always filled, then b, then c
    data_type = data_type_a;
    % Create joining character (if necessary)
    char_mid = cell(n_rows, 1);
    char_mid(:) = {''};
    % i = (~cellfun(@isempty,data_type_a) | ~cellfun(@isempty,data_type_b));
    i = ~cellfun(@isempty,data_type_b);
    char_mid(i) = {'_'};
    data_type = strcat(data_type,char_mid,data_type_b);
    % Reset joining character
    char_mid(:) = {''};
    i = ~cellfun(@isempty,data_type_c);
    char_mid(i) = {'_'};
    data_type = strcat(data_type,char_mid,data_type_c);
    
    %% Return
    % Return output(s)
    output_data_type = data_type;

end

%% func_parseCapacitor_TempChar.m
% Inline function which converts capacitor temperature characteristic of
% ceramic capacitor to an EIA 'Class' identifieer.
function output_filedata_tempCharClass = func_parseCapacitor_TempChar(input_filedata, input_filedata_tempChar, input_filename_tempChar)
%   First input is the raw imported table of data from digikey.
%   Second input is the temperature characteristic data associated with the
%       raw data.
%   Third input is the filename containing the TC to Class identifier conversion data. 
%   Returns an array containing the EIA temperature characteristic 'Class' for each component.
%       -   Either 'C1' (Class 1), 'C2' (Class 2), 'C3' (Class 3), or 'NA'
%           (for not available).
    
    %% Debug
%     % Import TC to Class conversion data from file
%     filename_tempChar = 'Ceramic_TC.csv';
%     input_filename_tempChar = fullfile(pwd,'RawData_Digikey',filename_tempChar);
%     tempCharTable = readtable(filename_tempChar,'Delimiter',{','},'ReadVariableNames',false);

    %%
    % Initialize input(s)
    filedata = input_filedata;
    filedata_tempChar = input_filedata_tempChar;
    filename_tempChar = input_filename_tempChar;
    
    % Import TC to Class data from file
    tempCharTable = readtable(filename_tempChar,'Delimiter',{','},'ReadVariableNames',false);
    
    % Parse manufacturer names from file data
    data_manufacturer = func_parseCapacitor_Manufacturer(filedata);
    
    % Iterate through entire TC/Class table and make the conversion for
    % each entry of the main data table.
    data_tempCharClass = cell(size(filedata_tempChar)); % Initialize
    for j = 1:height(tempCharTable)
        % Speed up computation if there are no manufacturer-specific stipulations
        if cellfun(@isempty, tempCharTable(j,:).Var3)
            i = any(ismember(filedata_tempChar,tempCharTable(j,:).Var1),2);
            % Determine the Class ID from the TC and assign
            data_tempCharClass(i) = tempCharTable(j,:).Var2;
        else
            % If a manufacturer is stipulated in TC/Class table then
            % adjust Class ID for this particular case.
            i1 = any(ismember(filedata_tempChar,tempCharTable(j,:).Var1),2);
            i2 = ~cellfun(@isempty,regexpi(data_manufacturer,tempCharTable(j,:).Var3));
            % Determine the Class ID from the TC and manufacturer name and assign
            data_tempCharClass(i1&~i2) = tempCharTable(j,:).Var2;
            data_tempCharClass(i1&i2) = tempCharTable(j,:).Var4;
        end
    end
    
    % Return output(s)
    output_filedata_tempCharClass = data_tempCharClass;

end

%% func_parseCapacitor_Manufacturer.m
% Inline function which parses capacitor manufacturer from imported data.
function output_data_manufacturer = func_parseCapacitor_Manufacturer(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the manufacturer name for each component.

    % Initialize input(s)
    filedata = input_filedata;

    % Get manufacturer name data from 'Mfr' (or 'Manufacturer') variable
    % in imported data table.
    if (sum(strcmp('Mfr', filedata.Properties.VariableNames)) == 1)
        data_manufacturer = filedata.Mfr;
    end
    if (sum(strcmp('Manufacturer', filedata.Properties.VariableNames)) == 1)
        data_manufacturer = filedata.Manufacturer;
    end
    
    % Return output(s)
    output_data_manufacturer = data_manufacturer;

end

%% func_parseCapacitor_MfrPartName.m
% Inline function which parses capacitor manufacturer part name from
% imported data.
function output_data_part = func_parseCapacitor_MfrPartName(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the manufacturer part name for each component.

    % Initialize input(s)
    filedata = input_filedata;

    % Get manufacturer part name from 'MfrPart_'
    % (or 'ManufacturerPartNumber') variable in imported data table.
    if (sum(strcmp('MfrPart_', filedata.Properties.VariableNames)) == 1)
        data_part = filedata.MfrPart_;
    end
    if (sum(strcmp('ManufacturerPartNumber', filedata.Properties.VariableNames)) == 1)
        data_part = filedata.ManufacturerPartNumber;
    end
    
    % Return output(s)
    output_data_part = data_part;

end

%% func_parseCapacitor_Capacitance.m
% Inline function which parses capacitance from imported data.
function output_data_capacitance = func_parseCapacitor_Capacitance(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the capacitance for each component.
%
%   The value of capacitance is contained within the single digikey variable
%   "Capacitance". Need to separate the numerical value from the units and
%   convert to SI units of Farads.

    % Initialize input(s)
    filedata = input_filedata;
    [n_rows, ~] = size(filedata);

    % Get capacitance data from 'Capacitance' variable in imported data table
    filedata_capacitance = filedata.Capacitance;
    % Remove potential empty spaces
    filedata_capacitance = regexprep(filedata_capacitance, '\s', '');

    % Extract numerical values from capacitance data
    data_cap_num = regexprep(filedata_capacitance, '[^\d\.]', '');
    % Convert from characters to doubles
    data_cap_num = cellfunc_str2double(data_cap_num);    

    % Extract letter values (the units) from capacitance data
    data_cap_unit = regexprep(filedata_capacitance, '[\d\.]', '');

    % Scale the numerical capacitance value based on the units
    data_cap_multiplier = zeros(n_rows,1);
    k_cap = 1E-12;
    data_cap_multiplier = data_cap_multiplier + strcmp(data_cap_unit, 'pF')*k_cap;
    k_cap = 1E-9;
    data_cap_multiplier = data_cap_multiplier + strcmp(data_cap_unit, 'nF')*k_cap;
    k_cap = 1E-6;
    data_cap_multiplier = data_cap_multiplier + (strcmp(data_cap_unit, 'µF')|strcmp(data_cap_unit, 'ÂµF'))*k_cap;
    k_cap = 1E-3;
    data_cap_multiplier = data_cap_multiplier + strcmp(data_cap_unit, 'mF')*k_cap;
    k_cap = 1;
    data_cap_multiplier = data_cap_multiplier + strcmp(data_cap_unit, 'F')*k_cap;

    % Construct total numerical value
    data_cap_total = data_cap_num.*data_cap_multiplier;
    data_cap_total(data_cap_total == 0) = NaN; % Remove null values
    
    % Return output(s)
    output_data_capacitance = data_cap_total;

end

%% func_parseCapacitor_VoltageRatedDC.m
% Inline function which parses capacitor rated dc voltage from imported data.
function output_data_voltage = func_parseCapacitor_VoltageRatedDC(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the rated dc voltage for each component.
%
%   The value of rated dc voltage is contained within one of a few possible
%   digikey variables. Need to separate the numerical value from the units
%   and convert to SI units of Volts.

    % Initialize input(s)
    filedata = input_filedata;
    [n_rows, ~] = size(filedata);
    
    % Parse rated DC voltage from 'Voltage_Rated', 'VoltageRating_DC', or
    % 'Voltage_Breakdown' in imported data table. As of now, only one variable
    % is ever defined.
    if (sum(strcmp('Voltage_Breakdown', filedata.Properties.VariableNames)) == 1)
        filedata_voltage = filedata.Voltage_Breakdown;
    end
    if (sum(strcmp('Voltage_Rated', filedata.Properties.VariableNames)) == 1)
        filedata_voltage = filedata.Voltage_Rated;
    end
    if (sum(strcmp('VoltageRating_DC', filedata.Properties.VariableNames)) == 1)
        filedata_voltage = filedata.VoltageRating_DC;
    end
    % Remove potential empty spaces
    filedata_voltage = regexprep(filedata_voltage, '\s', '');
    % There might be multiple (equivalent) values formatted as: 1000V (1kV)
    filedata_voltage = cellfun(@(x)x(:,1),regexp(filedata_voltage, '[^()]*', 'match')); % Extract and use first value

    % Extract numerical values from voltage data
    data_volt_num = regexprep(filedata_voltage, '[^\d\.]', '');
    % Convert from characters to doubles
    data_volt_num = cellfunc_str2double(data_volt_num);

    % Extract letter values (the units) from voltage data
    data_volt_unit = regexprep(filedata_voltage, '[\d\.]', '');

    % Scale the numerical voltage value based on the units
    data_volt_multiplier = zeros(n_rows,1);
    k_volt = 1E-3;
    data_volt_multiplier = data_volt_multiplier + strcmp(data_volt_unit, 'mV')*k_volt;
    k_volt = 1E0;
    data_volt_multiplier = data_volt_multiplier + strcmp(data_volt_unit, 'V')*k_volt;
    k_volt = 1E3;
    data_volt_multiplier = data_volt_multiplier + strcmp(data_volt_unit, 'kV')*k_volt;

    % Construct total numerical value
    data_volt_total = data_volt_num.*data_volt_multiplier;
    data_volt_total(data_volt_total == 0) = NaN; % Remove null values
    
    % Return output(s)
    output_data_voltage = data_volt_total;

end

%% func_parseCapacitor_ESR.m
% Inline function which parses capacitor ESR from imported data.
function output_data_ESR = func_parseCapacitor_ESR(input_filedata, input_filedata_tech, input_filedata_type)
%   First input is the imported table of data from digikey.
%   Second input is the technology identifier (taken from filename).
%   Third input is the custom type identifier for each element of the file data.
%   Returns an array containing the [ESR, frequency] for each component.

%   The value of equivalent series resistance (ESR) is contained within the
%   single digikey variable "ESR_EquivalentSeriesResistance_". Need to
%   separate the resistance value from the frequency value and then the
%   numerical value from the units for each.

%   TODO: Check ESR parsing for all capacitor types besides aluminum
%   electrolytics.

    % Initialize input(s)
    filedata = input_filedata;
    filedata_tech = input_filedata_tech;
    filedata_type = input_filedata_type;
    [n_rows, ~] = size(filedata);


    % Implementation currently works for aluminum electrolytic capacitor
    % types
    if ~isempty(regexp(filedata_tech,'(Alum)', 'once'))
        % Parse ESR data from 'ESR_EquivalentSeriesResistance_' variable in imported data table
        if (sum(strcmp('ESR_EquivalentSeriesResistance_', filedata.Properties.VariableNames)) == 1)
            filedata_ESR = filedata.ESR_EquivalentSeriesResistance_;
        end
        % Get resistance data before '@' symbol
        data_ESR_a = regexp(filedata_ESR, '.*(?=@)', 'match', 'once');
        % Re-incorporate the cases without a frequency (and an @ symbol)
        data_ESR_a_index = (cellfun(@isempty,regexp(filedata_ESR, '\-', 'match', 'once'))...
            & cellfun(@isempty,regexpi(filedata_ESR, '@', 'match', 'once')));
%         a = [filedata_ESR, num2cell(data_ESR_a_index)]; % Debugging
        data_ESR_a(data_ESR_a_index) = filedata_ESR(data_ESR_a_index);
        % Parse numeric data
        data_ESR_a_num = regexp(data_ESR_a, '[\d\.]*', 'match', 'once');
        data_ESR_a_num = cellfunc_str2double(data_ESR_a_num);
        % Parse units
        data_ESR_a_unit = regexp(data_ESR_a, '[^\d\.\s]*', 'match', 'once');
        % Scale the numerical resistance value based on the units
        data_ESR_a_multiplier = zeros(n_rows,1);
        k_ESR = 1E-3;
        data_ESR_a_multiplier = data_ESR_a_multiplier + (strcmp(data_ESR_a_unit, 'mOhm') | strcmp(data_ESR_a_unit, 'mohm'))*k_ESR;
        k_ESR = 1E0;
        data_ESR_a_multiplier = data_ESR_a_multiplier + (strcmp(data_ESR_a_unit, 'Ohm') | strcmp(data_ESR_a_unit, 'ohm'))*k_ESR;

        % Get frequency data after '@' symbol
        data_ESR_b = regexp(filedata_ESR, '(?<=@).*', 'match', 'once');
        % Parse numeric data
        data_ESR_b_num = regexp(data_ESR_b, '[\d\.]*', 'match', 'once');
        data_ESR_b_num = cellfunc_str2double(data_ESR_b_num);
        % Parse units
        data_ESR_b_unit = regexp(data_ESR_b, '[^\d\.\s]*', 'match', 'once');
        % Scale the numerical current value based on the units
        data_ESR_b_multiplier = zeros(n_rows,1);
        k_freq = 1E0;
        data_ESR_b_multiplier = data_ESR_b_multiplier + strcmp(data_ESR_b_unit, 'Hz')*k_freq;
        k_freq = 1E3;
        data_ESR_b_multiplier = data_ESR_b_multiplier + strcmp(data_ESR_b_unit, 'kHz')*k_freq;
        k_freq = 1E6;
        data_ESR_b_multiplier = data_ESR_b_multiplier + strcmp(data_ESR_b_unit, 'MHz')*k_freq;

        % Define final data to be written to data table.
        data_ESR = [data_ESR_a_num.*data_ESR_a_multiplier, data_ESR_b_num.*data_ESR_b_multiplier];

        % For wet aluminum electrolytic: if an ESR value without frequency,
        % assume frequency is 120 (ESR decreases with frequency).
        data_ESR_c_index1 = data_ESR_a_index & strcmp(filedata_type, 'ALUM_WET');
        data_ESR(data_ESR_c_index1,2) = 120;
    %     data_ESR(data_ESR_c_index1,2) = 100e3;

        % For polymer or hybrid aluminum electrolytic: if an ESR value without
        % frequency, assume frequency is 100 kHz.
        data_ESR_c_index2 = data_ESR_a_index & (strcmp(filedata_type, 'ALUM_POLY') | strcmp(filedata_type, 'ALUM_HYB'));
        data_ESR(data_ESR_c_index2,2) = 100e3;

    else
        % Define final (null) data to be written to data table.
        data_ESR = nan(n_rows, 2);
    end

    % Return output(s)
    output_data_ESR = data_ESR;

end

%% func_parseCapacitor_CurrentRatedRMS.m
% Inline function which parses capacitor rated current (low frequency and
% high frequency) from imported data.
function [output_data_currLF, output_data_currHF] = func_parseCapacitor_CurrentRatedRMS(input_filedata, input_filedata_tech)
%   First input is the imported table of data from digikey.
%   Second input is the technology identifier (taken from filename).
%   Returns two arrays (for low frequency and high frequency) containing
%   the [ESR, frequency] for each component.

%   The value of current ripple is contained within two digikey variables
%   "RippleCurrent_LowFrequency" and "RippleCurrent_HighFrequency" for low
%   frequency (120 Hz) or high frequency (10 kHz or 100 kHz), respectively.
%   Need to separate the current value from the frequency value and then the
%   numerical value from the units for each.

    % Initialize input(s)
    filedata = input_filedata;
    filedata_tech = input_filedata_tech;
    [n_rows, ~] = size(filedata);

    % Currently only relevant for aluminum electrolytic capacitor type ('wet',
    % 'polymer', and 'hybrid').
    if ~isempty(regexp(filedata_tech, '(Alum)', 'once'))
        % Parse low frequency (LF) current ripple data from
        % 'RippleCurrent_LowFrequency' variable in imported data table.
        if (sum(strcmp('RippleCurrent_LowFrequency', filedata.Properties.VariableNames)) == 1)
            filedata_currLF = filedata.RippleCurrent_LowFrequency;
        end

        % Get current data before '@' symbol
        data_currLF_a = regexp(filedata_currLF, '.*(?=@)', 'match', 'once');
        % Parse numeric data
        data_currLF_a_num = regexp(data_currLF_a, '[\d\.]*', 'match', 'once');
        data_currLF_a_num = cellfunc_str2double(data_currLF_a_num);
        % Parse units
        data_currLF_a_unit = regexp(data_currLF_a, '[^\d\.\s]*', 'match', 'once');
        % Scale the numerical current value based on the units
        data_currLF_a_multiplier = zeros(n_rows,1);
        k_currHF = 1E-3;
        data_currLF_a_multiplier = data_currLF_a_multiplier + strcmp(data_currLF_a_unit, 'mA')*k_currHF;
        k_currHF = 1E0;
        data_currLF_a_multiplier = data_currLF_a_multiplier + strcmp(data_currLF_a_unit, 'A')*k_currHF;

        % Get frequency data after '@' symbol
        data_currLF_b = regexp(filedata_currLF, '(?<=@).*', 'match', 'once');
        % Parse numeric data
        data_currLF_b_num = regexp(data_currLF_b, '[\d\.]*', 'match', 'once');
        data_currLF_b_num = cellfunc_str2double(data_currLF_b_num);
        % Parse units
        data_currRippleLF_b_unit = regexp(data_currLF_b, '[^\d\.\s]*', 'match', 'once');
        % Scale the numerical current value based on the units
        data_currLF_b_multiplier = zeros(n_rows,1);
        k_freqLF = 1E0;
        data_currLF_b_multiplier = data_currLF_b_multiplier + strcmp(data_currRippleLF_b_unit, 'Hz')*k_freqLF;
        k_freqLF = 1E3;
        data_currLF_b_multiplier = data_currLF_b_multiplier + strcmp(data_currRippleLF_b_unit, 'kHz')*k_freqLF;
        k_freqLF = 1E6;
        data_currLF_b_multiplier = data_currLF_b_multiplier + strcmp(data_currRippleLF_b_unit, 'MHz')*k_freqLF;


        % Parse high frequency (HF) current ripple data from
        % 'RippleCurrent_HighFrequency' variable in imported data table.
        if (sum(strcmp('RippleCurrent_HighFrequency', filedata.Properties.VariableNames)) == 1)
            filedata_currHF = filedata.RippleCurrent_HighFrequency;
        end

        % Get current data before '@' symbol
        data_currHF_a = regexp(filedata_currHF, '.*(?=@)', 'match', 'once');
        % Parse numeric data
        data_currHF_a_num = regexp(data_currHF_a, '[\d\.]*', 'match', 'once');
        data_currHF_a_num = cellfunc_str2double(data_currHF_a_num);
        % Parse units
        data_currHF_a_unit = regexp(data_currHF_a, '[^\d\.\s]*', 'match', 'once');
        % Scale the numerical current value based on the units
        data_currHF_a_multiplier = zeros(n_rows,1);
        k_currHF = 1E-3;
        data_currHF_a_multiplier = data_currHF_a_multiplier + strcmp(data_currHF_a_unit, 'mA')*k_currHF;
        k_currHF = 1E0;
        data_currHF_a_multiplier = data_currHF_a_multiplier + strcmp(data_currHF_a_unit, 'A')*k_currHF;

        % Get frequency data after '@' symbol
        data_currHF_b = regexp(filedata_currHF, '(?<=@).*', 'match', 'once');
        % Parse numeric data
        data_currHF_b_num = regexp(data_currHF_b, '[\d\.]*', 'match', 'once');
        data_currHF_b_num = cellfunc_str2double(data_currHF_b_num);
        % Parse units
        data_currHF_b_unit = regexp(data_currHF_b, '[^\d\.\s]*', 'match', 'once');
        % Scale the numerical current value based on the units
        data_currHF_b_multiplier = zeros(n_rows,1);
        k_freqHF = 1E0;
        data_currHF_b_multiplier = data_currHF_b_multiplier + strcmp(data_currHF_b_unit, 'Hz')*k_freqHF;
        k_freqHF = 1E3;
        data_currHF_b_multiplier = data_currHF_b_multiplier + strcmp(data_currHF_b_unit, 'kHz')*k_freqHF;
        k_freqHF = 1E6;
        data_currHF_b_multiplier = data_currHF_b_multiplier + strcmp(data_currHF_b_unit, 'MHz')*k_freqHF;

        % Define final data to be written to data table.
        data_currLF = [data_currLF_a_num.*data_currLF_a_multiplier, data_currLF_b_num.*data_currLF_b_multiplier];
        data_currHF = [data_currHF_a_num.*data_currHF_a_multiplier, data_currHF_b_num.*data_currHF_b_multiplier];
    else
        % Define final (null) data to be written to data table.
        data_currLF = nan(n_rows, 2);
        data_currHF = nan(n_rows, 2);
    end


    % Return output(s)
    output_data_currLF = data_currLF;
    output_data_currHF = data_currHF;

end

%% func_parseCapacitor_Volume.m
% Inline function which parses capacitor (box) volume from imported data.
function output_data_volume = func_parseCapacitor_Volume(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the (box) volume for each component in [m^3].

    % Initialize input(s)
    filedata = input_filedata;
%     [n_rows, ~] = size(filedata);
    
    % Get length/width or diameter/height or diameter dimensional
    % parameter data from 'Size_Dimension' variable in imported data table
    filedata_vol_1 = filedata.Size_Dimension;
    % filedata_vol_1 = [{'0.315" Dia (5.00mm)'};{'0.315" Dia (8.010mm)'};{'0.287" L x 0.169" W (7.30mm x 4.30mm)'}]

    % Parse height dimensional parameter from both 'Height_Seated_Max_',
    % 'Thickness_Max_', and 'Height' variables in imported data table.
    % A combination of these variables might be defined but only one (or
    % neither) contains a valid height parameter.
    if (sum(strcmp('Height_Seated_Max_', filedata.Properties.VariableNames)) == 1)
        if (exist('filedata_vol_2','var'))
            filedata_vol_2 = [filedata_vol_2, filedata.Height_Seated_Max_];
        else
            filedata_vol_2 = filedata.Height_Seated_Max_;
        end
    end
    if (sum(strcmp('Thickness_Max_', filedata.Properties.VariableNames)) == 1)
        if (exist('filedata_vol_2','var'))
            filedata_vol_2 = [filedata_vol_2, filedata.Thickness_Max_];
        else
            filedata_vol_2 = filedata.Thickness_Max_;
        end
    end
    if (sum(strcmp('Height', filedata.Properties.VariableNames)) == 1)
        if (exist('filedata_vol_2','var'))
            filedata_vol_2 = [filedata_vol_2, filedata.Height];
        else
            filedata_vol_2 = filedata.Height;
        end
    end

    % Check existence of different dimensional parameters to determine how to
    % parse the imported data structure.
    id_type_L = ~cellfun(@isempty, regexpi(filedata_vol_1, 'L'));
    id_type_W = ~cellfun(@isempty, regexpi(filedata_vol_1, 'W'));
    id_type_Dia = ~cellfun(@isempty, regexpi(filedata_vol_1, 'Dia'));
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
    data_vol_1 = regexpi(filedata_vol_1, '(?<=\()[^)]*', 'match', 'once');
    % Assume units are mm and remove "mm" string
    data_vol_1 = regexprep(data_vol_1, 'mm', '');
    % Remove extra spaces
    data_vol_1 = regexprep(data_vol_1, '\s', '');

    % Determine the numerical data enclosed by parenthesis. These represent
    % the height parameter in units of mm.
    data_vol_2 = regexpi(filedata_vol_2, '(?<=\()[^)]*', 'match', 'once');
    % Assume units are mm and remove "mm" string
    data_vol_2 = regexprep(data_vol_2, 'mm', '');
    % Remove extra spaces
    data_vol_2 = regexprep(data_vol_2, '\s', '');

    % Manually apply "if" statements to cell array to parse data based on
    % structure of data string.
    string_before_x_Pattern = '[^x]*(?=[^\d\.])'; % Get numerical data before "x"
    string_after_x_Pattern = '(?<=[^\d\.])[^x]*'; % Get numerical data after "x"
    string_none_Pattern = 'XXX'; % Get no numerical data
    string_any_Pattern = '[\S]*'; % Get all numerical data
    % Parse "length" dimensional parameter
    data_length = cell(size(filedata_vol_1));
    data_length(id_type_vol_a) = regexpi(data_vol_1(id_type_vol_a),string_before_x_Pattern, 'match', 'once'); 
    data_length(id_type_vol_b) = regexpi(data_vol_1(id_type_vol_b),string_none_Pattern, 'match', 'once'); 
    data_length(id_type_vol_c) = regexpi(data_vol_1(id_type_vol_c),string_none_Pattern, 'match', 'once');
    % Parse "width" dimensional parameter
    data_width = cell(size(filedata_vol_1));
    data_width(id_type_vol_a) = regexpi(data_vol_1(id_type_vol_a),string_after_x_Pattern, 'match', 'once'); 
    data_width(id_type_vol_b) = regexpi(data_vol_1(id_type_vol_b),string_none_Pattern, 'match', 'once'); 
    data_width(id_type_vol_c) = regexpi(data_vol_1(id_type_vol_c),string_none_Pattern, 'match', 'once');
    % Parse "diameter" dimensional parameter
    data_dia = cell(size(filedata_vol_1));
    data_dia(id_type_vol_a) = regexpi(data_vol_1(id_type_vol_a),string_none_Pattern, 'match', 'once'); 
    data_dia(id_type_vol_b) = regexpi(data_vol_1(id_type_vol_b),string_before_x_Pattern, 'match', 'once'); 
    data_dia(id_type_vol_c) = regexpi(data_vol_1(id_type_vol_c),string_any_Pattern, 'match', 'once');
    % Parse "height" dimensional parameter
    data_height = cell(size(filedata_vol_2));
    data_height(id_type_vol_a,:) = regexpi(data_vol_2(id_type_vol_a,:),string_any_Pattern, 'match', 'once');
    data_height(id_type_vol_b,1) = regexpi(data_vol_1(id_type_vol_b),string_after_x_Pattern, 'match', 'once');
    data_height(id_type_vol_c,:) = regexpi(data_vol_2(id_type_vol_c,:),string_any_Pattern, 'match', 'once');

    % Reformat dimensional parameters into usable units
    % Length
    data_length = cellfunc_str2double(data_length);
    data_length = data_length*1E-3; % Convert to meters
    data_length(isnan(data_length)) = 0;
    % Width
    data_width = cellfunc_str2double(data_width);
    data_width = data_width*1E-3; % Convert to meters
    data_width(isnan(data_width)) = 0;
    % Diameter
    data_dia = cellfunc_str2double(data_dia);
    data_dia = data_dia*1E-3; % Convert to meters
    data_dia(isnan(data_dia)) = 0;
    % Height
    data_height = cellfunc_str2double(data_height);
    data_height = data_height*1E-3; % Convert to meters
    data_height(isnan(data_height)) = 0;
    % Take (potentially) multi-column array (for height and thickness) and
    % condense it down to a 1 column vector because there is only one (or no)
    % nonzero height or thickness parameter.
    data_height = sum(data_height,2);

    % Compute volume from dimensional parameters and component shape
    data_vol = cellfun(@func_computeCapacitor_Volume, data_shape,...
        mat2cell([data_height,data_length,data_width,data_dia], ones(1,length(filedata_vol_2))));

    % Convert 'zero' volumes to NaN
    data_vol(data_vol == 0) = NaN;
    
    % Return output(s)
    output_data_volume = data_vol;

end

%% func_computeCapacitor_Volume.m
% Inline function for use in cellfun applied to cell array.
% Computes volume of components from dimensional parameters and shape.
function output_volume = func_computeCapacitor_Volume(input_shape, input_params)
%   First input is the shape of the capacitor. Two options are character
%       arrays 'rect' for rectangular prism or 'cyl' for cylinder.
%   Second input is an array of doubles which contains all possible
%       parameters in the following order:
%           - input_params = [height, length, width, diameter]
%   Returns the volume of the shape based on the given parameters.

    if (strcmp(input_shape, 'rect'))
        height = input_params(1);
        length = input_params(2);
        width = input_params(3);
        volume = height*length*width;
    elseif (strcmp(input_shape, 'cyl'))
        height = input_params(1);
        diameter = input_params(4);
        volume = height*pi*(diameter/2).^2;
    else % Undefined shape (not enough dimensional data)
        volume = NaN;
    end

    output_volume = volume;

end

%% func_parseCapacitor_Package.m
% Inline function which parses capacitor manufacturer part name from
% imported data.
function output_data_package = func_parseCapacitor_Package(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the manufacturer part name for each component.

%   The package idenitifier is contained within the single digikey variable
%   "Package_Case".
%   Currently only compatible for SMD type components.
%   Need to separate the numerical value from the metric value in parenthesis.

    % Initialize input(s)
    filedata = input_filedata;
%     [n_rows, ~] = size(filedata);

    % Get package data from 'Package_Case' variable in imported data table
    filedata_package = filedata.Package_Case;
    % Remove parentheses and contents (if present) and endline whitespace.
    % Largely applicable for EIA package names (e.g., 0402, 0603)
    data_package = regexpi(filedata_package, '[\w]*(?=\s\()', 'match', 'once');
    % Direct feedthrough entries which did not contain parentheses
    emptyCells = cellfun(@isempty, data_package);
    data_package(emptyCells) = filedata_package(emptyCells);
    
    % Return output(s)
    output_data_package = data_package;

end

%% func_parseCapacitor_UnitCost.m
% Inline function which parses capacitor per unit cost from imported data.
function output_data_unitcost = func_parseCapacitor_UnitCost(input_filedata)
%   Input is the imported table of data from digikey.
%   Returns an array containing the cost (per unit) for each component.

%   The value of per unit cost is contained within the single digikey
%   variable "Price" or "UnitPrice_USD_". For fairness, should account for
%   bulk costs. This information is contained within the digikey variable
%   "MinQty" or "Minimum Quantity".

    % Initialize input(s)
    filedata = input_filedata;
%     [n_rows, ~] = size(filedata);
    
    % Get unit cost data from 'Price' (or 'UnitPrice_USD_) variable in imported
    % data table
    if (sum(strcmp('Price', filedata.Properties.VariableNames)) == 1)
        filedata_unitcost = filedata.Price;
    end
    if (sum(strcmp('UnitPrice_USD_', filedata.Properties.VariableNames)) == 1)
        filedata_unitcost = filedata.UnitPrice_USD_;
    end
    % filedata_unitcost = cellstr(num2str(filedata_unitcost)); % Convert to cell array of character strings
    % Extract numerical values from cost data. Sometimes contains useless
    % strings which makes data a cell array of character strings.
    if isa(filedata_unitcost, 'double')
        data_unitcost_num = filedata_unitcost;
    elseif isa(filedata_unitcost, 'cell')
        data_unitcost_num = regexprep(filedata_unitcost, '[^\d\.]', '');
        data_unitcost_num = cellfunc_str2double(data_unitcost_num);
    end

    % Get minimum purchase quantity from 'MinQty' (or 'MinimumQuantity')
    % variable in imported data table
    if (sum(strcmp('MinQty', filedata.Properties.VariableNames)) == 1)
        filedata_minqty = filedata.MinQty;
    end
    if (sum(strcmp('MinimumQuantity', filedata.Properties.VariableNames)) == 1)
        filedata_minqty = filedata.MinimumQuantity;
    end
    % Extract numerical values from min quantity data. Sometimes contains
    % useless strings which makes data a cell array of character strings.
    if isa(filedata_minqty, 'double')
        data_minqty_num = filedata_minqty;
    elseif isa(filedata_minqty, 'cell')
        data_minqty_num = regexprep(filedata_minqty, '[^\d\.]', '');
        data_minqty_num = cellfunc_str2double(data_minqty_num);
    end

    % Only include components below the specified minimum quantity. Do not want
    % to include bulk prices.
    i = (data_minqty_num <= 1);
    data_unitcost_num(~i) = NaN;

    % Return output(s)
    output_data_unitcost = data_unitcost_num;

end

%% cellfunc_str2double.m
% Inline function for faster string to double conversion in large cell array.
function output_array = cellfunc_str2double(input_array)
%   Input is a cell array of strings.
%   Returns cell array of doubles.

    % Initialize input(s)
    string_array = input_array;
    
    % Check if input is cell array
    if ~iscell(input_array)
        output_array = str2double(string_array);
        return;
    end
    
    % Option #1: Twice as fast as slowest option
%     tic
    double_array = nan(size(string_array));
    for ii = 1:numel(double_array)
        if ~isempty(string_array{ii})
            double_array(ii) = sscanf(string_array{ii},'%f');
        else
            % Do nothing
            % double_array(ii) = NaN;
        end
    end
%     toc
    
    % Option #2: Slightly faster than slowest option
%     tic
%     double_array = cellfun(@(x)sscanf(x,'%f'), string_array, 'UniformOutput', false);
%     toc
    
    % Option #3: Slowest
%     tic
%     double_array = str2double(string_array);
%     toc
    
    % Return output(s)
    output_array = double_array;

end
