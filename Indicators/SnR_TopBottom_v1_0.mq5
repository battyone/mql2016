//+------------------------------------------------------------------+
//|                                                SnR_TopBottom.mq5 |
//| SnR_TopBottom                             Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   5

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_width2  1

#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  3

#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDodgerBlue
#property indicator_width4  3

#property indicator_type5   DRAW_ZIGZAG
#property indicator_color5  clrBlue
#property indicator_width5  2
//#property indicator_style5  STYLE_DOT


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input string Settings1="SnR Settings"; 
input double InpSize1=0.4;             // Damashi Size
input double InpSize2=1.0;             // Modoshi Size
input double InpSize3=1.8;             // Minimum Range Size
input double InpSize4=6.0;             // Maximum Range Size
input int InpPeriod=30;                // Channel Period
input int InpLookBack=120;             // LookBack
input string Settings2="ZigZag Settings"; 
input int InpDepth=3;                  // Depth
input double InpZZSize=1.0;            // ZigZag Size 
double ZZUP[];
double ZZDN[];
double BTM[];
double TOP[];

double SUP[];
double REG[];
double ATR[];
double LATR[];
int AtrPeriod=36;
double AtrAlpha=2.0/(AtrPeriod+1.0);
int LAtrPeriod=50;
double LAtrAlpha=2.0/(AtrPeriod+1.0);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,REG,INDICATOR_DATA);
   SetIndexBuffer(1,SUP,INDICATOR_DATA);
   SetIndexBuffer(2,TOP,INDICATOR_DATA);
   SetIndexBuffer(3,BTM,INDICATOR_DATA);
   SetIndexBuffer(4,ZZUP,INDICATOR_DATA);
   SetIndexBuffer(5,ZZDN,INDICATOR_DATA);
   SetIndexBuffer(6,ATR,INDICATOR_DATA);
   SetIndexBuffer(7,LATR,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_ARROW,158);
   PlotIndexSetInteger(1,PLOT_ARROW,158);
   PlotIndexSetInteger(2,PLOT_ARROW,217);
   PlotIndexSetInteger(3,PLOT_ARROW,218);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-20);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,20);

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
      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      ZZUP[i]=EMPTY_VALUE;
      ZZDN[i]=EMPTY_VALUE;
      SUP[i]=EMPTY_VALUE;
      REG[i]=EMPTY_VALUE;
      ATR[i]=EMPTY_VALUE;
      LATR[i]=EMPTY_VALUE;
      if(i==rates_total-1)continue;
      if(i==0)continue;
      //----
      double atr0 = MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      double atr1 = (ATR[i-1]==EMPTY_VALUE) ? atr0 : ATR[i-1];
      ATR[i]=AtrAlpha*atr0+(1-AtrAlpha)*atr1;
      //----      
      double latr0 = atr0;
      double latr1 = (LATR[i-1]==EMPTY_VALUE) ? latr0 : LATR[i-1];
      latr0=fmax(latr1*0.667,fmin(latr0,latr1*1.333));
      LATR[i]=LAtrAlpha*latr0+(1-LAtrAlpha)*latr1;
      //----
      double size1 = InpSize1*ATR[i];
      double size2 = InpSize2*ATR[i];
      double size3 = InpSize3*LATR[i];
      double size4 = InpSize4*LATR[i];
      double zzsize = InpZZSize*LATR[i];
      int dn_i=0;
      int up_i=0;
      int dn2_i=0;
      int up2_i=0;
      int dir = 0;
      calcZZ(dir,up_i,dn_i,up2_i,dn2_i,ZZUP,ZZDN,close[i],InpDepth,zzsize,i,rates_total);

      if(i<=InpPeriod)continue;
      double hmax=high[ArrayMaximum(high,i-(InpPeriod-1),InpPeriod)];
      double lmin=low[ArrayMinimum(low,i-(InpPeriod-1),InpPeriod)];


      calcSnR(REG,SUP,high[i],low[i],close[i],hmax,lmin,
              size1,size2,size3,size4,InpPeriod,InpLookBack,i,rates_total);
      if(dir!=0 && dn_i> 0 && up_i>0 && dn2_i> 0 && up2_i>0)
      {
      
         if(dir==-1  && REG[i]>REG[up_i-InpDepth]) // top?
         {
                  TOP[up_i]=high[up_i];
                 
         }
         else if(dir==1 && SUP[i]<SUP[dn_i-InpDepth]  )
         {
                  BTM[dn_i]=low[dn_i];
         }
      }       
     }
