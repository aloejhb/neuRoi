classdef RoiArray
    properties
        imageSize
        roiList
    end

    methods
        function self = RoiArray(imageSize,varargin)
            pa = inputParser;
            addRequired(pa,'imageSize',@ismatrix);
            addParameter(pa,'maskImg',[],@ismatrix);
            parse(pa,imageSize,varargin{:})
            pr = pa.Results;
            self.imageSize = imageSize;
            self.roiList = roiFunc.RoiM.empty();
            if length(pr.maskImg)
                tagArray = unique(pr.maskImg);
                for k=1:length(tagArray)
                    tag = tagArray(k);
                    if tag ~= 0
                        mask = pr.maskImg == tag;
                        [mposY,mposX] = find(mask);
                        position = [mposX,mposY];
                        roi = roiFunc.RoiM(position,'tag',double(tag));
                        self.roiList(end+1) = roi;
                    end
                end
            end
            end

        function transformRois(tform)
        for k=1:length(self.roiList)
            roi = self.roiList(k);
            roi.transformPosition(tform)
        end
        end

    end
end

