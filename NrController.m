classdef NrController < handle
    properties
        model
        view
        trialContrlArray
        rootListener
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(mymodel,self);

            % nFile = self.model.getNFile();
            self.trialContrlArray = TrialController.empty;
            % Listen to MATLAB root object for changing of current figure
            self.rootListener = listener(groot,'CurrentFigure','PostSet',@self.selectTrial_Callback);
        end
        
        % function setLoadMovieOption(self,loadMovieOption)
        %     self.model.loadMovieOption = loadMovieOption;
        % end
        
        function addFilePath_Callback(self,filePath)
            self.model.addFilePath(filePath);
            self.trialControllerArray{end+1} = [];
        end
        
        function loadRangeGroup_Callback(self,src,evnt)
            button = evnt.NewValue;
            tag = button.Tag;
            if strcmp(tag,'loadrange_radiobutton_2')
                self.view.toggleLoadRangeText('on');
                loadRange = self.view.getLoadRangeFromText();
                self.model.loadMovieOption.zrange = loadRange;
            else
                self.view.toggleLoadRangeText('off');
                self.model.loadMovieOption.zrange = 'all';
            end
        end
        
        function loadRangeText_Callback(self,src,evnt)
            startText = self.view.guiHandles.loadRangeStartText;
            endText = self.view.guiHandles.loadRangeEndText;
            startStr = startText.String;
            endStr = endText.String;
            startFrameNum = round(str2num(startStr));
            endFrameNum = round(str2num(endStr));
            
            switch src.Tag
              case 'loadrange_start_text'
                if startFrameNum < 1
                    startFramenNum = 1;
                end
                if startFrameNum > endFrameNum
                    startFrameNum = endFrameNum;
                end
                self.model.loadMovieOption.zrange = ...
                    [startFrameNum,endFrameNum];
                set(src,'String',num2str(startFrameNum));
              case 'loadrange_end_text'
                if endFrameNum < startFrameNum
                    endFrameNum = startFrameNum;
                end
                self.model.loadMovieOption.zrange = ...
                    [startFrameNum,endFrameNum];
                set(src,'String',num2str(endFrameNum));
            end
        end
        
        function loadStepText_Callback(self,src,evnt)
            stepStr = src.String;
            nFramePerStep = str2num(stepStr);
            self.model.loadMovieOption.nFramePerStep = nFramePerStep;
        end

        function selectTrial_Callback(self,src,evnt)
            fig = evnt.AffectedObject.(src.Name);
            if ~isempty(fig)
                tag = fig.Tag;
                trialTag = regexp(tag,'trial_([a-zA-Z0-9]+)_','tokens');
                if ~isempty(trialTag)
                    self.model.selectTrial(trialTag{1}{1});
                end
            end
        end

        function trialDeleted_Callback(self,src,evnt)
            trialTag = src.tag;
            idx = self.model.getTrialIdx(trialTag);
            self.model.selectTrial([]);
            self.model.trialArray(idx) = [];
            self.trialContrlArray(idx) = [];
        end
        
        function fileListBox_Callback(self,src,evnt)
            fig = src.Parent;
            if strcmp(fig.SelectionType,'open')
                ind = src.Value;
                if self.isTrialOpened(ind)
                    %self.raiseTrialView(ind);
                    % TODO raise view by tag
                else
                    self.openTrial(ind);
                end
            end
        end
        
        function res = isTrialOpened(self,ind)
            trialController = self.trialControllerArray{ind};
            trial = self.model.getTrialByInd(ind);
            res = false;
            if ~isempty(trialController) && ~isempty(trial)
                if isvalid(trialController) && ...
                        isvalid(trialController)
                    res = true;
                end
            end
        end
        
        function openTrial(self,fileIdx,fileType,varargin)
            trial = self.model.loadTrial(fileIdx,fileType,varargin{:});
            addlistener(trial,'trialDeleted',@self.trialDeleted_Callback);
            trialContrl = TrialController(trial);
            trialContrl.setSyncTimeTrace(true);
            self.trialContrlArray(end+1) = trialContrl;
            trialContrl.raiseView();
        end
        
        function raiseTrialView(self,ind)
            trialController = self.trialControllerArray{ind};
            trialController.raiseView();
        end
        
        
        % Map related callbacks
        function addResponseMap_Callback(self,src,evnt)
            responseOption = struct('offset',-10,...
                                    'fZeroWindow',[10 20],...
                                    'responseWindow',[40 50]);
            self.model.addMapWrap('current','response',responseOption);
        end
        
        
        
        function mainFigClosed_Callback(self,src,evnt)
            self.view.deleteFigures();
            delete(self.view);
            delete(self.model)
            delete(self)
        end
        
        
        function delete(self)
            if isvalid(self.view)
                self.view.deleteFigures();
                delete(self.view)
            end
        end
    end
end
