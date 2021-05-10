function [alignResult,varargout] = alignTrials(inDir,inFileList,templateName,varargin)
% ALIGNTRIALS align each trial with respect to the template anatomy
% image
%     Args:
%     Returns:

pa = inputParser;
addRequired(pa,'inDir',@ischar);
addRequired(pa,'inFileList',@iscell);
addRequired(pa,'templateName',@ischar);
addParameter(pa,'algorithm','rigid',@ischar);
addParameter(pa,'outFilePath','',@ischar);
addParameter(pa,'stackFilePath','',@ischar);
addParameter(pa,'metricThreshold',1000)
addParameter(pa,'climit',[0 1]);
addParameter(pa,'debug',false);
parse(pa,inDir,inFileList,templateName,varargin{:})
pr = pa.Results;


nFile = length(pr.inFileList);
anatomyArray = batch.loadStack(pr.inDir,pr.inFileList);

templateDir = fileparts(pr.templateName);
if isempty(templateDir)
    templatePath = fullfile(pr.inDir,pr.templateName);
else
    templatePath = pr.templateName;
end
templateAna = movieFunc.readTiff(templatePath);

if strcmp(pr.algorithm,'rigid')
    offsetYxMat = zeros(nFile,2);
    for k=1:nFile
        offsetYx = movieFunc.alignImage(anatomyArray(:,:,k),templateAna,pr.debug);
        offsetYxMat(k,:) = offsetYx;
    end
    alignResult.offsetYxMat = offsetYxMat;
elseif strcmp(pr.algorithm,'featureBased')
    zlimit = [0, 0.3];
    original = templateAna;
    original = imadjust(original,zlimit);
    disp(pr.metricThreshold)
    ptsOriginal  = detectSURFFeatures(original,'MetricThreshold',pr.metricThreshold);
    [featuresOriginal,validPtsOriginal]  = extractFeatures(original,ptsOriginal);
    tformList = affine2d.empty();
    for k=1:nFile
        distorted = anatomyArray(:,:,k);
        distorted = imadjust(distorted,zlimit);
        [tform,success] = movieFunc.registerImage(distorted,'featuresOriginal',featuresOriginal,'validPtsOriginal',validPtsOriginal);
        if ~success
            message = sprintf('Anatomy not matched: distorted: %s, template: %s',pr.inFileList{k},pr.templateName);
            disp(message)
        end
        tformList(k) = tform;
    end
    alignResult.tformList = tformList;
else
    error('Algorithm should be either rigid or featureBased!')
end

alignResult.algorithm = pr.algorithm;
alignResult.inDir = pr.inDir;
alignResult.inFileList = pr.inFileList;
alignResult.templateName = pr.templateName;

% Save alignment result
if length(pr.outFilePath)
    save(pr.outFilePath,'alignResult')
end

if nargout == 2 | length(pr.stackFilePath)
    if strcmp(pr.algorithm,'rigid')
        alignedStack = shiftStack(anatomyArray,offsetYxMat,pr.algorithm);
    else
        alignedStack = shiftStack(anatomyArray,tformList,pr.algorithm);
    end
    
    if length(pr.stackFilePath)
        movieFunc.saveTiff(alignedStack, ...
                           pr.stackFilePath);
    end
    if nargout == 2
        varargout{1} = alignedStack;
    end
end

function alignedStack = shiftStack(stack,tformList,algorithm)
alignedStack = stack;
if strcmp(algorithm,'featureBased')
    outputView = imref2d(size(alignedStack(:,:,1)));
end
for k=1:size(stack,3)
    if strcmp(algorithm,'rigid')
        offsetYxMat = tformList;
        yxShift = offsetYxMat(k,:);
        alignedStack(:,:,k) = circshift(alignedStack(:,:,k),yxShift);
    elseif strcmp(algorithm,'featureBased')
        alignedStack(:,:,k) = imwarp(alignedStack(:,:,k),tformList(k),...
                                     'OutputView',outputView);
    end
    
end
