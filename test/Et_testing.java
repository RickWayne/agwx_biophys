public class Et_testing {

static final double SOLCON     = 1367.0;
static final double STEFAN     = (0.0864*0.0000000567);
static final double SFCEMISS   = 0.96;
static final double ALBEDO     = 0.25;

  double DRefET, DClrRatio;
  
  public Et_testing() {
   DRefET = -1.0;
   DClrRatio = -1.0;
  }
  public Et_testing(double DToSol, int dayOfYear, double DMnTAir, double DMxTAir, 
            double DAvVPre, double DAvTAir, double lat) {
    this();
    if (lat < 1.0 || lat > 90.0) /* Dont use this in Indonesia!!! */
       return;
    // wha***k?
    /*
    if ( ( dayOfYear >= 91 ) && ( dayOfYear <= 273 ) )
         return;
    */
      
    double rad_lat =       lat *Math.PI/180.0;
    double DailyToSol =    0.0864 * DToSol;
    double Declin =    0.41 *Math.cos( 2 * Math.PI * ( dayOfYear -172. ) / 365. );

/*-----
 * The Old sunrise angle was given by
 *   Sunrise_Angle=acos(tan(Declin)*tan(rad_lat);formula used for ET days
 *       + 0.0145/(cos(Declin)*cos(rad_lat)))   ;other than months ?? (4-9)
 */

    double Sunrise_Angle = Math.acos( -1*Math.tan(Declin) * Math.tan(rad_lat));
    double Sunrise_Hour = 12 - ( 12 / Math.PI ) * Sunrise_Angle;
    double Day_Hours = 24 - 2 * Sunrise_Hour;
    double AvEIR = SOLCON * ( 1 + 0.035 * Math.cos( 2 * Math.PI * dayOfYear / 365. ) );
    double ToEIR = ( 0.0864 / Math.PI ) * AvEIR *
        ( Sunrise_Angle * Math.sin( Declin ) * Math.sin( rad_lat )
        + Math.cos( Declin ) * Math.cos( rad_lat ) * Math.sin( Sunrise_Angle ) );
        /* MJ/SQM/DY */

    double ToClr = ToEIR * (-.7 + 0.86*Day_Hours) / Day_Hours ;

    double T = ( DMxTAir + DMnTAir ) / 2;
    double LWU = SFCEMISS * STEFAN * Math.pow( 273.15+T,4  ); /*LONG WAVE RAD
                             EMITTED OUT */
    double Sfactor = 0.398 + 0.0171 * T - 0.000142 * T * T;
/*-------
 * Old Sky Emiss equation
 * SkyEmiss = ( 1 - 0.261 * Exp ( -0.000777 * T * T ) )
 */ double SkyEmiss;
    if ( DAvVPre > 0.5) {
        SkyEmiss = 0.7 + (5.95e-4)*DAvVPre*
            Math.exp(1500/(273+DAvTAir));
    }
    else {
            SkyEmiss = (1-0.261*Math.exp(-0.000777*T*T));
    }
    double Angstrom = 1 - SkyEmiss / SFCEMISS;

    double ClrRatio;
    if (DailyToSol <= ToClr) {          /*CLRRATIO = PCTCLR, < 100%
                                              100 added to relieve problem */
        ClrRatio =  DailyToSol / ToClr;
    }
    else {
        ClrRatio = 1.0;
    }

    double LWnet = Angstrom * LWU  * ClrRatio;
    double LWD = LWU - LWnet;
    double Rnet1 = ( 1-ALBEDO ) * DailyToSol - LWnet; /*  ;(RESULTANT ET)=MJ/M2/DY
                                               ;(RESULTANT ET)=REFN ET IN/DY */
    double RET1 = 1.28 * Sfactor * Rnet1;
    System.out.print("ToEIR: "); System.out.println(ToEIR);
    System.out.print("AvEIR: "); System.out.println(AvEIR);
    System.out.print("SkyEmiss: "); System.out.println(SkyEmiss);
    System.out.print("LWnet: "); System.out.println(LWnet);
    System.out.print("Angstrom: "); System.out.println(Angstrom);
    System.out.print("LWU: "); System.out.println(LWU);
    System.out.print("ClrRatio: "); System.out.println(ClrRatio);
    System.out.print("LWD: "); System.out.println(LWD);
    System.out.print("Rnet1: "); System.out.println(Rnet1);
    System.out.print("RET1: "); System.out.println(RET1);
    DRefET = RET1 / 62.3;
    DClrRatio = ClrRatio*100;
  } // ET ctor
  
  public double getET() {
   return DRefET;
  }
  public double getPctClr() {
   return DClrRatio;
  }

  public static void main(String[] args) {
    // public Et_testing(double DToSol, int dayOfYear, double DMnTAir, double DMxTAir, 
    //           double DAvVPre, double DAvTAir, float lat) {
    Et_testing eT = new Et_testing(336.0,172,16.0,24.0,1.0,(16.0+24.0)/2.0,45.0);
    System.out.println(eT.getET());
    System.out.println();
    System.out.println();
    System.out.println();
    // double[] et_obs1 = {244.40,10.80,24.88,1.49,152,44.12,0.18,63.05};
    eT = new Et_testing(285.40,153,5.23,15.91,0.86,10.60,44.12);
    System.out.println(eT.getET());
    System.out.println(eT.getET() - 0.18);
    double[] et_obs2 = {285.40,5.23,15.91,0.86,153,44.12,0.17,73.49};
    double[] et_obs3 = {319.60,3.63,21.95,0.92,154,44.12,0.20,82.15};
    double[] et_obs4 = {45.76,9.95,13.56,1.25,155,44.12,0.03,11.74};
    
    eT.invokedStandalone = true;
  }
  private boolean invokedStandalone = false;
} 