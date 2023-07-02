%% 1. 분석 전처리
% 1.1 파일 불러오기
% 분석을 수행할 csv 파일을 현재 작업 디렉토리에 붙여넣기

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
        name = files(i).name(1:end);
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



%% 2. 전처리
% 2.1 전처리를 수행할 시료 선택

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

%% 2.2 baseline correction을 위한 파라미터 선택

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
%% 2.3 선택한 시료의 전체 위치에 대해 동일한 기준으로 baseline correction 수행

% 사용자로부터 Raman band가 없는 Raman shift 범위 요청
noBandRange = input('Enter the Raman shift range where no Raman band is present (e.g., [200 300]): ');

if isempty(noBandRange) || length(noBandRange) ~= 2
    error('Please enter a valid Raman shift range.');
end

% 사용자에게 lambda 값 요청
clear lambda
lambda = input('Enter the lambda value for baseline correction (e.g., 1e5, default: 1e6): ');

if isempty(lambda)
    lambda = 1e6;
end

correctedSpectra = cell(size(spectra)); % 보정된 스펙트럼을 저장할 셀 배열
correctedSpectrum = zeros(size(selectedSpectrum));

noiseLevels = zeros(size(selectedSpectrum, 1), 1); % 노이즈 레벨을 저장할 배열

