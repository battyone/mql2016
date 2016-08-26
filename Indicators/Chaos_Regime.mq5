//+------------------------------------------------------------------+
//|                                                 Chaos_Regime.mq5 |
//| Chaos Regime v1.01                        Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//| This indicator is based upon the article,"Using a Self-Similarity|
//| Metric with Intraday Data to Define Market Regimes"              |
//| by David Varadi(https://cssanalytics.wordpress.com/)             |
//+------------------------------------------------------------------+


#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"


#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_minimum -50
#property indicator_maximum 50

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrRed,clrLightGreen
#property indicator_width1  6

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpPeriod=10;                // High Low Period
input int InpAvgPeriod=60;               // Avg Period
input int InpLookBack=252;               // LockBack Period
input int InpSmoothing=1;                // Smoothing

double SQ2=sqrt(2);


double RS[];
double MAIN[];
double CLR[];
double coef1,coef2,coef3;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   int i=0;
   SetIndexBuffer(i++,MAIN,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,RS,INDICATOR_DATA);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   double a = MathExp( -SQ2  * M_PI / InpSmoothing );
   coef2 = 2.0 * a * MathCos( SQ2 *M_PI / InpSmoothing );
   coef3 = -a * a;
   coef1 = 1.0 - coef2 - coef3;

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
     
      double dmax=0;
      double dmin=0;
      if(i>InpPeriod)
      {      
         dmax=high[ArrayMaximum(high,i-(InpPeriod-1),InpPeriod)];
         dmin=low[ArrayMinimum(low,i-(InpPeriod-1),InpPeriod)];
      }
      RS[i]=calcRS(high[i],low[i],dmax,dmin,InpPeriod,InpAvgPeriod,InpLookBack,i,rates_total);
      if(i<=1 || RS[i-1]==EMPTY_VALUE)continue;
      //--- 
      MAIN[i]=coef1 * RS[i] + coef2*MAIN[i-1] + coef3*MAIN[i-2];
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
double calcRS(double h,double l,double dmax,double dmin,int n,int avgPeriod,int lookback,int r,int bars)
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
   rsValues[r][1]=(h-l)+rsValues[r-1][1]-rsValues[r-n][0];   
   rsValues[r][2]=rsValues[r][1]/fmax((dmax-dmin),_Point);

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
   rsValues[r][4]= rsValues[r][3]/avgPeriod;
   int i2nd=i1st + avgPeriod;
   if(r<=i2nd+lookback+1)return 0;
   //---      
   double cnt=0;
   for(int j=1;j<=lookback;j++)
      if(rsValues[r-j][4]<=rsValues[r][4])cnt++;

   return(cnt/lookback)*100-50;

  }
//+------------------------------------------------------------------+
