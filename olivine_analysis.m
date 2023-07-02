%% Before analysis
% ! rsm -> csv 파일 저장할 때 header 를 포함하지 않고 저장하기 !
% 분석을 수행할 csv 파일들이 저장된 폴더에 아래의 코드를 복사 & 붙여넣기
% olivine_analysis.m: 현재 파일
% gaussian.m, lorentz.m: 가우시안, 로렌츠 함수
% basecor.m: baseline correction을 위한 arPLS 알고리즘 
% (Reference: https://github.com/heal-research/arPLS)

%% File read and save

folderPath = pwd; % 현재 작업 디렉토리로 폴더 경로 설정

defaultFilePattern = '*.csv'; % 기본 파일 패턴
disp(['Enter file pattern (e.g., *.csv) [default: ', defaultFilePattern, ']:']);
filePattern = input('', 's');
if isempty(filePattern)
    filePattern = defaultFilePattern;
end

files = dir(fullfile(folderPath, filePattern)); % 사용자가 입력한 파일 패턴에 맞는 파일 목록 가져오기

spectra = cell(1, numel(files)); % 스펙트럼을 저장할 셀 배열 선언
spectraNames = cell(1, numel(files)); % 시료 이름을 저장할 셀 배열 선언

for i = 1:numel(files)
    filename = fullfile(folderPath, files(i).name); % 파일의 전체 경로 생성
    
    % 시료 이름 처리
    useFilenameAsSpecimenName = input(['Do you want to use the file name "', files(i).name, '" as the specimen name? (y/n): '], 's');
    
    if strcmpi(useFilenameAsSpecimenName, 'y')
        endIndex = strfind(name, '.csv') - 1;
        specimenName = name(1:endIndex); % 파일 이름 그대로 시료 이름으로 사용
    else
        startingSubstring = input('Enter the starting substring to extract the specimen name: ', 's');
        startingIndex = strfind(files(i).name, startingSubstring) + numel(startingSubstring);
        name = files(i).name(startingIndex:end);
        endIndex = strfind(name, '.csv') - 1;
        specimenName = name(1:endIndex);
    end
    
    % 파일 읽기
    fileData = readmatrix(filename, 'OutputType', 'double'); % 첫 번째 행도 데이터로 읽어옴
    
    ramanShift = fileData(1, 2:end); % Raman shift (첫 번째 행, 첫 번째 열은 건너뛰고 두 번째 열부터 사용)
    intensity = fileData(2:end, 2:end); % Intensity (첫 번째 열, 첫 번째 행은 건너뛰고 두 번째 열부터 사용)

    % 스펙트럼 및 시료 이름 저장
    spectra{i} = intensity;
    spectraNames{i} = specimenName;
end



%% Preprocessing & analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 전처리 및 분석을 수행할 스펙트럼을 선택
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 시료 이름 리스트 출력
disp('List of available specimen names:');
disp(spectraNames);
selectedSpecimen = input('Select the specimen name: ', 's'); % 사용자에게 시료 이름 선택 요청

% 선택된 시료 이름에 해당하는 스펙트럼 찾기
selectedIndex = find(strcmp(spectraNames, selectedSpecimen), 1);
if isempty(selectedIndex)
    error('Specimen not found.');
else
    selectedSpectrum = spectra{selectedIndex}; % 선택된 시료의 스펙트럼
end

%% Preprocessing 0. Select lambda for baseline correction

% 사용자에게 lambda 배열 요청
lambdaArray = input('Enter the lambda values for baseline correction [e.g., 1e5, 1e6], default: [1e4, 1e5, 1e6]: ');

if isempty(lambdaArray)
    lambdaArray = [1e4, 1e5, 1e6];
end

rng('default'); % reproducibility를 보장하기 위해 랜덤 선택의 seed 를 기본값으로 지정
numRandomSpectra = 3; % 랜덤한 스펙트럼 개수

figure
for i = 1:numel(lambdaArray)
    lambda = lambdaArray(i);
    
    % Select random spectra for comparison
    numSpectra = size(selectedSpectrum, 1);
    randomIndices = randperm(numSpectra, numRandomSpectra);
    
    for j = 1:numRandomSpectra
        spectrum = selectedSpectrum(randomIndices(j), :);
        [~, bgd, ~] = basecor(spectrum', lambda, 0.001); % baseline correction을 수행하기 위해 spectrum을 전치행렬로 변환
        correctedSpectrum = spectrum' - bgd; % correctedSpectrum도 전치행렬로 변환하여 계산
        
        subplot(numel(lambdaArray), numRandomSpectra, (i-1)*numRandomSpectra + j);
        plot(ramanShift, spectrum, ramanShift, correctedSpectrum);
        xlabel('Raman Shift');
        ylabel('Intensity (A.U.)');
        title(['Lambda = ' num2str(lambda)]);
        legend('Original Spectrum', 'Corrected Spectrum');
    end
end
%% Preprocessing 1. Baseline correction for selectedSpectrum

% 사용자에게 lambda 값 요청
clear lambda
lambda = input('Enter the lambda value for baseline correction (e.g., 1e5, default: 1e6): ');

if isempty(lambda)
    lambda = 1e6;
end

correctedSpectra = cell(size(spectra)); % 보정된 스펙트럼을 저장할 셀 배열
correctedSpectrum = zeros(size(selectedSpectrum));

tic; % baseline correcttion에 걸리는 시간 확인
for i = 1:size(selectedSpectrum,1)
    spectrum = selectedSpectrum(i,:);
    [~, bgd, ~] = basecor(spectrum', lambda, 0.001); % baseline correction을 수행하기 위해 spectrum을 전치행렬로 변환
    correctedSpectrum(i,:) = (spectrum' - bgd)'; % correctedSpectrum도 전치행렬로 변환하여 계산
end

correctedSpectra{selectedIndex} = correctedSpectrum;
clear correctedSpectrum
toc; 

% 도움말; 보통 baseline correction은 컴퓨터 사양에 따라 다르지만 5분을 넘기지 않습니다
% 시간이 비정상적으로 오래걸리는 경우 일시정지를 누르고 i 값을 확인하여 주어진 lambda에 대해
% baseline correction이 잘 수행되지 않는 위치의 열 번호를 확인하여 for 문에서 제외합니다
%% Analysis 0. Input target
% 0. Display a random Raman shift, intensity plot and ask for fitting range
numSpectra = size(selectedSpectrum, 1);
randomIndex = randi(numSpectra);
randomSpectrum = selectedSpectrum(randomIndex, :);

figure
plot(ramanShift, randomSpectrum);
xlabel('Raman Shift');
ylabel('Intensity (A.U.)');
title('Randomly Selected Spectrum');

fittingRange = input('Enter the Raman shift range for fitting [e.g., 500 2000]: ');

% Select the data within the fitting range
fittingIndices = find(ramanShift >= fittingRange(1) & ramanShift <= fittingRange(2));
fittingShift = ramanShift(fittingIndices);
fittingSpectrum = randomSpectrum(fittingIndices);

% 1. Ask for the number of expected peaks
numPeaks = input('Enter the number of expected peaks: ');

% 2. Ask for the peak positions
peakPositions = input('Enter the peak positions or leave blank for random selection: ');

if isempty(peakPositions)
    peakPositions = randi([fittingRange(1), fittingRange(2)], 1, numPeaks);
elseif length(peakPositions) ~= numPeaks
    error('The number of peak positions does not match the number of expected peaks.');
end

% 3. Ask for the peak widths
peakWidths = input('Do you want to enter the peak widths? (y/n): ', 's');

if strcmp(peakWidths, 'y')
    peakWidths = input('Enter the peak widths: ');
    if isempty(peakWidths)
        peakWidths = repmat(80, 1, numPeaks);
    elseif length(peakWidths) ~= numPeaks
        error('The number of peak widths does not match the number of expected peaks.');
    end
else
    peakWidths = repmat(80, 1, numPeaks);
end

% 4. Ask for the peak shapes
peakShapes = input('Enter the peak shapes (g for Gaussian, l for Lorentzian) or leave blank for Lorentzian: ', 's');

if isempty(peakShapes)
    peakShapes = repmat('l', 1, numPeaks);
end
%
% 5. Perform curve fitting
fittingFunction = '';
for i = 1:numPeaks
    peakHeights = ['h' num2str(i)];
    if peakShapes(i) == 'g'
        peakFunction = ['gaussian(x, ' num2str(peakPositions(i)) ', ' peakHeights ', ' num2str(peakWidths(i)) ')'];
    else
        peakFunction = ['lorentz(x, ' num2str(peakPositions(i)) ', ' peakHeights ', ' num2str(peakWidths(i)) ')'];
    end
    if i == 1
        fittingFunction = peakFunction;
    else
        fittingFunction = [fittingFunction ' + ' peakFunction];
    end
end

startPoints = rand(1, numPeaks*2); % We need two starting points (height and width) for each peak
fittingOptions = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', startPoints);
fittingType = fittype(fittingFunction, 'options', fittingOptions, 'independent', 'x');

[fittingResult, gof] = fit(fittingShift', fittingSpectrum', fittingType);

% Display the fitting result and goodness of fit
disp(fittingResult);
disp(gof);

%% Visualization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot all spectra in specific specimen

% 시료 이름 처리
plotPlainOrCorrectedSpectrum = input('Do you want to plot plain (p) or corrected (c) spectra (p/c): ', 's');

if strcmpi(plotPlainOrCorrectedSpectrum, 'p')
    % 시료 이름 리스트 출력
    disp('List of plain specimen names:');
    disp(spectraNames);

    selectedSpecimen = input('Select the specimen name: ', 's'); % 사용자에게 시료 이름 선택 요청

    % 선택된 시료 이름에 해당하는 스펙트럼 찾기
    selectedIndexForPlot = find(strcmp(spectraNames, selectedSpecimen), 1);

    if isempty(selectedIndexForPlot)
        error('Specimen not found.');
    else
        selectedSpectrum = spectra{selectedIndexForPlot}; % 선택된 시료의 스펙트럼
        plot(ramanShift, selectedSpectrum);
        xlabel('Raman Shift');
        ylabel('Intensity (A.U.)');
        title(['Spectrum of ' selectedSpecimen]);
    end
else
    % 수정된 시료 이름 리스트 출력
    disp('List of corrected specimen names:');
    disp(spectraNames);

    selectedSpecimen = input('Select the specimen name: ', 's'); % 사용자에게 시료 이름 선택 요청

    % 선택된 시료 이름에 해당하는 스펙트럼 찾기
    selectedIndexForPlot = find(strcmp(spectraNames, selectedSpecimen), 1);
    
    if isempty(selectedIndexForPlot)
        error('Specimen not found.');
    else
        selectedSpectrum = correctedSpectra{selectedIndexForPlot}; % 선택된 시료의 스펙트럼
        plot(ramanShift, selectedSpectrum);
        xlabel('Raman Shift');
        ylabel('Intensity (A.U.)');
        title(['Spectrum of ' selectedSpecimen]);
    end
end