tic; % baseline correction에 걸리는 시간 확인
for i = 1:size(selectedSpectrum, 1)
    spectrum = selectedSpectrum(i, :);
    [~, bgd, ~] = basecor(spectrum', lambda, 0.001); % baseline correction을 수행하기 위해 spectrum을 전치행렬로 변환
    correctedSpectrum(i, :) = (spectrum' - bgd)'; % correctedSpectrum도 전치행렬로 변환하여 계산
    
    % 노이즈 레벨 계산
    indicesInRange = find(ramanShift >= noBandRange(1) & ramanShift <= noBandRange(2));
    noiseInRange = abs(correctedSpectrum(i, indicesInRange));
    noiseLevels(i) = std(noiseInRange);
end

correctedSpectra{selectedIndex} = correctedSpectrum;
clear correctedSpectrum
toc;
% 도움말; 보통 baseline correction은 컴퓨터 사양에 따라 다르지만 5분을 넘기지 않습니다
% 시간이 비정상적으로 오래걸리는 경우 일시정지를 누르고 i 값을 확인하여 주어진 lambda에 대해
% baseline correction이 잘 수행되지 않는 위치의 열 번호를 확인하여 for 문에서 제외합니다

%% 3. 분석
% 3.1 임의의 스펙트럼에 대해 예비 분석 수행
% 피팅을 수행할 ramanshift 범위 설정, peak 개수와 폭에 대한 초기값 확인

% 시료 이름 리스트 출력
disp('List of available specimen names:');
disp(spectraNames);
selectedSpecimen = input('Select the specimen name: ', 's'); % 사용자에게 시료 이름 선택 요청

% 선택된 시료 이름에 해당하는 스펙트럼 찾기
selectedIndex = find(strcmp(spectraNames, selectedSpecimen), 1);
if isempty(selectedIndex)
    error('Specimen not found.');
else
    selectedSpectrum = correctedSpectra{selectedIndex}; % 선택된 시료의 스펙트럼
end

numSpectra = size(selectedSpectrum, 1);
randomIndex = randi(numSpectra);
randomSpectrum = selectedSpectrum(randomIndex, :);

figure
plot(ramanShift, randomSpectrum);
xlabel('Raman Shift');
ylabel('Intensity (A.U.)');
title('Randomly Selected Spectrum');

% 사용자로부터 피팅을 수행할 라만 이동 범위를 입력 받음
fittingRange = input('Enter the Raman shift range for fitting e.g., [500 2000]: ');

% 피팅을 수행할 범위를 잘라내기
fittingIndices = find(ramanShift >= fittingRange(1) & ramanShift <= fittingRange(2));
fittingShift = ramanShift(fittingIndices);
fittingSpectrum = randomSpectrum(fittingIndices);

% 사용자로부터 입력 받은 피크 수를 기반으로 곡선 맞춤 수행
numPeaks = input('Enter the number of peaks: ');

% 사용자로부터 피크 위치를 입력 받음
peakPositions = input('Enter the peak positions or leave blank for random selection: ');

if isempty(peakPositions)
    peakPositions = randi([fittingRange(1), fittingRange(2)], 1, numPeaks);
elseif length(peakPositions) ~= numPeaks
    error('The number of peak positions does not match the number of expected peaks.');
end

% 사용자로부터 피크 너비를 입력 받음
peakWidthsInput = input('Do you want to enter the peak widths? [default: 20] (y/n): ', 's');

if strcmp(peakWidthsInput, 'y')
    peakWidths = input('Enter the peak widths: ');
    if isempty(peakWidths)
        peakWidths = repmat(20, 1, numPeaks);
    elseif length(peakWidths) ~= numPeaks
        error('The number of peak widths does not match the number of expected peaks.');
    end
else
    peakWidths = repmat(20, 1, numPeaks);
end

% 사용자로부터 피크 모양을 입력 받음
peakShapesInput = input('Enter the peak shapes (g for Gaussian, l for Lorentzian) or leave blank for Lorentzian: ', 's');

if isempty(peakShapesInput)
    peakShapesInput = repmat("l", 1, numPeaks);
else
    peakShapesInput = split(peakShapesInput);
    if length(peakShapesInput) ~= numPeaks
        error('The number of peak shapes does not match the number of expected peaks.');
    end
end

% 문자열로 함수 타입 정의
funcStr = '';
for i = 1:numPeaks
    h = ['h', num2str(i)];
    p = ['p', num2str(i)];
    w = ['w', num2str(i)];
    
    if strcmp(peakShapesInput(i), 'g')
        % Gaussian
        funcStr = [funcStr, h, '*exp(-((x-', p, ')/(0.60056120439323*', w, '))^2)'];
    else
        % Lorentzian
        funcStr = [funcStr, h, '/(1+((x-', p, ')/', w, ')^2)'];
    end
    
    if i ~= numPeaks
        funcStr = [funcStr, ' + '];
    end
end

f = fittype(funcStr); % fit 함수 정의

% 초기 추정값, 상한, 하한 설정
% 입력받은 position의 상한과 하한 범위를 설정
positionThreshold = 10;

% height의 초기 추정값을 저장할 배열
initialHeights = zeros(1, numPeaks);

% 각 피크에 대해 상한과 하한 범위 내에서 최대값을 찾음
for i = 1:numPeaks
    lowerBoundPosition = peakPositions(i) - positionThreshold;
    upperBoundPosition = peakPositions(i) + positionThreshold;
    
    % 상한과 하한 범위 내에 있는 데이터 선택
    indicesInRange = find(ramanShift >= lowerBoundPosition & ramanShift <= upperBoundPosition);
    spectrumInRange = randomSpectrum(indicesInRange);
    
    % 최대값을 찾아 초기 추정값으로 설정
    initialHeights(i) = max(spectrumInRange);
end

% startPoints 배열에 height의 초기 추정값 추가
startPoints = [initialHeights,peakPositions, peakWidths];

% fitting의 상한과 하한 설정
lowerBoundsPositions = peakPositions - positionThreshold;
upperBoundsPositions = peakPositions + positionThreshold;

% h와 w에 대한 상한과 하한을 설정, 추가로 설정된 threshold는 없음
lowerBoundsHeights = zeros(1, numPeaks);
upperBoundsHeights = Inf(1, numPeaks);
lowerBoundsWidths = zeros(1, numPeaks);
upperBoundsWidths = Inf(1, numPeaks);

% 모든 상한과 하한을 하나의 배열로 결합
lowerBounds = [lowerBoundsHeights, lowerBoundsPositions, lowerBoundsWidths];
upperBounds = [upperBoundsHeights, upperBoundsPositions, upperBoundsWidths];

% fit 함수를 사용하여 곡선 맞춤
[fitResult, gof] = fit(fittingShift', fittingSpectrum', f, 'StartPoint', startPoints, 'Lower', lowerBounds, 'Upper', upperBounds);

% 피팅 결과와 적합도 표시
disp(fitResult);
disp(gof);

% 원본 데이터 플롯
figure;
plot(fittingShift, fittingSpectrum, 'bo');
hold on;

% 피팅 곡선 플롯
x_fit = linspace(min(fittingShift), max(fittingShift), 1000);
y_fit = feval(fitResult, x_fit);
plot(x_fit, y_fit, 'r-');

% 레이블 및 제목 추가
xlabel('Raman Shift');
ylabel('Intensity (A.U.)');
title('Fitting Results');
legend('Original Data', 'Fitted Curve');

% hold 해제
hold off;


%% 3.2 선택한 시편의 전체 스펙트럼에 대해 수행
% 사용자에게 fitResult를 보여줌
disp(fitResult);

% fitResult, position, height, width를 저장할 변수 초기화
fitResults = cell(size(selectedSpectrum));
position = zeros(numSpectra, numPeaks);
height = zeros(numSpectra, numPeaks);
width = zeros(numSpectra, numPeaks);

% height의 초기 추정값을 저장할 배열
initialHeights = zeros(1, numPeaks);

% 사용자에게 fittingRange를 그대로 사용할 것인지 물어봄
useExistingFittingRange = input('Do you want to change the fitting range? (y/n): ', 's');

if strcmp(useExistingFittingRange, 'y')
    fittingRange = input('Enter the Raman shift range for fitting e.g., [500 2000]: ');
    fittingIndices = find(ramanShift >= fittingRange(1) & ramanShift <= fittingRange(2));
else

end

% 사용자에게 피크 수를 바꿀 것인지 물어봄
changeNumPeaks = input('Do you want to change the number of peaks? (y/n): ', 's');

if strcmp(changeNumPeaks, 'n')
    numPeaks = length(peakPositions);
end

% 사용자에게 피크 너비를 바꿀 것인지 물어봄
changePeakWidths = input('Do you want to change the peak widths? e.g., [23 52 44 ...](y/n): ', 's');

if strcmp(changePeakWidths, 'n')
    peakWidths = repmat(20, 1, numPeaks);
end

% 사용자에게 피크 모양을 바꿀 것인지 물어봄
changePeakShapes = input('Do you want to change the peak shapes? (y/n): ', 's');

if strcmp(changePeakShapes, 'n')
    peakShapesInput = repmat("l", 1, numPeaks);
else
    peakShapesInput = input('Enter the peak shapes (g for Gaussian, l for Lorentzian) or leave blank for Lorentzian: ', 's');
    if isempty(peakShapesInput)
        peakShapesInput = repmat("l", 1, numPeaks);
    else
        peakShapesInput = split(peakShapesInput);
        if length(peakShapesInput) ~= numPeaks
            error('The number of peak shapes does not match the number of expected peaks.');
        end
    end
end


% 문자열로 함수 타입 정의
funcStr = '';
for i = 1:numPeaks
    h = ['h', num2str(i)];
    p = ['p', num2str(i)];
    w = ['w', num2str(i)];

    if strcmp(peakShapesInput(i), 'g')
        % Gaussian
        funcStr = [funcStr, h, '*exp(-((x-', p, ')/(0.60056120439323*', w, '))^2)'];
    else
        % Lorentzian
        funcStr = [funcStr, h, '/(1+((x-', p, ')/', w, ')^2)'];
    end

    if i ~= numPeaks
        funcStr = [funcStr, ' + '];
    end
end

f = fittype(funcStr); % fit 함수 정의

% 초기 추정값, 상한, 하한 설정
% 입력받은 position의 상한과 하한 범위를 설정
positionThreshold = input('Enter the position threshold: ');

for locationIndex = 1:numSpectra
    fprintf('Fitting spectrum %d/%d\n', locationIndex, numSpectra);
    
    thisSpectrum= selectedSpectrum(locationIndex, :);
    fittingShift = ramanShift(fittingIndices);
    fittingSpectrum = thisSpectrum(fittingIndices);
    % 각 피크에 대해 상한과 하한 범위 내에서 최대값을 찾음
    for i = 1:numPeaks
        lowerBoundPosition = peakPositions(i) - positionThreshold;
        upperBoundPosition = peakPositions(i) + positionThreshold;

        % 상한과 하한 범위 내에 있는 데이터 선택
        indicesInRange = find(fittingShift >= lowerBoundPosition & fittingShift <= upperBoundPosition);
        spectrumInRange = fittingSpectrum(indicesInRange);

        % 최대값을 찾아 초기 추정값으로 설정
        initialHeights(i) = max(spectrumInRange);
    end

    % startPoints 배열에 height의 초기 추정값 추가
    startPoints = [initialHeights, peakPositions, peakWidths];

    % fitting의 상한과 하한 설정
    lowerBoundsPositions = peakPositions - positionThreshold;
    upperBoundsPositions = peakPositions + positionThreshold;

    % h와 w에 대한 상한과 하한을 설정, 추가로 설정된 threshold는 없음
    lowerBoundsHeights = zeros(1, numPeaks);
    upperBoundsHeights = Inf(1, numPeaks);
    lowerBoundsWidths = zeros(1, numPeaks);
    upperBoundsWidths = Inf(1, numPeaks);

    % 모든 상한과 하한을 하나의 배열로 결합
    lowerBounds = [lowerBoundsHeights, lowerBoundsPositions, lowerBoundsWidths];
    upperBounds = [upperBoundsHeights, upperBoundsPositions, upperBoundsWidths];

    % fit 함수를 사용하여 곡선 맞춤
    [fitResult, gof] = fit(fittingShift', fittingSpectrum', f, 'StartPoint', startPoints, 'Lower', lowerBounds, 'Upper', upperBounds);

    % 피팅 결과와 적합도 표시
    disp(fitResult);
    disp(gof);

    % fitResult, position, height, width 저장
    fitResults{locationIndex} = fitResult;
    temp = coeffvalues(fitResult);
    position(locationIndex, :) = temp(numPeaks+1:2*numPeaks);
    height(locationIndex, :) = temp(1:numPeaks);
    width(locationIndex, :) = temp(2*numPeaks+1:end);
end

% selectedSpectrum, selectedSpecimen, fitResults, position, height, width 저장
results.selectedSpectrum{selectedIndex} = selectedSpectrum;
results.selectedSpecimen{selectedIndex} = selectedSpecimen;
results.fitResults{selectedIndex} = fitResults;
results.position{selectedIndex} = position;
results.height{selectedIndex} = height;
results.width{selectedIndex} = width;
results.noiseLevels{selectedIndex} = noiseLevels;



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
