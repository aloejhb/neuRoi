function hdl = importRawDataGui(hNr,varargin)
if nargin == 1
    rawDataDir = pwd;
else
    rawDataDir = varargin{1};
end

hdl.fig= figure('Position',[80,300,700,700],'Resize','off');

setappdata(hdl.fig,'hNr',hNr)
setappdata(hdl.fig,'rawDataDir',rawDataDir)

set(hdl.fig,'MenuBar','none');
set(hdl.fig,'ToolBar','none');
set(hdl.fig,'Name','Import Raw Data','NumberTitle','off');

hdl.expTitleText = uicontrol(hdl.fig,...
                             'Style','text',...
                             'String','Experiment information',...
                             'Tag','expTitle_text',...
                             'Position',[10 650 200 30]);

hdl.expNameText = uicontrol(hdl.fig,...
                            'Style','text',...
                            'String','Experiment Name',...
                            'Tag','expName_text',...
                            'Position',[10 600 200 30]);

hdl.expNameEdit = uicontrol(hdl.fig,...
                            'Style','edit',...
                            'String','new_experiment',...
                            'Tag','expName_edit',...
                            'Position',[180 600 300 25]);

hdl.frameRateText = uicontrol(hdl.fig,...
                            'Style','text',...
                            'String','Frame Rate',...
                            'Tag','frameRate_text',...
                            'Position',[10 550 200 30]);

hdl.frameRateEdit = uicontrol(hdl.fig,...
                            'Style','edit',...
                            'String','30',...
                            'Tag','frameRate_edit',...
                            'Position',[180 550 100 25]);

hdl.nPlaneText = uicontrol(hdl.fig,...
                            'Style','text',...
                            'String','Number of planes',...
                            'Tag','nPlane_text',...
                            'Position',[10 500 200 30]);

hdl.nPlaneEdit = uicontrol(hdl.fig,...
                            'Style','edit',...
                            'String','1',...
                            'Tag','nPlane_edit',...
                            'Position',[180 500 100 25]);

hdl.dataTitleText = uicontrol(hdl.fig,...
                             'Style','text',...
                             'String','Raw data',...
                             'Tag','dataTitle_text',...
                             'Position',[10 450 200 30]);

hdl.rawDataDirText = uicontrol(hdl.fig,...
                            'Style','text',...
                            'String','Raw data directory',...
                            'Tag','rawDataDir_text',...
                            'Position',[10 400 200 30]);

hdl.rawDataDirEdit = uicontrol(hdl.fig,...
                               'Style','edit',...
                               'String',rawDataDir,...
                               'Tag','rawDataDir_edit',...
                               'Position',[180 400 200 25]);

hdl.rawDataDirButton = uicontrol(hdl.fig,...
                               'Style','pushbutton',...
                               'String','...',...
                               'Tag','rawDataDir_button',...
                               'Position',[390 400 100 25]);

hdl.fileListBox = uicontrol(hdl.fig,...
                            'Style','listbox',...
                            'Tag','fileListBox',...
                            'Max',20,...
                            'Position',[200 175 300 200],...
                            'FontSize',16);

hdl.removeFileButton =  uicontrol(hdl.fig,...
                                  'Style','pushbutton',...
                                  'String','-',...
                                  'Tag','rawDataDir_button',...
                                  'Position',[400   150   70    25],...
                                  'FontSize',20);


hdl.importButton = uicontrol(hdl.fig,...
                             'String','Import',...
                             'Tag','import_button',...
                             'Position',[10 10 100 35]);

updateFileList(hdl.fig,rawDataDir)

set(hdl.importButton,'Callback',@import_Callback)
set(hdl.rawDataDirButton,'Callback',@rawDataDirButton_Callback)
set(hdl.rawDataDirEdit,'Callback',@rawDataDirEdit_Callback)
set(hdl.removeFileButton,'Callback',@removeFileButton_Callback)


function import_Callback(src,event)
hfig = src.Parent;
expInfo.name = get(findobj(hfig,'Tag','expName_edit'),'String');
expInfo.frameRate = str2num(get(findobj(hfig,'Tag','frameRate_edit'),'String'));
expInfo.nPlane = str2num(get(findobj(hfig,'Tag','nPlane_edit'), ...
                             'String'));

rawDataDir = get(findobj(hfig,'Tag','rawDataDir_edit'),'String');

hNr = getappdata(hfig,'hNr');



function rawDataDirButton_Callback(src,event)
hfig = src.Parent;
rawDataDir = getappdata(hfig,'rawDataDir');
rawDataDir = uigetdir(rawDataDir,'Choose raw data directory');
if rawDataDir
    set(findobj(hfig,'Tag','rawDataDir_edit'),'String',rawDataDir);
    setappdata(hfig,'rawDataDir',rawDataDir)
    updateFileList(hfig,rawDataDir);
end

function rawDataDirEdit_Callback(src,event)
hfig = src.Parent;
rawDataDir = src.String;
setappdata(hfig,'rawDataDir',rawDataDir)
updateFileList(hfig,rawDataDir);

function updateFileList(hfig,rawDataDir)
if exist(rawDataDir,'dir')
    rawFileList = dir(fullfile(rawDataDir,'*.tif'));
    rawFileList = arrayfun(@(x) x.name, rawFileList,'UniformOutput',false);
    fileListBox = findobj(hfig,'Tag','fileListBox');
    set(fileListBox,'String',rawFileList);
else
    error('Raw data directory not found!')
end

function removeFileButton_Callback(src,event)
hfig = src.Parent;
fileListBox = findobj(hfig,'Tag','fileListBox');
selectedIdx = get(fileListBox,'Value');
currentItems = get(fileListBox, 'String');
newItems = currentItems;
newItems(selectedIdx) = [];
set(fileListBox,'Value',[]);
set(fileListBox, 'String', newItems);

% Filter
