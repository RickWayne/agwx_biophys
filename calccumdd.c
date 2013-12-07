#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>

#include <awsdir.h>
#include <awstime.h>
#include <awserror.h>
#include <grid/grid.h>


#ifndef M_PI
# define M_PI           3.14159265358979323846
#endif
#ifndef M_PI_2
# define M_PI_2		1.57079632679489661923
#endif
#ifndef M_1_PI
# define M_1_PI 	0.31830988618379067154
#endif

#ifndef O_RDWR
#  define O_RDWR    0000002   /* Open for reading or writing */
#  define O_CREAT   0000400   /* Open with file create (uses third open arg) */
#endif

#define VIEW_RADIUS   1.2

#define DD_MAX_TEMP   86.0

float RectDD(float TMin, float TMax,float BaseTemp);
float RectAvgDD(float TAvg, float BaseTemp);
float ModBaseDD(float TMin, float TMax,float BaseTemp);
float ModBaseNoMaxDD(float TMin, float TMax,float BaseTemp);
float SineDD(float TMin, float TMax, float BaseTemp);
float p(float t);
float PdayDD(float TMin, float TMax);
Grid * CalcCumDD(char * prefix, int StartDoy, 
              int EndDoy, int Year, int Method, float BaseTemp, 
              int Subset, float xLowSub, float xHighSub, float yLowSub, 
              float yHighSub);
              
/*-------------------------------------------------------------------------
                                                                RectDD()
*/
float RectDD(float TMin, float TMax, float BaseTemp) 
{
    float dd;
    dd = (TMin+TMax)/2.0 - BaseTemp;
    if (dd<0.0) {
	dd=0.0;
    }
    return dd;
}
/*-------------------------------------------------------------------------
                                                             RectAvgDD()
*/
float RectAvgDD(float TAvg, float BaseTemp) 
{
    float dd;
    dd = TAvg - BaseTemp;
    if (dd<0.0) {
	dd=0.0;
    }
    return dd;
}
/*-------------------------------------------------------------------------
                                                              ModBaseDD()
*/
float ModBaseDD(float TMin, float TMax,float BaseTemp) 
{
    if (TMin < BaseTemp) TMin=BaseTemp;
    if (TMax < BaseTemp) TMax=BaseTemp;
    if (TMin > DD_MAX_TEMP) TMin=DD_MAX_TEMP;
    if (TMax > DD_MAX_TEMP) TMax=DD_MAX_TEMP;

    return (TMin+TMax)/2.0 - BaseTemp;
}
/*-------------------------------------------------------------------------
                                                           ModBaseNoMaxDD()
*/
float ModBaseNoMaxDD(float TMin, float TMax,float BaseTemp) 
{
    if (TMin < BaseTemp) TMin=BaseTemp;
    if (TMax < BaseTemp) TMax=BaseTemp;

    return (TMin+TMax)/2.0 - BaseTemp;
}

