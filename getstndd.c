#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>

#include <awsdir.h>
#include <awstime.h>
#include <awserror.h>
#include <grid/grid.h>

#ifndef O_RDWR
#  define O_RDWR    0000002   /* Open for reading or writing */
#  define O_CREAT   0000400   /* Open with file create (uses third open arg) */
#endif

Grid * CalcCumDD(char * prefix, int StartDoy, 
                 int EndDoy, int Year, int Method, float BaseTemp, 
                 int Subset, float xLowSub, float xHighSub, float yLowSub, 
                 float yHighSub); 

/*========================================================================
 *                                                                  MAIN
 */
main( int argc, char ** argv)
{

    char Sub[40];

    char buf[255];

    char TMinFileName[255];
    char TMaxFileName[255];
    char  GradCtlFile[100];
    char  GradDatFile[100];
    char  Date[100]; 
    char  prefix[10];   
    int fd;
    FILE * fhctl; 
           
    Grid * pTMinG		=NULL;
    Grid * pTMaxG		=NULL;
    Grid * pDDG			=NULL;
    GridCursor * pTMinGC	=NULL;
    GridCursor * pTMaxGC	=NULL;
    GLayer * pDDL		=NULL;
    GLView * pGLV		=NULL;
    GLayer * pGL		=NULL;
    float ** CumDD=NULL;

    int Year;
    int StartDoy;
    int EndDoy;
    int Method;
    float BaseTemp;

    float TMin;
    float TMax;
    int   TMinErr;
    int   TMaxErr;
    float DD;

    int doy;
    int earlydoy;

    int srcdoy; 
    int TMinDoy,TMaxDoy;
    float xPos,yPos; 
    int xIdx,yIdx;   
    int FoundMin;
    int FoundMax;
    
    int xNo,yNo;
    float xLow, xHigh, yLow, yHigh;
    float lon,lat;

    float xLowSub, xHighSub, yLowSub, yHighSub;
    float xIncr,yIncr;
    int xStrt,xEnd,yStrt,yEnd;
    int lStrt,lEnd;
    float BadValue;
    int yr, mnth ,day;

    int Subset = FALSE;

    int x,y,l;
    
   

    strcpy(Sub,"GetStnDD:Main");

    StartConPrint();
    
    /*-------------------------------
     * Check Parameters
     */
    if ( !(argc==9) ) {
	goto USAGE;
    }
    Year 		= atoi(argv[1]);
    StartDoy	= atoi(argv[2]);
    EndDoy	= atoi(argv[3]);
    if ( !(strlen(argv[4])==4 && 
	( argv[4][0]=='R' || argv[4][0]=='S' || argv[4][0]=='M'
	|| argv[4][0]=='P' ) ) ) {
	printf("Method Must be 'Rect' or 'Sine' or 'ModB' or 'PDay' \n");
	goto USAGE;
    }
    switch (argv[4][0]) {
      case 'R' :
    	Method = GRD_DD_RECTANGULAR;
	break;
      case 'S' :
    	Method = GRD_DD_SINE_WAVE;
	break;
      case 'M' :
    	Method = GRD_DD_MODIFIED_BASE;
	break;
      case 'P' :
    	Method = GRD_DD_PDAY;
	break;	
    }
    BaseTemp	= atof(argv[5]);
    sprintf(prefix,argv[6]);
    lat = atof(argv[7]);
    lon = atof(argv[8]);
    
    Subset=TRUE;
    xLowSub = lon-0.5;
    xHighSub = lon+0.5;
    yLowSub = lat-0.5;
    yHighSub = lat+0.5;

    if (StartDoy <1 || StartDoy > 366) {
	RegErr(Sub,"","StartDoy Should be 1-366");
	goto USAGE;
    }
    if (EndDoy <1 || EndDoy > 366) {
	RegErr(Sub,"","EndDoy Should be 1-366");
	goto USAGE;
    }
    if (BaseTemp < 30 || BaseTemp > 90 ) {
	RegErr(Sub,"",
	   "Base Temp Should be in Deg F, <30 or >90 seems unreasonable");
	goto USAGE;
    }
    
    /*----------------------------------
     * Compute the Cumulative DD
     */
    if ( (pDDG=CalcCumDD(prefix,StartDoy,EndDoy,Year,Method,
                         BaseTemp,Subset,xLowSub,xHighSub,yLowSub,
                         yHighSub)) == NULL ) {
        RegErr(Sub,"","Error computing cumulative DD");
        goto ERROR;         
    } 
    if ( (pDDL=GetGLayer(pDDG,1)) == NULL ) {
        RegErr(Sub,"","Error retrieving layer from cumulative DD grid");
        goto ERROR;         
    } 
    
    
   /*---------------------------------------
    * Get the DD at lat,lon and print
    */
    GetGLVal(pDDG,pDDL,lon,lat,&DD);
    printf("%.0f",DD);
         
    EndConPrint();
    return AWS_OK;

ERROR:

    EndConPrint();
    return AWS_FAIL;

USAGE:
    printf(
"Usage: %s Year StartDoy EndDoy {Rect|ModB|Sine|Pday} BaseTemp TempPrefix Lat Long\n"
	, argv[0]);
    printf(
"Example: %s 96 66 73 ModB 50 Wi 43 -90\n"
	,argv[0]);
    EndConPrint();
    return AWS_FAIL;
}
