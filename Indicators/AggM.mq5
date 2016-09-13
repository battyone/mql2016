//+------------------------------------------------------------------+
//|                                                         AggM.mq5 |
//| Aggregate M 2009                                                 |
//| by David Varadi (https://cssanalytics.wordpress.com/)            |
//| ported by fxborg 2016 (http://fxborg-labo.hateblo.jp/)           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"


#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_minimum -60
#property indicator_maximum 60

#property indicator_level1 -45.0
#property indicator_level2 45.0
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrRed,clrDimGray,clrAqua
#property indicator_width1  5

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpFast=10;                     // 1st Period
input int InpSlow=252;                    // 2nd Period
input int InpWeight1=60;                     // 1st Weight
input int InpWeight2=50;                     // 2nd Weight


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
      MAIN[i]=calcAggrM(high[i],low[i],close[i],InpFast,InpSlow,InpWeight1,InpWeight2,i,rates_total)-50;
      CLR[i]=(MAIN[i]>=45)?0:(MAIN[i]<=-45)?2:1;
     }
//---   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Series[][4];
int H=0;
int L=1;
int C=2;
int M=3;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcAggrM(double hi,double lo,double cl,int fast,int slow,double weight1,double weight2,int r,int bars)
  {
   if(ArrayRange(Series,0)!=bars) ArrayResize(Series,bars);
   Series[r][H]=hi;
   Series[r][L]=lo;
   Series[r][C]=cl;
   //---
   if(r<=fmax(fast,slow))return EMPTY_VALUE;
   
   //---      
   double fast_cnt=0;
   double slow_cnt=0;
   for(int j=0;j<fast;j++)
   {
		if (Series[r-j][H]< cl)fast_cnt++;
		if (Series[r-j][L]< cl)fast_cnt++;
  		if (Series[r-j][C]< cl)fast_cnt++;
   }
   for(int j=0;j<slow;j++)
   {
		if (Series[r-j][H]< cl)slow_cnt++;
		if (Series[r-j][L]< cl)slow_cnt++;
  		if (Series[r-j][C]< cl)slow_cnt++;
   }
   
	double rank1 = 100 * slow_cnt / (slow * 3 - 1);
	double rank2 = 100 * fast_cnt / (fast * 3 - 1);

	Series[r][M]	= (rank1 * weight2 * 0.01 + rank2 * (100 - weight2) * 0.01);			
	return ((100 - weight1) * 0.01 * Series[r-1][M]) + (weight1 * 0.01 * Series[r][M]);

  }
//+------------------------------------------------------------------+
