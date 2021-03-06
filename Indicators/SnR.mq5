//+------------------------------------------------------------------+
//|                                                          SnR.mq5 |
//| SnR                                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_width2  1

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double InpSize1=0.4;             // Damashi Size
input double InpSize2=1.0;             // Modoshi Size
input double InpSize3=1.8;             // Minimum Range Size
input double InpSize4=6.0;             // Maximum Range Size
input int InpPeriod=30;                // Channel Period
input int InpLookBack=120;             // LookBack
double SUP[];
double REG[];
double ATR[];
int AtrPeriod=50;
double AtrAlpha=2.0/(AtrPeriod+1.0);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,REG,INDICATOR_DATA);
   SetIndexBuffer(1,SUP,INDICATOR_DATA);
   SetIndexBuffer(2,ATR,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_ARROW,158);
   PlotIndexSetInteger(1,PLOT_ARROW,158);
   
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
      SUP[i]=EMPTY_VALUE;
      REG[i]=EMPTY_VALUE;
      ATR[i]=EMPTY_VALUE;
      if(i==0)continue;
      double atr0 = MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      double atr1 = (ATR[i-1]==EMPTY_VALUE) ? atr0 : ATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      ATR[i]=AtrAlpha*atr0+(1-AtrAlpha)*atr1;

      if(i<=InpPeriod)continue;
      double hmax=high[ArrayMaximum(high,i-(InpPeriod-1),InpPeriod)];
      double lmin=low[ArrayMinimum(low,i-(InpPeriod-1),InpPeriod)];
      double size1 = InpSize1*ATR[i];
      double size2 = InpSize2*ATR[i];
      double size3 = InpSize3*ATR[i];
      double size4 = InpSize4*ATR[i];


      calcSnR(REG,SUP,high[i],low[i],close[i],hmax,lmin,
              size1,size2,size3,size4,InpPeriod,InpLookBack,i,rates_total);
     }
//---   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double wk[][8];
int H=0;
int L=1;
int C=2;
int UP=3;
int DN=4;
int UP2=5;
int DN2=6;
int FLG=7;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcSnR(double &reg[],double &sup[],double h0,double l0,double c0,double max0,double min0,
             double size1,double size2,double size3,double size4,int period,int lookback,int r,int bars)
  {
  
   if(ArrayRange(wk,0)!=bars) ArrayResize(wk,bars);
   wk[r][H]=h0;
   wk[r][L]=l0;
   wk[r][C]=c0;
   if(r<=period+1)
   { 
      wk[r][FLG]=0.0;
      wk[r][UP ]=max0;
      wk[r][DN ]=min0;
      wk[r][UP2]=max0;
      wk[r][DN2]=min0;
   }
   else
   {
      wk[r][FLG]=wk[r-1][FLG];
      wk[r][UP ]=wk[r-1][UP ];
      wk[r][DN ]=wk[r-1][DN ];
      wk[r][UP2]=wk[r-1][UP2];
      wk[r][DN2]=wk[r-1][DN2];
   }
   int back=fmin(lookback,r-1);
   double c1=wk[r-1][C];
   double flg=wk[r][FLG];
   double up =  wk[r][UP];
   double dn =  wk[r][DN];
   double up2 =  wk[r][UP2];
   double dn2 =  wk[r][DN2];
//+-------------------------------------------------+
//| update range 
//+-------------------------------------------------+
   if(h0 > up2)               { wk[r][UP2] = h0;}
   if(l0 < dn2)               { wk[r][DN2] = l0;}
//+-------------------------------------------------+
//| expand
//+-------------------------------------------------+
   if(flg==-1.0 && c0>dn2+size2)
     {
      wk[r][FLG]=0.0;
      if(up-dn2>size4)
        {
         if(dn-dn2>size3 && dn>fmax(h0,c1))
           {
            wk[r][UP]=dn;
            wk[r][UP2]=dn;
           }
         else
           {
            double y=h0;

            for(int j=0;j<back;j++)
              {
               if(wk[r-j][H]>y) y=wk[r-j][H];
               if(up<y)break;
               if(y-dn2>size2 && wk[r-j][H]<y-size2)
                 {
                  wk[r][UP]=y;
                  wk[r][UP2]=y;
                  break;
                 }
              }
           }
        }
      wk[r][DN]=dn2;

     }
   if(flg==1.0 && c0<up2-size2)
     {
      wk[r][FLG]=0.0;
      if(up2-dn>size4)
        {

         if(up2-up>size3 && up<fmin(l0,c1))
          {
          wk[r][DN] =up; 
          wk[r][DN2]=up;
          }
         else
           {
            double y=l0;
            for(int j=0;j<back;j++)
              {
               if(wk[r-j][L]<y) y=wk[r-j][L];
               if(dn>y)break;
               if(up2-y>size2 && wk[r-j][L]>y+size2)
                 {
                   wk[r][DN]=y; 
                   wk[r][DN2]=y;
                  break;
                 }
              }
           }
        }
      wk[r][UP]=up2;

     }

   if(up-dn>(max0-min0)*2.0)
     {
      wk[r][UP]=max0;
      wk[r][UP2]=max0;
      wk[r][DN]=min0; 
      wk[r][DN2]=min0;
     }

   if(h0>up+size1) { wk[r][FLG] = 1.0;  }
   if(l0<dn-size1) { wk[r][FLG] =-1.0;  }

   reg[r]=up;
   sup[r]=dn;

  }
//+------------------------------------------------------------------+
