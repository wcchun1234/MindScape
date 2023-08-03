// Importing necessary libraries //<>//
import peasy.PeasyCam; 
import java.util.ArrayList;
import KinectPV2.*;

// Initializing global variables
Table table1, table2;
ArrayList<PVector> imagePositions, linePositions;
PImage[] images;
int numImages, numLines;
float scaleFactor = 40;
PeasyCam cam;
float imgWidth = 1500;
float imgHeight = 1500;
boolean loaded = false;
KinectPV2 kinect;

float lerpSpeed = 0.015;
boolean isTracked = false;
PVector previousAverageBodyPos = null;

// Setting up the sketch
void setup() {
  fullScreen(P3D, 1);  // Fullscreen mode with 3D
  perspective(PI/2.0, width/float(height), 0.1, 1000000);  // Setting up 3D perspective
  smooth(2);  // Smoothing edges

  // Kinect setup
  kinect = new KinectPV2(this);
  kinect.enableDepthImg(true);
  kinect.enableBodyTrackImg(true);
  kinect.enableSkeletonDepthMap(true);
  kinect.enableDepthMaskImg(true);
  kinect.init();
}

// Main draw loop
void draw() {
  background(0);  // Set background to black
  
  // Retrieve skeleton data from Kinect
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonDepthMap();

  // Loading CSV data and initializing images
  if (!loaded) {
    // Load the CSV data
    table1 = loadTable("reduced_image_embeddings.csv", "header");
    numImages = table1.getRowCount();
    images = new PImage[numImages];
    imagePositions = new ArrayList<PVector>();
    linePositions = new ArrayList<PVector>();

    // Load the second CSV file
    table2 = loadTable("line_only.csv", "header");
    numLines = table2.getRowCount();
    
    // Set up the camera
    cam = new PeasyCam(this, 0, 0, 0, 1000);
    cam.setMinimumDistance(1);
    cam.setMaximumDistance(60000);
    cam.setWheelScale(0.5);

    // Load images and store positions
    for (int i = 0; i < numImages; i++) {
      float x = table1.getFloat(i, "x");
      float y = table1.getFloat(i, "y");
      float z = table1.getFloat(i, "z");
      String imageName = table1.getString(i, "image_name");
      PVector pos = new PVector(x * scaleFactor, y * scaleFactor, z * scaleFactor);
      imagePositions.add(pos);
      images[i] = loadImage(imageName);
      println(imageName + "  " + i);
    }

    // Load line positions
    for (int i = 0; i < numLines; i++) {
      float x = table2.getFloat(i, "x");
      float y = table2.getFloat(i, "y");
      float z = table2.getFloat(i, "z");
      PVector pos = new PVector(x * scaleFactor, y * scaleFactor, z * scaleFactor);
      linePositions.add(pos);
      println("Line " + i);
    }

    loaded = true;
  }

  // Skeleton tracking logic
  boolean trackedThisFrame = false;
  PVector currentAverageBodyPos = new PVector();
  int trackedSkeletonCount = 0;
  
  // Skeleton tracking loop
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = skeletonArray.get(i);
    if (skeleton.isTracked()) {
      trackedThisFrame = true;
      KJoint bodyCenter = skeleton.getJoints()[KinectPV2.JointType_SpineBase];
      PVector currentBodyPos = new PVector(bodyCenter.getX(), bodyCenter.getY(), bodyCenter.getZ());
      currentAverageBodyPos.add(currentBodyPos);
      trackedSkeletonCount++;
      delay(30);
    }
  }

  // Calculating average body position
  if (trackedSkeletonCount > 0) {
    currentAverageBodyPos.div(trackedSkeletonCount);

    // Rotate camera based on body position difference
    if (previousAverageBodyPos != null) {
      PVector diff = PVector.sub(currentAverageBodyPos, previousAverageBodyPos);
      cam.rotateX(diff.y * lerpSpeed);
      cam.rotateY(-diff.x * lerpSpeed);
    }

    previousAverageBodyPos = currentAverageBodyPos;
  }

  // Reset camera if no skeleton is being tracked
  if (!trackedThisFrame && isTracked) {
    cam.reset();
    previousAverageBodyPos = null;
  }
  
  isTracked = trackedThisFrame;

  // Draw lines between image positions
  stroke(255);
  for (int i = 0; i < numImages - 1; i++) {
    PVector pos1 = imagePositions.get(i);
    PVector pos2 = imagePositions.get(i + 1);
    line(pos1.x, pos1.y * -1, pos1.z, pos2.x, pos2.y * -1, pos2.z);
  }

  // Draw lines between line positions
  stroke(255, 0, 0);
  for (int i = 0; i < numLines - 1; i++) {
    PVector pos1 = linePositions.get(i);
    PVector pos2 = linePositions.get(i + 1);
    line(pos1.x, pos1.y * -1, pos1.z, pos2.x, pos2.y * -1, pos2.z);
  }

  // Draw images at image positions
  noStroke();
  for (int i = 0; i < numImages; i++) {
    PVector pos = imagePositions.get(i);
    PImage img = images[i];
    pushMatrix();
    translate(pos.x, pos.y * -1, pos.z);
    imageMode(CENTER);
    image(img, 0, 0, imgWidth, imgHeight);
    popMatrix();
  }
}

// Reset camera when 'r' key is pressed
void keyPressed() {
  if (key == 'r') {
    cam.reset();
  }
}
