// Macro to allow testing of RNAScope single puncta detection.
// Change the 6 variables on the line marked ****Enter Values***
// 6 variables, Channel Number to analyse, Small Spot size, Large Spot size, Outlier size.
// Recommend (2, 1.2, 5, 1000, 3, 200) for 570 & (3, 1.5, 10, 1000, 5, 100) for 690 puncta.
// for single puncta: (2, 1.2, 5, 6, 3, 200) for 570; (3, 1.5, 10, 12, 5, 100) for 690 puncta.
//
// 	     ***************************
//    Copyright (c) 2020 Dale Moulding, UCL. 
// Made available for use under the MIT license.
//     https://opensource.org/licenses/MIT

savelocation = getDirectory("Choose a Directory to save the ROIs");
count=roiManager("count");	
	if (count != 0) {
		roiManager("Deselect");
		roiManager("delete");
	}
AllPunctaValuesRemOut(2, 1.2, 5, 1000, 3, 200); // requires 6 variables. ****Enter Values****
// The Channel number
// Background subtraction corrector. Larger value = more BG subtracted. 1.2 for 570. 1.5 for 690.
// Particle sizes. 5/9, 18 for single puncta, 5/9, 1800 for all puncta. Larger lower value as threshold set from mean signal, rather than triangle threshold.
// The spot size for Remove outliers. 3 to 5 for Widefield, 100-200 Threshold ******* May be better at 250 for noisier images ********
// At 5 it also gets larger / more diffuse spots.

// changelog
// v101 use single points in centre of each detected spot, make a circle 13 pixel diameter for each puncta measurement
// v103 use voroni rather than watershed so all points are taken individually
// v301 Remove outliers, after  Gaus1 of orig. Difference of that to G1 original, then threshold Triangle, setting the size range for particles.
// this deals with patchy background (and N2V processed channels) isolating spots from the rest of the image.
// v302 try a variable for remove outliers threshold value.
// v303 Undo v302 5th variable, and setThreshold to mean/8 to 65535. Much harsher remove BG, now 5, was 25
// v304 add back v302 variable. reduce particle size to 2 (from 9). Divide Mean/20 for threshold. Background to 25
// v305 add median2 before Gaussian1
// v306 Subtract a RollingBall200 created image from input for BG correction.
// v307 abandoned, tried opening and G1 before thresholding
// v308 improve initial background correction. Minimum filter to remove bright spots, then a gaussian to make a smooth background.
// v308 remove median filter as no longer needed. 
// v308 I had mistakenly been doing a remove background rolling 3 BEFORE then making a background image to remove background! So that stage was doing nothing.
// v309 simply multiply the BG image by 1.4 before subtracting from orig
// v311 Increase minimum filter from 80 to 100 & the following gaussian from 100 to 20.
// v311 Move the measuring the mean for the channel AFTER duplicating the image. Otherwise in mutlichannel images it is doing the wrong channel!
// v311 add new variable. BG removal mulitplier. 1.2 for 570, 1.5 for 690.
// v502 add Find Maxima on BG subtracted and blurred image, with an AND function on the RemoveOutliers thresholded image, to remove edges detected on large spots.
// v504 Change output image to single spots with connected components labelling from the ROIs image, to fix errors in labelling.


