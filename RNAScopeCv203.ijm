// Macro in development
// Copyright (c) 2020 Dale Moulding, UCL. 
// Made available for use under the MIT license.
//     https://opensource.org/licenses/MIT
/*
 * Combine functions for single spot and all spots into a single macro.
 * Use AllPunctaFuncvC404 & SinglePunctaFunctionvC403 (rolling ball reduced from 100 to 10).
 * Take the result for the single puncta mean IntDen
 * Use this to set the value for each measured puncta, relative to 1 = single puncta
 * Save ROIs for single and all puncta.
 */

//changelog 
// v002 Use kill borders, and exclude on edges. 
// change all connected components labelling to connectivity=8 (was 4) & type=float
// these changes needed as some images generated spots that just touched edges and were missed, and over segmented due due connectivity.
// v003
// NOTE dist transform watershed fails if image is too large, needs more than 16bit. Changing to 32 bit changes how the watershed works.
// requires  run("Distance Transform Watershed", "distances=[Chessknight (5,7,11)] output=[32 bits] dynamic=3 connectivity=4");
// uses run("Collect Garbage");  to try and clear the RAM
// v004 Output 2 images, puncta as 13 pixel circles, and puncta as a single pixel.
// v004 rolling ball now 10, was 100.
// v101 Add the Dapi identification. Use Dapi ROIs to measure Area (= # of spots as background = NaN), intensities ave, min max etc and IntDen (total signal).
// v102 Make 3 results tables, 1 for each puncta channel.
// v102 make a 16bit image with a spot for every puncta. Each Puncta has a score. 100 = 1 single puncta.
// v103 table columns renamed / deleted. 
// v103 Save results tables and scaled puncta images.
// v104 Changed dapi segmentation, now using Kuwahara filtering and masking out the dimmer background and smaller signals.
// Make a summary image? The total score for each puncta per cell?
// v201. Swapped to a new spots identifyng method, combining Remove outliers with find maxima, using vC404 Puncta Function.
// v202. Save results tables for all puncta. Also the summary table.
// v203.fix the mis-labelling problem

	savelocation = getDirectory("Choose a Directory to save the ROIs");	
	count=roiManager("count");	
		if (count != 0) {
			roiManager("Deselect");
			roiManager("delete");
		}

	Shortname = substring(getTitle(), 0, lengthOf(getTitle())-4);

// measure single puncta ch2...
		selectWindow(Shortname+".tif");
		SinglePuncta = SinglePunctaValues(2, 1, 400, 10, 15, 5, 500); // requires 7 variables. ****Enter Values****
	// The Channel number
	// Background subtraction corrector. Larger value = more BG subtracted.
	// Maxima Tolerance, How bright does each spot need to be above background?
	// Particle sizes. 5-10 & 18 for single puncta, 5-10 & 4/5000 for all puncta. 
	// The spot size for Remove outliers. First radius, second how much brighter than the mean of that radius?
	
	// measure all puncta ch2...
		selectWindow(Shortname+".tif");
		AllPunctaValues(2, 1, 400, 10, 4000, 5, 500); // requires 7 variables. ****Enter Values****
	
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

// measure single puncta ch3...
		selectWindow(Shortname+".tif");
		SinglePuncta = SinglePunctaValues(3, 1, 750, 7, 14, 5, 400); // requires 7 variables. ****Enter Values****
	
	// measure all puncta ch3...
		selectWindow(Shortname+".tif");
		AllPunctaValues(3, 1, 750, 7, 4000, 5, 400); // requires 7 variables. ****Enter Values****
	
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
			
// measure single puncta ch4...
		selectWindow(Shortname+".tif");
		SinglePuncta = SinglePunctaValues(4, 1.5, 1000, 5, 10, 5, 400); // requires 7 variables. ****Enter Values****
	
	// measure all puncta ch4...
		selectWindow(Shortname+".tif");
		AllPunctaValues(4, 1.5, 1000, 5, 5000, 5, 400); // requires 7 variables. ****Enter Values****
	
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
		saveAs("Results", savelocation+Shortname+"-Ch43-AllPuncta.csv");

// Save the summary table
		selectWindow("Summary");
		saveAs("Results", savelocation+Shortname+"-Summary.csv");

	
