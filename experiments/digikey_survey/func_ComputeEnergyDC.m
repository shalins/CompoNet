function output_dataTable = func_ComputeEnergyDC(input_dataTables)
%% func_ComputeEnergyDC.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 1/31/21
%   Last Revision: 1/31/21
%
%   File Description:
%       This function estimates the rated dc (released) energy of each
%       component based on:
%           - linear C(v):      W = 1/2*C(0)*Vr^2
%           - nonlinear C(v):   W = 1/2*Ce(Vr)*Vr^2, where Ce(Vr) = k2*C(0)
%
%   TODO:
%   -   Pass capacitor derating ratio (k = C(Vr)/C(0)) into function.
%
%   Inputs:
%       - dataTable     --  table of data or cell array of tables where
%                               each table is associated with a particular
%                               technology
%
%   Outputs:
%       - dataTable     --  table of data including appended estimation of
%                               dc energy in [J]
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
% input_filename = 'Ceramic_20211111_b.csv';
% % input_filename = 'PowerCeramic_10142021.csv';
% % input_filename = 'FilmPolyester_03282021.csv';
% % input_filename = '';
% % 
% input_foldername = 'RawData_Digikey';
% 
% inputTables = cell(2,1);
% inputTables{1} = func_ParseCapacitorPages(input_filename,input_foldername);
% inputTables{2} = func_ParseCapacitorPages('',input_foldername);
% 
% % inputTables = func_ParseCapacitorPages(input_filename,input_foldername);
% 
% input_dataTables = inputTables;


%% Initialize data

inputTables = input_dataTables;

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
    else
        capacitance = nan(size(inputData,1),1);
        voltage = nan(size(inputData,1),1);
    end
    capacitance_energyEQ = nan(size(inputData,1),1); % dc energy equivalent capacitance
    energyDC = nan(size(inputData,1),1); % dc energy [J]
    
    if ismember('Tech', inputData.Properties.VariableNames)
        if ~isempty(inputData.Tech)
        % Sort by capacitor technology
            if strcmp('Ceramic', inputData.Tech(max(end,1)))
                
                % Class 1 ceramics - linear C(v)
                i = ~cellfun(@isempty,regexpi(inputData.Type, '_C1'));
                k2 = 1; % k2 = Ce(Vr)/C(0)
                capacitance_energyEQ(i) = k2*capacitance(i); 
                energyDC(i) = 0.5*capacitance_energyEQ(i).*voltage(i).^2;
                
                % Class 2 ceramics (and Class 3) - nonlinear C(v)
                i1 = ~cellfun(@isempty,regexpi(inputData.Type, '_C2'));
                i2 = ~cellfun(@isempty,regexpi(inputData.Type, '_C3'));
                i = i1|i2;
                % k = C(Vr)/C(0) derating ratio; k2 = Ce(Vr)/C(0)
                %   -> k=0.8, k2=0.89; k=0.6, k2=0.76; k=0.4, k2=0.6; k=0.2, k=0.38
                k = 0.4; % k = C(Vr)/C(0), normalized derating of differential capacitance
                k2 = 4*k/(sqrt(k)+1)^2; % k2 = Ce(Vr)/C(0)
                capacitance_energyEQ(i) = k2*capacitance(i);
                energyDC(i) = 0.5*capacitance_energyEQ(i).*voltage(i).^2;
                
            else
                % All other capacitors have a linear relationship between capacitance and voltage
                k2 = 1; % k2 = Ce(Vr)/C(0)
                capacitance_energyEQ = k2*capacitance; 
                energyDC = 0.5*capacitance_energyEQ.*voltage.^2;
            end
        else
            % Invalid filename (empty)
        end
    else
        % Skip case for inductors
    end

    % Create a new variable in the table for dc energy
    inputData.energyDC = energyDC; % [J]
    
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