function AllPunctaValuesRemOut(ImageChannel, BGcorrector, SizeSmall, SizeBig, Radii, RemOutThresh){
	 
	Shortname = substring(getTitle(), 0, lengthOf(getTitle())-8);
	run("Duplicate...", "title=ImageIn duplicate channels="+ImageChannel);

// get the mean image pixel intensity to set a threshold.
	run("Set Measurements...", "mean redirect=None decimal=3");
	run("Clear Results");
	run("Select All");
	run("Measure");
	Mean = getResult("Mean", 0);
		//print(Mean);
	selectWindow("Results");
	run("Close");
	
	//run("Subtract Background...", "rolling=3 disable");    // remove background so measures are absolute. move later in the script! This stops the next 5 lines doing anything!
// remove background after removing bright regions. v308	
	run("Duplicate...", "title=BG");
	run("Minimum...", "radius=100"); // v308 and do G50 in stead of background or g100. v311 100
	//run("Subtract Background...", "rolling=50 create sliding");
	run("Gaussian Blur...", "sigma=10");							// v311 20 (was 100)

run("Multiply...", "value="+BGcorrector); //v309 1.4 ???? Make this 1.2 for 570, 1.5 for 690
	
	imageCalculator("Subtract create", "ImageIn","BG");
	selectWindow("Result of ImageIn");

	//run("Subtract Background...", "rolling=25 disable");				// remove background so all measures are absolute.
	run("Duplicate...", "title=gaus");					// blur the image, identify spots radius ~8pixels, 500 brighter than surroundings
	//run("Median...", "radius=1");
	run("Gaussian Blur...", "sigma=0.75");
// v501 Find Maxima of all spots to use an AND command on the thresholded spots from Remove Outliers, to remove spots edged detected by Remvoe outliers.
	run("Find Maxima...", "prominence="+Mean/10+" output=[Single Points]"); //new window called "gaus maxima"
	selectWindow("gaus");
	
	run("Duplicate...", "title=gausRemOut");
	run("Remove Outliers...", "radius="+Radii+" threshold="+RemOutThresh+" which=Bright");
	imageCalculator("Difference create", "gaus","gausRemOut");
	selectWindow("gausRemOut"); // tidy up
	close();
	selectWindow("gaus");
	close();



	selectWindow("Result of gaus");

	//setAutoThreshold("Triangle dark"); // make a binary image of the spots. Selecting spots bigger than SizeSmall pixels.
	setThreshold(Mean/10, 65535);			// try a value 1/8th of the mean intensity
	setOption("BlackBackground", false);
	run("Convert to Mask");

	run("Watershed");
	run("Set Measurements...", "  redirect=None decimal=3");
	run("Analyze Particles...", "size="+SizeSmall+"-"+SizeBig+" pixel circularity=0.00-1.00 show=Masks exclude"); // change circ?? was 0.95
//v501 instead of making single points here with Find Maxima, do:
	imageCalculator("AND create", "Mask of Result of gaus","gaus Maxima"); // NOT WORKING AS EXPECTED - fixed, was just the wrong channel

	//run("Find Maxima...", "prominence=10 light output=[Single Points]"); // make each spot a single point.
	rename("Vor");
	run("Duplicate...", "title=PunctaCircles");
	run("Morphological Filters", "operation=Dilation element=Disk radius=6"); // make a circle for each puncta, diameter = 13 pixels
	run("Kill Borders");		// v503											// add a section to remove any spots touching edges, are some are missed by exclude edges
	rename("killBorders");
	selectWindow("Vor");
	run("Voronoi");											// rather than watershed, use an voroni image to separate all puncta
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Invert");
	imageCalculator("Min create", "Vor","killBorders"); // v503
	rename(Shortname+"-AllPunctaCh"+ImageChannel);
	run("Set Measurements...", "area mean integrated redirect=ImageIn decimal=3");
// v308 subtract BG on orig image now to make all measures absolute?? Or better still use the BG image made earlier
	selectWindow(Shortname+"-AllPunctaCh"+ImageChannel);
// measure on the input image AFTER removing background: redirect=[Result of ImageIn] (was Input, so the unprocessed image).
	run("Set Measurements...", "area mean integrated redirect=[Result of ImageIn] decimal=3");
	run("Analyze Particles...", "size=0-infinity pixel show=Nothing display exclude clear summarize add");

	roiManager("deselect");
	roiManager("Set Color", "cyan"); // set ROIs to cyanroiManager("Set Color", "cyan");
	roiManager("save selected", savelocation+Shortname+"-AllPunctaCh"+ImageChannel+".zip");

// Make an image of single points for each puncta that can be used to make a label map of IntDen of each point.
	selectWindow(Shortname+"-AllPunctaCh"+ImageChannel);
	run("Connected Components Labeling", "connectivity=8 type=[16 bits]");
	rename("labels");
	selectWindow("PunctaCircles"); // this is single spots from Find maxima
	run("Divide...", "value=255"); // make each spot value = 1
	imageCalculator("Multiply create", "labels","PunctaCircles"); //make the labelled image the ROI# with just a single spot.
	rename("PunctaCh"+ImageChannel);

	selectWindow("ImageIn"); // tidy up
	close();
	selectWindow("Result of gaus");
	close();
	selectWindow("Vor");
	close();
	selectWindow("PunctaCircles-Dilation");
	close();
	selectWindow("PunctaCircles");
	close();
	selectWindow("Mask of Result of gaus");
	close();
	selectWindow("Result of ImageIn");
	close();
	selectWindow("BG");
	close();
	selectWindow("gaus Maxima");
	close();
	selectWindow("killBorders");
	close();
	selectWindow("labels");
	close();
	selectWindow(Shortname+"-AllPunctaCh"+ImageChannel);
	close();

}