// Identify Nuclei
// Dapiv5, swapped to a Kuwahara filter (from Median), and thresholded the filtered image to remove low intensity and small particles.
	selectWindow(Shortname+".tif");
	DapiCutOff = 5;
	glow = 25;
	ghigh = 35;
	
	count=roiManager("count");	
		if (count != 0) {
			roiManager("Deselect");
			roiManager("delete");
		}
		
	run("Colors...", "foreground=white background=black selection=yellow");
	run("Duplicate...", "title=filter duplicate channels=1");
	run("Kuwahara Filter", "sampling=23");
	//run("Morphological Filters", "operation=Opening element=Square radius=25");
	rename("filter");
	run("Duplicate...", "title=mask");
	setAutoThreshold("Mean dark");								// remove dim parts of image and any small particles.
	run("Convert to Mask");
	run("Set Measurements...", "  redirect=None decimal=3");
	run("Analyze Particles...", "size=2000-Infinity pixel show=Masks");
	run("16-bit");
	run("Divide...", "value=255.000");
	imageCalculator("Multiply create", "filter", "Mask of mask"); // remove dim parts of image and any small particles.
	selectWindow("Result of filter");
	run("Duplicate...", "title=glow");
	run("Duplicate...", "title=ghigh");
	run("Gaussian Blur...", "sigma="+ghigh);
	selectWindow("glow");
	run("Gaussian Blur...", "sigma="+glow);
	imageCalculator("Subtract create", "glow","ghigh");
	run("Gaussian Blur...", "sigma="+glow);
	
	run("Find Maxima...", "prominence="+DapiCutOff+" output=[Single Points]");
	rename("NucSpots");
	run("Duplicate...", "title=NucExpanded");
	run("Morphological Filters", "operation=Dilation element=Disk radius=160"); // radius = assumed cell size
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
	run("Analyze Particles...", "size=50-Infinity exclude add");

	roiManager("deselect");
	roiManager("save selected", savelocation+Shortname+"-Nuclei.zip"); // save the Nuclei ROIs.
	
	//tidy up
	
	selectWindow("Result of glow");
	close();
	selectWindow("Result of NucSpots");
	close();
	selectWindow("NucSpots");
	close();
	selectWindow("NucExpanded-Dilation");
	close();
	selectWindow("glow");
	close();
	selectWindow("ghigh");
	close();
	selectWindow("Result of filter");
	close();
	selectWindow("Mask of mask");
	close();
	selectWindow("mask");
	close();
	selectWindow("filter");
	close();

// Measure the puncta in all channels for all nuclei, measure a channel at a time. 
	selectWindow("PunctaCh2");
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=unit");
	run("Set Measurements...", "area mean standard modal min integrated redirect=None decimal=3");
	roiManager("multi-measure measure_all");
	Table.renameColumn("Area","No. of Puncta");
	Table.renameColumn("IntDen","Total Puncta");
	Table.deleteColumn("RawIntDen");
	Table.rename("Results", "Results-Ch2");
	saveAs("Results", savelocation+Shortname+"-Ch2.csv");
	
	selectWindow("PunctaCh3");
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=unit");
	run("Set Measurements...", "area mean standard modal min integrated redirect=None decimal=3");
	roiManager("multi-measure measure_all");
	Table.renameColumn("Area","No. of Puncta");
	Table.renameColumn("IntDen","Total Puncta");
	Table.deleteColumn("RawIntDen");
	Table.rename("Results", "Results-Ch3");
	saveAs("Results", savelocation+Shortname+"-Ch3.csv");
	
	selectWindow("PunctaCh4");
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=unit");
	run("Set Measurements...", "area mean standard modal min integrated redirect=None decimal=3");
	roiManager("multi-measure measure_all");
	Table.renameColumn("Area","No. of Puncta");
	Table.renameColumn("IntDen","Total Puncta");
	Table.deleteColumn("RawIntDen");
	Table.rename("Results", "Results-Ch4");
	saveAs("Results", savelocation+Shortname+"-Ch4.csv");
	
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

	selectWindow("PunctaCh4");
	run("Select None");
	run("Multiply...", "value=100");
	setOption("ScaleConversions", false);
	run("16-bit");

	run("Merge Channels...", "c1=PunctaCh2 c2=PunctaCh3 c3=PunctaCh4 create ignore");
	run("Maximum...", "radius=4");
	Stack.setChannel(1);
	run("Green");
	Stack.setChannel(2);
	run("Red");
	Stack.setChannel(3);
	run("Yellow");

	rename(Shortname+"-ScaledPuncta");
	saveAs("Tif", savelocation+Shortname+"Puncta");

function SinglePunctaValues(ImageChannel, BGcorrector, MaxTol, SizeSmall, SizeBig, Radii, RemOutThresh){
	 
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
	selectWindow("Vor");
	run("Voronoi");											// rather than watershed, use an voroni image to separate all puncta
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Invert");
	imageCalculator("Min create", "Vor","PunctaCircles-Dilation");
	rename(Shortname+"-SinglePunctaCh"+ImageChannel);
// measure on the input image AFTER removing background: redirect=[Result of ImageIn] (was Input, so the unprocessed image).
	run("Set Measurements...", "area mean integrated redirect=[Result of ImageIn] decimal=3");
// v308 subtract BG on orig image now to make all measures absolute?? Or better still use the BG image made earlier
	selectWindow(Shortname+"-SinglePunctaCh"+ImageChannel);
	run("Analyze Particles...", "size=0-infinity pixel show=Nothing display exclude clear summarize add"); // v501 remove exclude on edges. Cv401 add this back

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