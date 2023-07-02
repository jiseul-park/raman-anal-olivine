# raman-anal-olivine
Hey there, I have a MATLAB code that can help you analyze the Raman spectrum of olivine. The best part is that with some modifications, you can also use this code to analyze the Raman spectrum of other minerals. 

## Data preparation
To prepare the data, we use confocal Raman microscopy from NOST, Korea, and the file format of mapping spectra is .rsm. When you open an rsm file, it will look something like this:
![image|400](https://github.com/jiseul-park/raman-anal-olivine/assets/43870536/9e6971c9-1620-4f40-85c7-c5bbd021fbf0)

### Remove cosmic ray
To eliminate cosmic rays, simply utilize the basic function in the Raon-Vu program. By right-clicking the ROI window in the left panel, you may select "Remove Cosmicray" multiple times. It's recommended to do this where no bands are visible to avoid eliminating any meaningful Raman signal. This image demonstrates how to do so:
![image|400](https://github.com/jiseul-park/raman-anal-olivine/assets/43870536/1d63859c-c114-4e2d-b60a-bb610083afa1)

### Export spectra as csv file without header
Afterward, export the spectra as a csv file without a header. When saving the csv file, remember NOT to include the header! These steps are demonstrated in these images: 
![스크린샷 2023-07-02 오후 12 54 11](https://github.com/jiseul-park/raman-anal-olivine/assets/43870536/4949d632-bf90-4714-96b6-c5c6bd93bfc8)

### Caution!
1. Save the CSV file without including headers! 
![스크린샷 2023-07-02 오후 12 57 28](https://github.com/jiseul-park/raman-anal-olivine/assets/43870536/daf2496a-2b04-4481-8bf9-181473f8b424)
2. The file name should start with a letter and consist of only letters, numbers, and underscores (_).
