int x;
int y;
final int w = 900;
final int h = 600;

float mv = 30;
float step = 0.001;

void setup() {
  
   size(900,600);
   
   x = w/2;
   y = h/2;
   
   background(0xffffff);
   noFill();
   stroke(0);
   
   updatePixels();
}

void newPoint() {
  
  int dx = 0;
  int dy = 0;
  
  if(random(1) > 0.5) {
    dx = floor(2*random(mv) - mv);
  } else {
    dy = floor(2*random(mv) - mv);
  }
  
  int newY = y + dy;
  int newX = x + dx;
  
  if(newX < 0 || newY < 0 || newX > width || newY > height) {
    
    newPoint();
    return;
    
  }
  
  loadPixels();
  System.out.println("X " + String.valueOf(newX) + " Y: " + String.valueOf(newY) );
  float sample = red(pixels[newY*width+newX]);
  
  System.out.println(sample);

  if(sample == 255.0) {
    
      System.out.println("line");
      line(x,y, newX, newY);
      x = newX;
      y = newY;
   
      mv -= step;
      
  } else {
        
    newPoint();
    return;
  
  }
}

void draw() {

  
  newPoint();
 
  
}