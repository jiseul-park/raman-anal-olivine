# raman-anal-olivine
Hey there, I have a MATLAB code that can help you analyze the Raman spectrum of olivine. The best part is that with some modifications, you can also use this code to analyze the Raman spectrum of other minerals. 

## Data preparation
To prepare the data, we use confocal Raman microscopy from NOST, Korea, and the file format of mapping spectra is .rsm. When you open an rsm file, it will look something like this:
![image|400](https://github.com/jiseul-park/raman-anal-olivine/assets/43870536/9e6971c9-1620-4f40-85c7-c5bbd021fbf0)

### Remove cosmic ray
To remove cosmic rays, you can use the basic function in the Raon-Vu program. Simply right-click the ROI window in the left panel and select "Remove Cosmicray" several times. It is recommended to do this where no bands are observed to prevent removing any meaningful Raman signal. 
![image|400](https://github.com/jiseul-park/raman-anal-olivine/assets/43870536/1d63859c-c114-4e2d-b60a-bb610083afa1)

