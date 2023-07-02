function y = custom_gaussian(x, position, height, width)
    %  gaussian(x,pos,wid) = gaussian peak centered on pos, half-width=wid
    %  x may be scalar, vector, or matrix, pos and wid both scalar
    %  T. C. O'Haver, 1988
    y = height*exp(-((x - position) ./ (0.60056120439323 .* width)) .^ 2);
end