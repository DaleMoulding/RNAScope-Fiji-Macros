// Macro in development
// 	     ***************************
//    Copyright (c) 2020 Dale Moulding, UCL. 
// Made available for use under the MIT license.
//     https://opensource.org/licenses/MIT

/*
 * Combine functions for single spot and all spots into a single macro.
 * Use AllPunctaFuncWFv504 & SinglePunctaFuncWFv503.
 * Take the result for the single puncta mean IntDen
 * Use this to set the value for each measured puncta, relative to 1 = single puncta
 * Save ROIs for single and all puncta.
 */

//changelog 
// Adapted from Confocal version.
// Done Nuclei & Functions.
// v201. Swapped to a new spots identifyng method, combining Remove outliers with find maxima, using vC404 Puncta Function.
// v202. Save the Dapi ROIs. And tables for all puncta values & the summary.
// Problem: some values are incorrect in the spot images, as the ROIs are numbered differently from the dots.
// Occurs as counts are done from top of image then from the left. If 2 spots in same row, then the one on the left counted first.
// If the ROI encompassing the spots is extends higher on the right of the 2 spots, that ROI will be counted first,
// so the spots will be mis-labelled from the results table.
// v203, fix the mis-labelling problem
// v204, close results tables

	savelocation = getDirectory("Choose a Directory to save the ROIs");	
	count=roiManager("count");	
		if (count != 0) {
			roiManager("Deselect");
			roiManager("delete");
		}

	Shortname = substring(getTitle(), 0, lengthOf(getTitle())-8);

// measure single puncta ch2...
		selectWindow(Shortname+"-3ch.tif");
		SinglePuncta = SinglePunctaValues(2, 1.2, 5, 6, 3, 200); // requires 6 variables. ****Enter Values****
	// The Channel number
	// Background subtraction corrector. Larger value = more BG subtracted.
	// Particle sizes. 5-10 & 18 for single puncta, 5-10 & 4/5000 for all puncta. 
	// The spot size for Remove outliers. First radius, second how much brighter than the mean of that radius?
	
	// measure all puncta ch2...
		selectWindow(Shortname+"-3ch.tif");
		AllPunctaValuesRemOut(2, 1.2, 5, 1000, 3, 200); // requires 6 variables. ****Enter Values****
	
	// Make a labelled image of all puncta, with each spot scored as its IntDen
		name = getTitle();
		run("Assign Measure to Label", "results=Results column=IntDen");
		rename("temp");
		selectWindow(name);
		close();
		selectWindow("temp");
		rename(name);
		run("Divide...", "value="+SinglePuncta);
		// gives a window with each spot labelled with a value relative to 1 = single puncta

	// Save the values of all puncta 
		selectWindow("Results");
		saveAs("Results", savelocation+Shortname+"-Ch2-AllPuncta.csv");
		run("Close"); //v204

// measure single puncta ch3...
		selectWindow(Shortname+"-3ch.tif");
		SinglePuncta = SinglePunctaValues(3, 1.5, 10, 12, 5, 100); // requires 6 variables. ****Enter Values****
	
	// measure all puncta ch3...
		selectWindow(Shortname+"-3ch.tif");
		AllPunctaValuesRemOut(3, 1.5, 10, 1000, 5, 100); // requires 6 variables. ****Enter Values****
	
	// Make a labelled image of all puncta, with each spot scored as its IntDen
		name = getTitle();
		run("Assign Measure to Label", "results=Results column=IntDen");
		rename("temp");
		selectWindow(name);
		close();
		selectWindow("temp");
		rename(name);
		run("Divide...", "value="+SinglePuncta);
		// gives a window with each spot labelled with a value relative to 1 = single puncta

	// Save the values of all puncta 
		selectWindow("Results");
		saveAs("Results", savelocation+Shortname+"-Ch3-AllPuncta.csv");
		run("Close"); //v204

// Save the summary table
		selectWindow("Summary");
		saveAs("Results", savelocation+Shortname+"-Summary.csv");
		run("Close"); //v204
	
