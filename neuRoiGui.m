function handles = neuRoiGui(varargin)
% NEUROIGUI creates a gui for drawing ROI on two-phonton imaging
% movies.

    handles = {};

    handles.mainFig = figureDM('Position',[600,300,750,650]); % figureDM is a
                                                % function to
                                                % create figure on dual monitor by Jan
    handles.mapAxes = axes('Position',[0.15,0.1,0.8,0.8]);

    handles.anatomyButton  = uicontrol('Style','pushbutton',...
                               'String','Anatomy',...
                               'Units','normal',...
                               'Position',[0.15,0.91,0.1,0.08]);
    
    handles.responseButton  = uicontrol('Style','pushbutton',...
                               'String','dF/F',...
                               'Units','normal',...
                               'Position',[0.25,0.91,0.1,0.08]);
    
    handles.addRoiButton  = uicontrol('Style','togglebutton',...
                              'String','Add ROI',...
                              'Units','normal',...
                              'Position',[0.02,0.8,0.1,0.08]);
    
    % Sliders for contrast adjustment
    handles.contrastMinSlider = uicontrol('Style','slider', ...
                                          'Units','normal','Position',[0.5 0.95 0.25 0.04]);
    
    handles.contrastMaxSlider = uicontrol('Style','slider', ...
                                          'Units','normal','Position',[0.5 0.9 0.25 0.04]);
    
    
    handles.traceFig = figureDM('Name','Time Trace','Tag','traceFig',...
                                'Position',[50,500,500,400],'Visible','off');
    handles.traceAxes = axes();
    figure(handles.mainFig)
end
