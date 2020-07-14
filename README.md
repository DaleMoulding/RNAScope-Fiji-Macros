# RNAScope-Fiji-Macros
A set of Fiji macros to automate analysis of fluorescent RNAScope images

All macros still in development.

One set was desigend to work on confocal images, the second set for widefield images.

All covered by MIT license.

The idea is to firstly identify the dimmest puncta, to set a value for a single spot. Then identify all puncta, and score each puncta relative to a single spot.
Cells are then identified in the Dapi channal and all cells scored for nuber of spots, and also each spot is scored relative to a single puncta.

SinglePunctaFuncvC404.ijm and AllPunctaFuncvC405 allow you to test the puncta identification on individual images.
You need to fine tune variables. (More help to come, advice for setting the variables).
Macros to allow testing of RNAScope single puncta detection.
Change the 7 variables on the line marked Enter Values

7 variables, Channel Number to analyse, BG multiplier, Maxima Tolerance, Small Spot size, Large Spot size, Outlier size & threshold.

WF Recommend (2, 1.2, 5, 1000, 3, 200) for 570 & (3, 1.5, 10, 1000, 5, 100) for 690 puncta. (No Maxima tolerance changes.)

for single puncta: (2, 1.2, 5, 6, 3, 200) for 570; (3, 1.5, 10, 12, 5, 100) for 690 puncta.

Confocal Recommend (2, 1.0, 500, 5, 5000, 4, 500); (3/4, 1.0, 1000, 5, 5000, 8, 500) for all Puncta.

Single Puncta: Make the Large spot size 1.5x small spots size, and round up to nearest whole number.

RNAScopeCv301 runs on a folder of 4 channel images. Dapi, and 3 RNAScope channels. (Crashes if no puncta detected).

RNAScopeCv202 runs on a single image.

Widefield Macros

SinglePunctaFuncWFv503, AllPunctaFuncWFv504 to test the 6 variable required.
6 variables, Channel Number to analyse, Small Spot size, Large Spot size, Outlier size.
Recommend (2, 1.2, 5, 1000, 3, 200) for 570 & (3, 1.5, 10, 1000, 5, 100) for 690 puncta.
for single puncta: (2, 1.2, 5, 6, 3, 200) for 570; (3, 1.5, 10, 12, 5, 100) for 690 puncta.

