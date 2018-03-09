/**
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */




import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.BinomialBlur;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.Laplace;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.Median;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.Sobel;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.SummedAreaTable;

import controlP5.ControlP5;
import controlP5.Group;
import controlP5.Slider;
import processing.core.*;
import processing.opengl.PGraphics2D;



  //
  // A demo to quickly checkout the available imageprocessing filters/kernels 
  // that are available for bluring, noise reduction, edge-detection, 
  // corner-detection, ...
  // 
  // All Filters are implemented as GLSL-shaders.
  //
  // - luminance
  // - boxblur
  // - gaussblur
  // - median
  // - sobel
  // - laplace
  // - convolution
  // - bilateral
  // - laplace
  // - dog
  // - harris corner detection
  // - custom convolution kernels
  // - ...
  //

  
  // two draw-buffers for swaping
  PGraphics2D pg_src_A;
  PGraphics2D pg_src_B;
  PGraphics2D pg_src_C; // just another buffer for temporary results
  PGraphics2D pg_voronoi_centers; // mask for the distance transform (voronoi)

  // filters
  DwFilter filter;

  int CONVOLUTION_KERNEL_INDEX = 0;
  
  // custom convolution kernel
  // https://en.wikipedia.org/wiki/Kernel_(image_processing)
  float[][] kernel = 
    {  
      { // lowpass: box-blur
        1/9f, 1/9f, 1/9f,
        1/9f, 1/9f, 1/9f,
        1/9f, 1/9f, 1/9f,   
      },
      { // lowpass: gauss-blur
        1/16f, 2/16f, 1/16f,
        2/16f, 4/16f, 2/16f,
        1/16f, 2/16f, 1/16f,   
      },
      { // sharpen highpass: laplace
        0,-1, 0,
       -1, 5,-1,
        0,-1, 0 
      },
      { // sharpen highpass: laplace
       -1,-1,-1,
       -1, 9,-1,
       -1,-1,-1, 
      },
      { // sharpen highpass: laplace
       -1,-2,-1,
       -2,13,-2,
       -1,-2,-1,   
      },
      { // edges 1
       +0,+1,+0,
       +1,-4,+1,
       +0,+1,+0 
      },
      { // edges 2
        +1,+1,+1,
        +1,-8,+1,
        +1,+1,+1 
       },
      { // gradient: sobel horizontal
        +1, 0,-1,
        +2, 0,-2,
        +1, 0,-1,   
      },
      { // gradient: sobel vertical
        +1,+2,+1,
         0, 0, 0,
        -1,-2,-1, 
      },
      { // gradient: sobel diagonal TL-BR
        +2, 1 ,0,
        +1, 0,-1,
        +0,-1,-2,   
      },
      {  // gradient: sobel diagonal TR-BL
         0,-1,-2,
        +1, 0,-1,
        +2,+1, 0,   
      },
      {  // emboss / structure / relief
        0,-1,-2,
       +1, 1,-1,
       +2,+1, 0,   
     },
  };
  
  
  
  // display states
  public boolean DISPLAY_IMAGE    = true;
  public boolean DISPLAY_GEOMETRY = true;
  
  // filter, currently active
  public int     DISPLAY_FILTER = 16;
  
  // how often the active filter gets applied
  public int     FILTER_STACKS = 1;
  
  // boxblur/gaussianblur
  public int     BLUR_RADIUS = 20;
  public float   GAUSSBLUR_SIGMA  = BLUR_RADIUS / 2.0f;
  public boolean GAUSSBLUR_AUTO_SIGMA = true;
  
  // bilateral filter
  public int     BILATERAL_RADIUS      = 5;
  public float   BILATERAL_SIGMA_COLOR = 0.3f;
  public float   BILATERAL_SIGMA_SPACE = 5;
  
  // laplace filter
  public int     LAPLACE_WEIGHT         = 1; // 0, 1, 2
  
  // background image
  PImage img;
  
  
  int view_w; 
  int view_h;
  int gui_w = 200;
 
  
  public void settings() {
    img = loadImage("../data/mc_escher.jpg");
    
    view_w = img.width;
    view_h = img.height;
    size(view_w+gui_w, view_h, P2D);
    smooth(8);
  }

  public void setup() {

    DwPixelFlow context = new DwPixelFlow(this);
    context.print();
    context.printGL();
    
    filter = new DwFilter(context);
    
    pg_src_A = (PGraphics2D) createGraphics(view_w, view_h, P2D);
    pg_src_A.smooth(4);
    
    pg_src_B = (PGraphics2D) createGraphics(view_w, view_h, P2D);
    pg_src_B.smooth(4);
    
    pg_src_C = (PGraphics2D) createGraphics(view_w, view_h, P2D);
    pg_src_C.smooth(4);
    
    
    // random distribution of white pixels, that are used as voronoi centers
    // and serve as a mask for the distance transform.
    int gap = 8;
    int num_x = width/gap;
    int num_y = height/gap;
    randomSeed(0);
    pg_voronoi_centers = (PGraphics2D) createGraphics(view_w, view_h, P2D);
    pg_voronoi_centers.smooth(0);
    pg_voronoi_centers.beginDraw();
    pg_voronoi_centers.background(0);
    pg_voronoi_centers.stroke(255);
    for(int y = 0; y < num_y; y++){
      for(int x = 0; x < num_x; x++){
        float px = (int) (x * gap + random(gap));
        float py = (int) (y * gap + random(gap));
        pg_voronoi_centers.point(px+0.5f,  py+0.5f);
      }
    }
    pg_voronoi_centers.endDraw();
    

    pg_src_B.beginDraw();
    pg_src_B.clear();
    pg_src_B.endDraw();
    
    
    createGUI();
    
//    frameRate(60);
    frameRate(1000);
  }
  
  

  
  

  // animated rectangle data
  float rs = 80;
  float rx = 600;
  float ry = 600;
  float dx = 0.6f;
  float dy = 0.25f;
  
  public void draw() {
    
    int w = view_w;
    int h = view_h;
    
    // update rectangle position
    rx += dx;
    ry += dy;
    // keep inside viewport
    if(rx <   rs/2) {rx =   rs/2; dx = -dx; }
    if(rx > w-rs/2) {rx = w-rs/2; dx = -dx; }
    if(ry <   rs/2) {ry =   rs/2; dy = -dy; }
    if(ry > h-rs/2) {ry = h-rs/2; dy = -dy; }
    
    // pg_src_C is used for the bloom input
    pg_src_C.beginDraw();
    pg_src_C.rectMode(CENTER);
    pg_src_C.background(0);
    
    
    if(DISPLAY_GEOMETRY){
      pg_src_C.strokeWeight(1);
      pg_src_C.stroke(0, 255, 0);
      pg_src_C.line(w/2, 0, w/2, h);
      pg_src_C.line(0, h/2, w, h/2);
      pg_src_C.line(0, 0, w, h);
      pg_src_C.line(w, 0, 0, h);
      
      pg_src_C.strokeWeight(1);
      pg_src_C.stroke(0, 255, 0);
      pg_src_C.noFill();
      pg_src_C.ellipse(w/2, h/2, 150, 150);
      
      pg_src_C.strokeWeight(1);
      pg_src_C.stroke(0, 255, 0);
      pg_src_C.noFill();
      pg_src_C.rect(w/2, h/2, 300, 300);
      
      int PEPPER = 1000;
      randomSeed(1);
      for(int i = 0; i < PEPPER; i++){
        float px = ((int) random(20, w-20));
        float py = ((int) random(20, h-20));
        
        pg_src_C.noStroke();
        pg_src_C.fill(0,255,0);
        pg_src_C.rect(px, py, 2, 2);
      }
    }
    
    
    
    
    
    // moving rectangle
    pg_src_C.fill(100, 175, 255);
    pg_src_C.rect(rx, ry, rs, rs);
    
    // mouse-driven ellipse
    pg_src_C.fill(255, 150, 0);
    pg_src_C.noStroke();
    pg_src_C.ellipse(mouseX, mouseY, 100, 100);
    
    pg_src_C.endDraw();
    
    
    // update input image
    pg_src_A.beginDraw();
    {
      pg_src_A.rectMode(CENTER);
      pg_src_A.clear();
      pg_src_A.background(255);
      
      if(DISPLAY_IMAGE){
        pg_src_A.image(img, 0, 0);
      }
      
      if(DISPLAY_GEOMETRY){
        pg_src_A.strokeWeight(1);
        pg_src_A.stroke(0);
        pg_src_A.line(w/2, 0, w/2, h);
        pg_src_A.line(0, h/2, w, h/2);
        pg_src_A.line(0, 0, w, h);
        pg_src_A.line(w, 0, 0, h);
        
        pg_src_A.strokeWeight(1);
        pg_src_A.stroke(0);
        pg_src_A.noFill();
        pg_src_A.ellipse(w/2, h/2, 150, 150);
        
        pg_src_A.strokeWeight(1);
        pg_src_A.stroke(0);
        pg_src_A.noFill();
        pg_src_A.rect(w/2, h/2, 300, 300);
        
        int PEPPER = 1000;
        randomSeed(1);
        for(int i = 0; i < PEPPER; i++){
          float px = ((int) random(20, w-20));
          float py = ((int) random(20, h-20));
          
          pg_src_A.noStroke();
          pg_src_A.fill(0);
          pg_src_A.rect(px, py, 1, 1);
        }
      }
      
      // moving rectangle
      pg_src_A.fill(100, 175, 255);
      pg_src_A.rect(rx, ry, rs, rs);
      
      // mouse-driven ellipse
      pg_src_A.fill(255, 150, 0);
      pg_src_A.noStroke();
      pg_src_A.ellipse(mouseX, mouseY, 100, 100);
    }
    pg_src_A.endDraw();
    
    
    if(GAUSSBLUR_AUTO_SIGMA){
      GAUSSBLUR_SIGMA = BLUR_RADIUS/2f;
      cp5_slider_sigma.setValue(GAUSSBLUR_SIGMA);
    }
    
    int IDX = 0;
    
    // APPLY FILTERS
    if( DISPLAY_FILTER == IDX++) { 
      filter.luminance.apply(pg_src_A, pg_src_B); swapAB(); 
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.boxblur.apply(pg_src_A, pg_src_A, pg_src_B, BLUR_RADIUS);
      }
    }
    if( DISPLAY_FILTER == IDX++) {
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.summedareatable.setFormat(SummedAreaTable.InternalFormat.RGBA32F);
        filter.summedareatable.create(pg_src_A);
        filter.summedareatable.apply(pg_src_A, BLUR_RADIUS);
      }
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.gaussblur.apply(pg_src_A, pg_src_A, pg_src_B, BLUR_RADIUS, GAUSSBLUR_SIGMA);
      }
    }
    if( DISPLAY_FILTER == IDX++) {
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.binomial.apply(pg_src_A, pg_src_A, pg_src_B, BinomialBlur.TYPE._15x15);
      }
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.bilateral.apply(pg_src_A, pg_src_B, BILATERAL_RADIUS, BILATERAL_SIGMA_COLOR, BILATERAL_SIGMA_SPACE); swapAB(); 
      }
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.convolution.apply(pg_src_A, pg_src_B, kernel[CONVOLUTION_KERNEL_INDEX]); swapAB(); 
      }
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.median.apply(pg_src_A, pg_src_B, Median.TYPE._3x3_); swapAB(); 
      }
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.median.apply(pg_src_A, pg_src_B, Median.TYPE._5x5_); swapAB(); 
      }
    }
    if( DISPLAY_FILTER == IDX++) { 
      filter.sobel.apply(pg_src_A, pg_src_B, Sobel.TYPE._3x3_HORZ); swapAB(); 
    }
    if( DISPLAY_FILTER == IDX++) { 
      filter.sobel.apply(pg_src_A, pg_src_B, Sobel.TYPE._3x3_VERT); swapAB(); 
    }
    if( DISPLAY_FILTER == IDX++) { 
      filter.sobel.apply(pg_src_A, pg_src_B, Sobel.TYPE._3x3_HORZ);
      filter.sobel.apply(pg_src_A, pg_src_C, Sobel.TYPE._3x3_VERT);
      float[] mad = {0.5f, 0};
      filter.merge.apply(pg_src_A, pg_src_B, pg_src_C, mad, mad);
    }
    if( DISPLAY_FILTER == IDX++) { 
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.laplace.apply(pg_src_A, pg_src_B, Laplace.TYPE.values()[LAPLACE_WEIGHT]); swapAB(); 
      }
    }
    if( DISPLAY_FILTER == IDX++) {
      filter.dog.param.kernel_A = BLUR_RADIUS * 2;
      filter.dog.param.kernel_B = BLUR_RADIUS * 1;
      filter.dog.param.mult  = 2.5f;
      filter.dog.param.shift = 0.5f;
      filter.dog.apply(pg_src_A, pg_src_B, pg_src_C);
      swapAB();
    }
    if( DISPLAY_FILTER == IDX++) {
      filter.median.apply(pg_src_A, pg_src_B, Median.TYPE._3x3_); swapAB();
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.gaussblur.apply(pg_src_A, pg_src_A, pg_src_B, BLUR_RADIUS, GAUSSBLUR_SIGMA);
      }
      filter.sobel.apply(pg_src_A, pg_src_B, Sobel.TYPE._3x3_HORZ); swapAB();
    }
    if( DISPLAY_FILTER == IDX++) {
      filter.median.apply(pg_src_A, pg_src_B, Median.TYPE._3x3_); swapAB();
      for(int i = 0; i < FILTER_STACKS; i++){
        filter.gaussblur.apply(pg_src_A, pg_src_A, pg_src_B, BLUR_RADIUS, GAUSSBLUR_SIGMA);
      }
      filter.laplace.apply(pg_src_A, pg_src_B, Laplace.TYPE.values()[LAPLACE_WEIGHT]); swapAB();
    }
    if( DISPLAY_FILTER == IDX++) {
      filter.bloom.apply(pg_src_C, pg_src_C, pg_src_A);
    }
    if( DISPLAY_FILTER == IDX++) {
//      filter.gaussblur.apply(pg_src_A, pg_src_A, pg_src_B, BLUR_RADIUS);
      filter.luminance_threshold.apply(pg_src_A, pg_src_A);
    }
    if( DISPLAY_FILTER == IDX++) {
      filter.luminance_threshold.apply(pg_src_A, pg_src_B);
//      filter.bloom.apply(pg_src_B, pg_src_A);
      filter.bloom.apply(pg_src_B, pg_src_B, pg_src_A);
    }
    
    if( DISPLAY_FILTER == IDX++) {
      pg_src_B.beginDraw();
      pg_src_B.background(0);
      pg_src_B.noStroke();
      pg_src_B.fill(255);
      pg_src_B.rectMode(CENTER);
      pg_src_B.ellipse(mouseX, mouseY, 200, 200);
      pg_src_B.endDraw();
      filter.distancetransform.create(pg_voronoi_centers);
      filter.distancetransform.apply(pg_src_A, pg_src_C);
      swapAC();
    }

    // display result
    background(0);
    blendMode(REPLACE);
    image(pg_src_A, 0, 0);
    blendMode(BLEND);

    // info
    String txt_fps = String.format(getClass().getName()+ "   [size %d/%d]   [frame %d]   [fps %6.2f]", pg_src_A.width, pg_src_A.height, frameCount, frameRate);
    surface.setTitle(txt_fps);
  }
  
  
  void swapAB(){
    PGraphics2D tmp = pg_src_A;
    pg_src_A = pg_src_B;
    pg_src_B = tmp;
  }
  
  void swapAC(){
    PGraphics2D tmp = pg_src_A;
    pg_src_A = pg_src_C;
    pg_src_C = tmp;
  }
  
  
 
  
  
  

  
  ControlP5 cp5;
  Slider cp5_slider_sigma;
  
  public void createGUI(){
    cp5 = new ControlP5(this);
    
    Group group_filter = cp5.addGroup("ImageProcessing")
    .setPosition(view_w, 20).setHeight(20).setWidth(gui_w)
    .setBackgroundHeight(view_h).setBackgroundColor(color(16, 220)).setColorBackground(color(16, 180));
    group_filter.getCaptionLabel().align(LEFT, CENTER);
    
    int sx = 100, sy = 14;
    
//    cp5.setAutoSpacing(10, 50);
    
    cp5.addSlider("blur radius").setGroup(group_filter).setSize(sx, sy)
    .setRange(1, 120).setValue(BLUR_RADIUS)
    .plugTo(this, "BLUR_RADIUS").linebreak();
    
    cp5_slider_sigma = cp5.addSlider("gauss sigma").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 100).setValue(GAUSSBLUR_SIGMA)
    .plugTo(this, "GAUSSBLUR_SIGMA").linebreak();
    
    cp5.addToggle("auto sigma").setGroup(group_filter).setSize(sy, sy)
    .setValue(GAUSSBLUR_AUTO_SIGMA)
    .plugTo(this, "GAUSSBLUR_AUTO_SIGMA").linebreak();
    
    cp5.addSlider("convolution index").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, kernel.length-1).setValue(CONVOLUTION_KERNEL_INDEX)
    .plugTo(this, "CONVOLUTION_KERNEL_INDEX").linebreak();
    
    cp5.addSlider("laplace weight").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 2).setValue(LAPLACE_WEIGHT)
    .plugTo(this, "LAPLACE_WEIGHT").linebreak();
    
    cp5.addSlider("bil radius").setGroup(group_filter).setSize(sx, sy)
    .setRange(1, 10).setValue(BILATERAL_RADIUS)
    .plugTo(this, "BILATERAL_RADIUS").linebreak();
    
    cp5.addSlider("bil sigma color").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 1).setValue(BILATERAL_SIGMA_COLOR)
    .plugTo(this, "BILATERAL_SIGMA_COLOR").linebreak();
    
    cp5.addSlider("bil sigma space").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 10).setValue(BILATERAL_SIGMA_SPACE)
    .plugTo(this, "BILATERAL_SIGMA_SPACE").linebreak();
    
    cp5.addSlider("luminance thresh").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 1).setValue(filter.luminance_threshold.param.threshold)
    .plugTo(filter.luminance_threshold.param, "threshold").linebreak();
    
    cp5.addSlider("luminance exponent").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 20).setValue(filter.luminance_threshold.param.exponent)
    .plugTo(filter.luminance_threshold.param, "exponent").linebreak();
    
    cp5.addSlider("bloom mul").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 10).setValue(filter.bloom.param.mult)
    .plugTo(filter.bloom.param, "mult").linebreak();
    
    cp5.addSlider("bloom radius").setGroup(group_filter).setSize(sx, sy)
    .setRange(0, 1).setValue(filter.bloom.param.radius)
    .plugTo(filter.bloom.param, "radius").linebreak();
    
    cp5.addSlider("filter stacks").setGroup(group_filter).setSize(sx, sy)
    .setRange(1, 10).setValue(FILTER_STACKS)
    .setNumberOfTickMarks(10)
    .plugTo(this, "FILTER_STACKS").linebreak();
    
    
    cp5.addCheckBox("displayContent").setGroup(group_filter).setSize(18, 18).setPosition(10, 330)
    .setItemsPerRow(1).setSpacingColumn(2).setSpacingRow(2)
    .addItem("display image"   , 1)
    .addItem("display geometry/noise", 2)
    .activate(0)
    .activate(1)
    ;
    
    int IDX  = 0;
    cp5.addRadio("displayFilter").setGroup(group_filter)
        .setPosition(10, 390).setSize(18,18)
        .setSpacingColumn(2).setSpacingRow(2).setItemsPerRow(1)
        .addItem("luminance"                   , IDX++)
        .addItem("box blur"                    , IDX++)
        .addItem("Summed Area Table blur"      , IDX++)
        .addItem("gauss blur"                  , IDX++)
        .addItem("binomial blur"               , IDX++)
        .addItem("bilateral"                   , IDX++)
        .addItem("convolution"                 , IDX++)
        .addItem("median 3x3"                  , IDX++)
        .addItem("median 5x5"                  , IDX++)
        .addItem("sobel 3x3 horz"              , IDX++)
        .addItem("sobel 3x3 vert"              , IDX++)
        .addItem("sobel 3x3 horz/vert"         , IDX++)
        .addItem("laplace"                     , IDX++)
        .addItem("Dog"                         , IDX++)
        .addItem("median + gauss + sobel(H)"   , IDX++)
        .addItem("median + gauss + laplace"    , IDX++)
        .addItem("Bloom"                       , IDX++)
        .addItem("Luminance Threshold"         , IDX++)
        .addItem("Luminance Threshold + Bloom" , IDX++)
        .addItem("Distance Transform / Voronoi", IDX++)
        .activate(DISPLAY_FILTER)
        ;
    System.out.println("number of filters: "+IDX);

    group_filter.open();
  }
  

  
  public void displayFilter(int val){
    DISPLAY_FILTER = val;
  }
  
  public void displayContent(float[] val){
    DISPLAY_IMAGE    = val[0] > 0.0;
    DISPLAY_GEOMETRY = val[1] > 0.0;
  }
  
  