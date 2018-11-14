function responseFilePath = getResponseFilePath(filePath, ...
                                                responseResultDir,responseOption)
    [~,fileBaseName,~] = fileparts(filePath);
    responseOptStr = sprintf('resp-%d-%d',responseOption.responseWindow(1), ...
                             responseOption.responseWindow(2));
    responseFilePath = fullfile(responseResultDir,[fileBaseName '_' ...
                        responseOptStr '.mat']);