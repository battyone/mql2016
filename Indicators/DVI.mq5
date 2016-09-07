//+------------------------------------------------------------------+
//|                                                          DVI.mq5 |
//| DV Intermediate Oscillator (DVI) 2009                            |
//| by David Varadi (https://cssanalytics.wordpress.com/)            |
//| ported by fxborg 2016 (http://fxborg-labo.hateblo.jp/)           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"


#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_level1 20.0
#property indicator_level2 50.0
#property indicator_level3 80.0
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrRed,clrLightGreen
#property indicator_width1  2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpLookBack=252;               // LockBack Period
input int InpSmoothing=3;                // Smoothing


double MAIN[];
double CLR[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,MAIN,INDICATOR_DATA);
   SetIndexBuffer(1,CLR,INDICATOR_COLOR_INDEX);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
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
     
      double dmax=0;
      double dmin=0;
      MAIN[i]=calcDVI(close[i],InpSmoothing,InpLookBack,i,rates_total);
      CLR[i]=(MAIN[i]>=50)?1:0;
     }
//---   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Series[][10];
int PRICE=0;
int R=1;
int B=2;
int R5MA=3;
int R100=4;
int R100MA=5;
int B10=6;
int B100=7;
int MAG=8;
int STR=9;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcDVI(double price,int smooth,int lookback,int r,int bars)
  {
   double v;
   if(ArrayRange(Series,0)!=bars) ArrayResize(Series,bars);
   Series[r][PRICE]=price;
   //---
   if(r==0)return 0;
   Series[r][B] = price > Series[r-1][PRICE] ? 1 : -1;   
   int i1st=smooth;
   if(r<=i1st) return 0;
   //---      
   v=0.0;
   for(int j=0;j<smooth;j++)v+=Series[r-j][PRICE];
   double avg = v / smooth ;
   Series[r][R] = price / avg - 1.0;
   //---      
   if(r<=i1st+4)return 0;   
   //---      
   v=0.0;
   for(int j=0;j<5;j++)v+=Series[r-j][R];
   Series[r][R5MA] = v/5.0;
   if(r<=i1st+9)return 0;
   //---      
   v=0.0;
   for(int j=0;j<10;j++)v+=Series[r-j][B];
   Series[r][B10]=v;
   //---      
   if(r< i1st+99)return 0;
   if(r<=i1st+99)
   {
      //---
      v=0.0;
      for(int j=0;j<100;j++)v+=Series[r-j][B];
      Series[r][B100]=v;
      //---
      v=0.0;
      for(int j=0;j<100;j++) v+=Series[r-j][R];
      Series[r][R100]=v;
      return 0;
   }
   
   //---      
   Series[r][R100] = (Series[r-1][R100]+ Series[r][R]) - Series[r-100][R];
   Series[r][R100MA] = Series[r][R100] / 100.0;
 
    //---      
   int i2nd=i1st+100;
   if (r<=i2nd+1)return 0;
   //---      
   v=0.0;
   for(int j=0;j<2;j++)      v+=( Series[r-j][B10] + Series[r-j][B100]*0.1 )*0.5;
   Series[r][STR]=v/2.0;
   //---      
   if(r<=i2nd+4)return 0;   
   v=0.0;
   for(int j=0;j<5;j++)      v+=( Series[r-j][R5MA] + Series[r-j][R100MA]*0.1 )*0.5;
   Series[r][MAG] = v/5.0;
   //---       
   int i3rd=i2nd+5;   
   if(r<=i3rd+lookback)return 0;
   //---      
   double mag_cnt=0;
   double str_cnt=0;
   for(int j=1;j<=lookback;j++)
   {
      if(Series[r-j][STR]<= Series[r][STR])str_cnt++;
      if(Series[r-j][MAG]<= Series[r][MAG])mag_cnt++;
   }
   double str =(str_cnt/lookback)*100;
   double mag =(mag_cnt/lookback)*100;
   
   return 0.2 * mag + 0.8 * str;

  }
//+------------------------------------------------------------------+
