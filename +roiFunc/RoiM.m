classdef RoiM
    properties
        tag
        position
        offsetYx
        posErr
        type
    end
    
    methods
        function self = RoiM(position, varargin)
            pa = inputParser;
            addRequired(pa,'position',@ismatrix);
            addParameter(pa,'tag','',@ischar);
            parse(pa,position,varargin{:})
            pr = pa.Results;
                
            if isempty(pr.position) || ~isequal(size(pr.position,2),2)
                error('Invalid Position!')
            end
            self.position = pr.position;
            self.tag = pr.tag;
        end
        
        function mask = createMask(self,imageSize)
            mask = zeros(imageSize);
            pos = self.position;
            linearInd = sub2ind(imageSize, pos(:,2),pos(:,1));
            mask(linearInd) = 1;
        end

        function [mask,offset] = createSmallMask(self)
            offset = min(self.position,[],1);
            roiSize = ceil(max(self.position,[],1) - offset) + 1;
            mask = zeros(roiSize(end:-1:1));
            posShifted = self.position - offset + 1;
            linearInd = sub2ind(roiSize(end:-1:1), posShifted(:,2),posShifted(:,1));
            mask(linearInd) = 1;
        end

        function roiPatch = createRoiPatch(self,parent,ptcolor)
        % CREATEROIPATCH create a patch handle according to ROI position
        % for visualization
        % Usage: createRoiPatch(roi,parent)
        % roi: the handle to a RoiFreehand object
        % parent: the handle to the parent to which the patch is attached
            
            if ~exist('parent', 'var')
                parent = gca;
            end

            if ~exist('ptcolor', 'var')
                ptcolor = 'red';
            end
            
            try
                inputImageSize = size(getimage(parent));
                parentAxes = parent;
            catch ME
                try
                    % if the parent is a group, get imageSize from
                    % the parent axes of the group
                    inputImageSize = size(getimage(parent.Parent));
                    parentAxes = parent.Parent;
                catch ME
                    rethrow ME
                end
            end
            
            [smallMask,offset] = self.createSmallMask();
            plyPos = bwboundaries(smallMask);
            pixelPosition = plyPos{1}+offset;
            axesPosition = getAxesPosition(parentAxes,pixelPosition);
            roiPatch = patch(axesPosition(:,1),axesPosition(:,2),ptcolor,'Parent',parent);
            set(roiPatch,'FaceAlpha',0.5)
            set(roiPatch,'LineStyle','none');
            ptTag = RoiFreehand.getPatchTag(self.tag);
            set(roiPatch,'Tag',ptTag);
        end
        
        function updateRoiPatchPos(self,roiPatch)
            offsetYx = self.offsetYx;
            offsetFlag = any(offsetYx);
            parent = ancestor(roiPatch,'Axes');
            pixelPosition = self.position;
            if offsetFlag
                pixelPosition = pixelPosition + [offsetYx(2), ...
                                    offsetYx(1)];
            end
            axesPosition = getAxesPosition(parent,pixelPosition);
            set(roiPatch,'XData',axesPosition(:,1),'YData', ...
                         axesPosition(:,2));
            if offsetFlag
                %set(roiPatch,'FaceAlpha',0.5);
                set(roiPatch,'LineStyle','-');
                set(roiPatch,'UserData','offset');
                cmap = jet(256);
                errColorIdx = max(1,round(self.posErr*length(cmap)));
                disp(errColorIdx)
                fcolor = cmap(errColorIdx,:);
                set(roiPatch,'FaceColor',fcolor);
            else
                if strcmp(get(roiPatch,'UserData'),'offset')
                    % TODO reset to default face color
                    %set(roiPatch,'FaceAlpha',0.5);
                    set(roiPatch,'LineStyle','none');
                    set(roiPatch,'UserData',[]);
                end
            end
        end
        
        function offsetYx = matchPos(self,inputImg,tempImg, ...
                                        windowSize,fitGauss,normFlag,plotFlag)
            if ~exist('fitGauss','var')
                fitGauss=1;
            end
                
            if ~exist('plotFlag','var')
                plotFlag=0;
            end
            
            mask = self.createMask();
            [maskIndX,maskIndY] = find(mask==1);
            xmin = max(min(maskIndX)-windowSize,1);
            xmax = min(max(maskIndX)+windowSize,size(inputImg,1));
            ymin = max(min(maskIndY)-windowSize,1);
            ymax = min(max(maskIndY)+windowSize,size(inputImg,2));
            inputRimg = inputImg(xmin:xmax,ymin:ymax);
            tempRimg = tempImg(xmin:xmax,ymin:ymax);
            if plotFlag
                figure
                imagesc(inputRimg)
                title('input')
                figure
                imagesc(tempRimg)
                title('temp')
            end
            [self.offsetYx,self.posErr] = movieFunc.alignImage(inputRimg, ...
                                                 tempRimg,fitGauss,normFlag,plotFlag);
        end
        
        function acceptShift(self)
            offsetYx = self.offsetYx;
            self.position = self.position + [offsetYx(2),offsetYx(1)];
        end
        
        function rejectShift(self,roiPatch)
            self.offsetYx = [0, 0];
        end
    end
    
    methods (Static)
        function mpos = computePosFromPatch(axesPosition,parent)
        % Get ROI position from patch object in axes position
            if ishandle(parent)
                imageSize = size(getimage(parent));
                plpos = getPixelPosition(parent, ...
                                       axesPosition);
                offset = floor(min(plpos,[],1));
                plpos_small = plpos - offset + 1;
                roiSize = ceil(max(plpos,[],1) - offset);
                mask = poly2mask(plpos_small(:,1),plpos_small(:,2),...
                                 roiSize(2),roiSize(1));
                [mposY,mposX] = find(mask);
                mpos = [mposX,mposY] + offset;
            end
        end
        
        function result = isaRoiPatch(hobj)
            result = false;
            if ishandle(hobj) && isvalid(hobj) && isprop(hobj,'Tag')
                tag = get(hobj,'Tag');
                if strfind(tag,'roi_')
                    result = true;
                end
            end
        end
        
        function ptTag = getPatchTag(tag)
            ptTag = sprintf('roi_%04d',tag);
        end

    end
