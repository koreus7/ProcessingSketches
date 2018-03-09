float elapsed = 0.0f;
int sides = 3;
void setup() {
  size(640, 360, P3D);
  frameRate(30);
}

void draw() {
  background(0);
  lights();
  translate(width / 2, height / 2);
  rotateY(map(mouseX, 0, width, 0, 2*PI));
  rotateX(map(mouseY, 0, height, 0, -2*PI));
  noStroke();
  fill(255, 255, 255);
  translate(0, -40, 0);
  //int sides = floor(abs(sin(elapsed/10000.0f))*30.0f) + 3;
  drawCylinder(1, 180, 200, sides); // Draw a mix between a cylinder and a cone
  //drawCylinder(70, 70, 120, 64); // Draw a cylinder
  //drawCylinder(0, 180, 200, 4); // Draw a pyramid
  elapsed += 10;
}

void keyPressed()
{
  sides += 1;
}

void drawCylinder(float topRadius, float bottomRadius, float tall, int sides) {
  float angle = 0;
  float angleIncrement = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i < sides + 1; ++i) {
    vertex(topRadius*cos(angle), 0, topRadius*sin(angle));
    vertex(bottomRadius*cos(angle), tall, bottomRadius*sin(angle));
    angle += angleIncrement;
  }
  endShape();
  
  // If it is not a cone, draw the circular top cap
  if (topRadius != 0) {
    angle = 0;
    beginShape(TRIANGLE_FAN);
    
    // Center point
    vertex(0, 0, 0);
    for (int i = 0; i < sides + 1; i++) {
      vertex(topRadius * cos(angle), 0, topRadius * sin(angle));
      angle += angleIncrement;
    }
    endShape();
  }

  // If it is not a cone, draw the circular bottom cap
  if (bottomRadius != 0) {
    angle = 0;
    beginShape(TRIANGLE_FAN);

    // Center point
    vertex(0, tall, 0);
    for (int i = 0; i < sides + 1; i++) {
      vertex(bottomRadius * cos(angle), tall, bottomRadius * sin(angle));
      angle += angleIncrement;
    }
    endShape();
  }
}