// Identify Nuclei
	selectWindow(Shortname+"-3ch.tif");
	DapiCutOff = 200;
	glow = 10;
	ghigh = 20;
	Cellradius = 140; // assumed cell size

	count=roiManager("count");	
		if (count != 0) {
			roiManager("Deselect");
			roiManager("delete");
		}

	run("Duplicate...", "title=dapi duplicate channels=1");
	run("Subtract Background...", "rolling=100 sliding");
	run("Remove Outliers...", "radius=20 threshold=500 which=Bright");
	rename("glow");
	run("Duplicate...", "title=ghigh");
	run("Gaussian Blur...", "sigma="+ghigh);
	selectWindow("glow");
	run("Gaussian Blur...", "sigma="+glow);
	imageCalculator("Subtract create", "glow","ghigh");
	run("Gaussian Blur...", "sigma="+glow);
	
	run("Find Maxima...", "prominence="+DapiCutOff+" output=[Single Points]");
	rename("NucSpots");
	run("Duplicate...", "title=NucExpanded");
	run("Morphological Filters", "operation=Dilation element=Disk radius="+Cellradius);
	selectWindow("NucExpanded");
	close();
	selectWindow("NucSpots");
	run("Voronoi");
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	selectWindow("NucSpots");
	run("Invert");
	imageCalculator("Min create", "NucSpots","NucExpanded-Dilation");
	selectWindow("Result of NucSpots");
	run("Set Measurements...", "  redirect=None decimal=3");
	run("Analyze Particles...", "size=50-Infinity add");

	roiManager("deselect");
	roiManager("save selected", savelocation+Shortname+"-Nuclei.zip"); // save the Nuclei ROIs.
	
	//tidy up
	selectWindow("glow");
	close();
	selectWindow("ghigh");
	close();
	selectWindow("Result of glow");
	close();
	selectWindow("NucSpots");
	close();
	selectWindow("NucExpanded-Dilation");
	close();
	selectWindow("Result of NucSpots");
	close();

// Measure the puncta in all channels for all nuclei, measure a channel at a time. 
	selectWindow("PunctaCh2");
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=unit");
	run("Set Measurements...", "area mean standard modal min integrated redirect=None decimal=3");
	roiManager("multi-measure measure_all");
	Table.renameColumn("Area","No. of Puncta");
	Table.renameColumn("IntDen","Total Puncta");
	Table.deleteColumn("RawIntDen");
	//Table.rename("Results", "Results-Ch2");
	saveAs("Results", savelocation+Shortname+"-Ch2.csv");
	run("Close"); //v204
	
	selectWindow("PunctaCh3");
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=unit");
	run("Set Measurements...", "area mean standard modal min integrated redirect=None decimal=3");
	roiManager("multi-measure measure_all");
	Table.renameColumn("Area","No. of Puncta");
	Table.renameColumn("IntDen","Total Puncta");
	Table.deleteColumn("RawIntDen");
	//Table.rename("Results", "Results-Ch3");
	saveAs("Results", savelocation+Shortname+"-Ch3.csv");
	run("Close"); //v204
	
// Make Puncta images 16bit, with all values = 100x original. i.e. 100 = 1 puncta.
	selectWindow("PunctaCh2");
	run("Select None");
	run("Multiply...", "value=100");
	setOption("ScaleConversions", false);
	run("16-bit");

	selectWindow("PunctaCh3");
	run("Select None");
	run("Multiply...", "value=100");
	setOption("ScaleConversions", false);
	run("16-bit");

	run("Merge Channels...", "c1=PunctaCh2 c2=PunctaCh3 create ignore");
	run("Maximum...", "radius=4");
	Stack.setChannel(1);
	run("Green");
	Stack.setChannel(2);
	run("Red");

	rename(Shortname+"-ScaledPuncta");
	saveAs("Tif", savelocation+Shortname+"Puncta");
	run("Close All"); //v204


function SinglePunctaValues(ImageChannel, BGcorrector, SizeSmall, SizeBig, Radii, RemOutThresh){
	 
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
	rename(Shortname+"-SinglePunctaCh"+ImageChannel);
	run("Set Measurements...", "area mean integrated redirect=ImageIn decimal=3");
// v308 subtract BG on orig image now to make all measures absolute?? Or better still use the BG image made earlier
	selectWindow(Shortname+"-SinglePunctaCh"+ImageChannel);
// measure on the input image AFTER removing background: redirect=[Result of ImageIn] (was Input, so the unprocessed image).
	run("Set Measurements...", "area mean integrated redirect=[Result of ImageIn] decimal=3");
	run("Analyze Particles...", "size=0-infinity pixel show=Nothing display exclude clear summarize add");

	roiManager("deselect");
	roiManager("save selected", savelocation+Shortname+"-SinglePunctaCh"+ImageChannel+".zip");

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
	selectWindow(Shortname+"-SinglePunctaCh"+ImageChannel);
	close(); // need to close this when combined with AllPuncta macro.

	// get the mean Integrated density for single spots
		count = nResults(); 
		//Put the results into an array 
		resultsArray=newArray(); 
		for(i=0;i<count;i++){ 
			resultsArray=Array.concat(resultsArray,getResult("IntDen",i)); 
		   }; 
		//Get the summary out and into variables; 
		Array.getStatistics(resultsArray,min,max,avg,stDev); 
		return avg;

}


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