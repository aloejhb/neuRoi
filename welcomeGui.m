function hdl = welcomeGui()
hdl.fig= figure('Position',[80,300,550,300],'Resize','off');
hdl.newButton  = uicontrol(hdl.fig,...
                           'String','New experiment',...
                           'Tag','newButton',...
                           'Position',[10 200 150 60])
hdl.openButton = uicontrol(hdl.fig,...
                           'String','Open',...
                           'Tag','openButton',...
                           'Position',[10 100 150 60])
set(hdl.fig,'MenuBar','none');
set(hdl.fig,'ToolBar','none');
set(hdl.fig,'Name','Welcome to neuRoi','NumberTitle','off');
