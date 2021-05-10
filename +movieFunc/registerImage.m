function [tform,success]=registerImage(distorted,varargin)
    pa = inputParser;
    addRequired(pa,'distorted',@ismatrix);
    addParameter(pa,'original',[],@ismatrix);
    addParameter(pa,'metricThreshold',1000,@isnumeric)
    addParameter(pa,'featuresOriginal',[])
    addParameter(pa,'validPtsOriginal',[])
    parse(pa,distorted,varargin{:})
    pr = pa.Results;

    if length(pr.original)
        ptsOriginal  = detectSURFFeatures(original,'MetricThreshold',pr.metricThreshold);
        [featuresOriginal,validPtsOriginal]  = extractFeatures(original,ptsOriginal);
    else
        if length(pr.featuresOriginal)
            featuresOriginal = pr.featuresOriginal;
        else
            error('Neither original image nor features was provided!')
        end
        
        if length(pr.validPtsOriginal)
            validPtsOriginal = pr.validPtsOriginal;
        else
            error('Neither original image nor valid points was provided!')
        end
    end
    
    ptsDistorted = detectSURFFeatures(distorted, 'MetricThreshold',pr.metricThreshold);
    [featuresDistorted,validPtsDistorted] = extractFeatures(distorted,ptsDistorted);
    indexPairs = matchFeatures(featuresOriginal,featuresDistorted);
    if length(indexPairs) > 2
        matchedOriginal  = validPtsOriginal(indexPairs(:,1));
        matchedDistorted = validPtsDistorted(indexPairs(:,2));
        [tform, inlierIdx] = estimateGeometricTransform2D(...
            matchedDistorted, matchedOriginal, 'similarity');
        success = 1;
    else
        warning('Feature not matched! Returning identity');
        tform = affine2d();
        success = 0;
    end
    %inlierDistorted = matchedDistorted(inlierIdx, :);
    %inlierOriginal  = matchedOriginal(inlierIdx, :);
end

