//Signal Void, David Reiner (ntrcpt) 2017
//VERSION 1.0 - 11.09.2017 - USE THIS FOR PRODUCTION
//davidreiner.at
//t.me/ntrcpt
import processing.pdf.*;
//Global Declarations
PImage img;
PrintWriter output;
IntList AllColors;
FloatList deltaXlist;
FloatList deltaYlist;

//File Setup
//depending on machine type only landscape or horizontal images can be used
String filename = ""; //file needs to be in the sketch dir
String filetype = "png"; //dont forget to choose a file type

//Machine Setup
float sh = 4.0; //save height for fast moves
float fts = 2400; //fast travel speed
float zts = 1200; //z travel speed
float drs = 1800; //drawing speed
int xmax = 400; //x-axis drawing size in mm
int ymax = 533; //y-axis drawing size in mm

//Drawing Setup
int PixelPerLine = 9;
float LineSegLMin = 0.5; //min. length of line segments
float LineSegLMax = 1.0; //max. length of line segments
int GridSize = 3; //grid is always square

void setup() {
  size(2000, 2000); // test if initial size influences output
  surface.setResizable(true);
  img = loadImage(filename+"."+filetype);
  surface.setSize(img.width, img.height);
  image(img, 0, 0);
  loadPixels();
  noLoop();
  beginRecord(PDF, filename+".pdf"); 
  output = createWriter(filename+".gcode"); //create gcode file
  output.println("; SETUP");
  output.println("; PixelPerLine: "+PixelPerLine);
  output.println("; LineSegLMin:"+LineSegLMin);
  output.println("; LineSegLMax:"+LineSegLMax);
  output.println("; GridSize:"+GridSize);
  output.println("G21 ; set units to millimeters");
  output.println("G90 ; use absolute coordinates");
  output.println("G0 Z"+sh); //move tool to safeheight
  output.println("G0 F"+fts); //set G0 speed
  println("started");
}
void colors() {
  int allPixels = img.width * img.height;
  AllColors = new IntList();
  for (int i=0; i<allPixels; i++) {
    color pixelColor = pixels[i];
    String pChex = hex(pixelColor, 6);
    int pCnum = unhex(pChex);
    AllColors.append(pCnum);
  }
}
void draw() {
  colors();
  deltaXlist = new FloatList();
  deltaYlist = new FloatList();
  for (int i = 0; i < xmax; i+=GridSize) {
    for (int j = 0; j < ymax; j+=GridSize) {
      if (AllColors.size() >= PixelPerLine) {
        for (int k = 0; k <= PixelPerLine-1; k++) {
          float l = random(LineSegLMin, LineSegLMax);
          int pCnum = AllColors.get(0);
          float a =  map(pCnum, 0, 16777215, 0, 2*PI);
          float deltaX = l * (cos( a ));
          float deltaY = l * (sin( a ));
          deltaXlist.append(deltaX);
          deltaYlist.append(deltaY);
          AllColors.remove(0);
        }
        stroke(0, 0, 0);
        noFill();
        float xPos = i;
        float yPos = j;
        output.println("G0 X"+xPos+" Y"+yPos); //go to beginning of line
        output.println("G0 Z1"); //fast-move to Z1
        output.println("G1 Z0 F"+zts); //go to Z0
        for (int m = 0; m <= PixelPerLine-1; m++) {
          line(xPos, yPos, xPos = xPos + deltaXlist.get(m), yPos = yPos + deltaYlist.get(m));
          output.println("G1 X"+xPos+" Y"+yPos+" F"+drs); //end of line gets calculated in line before
        }
        output.println("G0 Z"+sh); //fast-move to safe-height
        deltaXlist.clear();
        deltaYlist.clear();
      }
    }
  }
  output.println("G0 Z"+sh); //move tool to safeheight
  output.println("M18"); //turn steppers off
  output.flush(); //write remaining data to file
  output.close(); //finish the file
  println("AllColors.size()="+AllColors.size());
  float m = millis();
  println("DONE AFTER " + m/1000 +" SECOND(S)");
  endRecord();
  //exit(); //stop the program
}