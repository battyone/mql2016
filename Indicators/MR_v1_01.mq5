//+------------------------------------------------------------------+
//|                                                     MR_v1_01.mq5 |
//| mean reversion v1.01                      Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDeepPink
#property indicator_width1  2

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrAqua
#property indicator_width2  2

#property indicator_type3   DRAW_LINE
#property indicator_color3  Goldenrod
#property indicator_width3  2

#property indicator_type4   DRAW_LINE
#property indicator_color4  Goldenrod
#property indicator_width4  2

#property indicator_type5   DRAW_LINE
#property indicator_color5  clrRed
#property indicator_width5  2

#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed
#property indicator_width6  2
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpPeriod1=50;                // Z-Score Period(Inner)
input int InpPeriod2=250;               // Z-Score Period(Outer)
input double InpLevel1=2.0;             // Level(Inner)
input double InpLevel2=2.5;             // Level(Outer)
input int MaxMinSize=20;
double UP[];
double DN[];

double BB1H[];
double BB1L[];
double BB2H[];
double BB2L[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,UP,INDICATOR_DATA);
   SetIndexBuffer(1,DN,INDICATOR_DATA);
   SetIndexBuffer(2,BB1H,INDICATOR_DATA);
   SetIndexBuffer(3,BB1L,INDICATOR_DATA);
   SetIndexBuffer(4,BB2H,INDICATOR_DATA);
   SetIndexBuffer(5,BB2L,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_ARROW,218);
   PlotIndexSetInteger(1,PLOT_ARROW,217);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-20);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,20);
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
      
      calcMR(BB1H,BB1L,BB2H,BB2L,high[i],low[i],close[i],InpPeriod1,InpPeriod2,i,rates_total);
      if(i<=MaxMinSize)continue;
      double hi = high[ArrayMaximum(high,i-MaxMinSize-1,MaxMinSize)];
      double lo = low[ArrayMinimum(low,i-MaxMinSize-1,MaxMinSize)];
      
      if(BB1H[i]<close[i] &&BB2H[i]>close[i] && hi>close[i])UP[i]=high[i]; 
      else UP[i]=EMPTY_VALUE;
      if(BB1L[i]>close[i] &&BB2L[i]<close[i] && lo<close[i])DN[i]=low[i]; 
      else DN[i]=EMPTY_VALUE;
     }
//---   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Series[][11];
int H=0;
int L=1;
int C=2;
int SUM1=3;
int MA1=4;
int VAR1=5;
int SD1=6;
int SUM2=7;
int MA2=8;
int VAR2=9;
int SD2=10;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcMR(double &bb1hi[],double &bb1lo[],double &bb2hi[],double &bb2lo[], double hi,double lo,double cl,int period1,int period2,int r,int bars)
  {
   if(ArrayRange(Series,0)!=bars) ArrayResize(Series,bars);
   Series[r][H]=hi;
   Series[r][L]=lo;
   Series[r][C]=cl;
   int skip =fmax(period1,period2);
   if(r<skip)return ;
   if(r==skip)
   {
      //--   main
      double sum=0;
      for(int j=0; j<period1; j++)         sum += Series[r-j][C];
      Series[r][SUM1]=sum;
      Series[r][MA1]=sum/period1;
      //---
      sum=0;
      for(int j=0;j<period1;j++)         sum += pow((Series[r][MA1] - Series[r-j][C]),2);
      Series[r][VAR1]=sum;      
      
      //--- sub
      sum=0;      
      for(int j=0; j<period2; j++)       sum += Series[r-j][C];
      Series[r][SUM2]=sum;
      Series[r][MA2]=sum/period2;
      //---
      sum=0;
      for(int j=0;j<period2;j++)         sum += pow((Series[r][MA2] - Series[r-j][C]),2);
      Series[r][VAR2]=sum;
      return;
   }
   
   Series[r][SUM1]= Series[r-1][SUM1] + Series[r][C] - Series[r-period1][C];
   Series[r][MA1]=Series[r][SUM1]/period1;
      
   Series[r][SUM2]= Series[r-1][SUM2] + Series[r][C] - Series[r-period2][C];
   Series[r][MA2]=Series[r][SUM2]/period2;

   //---
   double df1   = pow((Series[r][MA1] - Series[r][C]),2);
   double past1 = pow((Series[r-1][MA1] - Series[r-period1][C]),2);
   Series[r][VAR1]=Series[r-1][VAR1] + df1 - past1;
   Series[r][SD1]=sqrt(Series[r][VAR1]/period1);
   //---
   double df2   = pow((Series[r][MA2] - Series[r][C]),2);
   double past2 = pow((Series[r-1][MA2] - Series[r-period2][C]),2);
   Series[r][VAR2]=Series[r-1][VAR2] + df2 - past2;
   Series[r][SD2]=sqrt(Series[r][VAR2]/period2);
   //---  
   bb1hi[r] = Series[r][MA1]+Series[r][SD1]*InpLevel1;
   bb1lo[r] = Series[r][MA1]-Series[r][SD1]*InpLevel1;

   bb2hi[r] = Series[r][MA2]+Series[r][SD2]*InpLevel2;
   bb2lo[r] = Series[r][MA2]-Series[r][SD2]*InpLevel2;
  }
//+------------------------------------------------------------------+

