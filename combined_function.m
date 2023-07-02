function y = combined_function(params, x, peakShapes, numPeaks)
    y = zeros(size(x));
    numParamsPerPeak = 3;
    for i = 1:numPeaks
        index = (i-1) * numParamsPerPeak + 1;
        position = params(index);
        height = params(index + 1);
        width = params(index + 2);
        
        if strcmp(peakShapes(i), 'g')
            y = y + custom_gaussian(x, position, height, width);
        else
            y = y + custom_lorentzian(x, position, height, width);
        end
    end
end