//---   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double wk1[][8];
double wk2[][10];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcZZ(int &dir, int &up_i,int &dn_i,int &up2_i,int &dn2_i,double &zup[],double &zdn[],double c0,int depth,double size,int r,int bars)
  {
   int DIR=0;
   int C=1;
   int UP=2;
   int DN=3;
   int iUP=4;
   int iDN=5;
   int iUP2=6;
   int iDN2=7;
   int iUP3=8;
   int iDN3=9;

   if(ArrayRange(wk2,0)!=bars) ArrayResize(wk2,bars);
   wk2[r][C]=c0;
   if(r<2)return;
   if(r==2)
     {
         wk2[r][DIR]=1;
         wk2[r][UP]=c0;
         wk2[r][iUP]=r;
         wk2[r][iUP2]=r;
      return;
     }
   wk2[r][DIR] =wk2[r-1][DIR];
   wk2[r][UP]  =wk2[r-1][UP];
   wk2[r][iUP] =wk2[r-1][iUP];
   wk2[r][DN]  =wk2[r-1][DN];
   wk2[r][iDN] =wk2[r-1][iDN];
   wk2[r][iUP2] =wk2[r-1][iUP2];
   wk2[r][iDN2] =wk2[r-1][iDN2];
   wk2[r][iUP3] =wk2[r-1][iUP3];
   wk2[r][iDN3] =wk2[r-1][iDN3];
   if(wk2[r][DIR]==1.0)
     {
      if(c0>wk2[r][UP])
        {
         wk2[r][UP]=c0;
         wk2[r][iUP]=r;
        }

      if(r-wk2[r][iUP]>=depth && wk2[r][UP]-c0>size)
        {
         int ii=(int)wk2[r][iUP];
         zup[ii]=wk2[r][UP];
         wk2[r][iUP3]=wk2[r][iUP2];
         wk2[r][iUP2]=wk2[r][iUP];
         
         wk2[r][DN]=c0;
         wk2[r][iDN]=r;
         wk2[r][DIR]=-1.0;
        }
     }
   else if(wk2[r][DIR]==-1.0)
     {
      if(c0<wk2[r][DN])
        {
         wk2[r][DN]=c0;
         wk2[r][iDN]=r;
        }
      if(r-wk2[r][iDN]>=depth && c0-wk2[r][DN]>size)
        {
         int ii=(int)wk2[r][iDN];
         zdn[ii]=wk2[r][DN];
         wk2[r][iDN3]=wk2[r][iDN2];         
         wk2[r][iDN2]=wk2[r][iDN];         
         wk2[r][UP]=c0;
         wk2[r][iUP]=r;
         wk2[r][DIR]=1.0;
        }
     }
     dir=(int)wk2[r][DIR];
     up_i=(int)wk2[r][iUP2];
     dn_i=(int)wk2[r][iDN2];
     up2_i=(int)wk2[r][iUP3];
     dn2_i=(int)wk2[r][iDN3];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcSnR(double &reg[],double &sup[],double h0,double l0,double c0,double max0,double min0,
             double size1,double size2,double size3,double size4,int period,int lookback,int r,int bars)
  {
   int H=0;
   int L=1;
   int C=2;
   int UP=3;
   int DN=4;
   int UP2=5;
   int DN2=6;
   int FLG=7;

   if(ArrayRange(wk1,0)!=bars) ArrayResize(wk1,bars);
   wk1[r][H]=h0;
   wk1[r][L]=l0;
   wk1[r][C]=c0;
   if(r<=period+1)
     {
      wk1[r][FLG]=0.0;
      wk1[r][UP ]=max0;
      wk1[r][DN ]=min0;
      wk1[r][UP2]=max0;
      wk1[r][DN2]=min0;
     }
   else
     {
      wk1[r][FLG]=wk1[r-1][FLG];
      wk1[r][UP ]=wk1[r-1][UP ];
      wk1[r][DN ]=wk1[r-1][DN ];
      wk1[r][UP2]=wk1[r-1][UP2];
      wk1[r][DN2]=wk1[r-1][DN2];
     }
   int back=fmin(lookback,r-1);
   double c1=wk1[r-1][C];
   double flg=wk1[r][FLG];
   double up =  wk1[r][UP];
   double dn =  wk1[r][DN];
   double up2 =  wk1[r][UP2];
   double dn2 =  wk1[r][DN2];
//+-------------------------------------------------+
//| update range 
//+-------------------------------------------------+
   if(h0 > up2)               { wk1[r][UP2] = h0;}
   if(l0 < dn2)               { wk1[r][DN2] = l0;}
//+-------------------------------------------------+
//| expand
//+-------------------------------------------------+
   if(flg==-1.0 && c0>dn2+size2)
     {
      wk1[r][FLG]=0.0;
      if(up-dn2>size4)
        {
         if(dn-dn2>size3 && dn>fmax(h0,c1))
           {
            wk1[r][UP]=dn;
            wk1[r][UP2]=dn;
           }
         else
           {
            double y=h0;

            for(int j=0;j<back;j++)
              {
               if(wk1[r-j][H]>y) y=wk1[r-j][H];
               if(up<y)break;
               if(y-dn2>size2 && wk1[r-j][H]<y-size2)
                 {
                  wk1[r][UP]=y;
                  wk1[r][UP2]=y;
                  break;
                 }
              }
           }
        }
      wk1[r][DN]=dn2;

     }
   if(flg==1.0 && c0<up2-size2)
     {
      wk1[r][FLG]=0.0;
      if(up2-dn>size4)
        {

         if(up2-up>size3 && up<fmin(l0,c1))
           {
            wk1[r][DN] =up;
            wk1[r][DN2]=up;
           }
         else
           {
            double y=l0;
            for(int j=0;j<back;j++)
              {
               if(wk1[r-j][L]<y) y=wk1[r-j][L];
               if(dn>y)break;
               if(up2-y>size2 && wk1[r-j][L]>y+size2)
                 {
                  wk1[r][DN]=y;
                  wk1[r][DN2]=y;
                  break;
                 }
              }
           }
        }
      wk1[r][UP]=up2;

     }

   if(up-dn>(max0-min0)*2.0)
     {
      wk1[r][UP]=max0;
      wk1[r][UP2]=max0;
      wk1[r][DN]=min0;
      wk1[r][DN2]=min0;
     }

   if(h0>up+size1) { wk1[r][FLG] = 1.0;  }
   if(l0<dn-size1) { wk1[r][FLG] =-1.0;  }

   reg[r]=up;
   sup[r]=dn;

  }
//+------------------------------------------------------------------+
