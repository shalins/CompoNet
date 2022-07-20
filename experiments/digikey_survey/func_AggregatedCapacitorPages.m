function output_filepath = func_AggregatedCapacitorPages(input_folderpath, input_parentPath)
%% func_AggregatedCapacitorPages.m
%   Author: Nathan C. Brooks
%   Author Info: PhD Candidate at UC Berkeley, EECS Department
%   Date Created: 11/17/19
%   Last Revision: 11/19/21
%
%   File Description:
%       This function aggregates all .csv files in a specified folder into
%       a single .csv file.
%
%   Inputs:
%       - folderpath    --  relative folder path containing all .csv files
%                           to be aggregated.
%       - parentPath    -- (optional) parent path directory 
%
%   Outputs:
%       - filepath      --  full path of final aggregated .csv file
%
%   Other m-files required:
%   Other files required:   Relevant .csv files
%

%% Debug
clear all
clc
close all

% Manually specificy function inputs for debugging
% filename = 'AlumElec_11152019';
% filename = 'AlumElec_03282021';
% filename = 'AlumElec_20211117';
% filename = 'AlumElecBipolar_03282021';
% filename = 'AlumHybrid_11152019';
% filename = 'AlumHybrid_03282021';
% filename = 'AlumHybrid_20211118';
% filename = 'AlumPoly_11082019';
% filename = 'AlumPoly_03282021';
% filename = 'AlumPoly_20211118';
% filename = 'C0GNP0_03222021';
% filename = 'Ceramic_20211111';
% filename = 'PowerCeramic_10142021';
% filename = 'EDLC_03282021';
% filename = 'EDLC_20211118';
% filename = 'FilmAcrylic_03282021';
% filename = 'FilmAcrylic_20211118';
% filename = 'FilmPaper_03282021';
% filename = 'FilmPaper_20211118';
% filename = 'FilmPEN_03282021';
% filename = 'FilmPEN_20211118';
% filename = 'FilmPET_03282021';
% filename = 'FilmPET_20211118';
filename = 'FilmPolyester_03282021';
% filename = 'FilmPolyester_20211118';
% filename = 'FilmPolymer_20211118';
% filename = 'FilmPP_03282021';
% filename = 'FilmPP_20211118';
% filename = 'FilmPPS_03282021';
% filename = 'FilmPPS_20211118';
% filename = 'FilmPTFE_20211118';
% filename = 'Mica_03282021';
% filename = 'Mica_20211118';
% filename = 'NbO_03282021';
% filename = 'NbO_20211118';
% filename = 'Silicon_03282021';
% filename = 'Silicon_20211118';
% filename = 'Tantalum_03282021';
% filename = 'Tantalum_20211117';
% filename = 'TantalumPoly_03282021';
% filename = 'TantalumPoly_20211118';
% filename = 'ThinFilm(Silicon)_03282021'; % This data set is essentially "silicon" type
% filename = 'ThinFilm(Silicon)_20211118'; % This data set is essentially "silicon" type
% filename = 'MLCC_TDK_20210513\Products';
% filename = 'Inductor_20211014';

input_foldername1 = 'RawData_Digikey';
% input_foldername1 = 'RawData_TDK';
input_foldername2 = filename;
input_folderpath = fullfile(input_foldername1,input_foldername2);

%% Initialize directory of files to be aggregated

% Supress warning messages
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

% Determine relevant write and read paths
if ~exist('inputPath','var')
    parentPath = pwd;
else
    parentPath = input_parentPath;
end
childPath = fullfile(parentPath,input_folderpath);
aggregated_filename = [input_folderpath,'.csv'];

% Check if specified folder exists
if exist(childPath, 'file') ~= 7 % 7 - name is a folder
    error(['The specified foldername, ''', input_folderpath, ''', does not exist.']);
end

% Determine the names and total quantity of .csv files to be aggregated. 
% This functionality assumes the only files within the child folder are
% those to be aggregated. No more and no less.
d = dir(fullfile(childPath,'*.csv'));
n_file = length(d(not([d.isdir])));

%% Testing
% % Read first exemplar file in folder
% filename = fullfile(childPath,d(1).name);
% % Additional connfiguration to ensure all variable types are the same
% % (character strings) between all appended files
% opts = detectImportOptions(filename,'Delimiter',{','});
% [opts_VariableTypes{1:length(opts.VariableTypes)}] = deal('char');
% opts.VariableTypes = opts_VariableTypes;    
% filedata = readtable(filename,opts); 
% filedata_vars = filedata.Properties.VariableNames;
% 
% ds = tabularTextDatastore(childPath)
% ds.VariableNames = filedata_vars;
% % ds.SelectedFormats = opts_VariableTypes;
% 
% % writeall(ds(1:10),aggregated_filename,'FolderLayout','flatten')
% 
% tt = tall(ds)
% % ttSubset = head(tt,1000)
% write(aggregated_filename,tt,'FileType','text','Delimiter',',')
% % write([input_folderpath,'_*.csv'],ttSubset,'FileType','txt')

%% Main
% Sequentially read data from each file and append to one table. Note that
% this type of data import alters the column headers to valid MATLAB
% variable syntax.
% warning('off','MATLAB:table:ModifiedAndSavedVarnames');
tic
disp(['Starting file aggregation of folder: ',input_folderpath])
for i = 1:n_file
    disp(['... Aggregating file ',num2str(i),' of ',num2str(n_file)])
    filename = fullfile(childPath,d(i).name);
    % Additional configuration to ensure all variable types are the same
    % (character strings) between all appended files
    opts = detectImportOptions(filename,'Delimiter',{','});
    clear opts_VariableTypes
    [opts_VariableTypes{1:length(opts.VariableTypes)}] = deal('char');
    opts.VariableTypes = opts_VariableTypes;    
    filedata = readtable(filename,opts); 

    if (~exist('aggregated_filedata','var'))
        filedata_vars = filedata.Properties.VariableNames;
        % Option #1: Slow for large files
%         aggregated_filedata = filedata;
        % Option #2: Reasonably fast and fixed speed
        fileheight = height(filedata); % Number of components per file. Assumes all equal.
        aggregated_filedata = table('Size',[fileheight*n_file length(filedata_vars)],'VariableTypes',repmat({'string'},length(filedata_vars),1),'VariableNames',filedata_vars);
        aggregated_filedata((1:fileheight)+(i-1)*fileheight,:) = filedata;
    else
        if ~isempty(filedata)
            % Remove extra columns in files which have erroneous data
            filedata = filedata(:,filedata_vars);
            % Option #1: Slow for large files
%             aggregated_filedata = [aggregated_filedata; filedata];
            % Option #2: Reasonably fast and fixed speed
            aggregated_filedata((1:height(filedata))+(i-1)*fileheight,:) = filedata;
        else
            % Do nothing if empty file
        end

    end
end
toc
disp(' ')

%% Find unique rows of aggregated file data
tic
disp(['Isolate unique components...'])
aggregated_filedata = rmmissing(aggregated_filedata); % Remove empty rows
aggregated_filedata = unique(aggregated_filedata); % Remove duplicate rows
disp(['Unqiue components isolated.'])
toc
disp(' ')

%% Write appended data to file
tic
disp(['Saving aggregated file ',aggregated_filename,' ...'])
writetable(aggregated_filedata,aggregated_filename);
disp(['Filed successfully saved.'])
toc
disp(' ')

%% Return full path of appended file
output_filepath = fullfile(parentPath,aggregated_filename);

end

