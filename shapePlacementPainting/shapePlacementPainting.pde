import java.util.Collections;
PImage photo;

Cie94Comparison comp = new Cie94Comparison();

class Square  implements Comparable<Square> {
  
  private int size;
  private color colour;
  private int rating;
  
  public Square(int size, color colour)
  {
    this.size = size;
    this.colour = colour;
  }
  
  public int GetSize()
  {
    return size;
  }
  
  public color GetColour()
  {
    return colour;
  }
  
  public int GetRating()
  {
    return rating;
  }
  
  public void SetRating(int val)
  {
    rating = val;
  }
  
  public void Draw(float x, float y)
  {
    fill(colour);
    noStroke();
    ellipse(x,y,size,size);
    //rect(x,y,size,size);
  }
  public int compareTo(Square anotherInstance) {
        return this.rating - anotherInstance.rating;
  }
}

float exponentialEasing (float x, float a){
  
  float epsilon = 0.00001;
  float min_param_a = 0.0 + epsilon;
  float max_param_a = 1.0 - epsilon;
  a = max(min_param_a, min(max_param_a, a));
  
  if (a < 0.5){
    // emphasis
    a = 2.0*(a);
    float y = pow(x, a);
    return y;
  } else {
    // de-emphasis
    a = 2.0*(a-0.5);
    float y = pow(x, 1.0/(1-a));
    return y;
  }
}

float shape(float x)
{
  return exponentialEasing(x,0.6);
}

int oldSize = 10;

Square getRandomSquare()
{
  color col = color(random(0,100), random(0,100),random(0,100));
  //int size = 5;
  //int maxSize = width/20;
  //float maxTime = 30000;
  //if(maxTime - millis() > 0)
  //{
  //  size = floor(maxSize*shape((maxTime - millis())/maxTime));
  //}
  int size = oldSize;
  if(mousePressed)
  {
    size = floor(200*mouseY/height);
  }
  oldSize = size;
  return new Square((int)random(1,size), col);
}

int colorRating(int col1, int col2)
{
  return floor(1000*comp.Compare(col1,col2)); //- floor(abs(hue(col1) - hue(col2)))/10 ;
  //return floor(abs(hue(col1) - hue(col2))) 
  //+ floor(abs(brightness(col1) - brightness(col2)))
  //+ floor(abs(saturation(col1) - saturation(col2)));
}

void setup() {
  colorMode(HSB, 100);
  rectMode(CENTER);
  ellipseMode(CENTER);
  photo = loadImage("pool.jpg");
  size(1200, 700);
  background(0);
}

void keyPressed(){
  saveFrame();
}

int averageCol(int x,int y, int rad, PImage img) {
  int count = rad*rad*4; 
  int hs = 0;
  int ss = 0;
  int bs = 0;
  
  for(int i = x -rad; i < x + rad; i++)
  {
    for(int j = y - rad; j < y + rad; j++)
    {
      int col;
      if(img == null)
      {
        col = get(i,j);
      }
      else
      {
        col = img.get(i,j);
      }
      hs += hue(col);
      ss += saturation(col);
      bs += brightness(col);
    }
  }
  
  hs/= count;
  ss/= count;
  bs/= count;
  return color(hs,ss,bs);
}

void draw() {
  
  int x = floor(random(0,photo.width));
  int y = floor(random(0,photo.height));
  
  int numSquares = 2000;
  ArrayList<Square> possibleSquares = new ArrayList<Square>();
  //image(photo, 0, 0);
  
  
  for(int i = 0; i < numSquares; i++)
  {
    Square s = getRandomSquare();
    int currentRating = colorRating(averageCol(x,y,s.size, null), averageCol(x,y,s.size, photo));
    int sqRating = colorRating(photo.get(x,y),s.GetColour());
    if(sqRating > currentRating)
    {
      s.SetRating(sqRating);
      possibleSquares.add(s);
    }
  }
  
  Collections.sort(possibleSquares);
  if(possibleSquares.size() > 0)
  {
    println(String.valueOf(possibleSquares.get(0).GetRating()));
    possibleSquares.get(0).Draw(x,y);
  }
  
}