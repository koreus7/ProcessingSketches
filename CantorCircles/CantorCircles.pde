ArrayList<PVector> Cantor(ArrayList<PVector> last){
  ArrayList<PVector> result = new ArrayList<PVector>();
  for(int i = 0; i < last.size(); i++) {
    // Remove the middle third
    float len = last.get(i).y - last.get(i).x;
    result.add(new PVector(last.get(i).x, last.get(i).x + len/3.0));
    result.add(new PVector(last.get(i).x + 2*len/3.0, last.get(i).y));
  }
  return result;
}

ArrayList<PVector> currentSet = new ArrayList<PVector>();
final int iterations = 6;

void setup() {
  colorMode(HSB,100);
  size(800, 800);
 
}

void draw(){
  background(0xffffff);
  float t = millis()/1000.0;
  currentSet.clear();
  currentSet.add(new PVector(0,TAU));
  
  for(int i = 0; i < iterations; i ++){
    float per = ((float)i/iterations);
    float off = t*(1 - per*per);
    for(int j = 0; j < currentSet.size(); j++)
    {
      noFill();
      arc(width/2,height/2, per*width,per*height,
      currentSet.get(j).x + off, currentSet.get(j).y + off);
    }
    
    currentSet = Cantor(currentSet);
  }
}