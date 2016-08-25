//+------------------------------------------------------------------+
//|                                                 Chaos_Regime.mq5 |
//| Chaos Regime v1.00                        Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//| This indicator is based upon the article,"Using a Self-Similarity|
//| Metric with Intraday Data to Define Market Regimes"              |
//| by David Varadi(https://cssanalytics.wordpress.com/)             |
//+------------------------------------------------------------------+


#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"


#property indicator_separate_window
#property indicator_buffers 16
#property indicator_plots   1
#property indicator_minimum -50
#property indicator_maximum 50

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLightGreen,clrRed
#property indicator_width1  6

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpPeriod=10;                // High Low Period
input int InpAvgPeriod=60;               // Avg Period
input int InpLookBack=252;               // LockBack Period
input double InpStepSize=5.0;             // Step Size

double Size1=1.0;
double Size2=1.25;
double Size3=1.5;
double Size4=1.75;
double Size5=2.0;
double Size6=2.25;

double RS[];
double MAIN[];
double CLR[];
double DOT[];
double DOTCLR[];

double REGIME[];


//---- will be used as indicator buffers
double STEP1[];
double STEP2[];
double STEP3[];
double STEP4[];
double STEP5[];
double STEP6[];

double CLR1[];
double CLR2[];
double CLR3[];
double CLR4[];
double CLR5[];
double CLR6[];


int Length=int(PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_M5));
double c1,c2,c3,c4,t3Alpha;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(Length<=1)return(0);
   int i=0;
   SetIndexBuffer(i++,MAIN,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR,INDICATOR_COLOR_INDEX);

   SetIndexBuffer(i++,RS,INDICATOR_DATA);

   SetIndexBuffer(i++,STEP1,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR1,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP2,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR2,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP3,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR3,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP4,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR4,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP5,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR5,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,STEP6,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR6,INDICATOR_COLOR_INDEX);

   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);


   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])

  {

   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
     {
      
      RS[i]=calcRS(high[i],low[i],InpPeriod,InpAvgPeriod,InpLookBack,i,rates_total);
      if(i==0 || RS[i-1]==EMPTY_VALUE)continue;
      //--- 
      iStepMa(STEP1,CLR1,RS[i],Size1*InpStepSize,i);
      iStepMa(STEP2,CLR2,RS[i],Size2*InpStepSize,i);
      iStepMa(STEP3,CLR3,RS[i],Size3*InpStepSize,i);
      iStepMa(STEP4,CLR4,RS[i],Size4*InpStepSize,i);
      iStepMa(STEP5,CLR5,RS[i],Size5*InpStepSize,i);
      iStepMa(STEP6,CLR6,RS[i],Size6*InpStepSize,i);

      MAIN[i]=  (STEP1[i]+STEP2[i]+STEP3[i]+STEP4[i]+STEP5[i]+STEP6[i])/6;
      CLR[i]=(MAIN[i]>=0.0)?1:0;
     }
//---   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double rsValues[][5];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcRS(double h,double l,int n,int avgPeriod,int lookback,int r,int bars)
  {
   if(ArrayRange(rsValues,0)!=bars) ArrayResize(rsValues,bars);
   rsValues[r][0]=h-l;
   //---
   if(r==0)
   {
    rsValues[r][1]=rsValues[r][0];
    return 0;
   }
   rsValues[r][1]=(h-l)+rsValues[r-1][1];   
   //---
   if(r<n) return 0;
   double dmax=rsValues[ArrayMaximum(rsValues,r-(n-1),n)][0];
   double dmin=rsValues[ArrayMinimum(rsValues,r-(n-1),n)][0];
   rsValues[r][1]=(h-l)+rsValues[r-1][1]-rsValues[r-n][0];   
   rsValues[r][2]=rsValues[r][1]/fmin((dmax-dmin),_Point);
   //---
   int i1st=n;
   if(r<=i1st)
     {
     rsValues[r][3]=rsValues[r][2];
     return 0;
     }
   rsValues[r][3]=rsValues[r][2]+rsValues[r-1][3];
   //---
   if(r < i1st + avgPeriod) return 0;
   rsValues[r][3]=rsValues[r][2]+rsValues[r-1][3]-rsValues[r-avgPeriod][2];   

   //---
   rsValues[r][4]=rsValues[r][3]/avgPeriod;

   int i2nd=i1st + avgPeriod;
   if(r<=i2nd+lookback+1)return 0;
   //---      
   double cnt=0;
   for(int j=1;j<=lookback;j++)
      if(rsValues[r-j][4]<=rsValues[r][4])cnt++;

   return(cnt/lookback)*100-50;

  }
//+------------------------------------------------------------------+
void iStepMa(double &step[],double &clr[],const double price,const double size,const int i)
{
         if(clr[i-1]==0)
         {
            if((price-size)>step[i-1]) step[i]=price-size;
            else if((price+size)<step[i-1]) step[i]=price+size;
            else step[i]=step[i-1];
         }
         else
         {
            if((price-size)>step[i-1]) step[i]=price-size;
            else if((price+size)<step[i-1]) step[i]=price+size;
            else step[i]=step[i-1];
         }
         if(step[i]>step[i-1])clr[i]=0;
         else if(step[i]<step[i-1])clr[i]=1;
         else clr[i]=clr[i-1];

}
