import processing.video.*;

final float drag = 7.5;
final int butterflyWidth = 500;
final float tstep = 0.05;
final float moveSpeed = 10;
final int xStopThreshold = 50;
final int yStopThreshold = 50;
final int randomFlyDistance = 90000;
final int MOVE_TO_MOUSE = 0;
final int WANDER_AROUND = 1;
final int FLY_BACK = 2;

Animation ani1, ani2, ani3, ani4;
Animation[] ani = new Animation[3];
Animation currentAni;
Movie movie;
String line;
float xpos;
float ypos;
float lastMouseX;
float lastMouseY;
float rdmX;
float rdmY;
float[] otherx = {1920, 1920, 0};
float[] othery = {0, 1080, 1080};
float t = 0;
float[] ot = {20.17, 1.2, 0.23};
int lastTime = 0;
int status = MOVE_TO_MOUSE;

void setup() {
  size(1920, 1080);
  movie = new Movie(this, sketchPath("") + "../123/123.avi");
  movie.loop();
  frameRate(10);
  ani1 = new Animation("../serial_frames/serial1/", 22, 40000, 0);
  ani2 = new Animation("../serial_frames/serial2/", 14, 40000, 0);
  ani3 = new Animation("../serial_frames/serial3/", 7, 40000, 0);
  ani4 = new Animation("../serial_frames/serial4/", 24, 30000, 0);
  
  ani[0] = new Animation("../", 7, 40000, 1);
  ani[1] = new Animation("../", 7, 40000, 2);
  ani[2] = new Animation("../", 7, 40000, 3);
  currentAni = ani4;
  //reader = createReader("test_color.txt");
}

void movieEvent(Movie movie) {
  movie.read();
}

void draw() {
  if (millis() - lastTime > 3000) {
    String[] lines = loadStrings("../butterfly.dat");
    if(lines.length > 0) {
      if(lines[lines.length-1].equals("1")) {
        ani1.reprocess();
        currentAni = ani1;
        frameRate(10);
      }
      else if(lines[lines.length-1].equals("2")) {
        ani2.reprocess();
        currentAni = ani2;
        frameRate(10);
      }
      else if(lines[lines.length-1].equals("3")) {
        ani3.reprocess();
        currentAni = ani3;
        frameRate(20);
      }
      else if(lines[lines.length-1].equals("4")) {
        ani4.reprocess();
        currentAni = ani4;
        frameRate(10);
      }
    lastTime = millis();
    }
  }
  
  float dx = mouseX - xpos;
  float dy = mouseY - ypos;
  float dMouseX = mouseX - lastMouseX;
  float dMouseY = mouseY - lastMouseY;
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  boolean isLeft;
  //println(dx, dy);
  
  // status transform
  if (dMouseX != 0 || dMouseY != 0) {
    status = MOVE_TO_MOUSE;
  }
  else {
    if (pow(dx, 2) + pow(dy, 2) > randomFlyDistance) {
      if (status == WANDER_AROUND) {
        status = FLY_BACK;
        float r = random(0, sqrt(randomFlyDistance));
        float theta = random(radians(0), radians(360));
        rdmX = mouseX + r * cos(theta);
        rdmY = mouseY + r * sin(theta);
      }
      else if (status == MOVE_TO_MOUSE) {
        status = MOVE_TO_MOUSE;
      }
      else {
        status = FLY_BACK;
      }
    }
    else {
      if (status == MOVE_TO_MOUSE) {
        if (abs(dx) < xStopThreshold && abs(dy) < yStopThreshold) {
          status = WANDER_AROUND;
          t = random(radians(0), radians(360));
        }
        else
          status = MOVE_TO_MOUSE;
      }
      else if (status == FLY_BACK) {
        if (abs(rdmX - xpos) < xStopThreshold && abs(rdmY - ypos) < yStopThreshold) {
          status = WANDER_AROUND;
          t = random(radians(0), radians(360));
        }
        else
          status = FLY_BACK;
      }
      else
        status = WANDER_AROUND;
    }
  }
  
   
  
  if (status == WANDER_AROUND) {
    println("WANDER_AROUND");
    float direction = map(noise(t), 0, 1, radians(0), radians(360));
    //println(direction);
    t += tstep;
    xpos += moveSpeed * cos(direction);
    ypos += moveSpeed * sin(direction);
    isLeft = (cos(direction) <= 0);
  }
  else if(status == MOVE_TO_MOUSE) {
    println("MOVE_TO_MOUSE");
    xpos = xpos + dx/drag;
    ypos = ypos + dy/drag/2;
    isLeft = (dx <= 0);
  }
  else { // FLY BACK
    println("FLY_BACK");
    dx = rdmX - xpos;
    dy = rdmY - ypos;
    xpos = xpos + moveSpeed * (dx / sqrt(pow(dx, 2) + pow(dy, 2)));
    ypos = ypos + moveSpeed * (dy / sqrt(pow(dx, 2) + pow(dy, 2)));
    isLeft = (dx <= 0);
  }
    image(movie, 0, 0);
    currentAni.display(xpos, ypos, isLeft);
    
    frameRate(10);
    for(int i = 0; i < 3; i ++) {
      float dir = map(noise(ot[i]), 0, 1, radians(0), radians(360));
      ot[i] += tstep;
      otherx[i] += moveSpeed * cos(dir);
      othery[i] += moveSpeed * sin(dir);
      isLeft = (cos(dir) <= 0);
      if(otherx[i] <= 0)
        otherx[i] += 1920;
      if(othery[i] <= 0)
        othery[i] += 1080;
      if(otherx[i] >= 1920)
        otherx[i] -= 1920;
      if(othery[i] >= 1080)
        othery[i] -= 1080;
      ani[i].display(otherx[i], othery[i], isLeft);
    }
}



