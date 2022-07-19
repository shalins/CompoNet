function [output_dataTable] = func_removeOutliers(input_outlierFilepath, input_dataTable)
%% func_removeOutliers.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 10/12/21
%   Last Revision: 10/14/21
%
%   File Description:
%       This function removes the components from the input data table by
%       omitting rows which match any manufacturer and manufacturer part
%       name from the text file containing outliers.
%       Data table must include variable names "Manufacturer" and
%       "MfrPartNum" to compare against. If manufacturer is left empty,
%       then it is ignored by default.
%
%   Inputs:
%       - outlierFilepath   -- all xy coordinate data (data = [x,y])
%       - dataTable         -- input data table
%
%   Outputs:
%       - dataTable         --  output data table (without outliers)
%
%   Other m-files required:
%   Other files required: Relevant txt file of outlier manuf. part num.
%

%% Debug
% close all
% clear all
% clc
% 
% foldername = 'RawData_Digikey';
% input_outlierFilepath = fullfile(foldername,'outlierCaps_03282021.txt');
% 
% foldername = 'RawData_Digikey';
% % dataFilename = 'AlumElec_03282021.csv';
% % dataFilename = 'Tantalum_03282021.csv';
% dataFilename = 'C0GNP0_03222021.csv';
% input_dataTable = func_ParseCapacitorPages(dataFilename,foldername);

%% Initialize variables and read outliers from file
dataTable = input_dataTable;

outlierFilename = input_outlierFilepath;
% Read data from outlier input file
outlierTable = readtable(outlierFilename,'Delimiter',{';'},'ReadVariableNames',false);

% These lines handles null (nan) values
dataTable.MfrPartName = cellstr(char(dataTable.MfrPartName));
dataTable.Manufacturer = cellstr(char(dataTable.Manufacturer));

%% Option #1: works for only matching part names (not manufacturer)
% % Find logical indices of rows which match outlier parts
% i = any(ismember(dataTable.MfrPartNum,outlierTable.Var1),2);
% % Remove outliers from table
% dataTable = dataTable(~i,:);

%% Option #2: works for both matching part names and manufacturer
% Iterate through entire outlier table and remove components which match
% the manufacturer and manufacturer part name from data table.
for j = 1:height(outlierTable)
%     disp(j)
    % Speed up computation if there is no manufacturer
    if cellfun(@isempty, outlierTable(j,:).Var2)
        i = any(ismember(dataTable.MfrPartName,outlierTable(j,:).Var1),2);
        % Remove outliers from table
        dataTable = dataTable(~i,:);
    else
        % Check if there's a wildcard character (*) within a manufacturer
        % part name (assumedly only at the end).
        if cellfun(@isempty, regexp(outlierTable(j,:).Var1,'\*'))
            % Find logical indices of rows which match full outlier part
            i1 = ~cellfun(@isempty, regexpi(dataTable.MfrPartName,outlierTable(j,:).Var1));
        else
            % Find logical indices of rows which contain the specified
            % substring of the part at the beginning of the part name
            i1 = ~cellfun(@isempty, regexpi(dataTable.MfrPartName,['^',outlierTable(j,:).Var1{:}(1:end-1)]));
        end
        
        % Find logical indices of rows which match outlier manufacturer
        if ~cellfun(@isempty, outlierTable(j,:).Var2)
            i2 = ~cellfun(@isempty, regexpi(dataTable.Manufacturer,outlierTable(j,:).Var2));
        else
            % Account for case where entry in outlier table is empty
            i2 = 1;
        end
        % Identify indices which match both manufacturer and part number
        i = (i1&i2);
        % Remove outlier from data table
        dataTable = dataTable(~i,:);
        % Debug
    %     disp(height(dataTable)); 
    end
end

%% Output
output_dataTable = dataTable;

end

