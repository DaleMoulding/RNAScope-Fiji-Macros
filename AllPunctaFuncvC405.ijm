// Macro to allow testing of RNAScope single puncta detection.
// Change the 7 variables on the line marked ****Enter Values***
// 7 variables, Channel Number to analyse, BG multiplier, Maxima Tolerance, Small Spot size, Large Spot size, Outlier size & threshold.
// WF Recommend (2, 1.2, 5, 1000, 3, 200) for 570 & (3, 1.5, 10, 1000, 5, 100) for 690 puncta. (No Maxima tolerance changes.)
// for single puncta: (2, 1.2, 5, 6, 3, 200) for 570; (3, 1.5, 10, 12, 5, 100) for 690 puncta.
// Confocal Recommend (2, 1.0, 500, 5, 5000, 4, 500); (3/4, 1.0, 1000, 5, 5000, 8, 500)
// Rakesh settings: (2, 1, 400, 10, 4000, 5, 500); (3, 1, 750, 7, 4000, 5, 400); (4, 1.5, 1000, 5, 5000, 5, 400); 
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
AllPunctaValues(3, 1, 750, 7, 4000, 5, 400); // requires 7 variables. ****Enter Values****
// The Channel number
// Background subtraction corrector. Larger value = more BG subtracted. 1.2 for 570. 1.5 for 690.
// Maxima Tolerance, Ch2 = 500, Ch3/4 = 1000
// Particle sizes. 5-10 & 18 for single puncta, 5-10 & 1800 for all puncta. Larger lower value as threshold set from mean signal, rather than triangle threshold.
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
// Cv401 Adapt the WF version for use on Confocal Images.
// vC402 Remove watershed, not needed as just taking the maxima that overlap with threhsolded regions.
// vC402, revert to subtract BG rather than using minimum filter, as edges are empty on tiled images.
// vC402, no need for BG relative threshold, ust use triangle for confocal. 
// vC402, add new variable, Maxima Toloerance. Ch2 = 500, Ch3/4 = 1000
// vc403, clean up opened images. Clean up //annotations and //old code. 
// vc403, Remove measuring mean intensity of spots (for AllPuncta).
// vc403, measure on the BG subtracted image.
// vc404, add Kill borders to remove spots touching edges that get missed by 'exclude' in analyse particles
// vc405, crashes if no spots detected. ROI manager saves with previous ROIs. Need to empty ROI manager for each round. Need to add an 'if manager isn't empty' before changing ROI manager colour.

function AllPunctaValues(ImageChannel, BGcorrector, MaxTol, SizeSmall, SizeBig, Radii, RemOutThresh){
	 
	Shortname = substring(getTitle(), 0, lengthOf(getTitle())-4);
	run("Duplicate...", "title=ImageIn duplicate channels="+ImageChannel);


	
// remove background so measures are absolute.
	run("Duplicate...", "title=BG");
	run("Subtract Background...", "rolling=10 create disable");   // 10 is standard setting
	run("Multiply...", "value="+BGcorrector); //v309 1.4 ???? Make this 1.2 for 570, 1.5 for 690
	imageCalculator("Subtract create", "ImageIn","BG");
	selectWindow("Result of ImageIn");

	run("Duplicate...", "title=gaus");					// blur the image, identify spots radius ~8pixels, 500 brighter than surroundings
	run("Gaussian Blur...", "sigma=0.75");  // 0.75 for WF. Try 1 for Confocal??
	run("Find Maxima...", "prominence="+MaxTol+" output=[Single Points]"); //new window called "gaus maxima" 
	selectWindow("gaus");
	
	run("Duplicate...", "title=gausRemOut");
	run("Remove Outliers...", "radius="+Radii+" threshold="+RemOutThresh+" which=Bright");
	imageCalculator("Difference create", "gaus","gausRemOut"); 
	selectWindow("gausRemOut"); // tidy up
	close();
	selectWindow("gaus");
	close();

	selectWindow("Result of gaus");
	setAutoThreshold("Triangle dark"); 
	setOption("BlackBackground", false);
	run("Convert to Mask");

	//run("Watershed");	// remove this step vC402, not neded as combining threshold with Find Maxima.
	run("Set Measurements...", "  redirect=None decimal=3");
	run("Analyze Particles...", "size="+SizeSmall+"-"+SizeBig+" pixel circularity=0.00-1.00 show=Masks exclude"); // change circ?? was 0.95
//v501 instead of making single points here with Find Maxima, do:
	imageCalculator("AND create", "Mask of Result of gaus","gaus Maxima"); 
	rename("Vor");
	run("Duplicate...", "title=PunctaCircles");
	run("Morphological Filters", "operation=Dilation element=Disk radius=6"); // make a circle for each puncta, diameter = 13 pixels
	run("Kill Borders");													// add a section to remove any spots touching edges, are some are missed by exclude edges
	rename("killBorders");
	selectWindow("Vor");
	run("Voronoi");											// rather than watershed, use an voroni image to separate all puncta
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Invert");
	imageCalculator("Min create", "Vor","killBorders");
	rename(Shortname+"-AllPunctaCh"+ImageChannel);
// measure on the input image AFTER removing background: redirect=[Result of ImageIn] (was Input, so the unprocessed image).
	run("Set Measurements...", "area mean integrated redirect=[Result of ImageIn] decimal=3");
// v308 subtract BG on orig image now to make all measures absolute?? Or better still use the BG image made earlier
	selectWindow(Shortname+"-AllPunctaCh"+ImageChannel);
	run("Analyze Particles...", "size=0-infinity pixel show=Nothing display exclude clear summarize add"); // v501 remove exclude on edges. Cv401 add this back

	count=roiManager("count");																//v405
	if (count != 0) {roiManager("deselect");												//v405
	roiManager("Set Color", "cyan"); // set ROIs to cyanroiManager("Set Color", "cyan");
	roiManager("save selected", savelocation+Shortname+"-AllPunctaCh"+ImageChannel+".zip");
	}

// Make an image of single points for each puncta that can be used to make a label map if IntDen of each point.
	imageCalculator("AND create", "PunctaCircles", Shortname+"-AllPunctaCh"+ImageChannel);
	selectWindow(Shortname+"-AllPunctaCh"+ImageChannel);
	close();
	selectWindow("Result of PunctaCircles");
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

}