end


function pixelPos = getPixelPosition(parent,axesPos)
    [xdata,ydata,cdata] = getimage(parent);
    imageSize = size(cdata);

    if isDefaultCoordinate(imageSize,xdata,ydata)
        pixelPos = axesPos;
    else
        [xWorldLim,yWorldLim] = getWorldLim(imageSize,xdata,ydata);
        refObj = imref2d(imageSize,xWorldLim,yWorldLim);
        [posx,posy] = worldToIntrinsic(refObj,...
                                       axesPos(:,1),axesPos(:,2));
        pixelPos = [posx,posy];
    end
end

function axesPos = getAxesPosition(parent,pixelPos)
% GETAXESPOSITON convert postion in intrinsic coordinates into world
% coordinates.
% Usage: axesPos = getAxesPosition(parent,pixelPos)
% parent can be a handle of an image, or a handle that contains
% image as children
    
    [xdata,ydata,cdata] = getimage(parent);
    imageSize = size(cdata);

    if isDefaultCoordinate(imageSize,xdata,ydata)
        axesPos = pixelPos;
    else
        [xWorldLim,yWorldLim] = getWorldLim(imageSize,xdata,ydata);
        refObj = imref2d(imageSize,xWorldLim,yWorldLim);
        [posx,posy] = intrinsicToWorld(refObj,...
                                       pixelPos(:,1),pixelPos(:,2));
        axesPos = [posx,posy];
    end
end

function [xWorldLim,yWorldLim] = getWorldLim(imageSize,xdata,ydata)
        pixelExtentInWorldX = (xdata(2)-xdata(1))/imageSize(2);
        xWorldLim = [xdata(1)-pixelExtentInWorldX*0.5,...
                     xdata(2)+pixelExtentInWorldX*0.5];
        pixelExtentInWorldY = (ydata(2)-ydata(1))/imageSize(1);
        yWorldLim = [ydata(1)-pixelExtentInWorldY*0.5,...
                     ydata(2)+pixelExtentInWorldY*0.5];
end

function tf = isDefaultCoordinate(imageSize,xdata,ydata)
    if isequal(xdata,[1 imageSize(2)]) && isequal(ydata,[1 imageSize(1)])
        tf = true;
    else
        tf = false;
    end
end
