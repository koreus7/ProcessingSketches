public class Lab
{
  public float L;
  public float A;
  public float B;
  
  public Lab(float l, float a, float b)
  {
    L = l;
    A = a;
    B = b;
  }
}

public Lab rgb2lab(int c) {
    int R = floor(red    (c));
    int G = floor(green  (c));
    int B = floor(blue   (c));

    float r, g, b, X, Y, Z, fx, fy, fz, xr, yr, zr;
    float Ls, as, bs;
    float eps = 216.f/24389.f;
    float k = 24389.f/27.f;

    float Xr = 0.964221f;  // reference white D50
    float Yr = 1.0f;
    float Zr = 0.825211f;

    // RGB to XYZ
    r = R/255.f; //R 0..1
    g = G/255.f; //G 0..1
    b = B/255.f; //B 0..1

    // assuming sRGB (D65)
    if (r <= 0.04045)
        r = r/12;
    else
        r = (float) Math.pow((r+0.055)/1.055,2.4);

    if (g <= 0.04045)
        g = g/12;
    else
        g = (float) Math.pow((g+0.055)/1.055,2.4);

    if (b <= 0.04045)
        b = b/12;
    else
        b = (float) Math.pow((b+0.055)/1.055,2.4);


    X =  0.436052025f*r     + 0.385081593f*g + 0.143087414f *b;
    Y =  0.222491598f*r     + 0.71688606f *g + 0.060621486f *b;
    Z =  0.013929122f*r     + 0.097097002f*g + 0.71418547f  *b;

    // XYZ to Lab
    xr = X/Xr;
    yr = Y/Yr;
    zr = Z/Zr;

    if ( xr > eps )
        fx =  (float) Math.pow(xr, 1/3.);
    else
        fx = (float) ((k * xr + 16.) / 116.);

    if ( yr > eps )
        fy =  (float) Math.pow(yr, 1/3.);
    else
    fy = (float) ((k * yr + 16.) / 116.);

    if ( zr > eps )
        fz =  (float) Math.pow(zr, 1/3.);
    else
        fz = (float) ((k * zr + 16.) / 116);

    Ls = ( 116 * fy ) - 16;
    as = 500*(fx-fy);
    bs = 200*(fy-fz);
    return new Lab(
    (2.55*Ls + .5)/255.0,
    (as + .5)/255.0,
    (bs + .5)/255.0);
}

class Cie94Comparison
{
  class Cie94Constants
  {
    public float Kl;
    public float K1;
    public float K2;
  }
  
  private Cie94Constants GraphicArts()
  {
    Cie94Constants c = new Cie94Constants();
    c.Kl = 1.0;
    c.K1 = .045;
    c.K2 = .015;
    return c;
  }
   
  private Cie94Constants Textiles()
  {
    Cie94Constants c = new Cie94Constants();
     c.Kl = 2.0;
     c.K1 = .048;
     c.K2 = .014;
    return c;
  }
  
  public float Compare(int ca, int cb)
  {
     Cie94Constants constants = GraphicArts();
     
     Lab labA = rgb2lab(ca);
     Lab labB = rgb2lab(cb);
     
     float deltaL = labA.L - labB.L;
     float deltaA = labA.A - labB.A;
     float deltaB = labA.B - labB.B;
     
     float c1 = sqrt(labA.A * labA.A + labA.B * labA.B);
     float c2 = sqrt(labB.A * labB.A + labB.B * labB.B);
     float deltaC = c1 - c2;
     
     float deltaH = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
     deltaH = deltaH < 0 ? 0 : sqrt(deltaH);
 
     final float sl = 1.0;
     final float kc = 1.0;
     final float kh = 1.0;
     
     float sc = 1.0 + constants.K1 * c1;
     float sh = 1.0 + constants.K2 * c1;
     
     float deltaLKlsl = deltaL / (constants.Kl * sl);
     float deltaCkcsc = deltaC / (kc * sc);
     float deltaHkhsh = deltaH / (kh * sh);
     
     float i = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc 
     + deltaHkhsh * deltaHkhsh;
     return i < 0 ? 0 : sqrt(i);
  }
}