/*-------------------------------------------------------------------------
                                                                SineDD()
*/
float SineDD(float TMin, float TMax, float BaseTemp)
{
    float alpha;
    float o1,o2;
    float dd;
    float avg;

    /*-----------------------
     * Source Degree-Days: The Calculation and Use
     * of Heat Units in Pest management
     */
    if (TMin > TMax) {
	RegErr("CalcDayDD:SineDD:","","Tmin > Tmax");
	return -9999999;
    }
    if (TMin >= DD_MAX_TEMP) {
	return DD_MAX_TEMP - BaseTemp;
    }
    if (TMax <= BaseTemp) {
	return 0;
    }
    if (TMax <= DD_MAX_TEMP && TMin >= BaseTemp) {
	return (TMax+TMin)/2 - BaseTemp;
    }
    alpha = (TMax-TMin)/2;
    avg   = (TMax+TMin)/2;

    if (TMax <= DD_MAX_TEMP && TMin < BaseTemp) {
        o1    = asin( (BaseTemp-avg)/alpha);
	return M_1_PI*( (avg-BaseTemp) * (M_PI_2-o1) + alpha*cos(o1) );
    }
    if (TMax >  DD_MAX_TEMP && TMin >= BaseTemp) {
        o2    = asin( (DD_MAX_TEMP-avg)/alpha);
	return M_1_PI*( (avg-BaseTemp) * (o2+M_1_PI) +
		(DD_MAX_TEMP-BaseTemp) * (M_PI_2-o2) - alpha*cos(o2) );
    }
    if (TMax >  DD_MAX_TEMP && TMin < BaseTemp) {
        o1    = asin( (BaseTemp-avg)/alpha);
        o2    = asin( (DD_MAX_TEMP-avg)/alpha);
	return M_1_PI*( (avg-BaseTemp)*(o2-o1) + alpha*(cos(o1)-cos(o2))
			+ (DD_MAX_TEMP-BaseTemp)*(M_PI_2-o2) );
    }
} 
/*-------------------------------------------------------------------------
                                                                   p()
  Function needed to calculate p-days, page B-81 of the PCM manual  
*/   
float p(float t)
{
    t=(t-32.)*5./9.;
    if (t<7) return 0.0;
    if (t<21) return 10*(1.-((t-21.)*(t-21.))/196.);
    if (t<30) return 10*(1.-((t-21.)*(t-21.))/81.);
    return 0.0;
}
/*-------------------------------------------------------------------------
                                                                   PdayDD()
  P-day thermal time calculation                                                                    
*/
float PdayDD(float TMin, float TMax)
{
   return (1./24.)*(5*p(TMin)+8*p(2*TMin/3+TMax/3)+8*p(2*TMax/3+TMin/3)
     +3*p(TMax));
}    
/*-------------------------------------------------------------------------
                                                                CalcCumDD()
  Calculates cumulative DD between StartDoy & EndDoy using 
  Method and BaseTemp.  Returns a grid with the cumDDs in
  layer 1.                                                                
*/
Grid * CalcCumDD(char * prefix, int StartDoy, 
              int EndDoy, int Year, int Method, float BaseTemp, 
              int Subset, float xLowSub, float xHighSub, float yLowSub, 
              float yHighSub) 
{

    char Sub[40];

    char buf[255];

    char TMinFileName[255];
    char TMaxFileName[255];
    char TAvgFileName[255];    
    char  GradCtlFile[100];
    char  GradDatFile[100];
    char  GridTmpFile[100]; 
    char  Date[100];    
    int fd;
    FILE * fhctl; 
           
    Grid * pTMinG		=NULL;
    Grid * pTMaxG		=NULL;
    Grid * pTAvgG		=NULL;    
    Grid * pDDG			=NULL;
    GridCursor * pTMinGC	=NULL;
    GridCursor * pTMaxGC	=NULL;
    GridCursor * pTAvgGC	=NULL;    
    GLayer * pDDL		=NULL;
    GLView * pGLV		=NULL;
    GLayer * pGL		=NULL;

    float TMin;
    float TMax;
    float TAvg;    
    int   TMinErr;
    int   TMaxErr;
    int   TAvgErr;    
    float DD;

    int doy;
    int earlydoy;

    int srcdoy; 
    int TMinDoy,TMaxDoy,TAvgDoy;
    float xPos,yPos; 
    int xIdx,yIdx;   
    float Val;
    int FoundMin;
    int FoundMax;
    int FoundAvg;
    
    int xNo,yNo;
    int xNoSave,yNoSave;
    float xLow, xHigh, yLow, yHigh;
    int xStrt,xEnd,yStrt,yEnd;

    float xIncr,yIncr,zIncr;
    int lStrt,lEnd;
    float BadValue;
    int mnth ,day;
    int DecPlace;

    int x,y,l;
    int i,j;
    
    float ** CumDD=NULL;   

    strcpy(Sub,"CalcCumDD");


    
    /*-------------------------------
     * Generate Temperature Grid File Names
     */
    sprintf(TMinFileName,"%s/%sTMin%d",ASOS_GRID_DIR,prefix,Year);
    sprintf(TMaxFileName,"%s/%sTMax%d",ASOS_GRID_DIR,prefix,Year);
    sprintf(TAvgFileName,"%s/%sTAvg%d",ASOS_GRID_DIR,prefix,Year);
    sprintf(GridTmpFile,"ddgrid.tmp");

    /*------------------------------
     * Load Grids and Create Cursors
     */
    if ( (pTMinG=LoadGrid(TMinFileName)) == NULL) {
	RegErr(Sub,TMinFileName,"Couldn't Load Grid File");
	goto ERROR;
    }
    if ( (pTMinGC=CreateGridCursor(pTMinG)) == NULL) {
	RegErr(Sub,TMinFileName,"Couldn't Load Grid Cursor");
	goto ERROR;
    }

    if ( (pTMaxG=LoadGrid(TMaxFileName)) == NULL) {
	RegErr(Sub,TMaxFileName,"Couldn't Load Grid File");
	goto ERROR;
    }
    if ( (pTMaxGC=CreateGridCursor(pTMaxG)) == NULL) {
	RegErr(Sub,TMaxFileName,"Couldn't Load Grid Cursor");
	goto ERROR;
    }        

    if ( (pTAvgG=LoadGrid(TAvgFileName)) == NULL) {
	RegErr(Sub,TAvgFileName,"Couldn't Load Grid File");
	goto ERROR;
    }
    if ( (pTAvgGC=CreateGridCursor(pTAvgG)) == NULL) {
	RegErr(Sub,TAvgFileName,"Couldn't Load Grid Cursor");
	goto ERROR;
    }        

    
    /*---------------------------------------
     * Get the Dimensions of the temp grids 
     * (from TMAX; TMIN had better be the same)
     */
    xNo   = GetGridXDim(pTMaxG);
    yNo   = GetGridYDim(pTMaxG);
    xLow  = GetGridXMin(pTMaxG);
    xHigh = GetGridXMax(pTMaxG);
    yLow  = GetGridYMin(pTMaxG);
    yHigh = GetGridYMax(pTMaxG);
    lStrt = GetGridZMin(pTMaxG);
    lEnd  = GetGridZMax(pTMaxG);
    xIncr = (xHigh-xLow)/(xNo-1);
    yIncr = (yHigh-yLow)/(yNo-1);
    BadValue = GetGridBadVal(pTMaxG);
    DecPlace = GetGridDecPlace(pTMaxG);
    xNoSave = xNo;
    yNoSave = yNo;
    
    /*---------------------------------------
     * If this is a subset extraction then
     * set limits.
     */
    if (Subset==TRUE) {
    
        /*----------------------
         * Check for ridiculous values
	if (xLowSub >= xHighSub) {
	    printf("error  xLowSub %f  >= xHighSub Value %f\n",xLowSub,
							xHighSub);
	    goto ERROR;
        }
	if (xLowSub > xHigh) {
	    printf("Bad xLowSub Value %f \n",xLowSub);
	    goto ERROR;
        }
	if (xHighSub < xLow) {
	    printf("Bad xHighSub Value %f \n",xHighSub);
	    goto ERROR;
        }

	if (yLowSub >= yHighSub) {
	    printf("error  yLowSub %f  >= yHighSub Value %f\n",yLowSub,
							yHighSub);
	    goto ERROR;
        }
	if (yLowSub > yHigh) {
	    printf("Bad yLowSub Value %f \n",yLowSub);
	    goto ERROR;
        }
	if (yHighSub < yLow) {
	    printf("Bad yHighSub Value %f \n",yHighSub);
	    goto ERROR;
        }
         
        /*----------------------
         * Set to limits if exceeded
         */
        if (xLowSub<xLow) xLowSub=xLow;
        if (xHighSub>xHigh) xHighSub=xHigh;
        if (yLowSub<yLow) yLowSub=yLow;
        if (yHighSub>yHigh) yHighSub=yHigh;

        /*--------------------
	 * Find indices - All "rounding" is down when converting 
	 * to integer.  We check to see if it just (10% of the grid increment) 
	 * misses a grid location
	 *
	 */
        xStrt=(xLowSub-xLow)/xIncr;
	if ( xLowSub-(xIncr*xStrt+xLow) > xIncr*0.1) xStrt++;
        xEnd=(xHighSub-xLow)/xIncr;
	if ( (xIncr*(xEnd+1)+xLow-xHighSub) < xIncr*0.1) xEnd++;
        yStrt=(yLowSub-yLow)/yIncr;
	if ( yLowSub-(yIncr*yStrt+yLow) > yIncr*0.1) yStrt++;
        yEnd=(yHighSub-yLow)/yIncr;
	if ( (yIncr*(yEnd+1)+yLow-yHighSub) < yIncr*0.1) yEnd++;
/*        printf("Actual Limits Are %f %f %f and %f\n"
		,xStrt*xIncr+xLow,xEnd*xIncr+xLow
		,yStrt*yIncr+yLow,yEnd*yIncr+yLow); */
	xHigh = xEnd*xIncr+xLow;		
        xLow =  xStrt*xIncr+xLow;
	xNo = xEnd-xStrt+1;
	yHigh = yEnd*yIncr+yLow;	
	yLow =  yStrt*yIncr+yLow;
	yNo = yEnd-yStrt+1;

    }
    else {
	xStrt = 0;
	xEnd = xNo-1;
	yStrt = 0;
	yEnd = yNo-1;
    }
    
    /*---------------------------------------
     * Allocate temporary CumDD Array.
     */
    if ( (CumDD=malloc(sizeof(float *) * xNoSave)) == NULL) {
	RegErr(Sub,"CumDD",AWSERR_MALLOC);
	goto ERROR;
    }
    for(i=0;i<xNoSave;i++) {
	CumDD[i] = NULL;
    }
    for(i=0;i<xNoSave;i++) {
	if ( (CumDD[i]=malloc(sizeof(float) * yNoSave) ) == NULL) {
	    RegErr(Sub,"CumDD sub",AWSERR_MALLOC);
	    goto ERROR;
	}
	for(j=0;j<yNoSave;j++) {
	  CumDD[i][j]=0.0;
	}
    } 
        
    /*---------------------------------------
     * Create the Output CumDD Grid with 1 layer.
     */  
    zIncr    = 1;
    if ( (pDDG=CreateGrid(GridTmpFile,xLow,xHigh,xNo,yLow,yHigh,yNo,
                          zIncr,BadValue,DecPlace)) == NULL) {
        RegErr(Sub,"","Creating Temporary Grid");
        goto ERROR;
    } 
    if ( (pDDL=CreateGLayer(pDDG,1)) == NULL) {
        RegErr(Sub,"","Creating Temporary Grid Layer");
        goto ERROR;
    }     
    if ( (AddGLayer(pDDG,pDDL,FALSE)) != AWS_OK ) {
        RegErr(Sub,"","Adding Temporary Grid Layer");
        goto ERROR;
    }   
           
    /*===========================================================
     * THE MAIN LOOP.  For Each Day in the DD Calculation Range
     */

    for (doy=StartDoy; doy<=EndDoy;doy++) {

        /*----------------------------
         * Set The Source TMin And TMax 
	 * Cursors. If doy is not available 
	 * Go back to doy-1 and onward to 
	 * doy-5.  If you go back past
	 * doy-5 then it is an error.
	 */
	TMinDoy=doy;
	earlydoy = doy-5; if (earlydoy < 1) earlydoy = 1;

	while(SetGCLayer(pTMinGC,TMinDoy)!=AWS_OK) {
	    if (TMinDoy<=earlydoy) {
		sprintf(buf,"Can Not Find a Layer between %d and %d"
			,earlydoy,doy);
		RegErr(Sub,TMinFileName,buf);
		goto ERROR;
	    }
	    TMinDoy--;
	}
	
	TMaxDoy=doy;
	earlydoy = doy-5; if (earlydoy < 1) earlydoy = 1;

	while(SetGCLayer(pTMaxGC,TMaxDoy)!=AWS_OK) {
	    if (TMaxDoy<=earlydoy) {
		sprintf(buf,"Can Not Find a Layer between %d and %d"
			,earlydoy,doy);
		RegErr(Sub,TMaxFileName,buf);
		goto ERROR;
	    }
	    TMaxDoy--;
	}
	
	TAvgDoy=doy;
	earlydoy = doy-5; if (earlydoy < 1) earlydoy = 1;

	while(SetGCLayer(pTAvgGC,TAvgDoy)!=AWS_OK) {
	    if (TAvgDoy<=earlydoy) {
		sprintf(buf,"Can Not Find a Layer between %d and %d"
			,earlydoy,doy);
		RegErr(Sub,TAvgFileName,buf);
		goto ERROR;
	    }
	    TAvgDoy--;
	}
	
	/*-------------------------------------------------
         * With Source Days Set Now Loop Through All Locations
	 * on the Grid Layer
	 */
	TMinErr = FirstGC(pTMinGC,&TMin);
	TMaxErr = FirstGC(pTMaxGC,&TMax);
	TAvgErr = FirstGC(pTAvgGC,&TAvg);	
	do {
	    if (GetGCPos(pTMinGC,&xPos,&yPos) != AWS_OK) {
		RegErr(Sub,"","Couldn't Get Position of the TMin Cursor");
		goto ERROR;
	    }
	    
            /* Extract data only within requested limits */
	    if (GetGCPosIndex(pTMinGC,&xIdx,&yIdx) != AWS_OK) {
		RegErr(Sub,"","Couldn't Get Position Index of the TMin Cursor");
		goto ERROR;
	    }
	    if (xIdx<xStrt || xIdx>xEnd || yIdx<yStrt || yIdx>yEnd) {
	        continue;
	    }	    

            /*----------------------
             * If The Grid Position Has  returned a bad value code
	     * we need to know if this an area that MICIS does not 
	     * cover.  We define that to be a location that has not had 
	     * a value for 6 days.  If a value at that location is
	     * found in the last 6 days then  we  take an average of the  
	     * surounding area (defined by VIEW_RADIUS) if that returns  a 
	     * bad value, go to previous days. If you end up at the date 
	     * of begining cumulation then Error.
	     * 
	     * NOTE: the view area is a square.  I use the term radius
	     * to suggest that the length is half way across.
	     */
	    FoundMin = TRUE;
  	    if (TMinErr!=AWS_OK) {
	        FoundMin = FALSE;
		srcdoy = TMinDoy;
		earlydoy = TMinDoy-5; if (earlydoy<1) earlydoy = 1;
		for (srcdoy = TMinDoy; srcdoy >= earlydoy; srcdoy--) {
		    if ( (pGL=GetGLayer(pTMinG,srcdoy)) != NULL) {
			if ( GetGLVal(pTMinG,pGL,xPos,yPos,&Val) == AWS_OK) {
			    FoundMin = TRUE;
			    break;
			}
		    }
		}
	    }
	    if ((FoundMin==TRUE) && (TMinErr!=AWS_OK)) {
	        srcdoy = TMinDoy;
		while (TMinErr!=AWS_OK) {
		    if ( (pGLV=CreateGLView(pTMinG,srcdoy,
				xPos-VIEW_RADIUS,xPos+VIEW_RADIUS,
				yPos-VIEW_RADIUS,yPos+VIEW_RADIUS)) != NULL) {
		        if ( (TMinErr = AverageGLV(pGLV,&TMin) ) != AWS_OK ) {
			    if (srcdoy<=1) {
				sprintf(buf,
	"Couldn't get tmin value for x=%f y=%f between %d and %d",
					xPos,yPos,1,doy);	
				RegErr(Sub,"",buf);
				goto ERROR;
			    }
			}
		    } 
		    srcdoy--;
		}
	    }
	    if (FoundMin == FALSE) {
		/*--------------------------
		 * Found is False for locations 
		 * where Micis does not have coverage.
		 * Set these locations ot the BadValue code.
		 */
		TMin = GetGridBadVal(pTMinG);
	    }
	
	    /*----------------------
	     * Now do the same for TMax if there
	     * was a problem.
	     */
	    if (GetGCPos(pTMaxGC,&xPos,&yPos) != AWS_OK) {
	        RegErr(Sub,"","Couldn't Get Position for TMax Cursor");
		goto ERROR;
	    }
	    FoundMax = TRUE;
  	    if (TMaxErr!=AWS_OK) {
	        FoundMax = FALSE;
		srcdoy = TMaxDoy;
		earlydoy = TMaxDoy-5; if (earlydoy<1) earlydoy = 1;
		for (srcdoy = TMaxDoy; srcdoy >= earlydoy; srcdoy--) {
		    if ( (pGL=GetGLayer(pTMaxG,srcdoy)) != NULL) {
			if ( GetGLVal(pTMaxG,pGL,xPos,yPos,&Val)
					== AWS_OK) {
			    FoundMax = TRUE;
			    break;
			}
		    }
		}
	    }
	    if ((FoundMax == TRUE) && (TMaxErr!=AWS_OK)) {
	        srcdoy = TMaxDoy;
		while (TMaxErr!=AWS_OK) {
		    if ( (pGLV=CreateGLView(pTMaxG,srcdoy,
				xPos-VIEW_RADIUS,xPos+VIEW_RADIUS,
				yPos-VIEW_RADIUS,yPos+VIEW_RADIUS)) != NULL) {
		        if ( (TMaxErr = AverageGLV(pGLV,&TMax) ) != AWS_OK ) {
			    if (srcdoy<=1) {
				sprintf(buf,
	"Couldn't get tmax value for x=%f y=%f between %d and %d",
					xPos,yPos,1,doy);	
				RegErr(Sub,"",buf);
				goto ERROR;
			    }
			}
		    } 
		    srcdoy--;
		}
	    }
	    if (FoundMax == FALSE) {
		/*--------------------------
		 * Found is False for locations 
		 * where Micis does not have coverage.
		 * Set these locations ot the BadValue code.
		 */
		TMax = GetGridBadVal(pTMaxG);
	    }
	    /*----------------------
	     * Now do the same for TAvg if there
	     * was a problem.
	     */
	    if (GetGCPos(pTAvgGC,&xPos,&yPos) != AWS_OK) {
	        RegErr(Sub,"","Couldn't Get Position for TAvg Cursor");
		goto ERROR;
	    }
	    FoundAvg = TRUE;
  	    if (TAvgErr!=AWS_OK) {
	        FoundAvg = FALSE;
		srcdoy = TAvgDoy;
		earlydoy = TAvgDoy-5; if (earlydoy<1) earlydoy = 1;
		for (srcdoy = TAvgDoy; srcdoy >= earlydoy; srcdoy--) {
		    if ( (pGL=GetGLayer(pTAvgG,srcdoy)) != NULL) {
			if ( GetGLVal(pTAvgG,pGL,xPos,yPos,&Val)
					== AWS_OK) {
			    FoundAvg = TRUE;
			    break;
			}
		    }
		}
	    }
	    if ((FoundAvg == TRUE) && (TAvgErr!=AWS_OK)) {
	        srcdoy = TAvgDoy;
		while (TAvgErr!=AWS_OK) {
		    if ( (pGLV=CreateGLView(pTAvgG,srcdoy,
				xPos-VIEW_RADIUS,xPos+VIEW_RADIUS,
				yPos-VIEW_RADIUS,yPos+VIEW_RADIUS)) != NULL) {
		        if ( (TAvgErr = AverageGLV(pGLV,&TAvg) ) != AWS_OK ) {
			    if (srcdoy<=1) {
				sprintf(buf,
	"Couldn't get tmax value for x=%f y=%f between %d and %d",
					xPos,yPos,1,doy);	
				RegErr(Sub,"",buf);
				goto ERROR;
			    }
			}
		    } 
		    srcdoy--;
		}
	    }
	    if (FoundAvg == FALSE) {
		/*--------------------------
		 * Found is False for locations 
		 * where Micis does not have coverage.
		 * Set these locations ot the BadValue code.
		 */
		TAvg = GetGridBadVal(pTAvgG);
	    }
	    	    
	    if ((FoundMax == TRUE) && (FoundMin == TRUE) && (FoundAvg == TRUE)) {
	        /*-----------------------
	         * Convert from Celsius to Fahrenheit
	         */
	         TMax = TMax*1.8+32.0;
	         TMin = TMin*1.8+32.0;
	         TAvg = TAvg*1.8+32.0;
	         
		/*------------------------
		 * Some times the grids get
		 * weird and the max is less than the min.
		 */
		if (TMax<TMin) {
		    Val = TMax;
		    TMax = TMin;
		    TMin = TMax;

		}
	    	/*-----------------------
	    	 * OK.  Now we Have a Good 
	    	 * TMin and TMax. Calculate DD
	    	 */
	    	switch (Method) {
	      	  case GRD_DD_RECTANGULAR:
		    DD=RectDD(TMin,TMax,BaseTemp);
		    break;
	      	  case GRD_DD_RECT_AVG:
		    DD=RectAvgDD(TAvg,BaseTemp);
		    break;		    
	          case GRD_DD_SINE_WAVE:
		    DD=SineDD(TMin,TMax,BaseTemp);
		    break;
	          case GRD_DD_MODIFIED_BASE:
		    DD=ModBaseDD(TMin,TMax,BaseTemp);
		    break;
		  case GRD_DD_PDAY:
		    DD=PdayDD(TMin,TMax);
		    break;
	          case GRD_DD_MODIFIED_BASE_NOMAX:
		    DD=ModBaseNoMaxDD(TMin,TMax,BaseTemp);
		    break;		    
		}
	    }
	    else {
		DD = BadValue;
	    }
	    
	    /*------------------------
	     * Add DD to cumulative sum at that location
	     */

             if (DD!=BadValue && CumDD[xIdx][yIdx]!=BadValue) {
               CumDD[xIdx][yIdx]+=DD;
             } else {
               CumDD[xIdx][yIdx]=BadValue;
             }
               
	} while ( ((TMinErr = NextGC(pTMinGC,&TMin)) != AWS_ENDOFSTREAM)
		&&((TMaxErr = NextGC(pTMaxGC,&TMax)) != AWS_ENDOFSTREAM) 
		&&((TAvgErr = NextGC(pTAvgGC,&TAvg)) != AWS_ENDOFSTREAM) );
	
    } 
    /*
     * END OF DOY LOOP
     *============================================================*/

     /*-------------------------
        Enter CumDD data into grid, 
        which may be a subset of the temp grids
      */     
     yIdx=0;
     for (y=yStrt;y<=yEnd;y++) {
        xIdx=0;
	for (x=xStrt;x<=xEnd;x++) {
	   if (PutGLValByIndex(pDDG,pDDL,xIdx,yIdx,CumDD[x][y]) !=  AWS_OK) {
	       RegErr(Sub,"Error filling temporary CumDD grid",buf);
	       goto ERROR;
	   }
	   xIdx++;
        }
        yIdx++;
     } 
     
    /*---------------------------
     * Clean Up And Leave
     */
     
    if (pTMinG!=NULL) {
	CloseGrid(pTMinG);
	free(pTMinG);
	pTMinG = NULL;
    }
    if (pTMaxG!=NULL) {
	CloseGrid(pTMaxG);
	free(pTMaxG);
	pTMaxG = NULL;
    }
    if (pTAvgG!=NULL) {
	CloseGrid(pTAvgG);
	free(pTAvgG);
	pTAvgG = NULL;
    }    
    if (pTMinGC!=NULL) {
	free(pTMinGC);
	pTMinGC==NULL;
    }
    if (pTMaxGC!=NULL) {
	free(pTMaxGC);
	pTMaxGC==NULL;
    }
    if (pTAvgGC!=NULL) {
	free(pTAvgGC);
	pTAvgGC==NULL;
    }
    
    if (CumDD!=NULL) {
        for(i=0;i<xNoSave;i++) {
          free(CumDD[i]);
        }
        free(CumDD);
    }

    return pDDG;
         
ERROR:
    if (pTMinG!=NULL) {
	ClearGrid(pTMinG);
	free(pTMinG);
	pTMinG = NULL;
    }
    if (pTMaxG!=NULL) {
	ClearGrid(pTMaxG);
	free(pTMaxG);
	pTMaxG = NULL;
    }
    if (pTAvgG!=NULL) {
	ClearGrid(pTAvgG);
	free(pTAvgG);
	pTAvgG = NULL;
    }    
    if (pTMinGC!=NULL) {
	free(pTMinGC);
	pTMinGC==NULL;
    }
    if (pTMaxGC!=NULL) {
	free(pTMaxGC);
	pTMaxGC==NULL;
    }
    if (pTAvgGC!=NULL) {
	free(pTAvgGC);
	pTAvgGC==NULL;
    }
    
    if (CumDD!=NULL) {
        for(i=0;i<xNoSave;i++) {
          free(CumDD[i]);
        }
        free(CumDD);
    }

    return NULL;
}    