// Class for animating a sequence of GIFs

class Animation {
  PImage[] images;
  PImage[] displayImages;
  int imageCount;
  int frame;
  int colorTolerance;
  color[] myColors;
  int mType;
  
  Animation(String filePath, int count, int ct, int type) {
    mType = type;
    colorTolerance = ct;
    myColors = new color[6];
    if(type > 0) {
      String[] lines = loadStrings("../test_color_" + type + ".dat");
      for (int i = 0; i < lines.length; i ++) {
        String[] pieces = split(lines[i], ' ');
        myColors[i] = (color(int(pieces[0]), int(pieces[1]), int(pieces[2])));
      } 
    }
    else {
      String[] lines = loadStrings("../butterfly.dat");
      for (int i = 0; i < lines.length - 1; i ++) {
        String[] pieces = split(lines[i], ' ');
        myColors[i] = (color(int(pieces[0]), int(pieces[1]), int(pieces[2])));
      }
    }
    
    imageCount = count;
    images = new PImage[imageCount];
    displayImages = new PImage[imageCount];

    for (int i = 0; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      String filename = sketchPath("") + filePath + (i + 1) + ".png";
      images[i] = loadImage(filename);
      images[i].resize(butterflyWidth, images[i].height * butterflyWidth / images[i].width);
      displayImages[i] = createImage(butterflyWidth, images[i].height * butterflyWidth / images[i].width, ARGB);
      process(i);
    }
  }
  
  void reprocess() {
    String[] lines = loadStrings("../butterfly.dat");
    for (int i = 0; i < lines.length-1; i ++) {
      String[] pieces = split(lines[i], ' ');
      myColors[i] = (color(int(pieces[0]), int(pieces[1]), int(pieces[2])));
    }
    for(int i = 0; i < imageCount; i++) {
      process(i);
    }
  }

  void display(float xpos, float ypos, boolean isLeft) {
    frame = (frame+1+mType*mType) % imageCount;
    if(isLeft)
      image(displayImages[frame], xpos - getWidth() / 2, ypos);
    else {
      pushMatrix();
      translate(xpos + getWidth() / 2, 0);
      scale(-1, 1);
      image(displayImages[frame], 0, ypos);
      popMatrix();
    }
  }
  
  int getWidth() {
    return images[0].width;
  }
  
  void process(int index) {
    images[index].loadPixels();
    displayImages[index].loadPixels();
    for (int i = 0; i < images[index].pixels.length; i++) {
      color c = images[index].pixels[i];
      if (alpha(c) > 0) {
        /*
        if (isSameColor(c, color(255, 0, 0)))
          displayImages[index].pixels[i] = color(255, 0, 0);
        else if (isSameColor(c, color(0, 255, 0)))
          displayImages[index].pixels[i] = color(0, 255, 0);
        else if (isSameColor(c, color(0, 0, 255)))
          displayImages[index].pixels[i] = color(0, 0, 255);
        else if (isSameColor(c, color(255, 255, 0)))
          displayImages[index].pixels[i] = color(255, 255, 0);
        else if (isSameColor(c, color(255, 0, 255)))
          displayImages[index].pixels[i] = color(255, 0, 255);
        else if (isSameColor(c, color(0, 255, 255)))
          displayImages[index].pixels[i] = color(0, 255, 255);
        else if (isSameColor(c, color(0, 0, 0)))
          displayImages[index].pixels[i] = color(0, 0, 0);
        else if (isSameColor(c, color(255, 255, 255)))
          displayImages[index].pixels[i] = color(255, 255, 255);
        else
          displayImages[index].pixels[i] = color(0, 0, 0, 0);
         */ 
        if (isSameColor(c, color(255, 0, 0)))
          displayImages[index].pixels[i] = myColors[0];
        else if (isSameColor(c, color(0, 255, 0)))
          displayImages[index].pixels[i] = myColors[1];
        else if (isSameColor(c, color(0, 0, 255)))
          displayImages[index].pixels[i] = myColors[2];
        else if (isSameColor(c, color(255, 255, 0)))
          displayImages[index].pixels[i] = myColors[3];
        else if (isSameColor(c, color(255, 0, 255)))
          displayImages[index].pixels[i] = myColors[4];
        else if (isSameColor(c, color(0, 255, 255)))
          displayImages[index].pixels[i] = myColors[5];
        else if (isSameColor(c, color(0, 0, 0)))
          displayImages[index].pixels[i] = color(0, 0, 0);
        else if (isSameColor(c, color(255, 255, 255)))
          displayImages[index].pixels[i] = color(255, 255, 255, 0);
        else
          displayImages[index].pixels[i] = color(0, 0, 0, 0);
          
      }
      else
        displayImages[index].pixels[i] = color(0, 0, 0, 0);
    }
    displayImages[index].updatePixels();
    
  }
  
  boolean isSameColor(color c1, color c2) {
    float distance =  pow((red(c1) - red(c2)), 2);
    distance += pow((green(c1) - green(c2)), 2);
    distance += pow((blue(c1) - blue(c2)), 2);
    return distance < colorTolerance;
  }
}