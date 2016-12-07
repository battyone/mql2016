//+------------------------------------------------------------------+
//|                                                       SnR_TL.mq5 |
//| SnR_TL                                    Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots   4

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_width2  1

#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  2

#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDodgerBlue
#property indicator_width4  2



#property indicator_type5   DRAW_ZIGZAG
#property indicator_color5  clrBlue
#property indicator_width5  2

int WinNo=ChartWindowFind();

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
input string Settings3="TL Settings";
input int InpTLPeriod1=50;             // TL Period1(min)
input int InpTLPeriod2=200;            // TL Period2(max)
input int InpTLSpan=10;                // TL Span

double wk1[][8];
double wk2[][9];
double HI[];
double LO[];
double ZZUP[];
double ZZDN[];
double BTM[];
double TOP[];
double TOP_BK[];
double BTM_BK[];

double SUP[];
double REG[];
double SUP2[];
double REG2[];
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
   ObjectDeleteByName("SnR_Trend");

   SetIndexBuffer(0,REG,INDICATOR_DATA);
   SetIndexBuffer(1,SUP,INDICATOR_DATA);
   SetIndexBuffer(2,TOP,INDICATOR_DATA);
   SetIndexBuffer(3,BTM,INDICATOR_DATA);
   SetIndexBuffer(4,ZZUP,INDICATOR_DATA);
   SetIndexBuffer(5,ZZDN,INDICATOR_DATA);
   SetIndexBuffer(6,ATR,INDICATOR_DATA);
   SetIndexBuffer(7,LATR,INDICATOR_DATA);
   SetIndexBuffer(8,TOP_BK,INDICATOR_DATA);
   SetIndexBuffer(9,BTM_BK,INDICATOR_DATA);
   SetIndexBuffer(10,HI,INDICATOR_DATA);
   SetIndexBuffer(11,LO,INDICATOR_DATA);

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
      TOP_BK[i]=0;
      BTM_BK[i]=0;
      HI[i]=EMPTY_VALUE;
      LO[i]=EMPTY_VALUE;
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
      //---UP & DN
      TOP_BK[i]=TOP_BK[i-1];
      BTM_BK[i]=BTM_BK[i-1];

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
      double zzsize= InpZZSize*LATR[i];
      int dn_i=0,up_i=0,dir=0;
      calcZZ(dir,up_i,dn_i,ZZUP,ZZDN,close[i],close[i],InpDepth,zzsize,i,rates_total);

      if(i<=InpPeriod)continue;
      double hmax=high[ArrayMaximum(high,i-(InpPeriod-1),InpPeriod)];
      double lmin=low[ArrayMinimum(low,i-(InpPeriod-1),InpPeriod)];

      calcSnR(REG,SUP,high[i],low[i],close[i],hmax,lmin,
              size1,size2,size3,size4,InpPeriod,InpLookBack,i,rates_total);

      if(REG[i]-REG[i-1]>size1)TOP_BK[i]=0;
      if(SUP[i-1]-SUP[i]>size1)BTM_BK[i]=0;
      if(i<=100)continue;
      //---
      //---
      if(dir==0 || up_i==0 || dn_i==0)continue;
      //---
      bool isTop=false;
      bool isBtm=false;
      //---
      if(dir==-1)
        {
         if(TOP_BK[i]!=1)
           {
            int imax=ArrayMaximum(high,dn_i,i-dn_i-1);
            if(high[imax]==REG[i])
              {
               TOP[up_i]=high[up_i];
               TOP_BK[i]=1;
               isTop=true;
              }
           }
        }
      else if(dir==1)
        {
         if(BTM_BK[i]!=1)
           {
            int imin=ArrayMinimum(low,up_i,i-up_i-1);
            if(low[imin]==SUP[i])
              {
               BTM[dn_i]=close[dn_i];
               BTM_BK[i]=1;
               isBtm=true;
              }
           }
        }
      if(fmin(dn_i,up_i)<=InpTLPeriod2)continue;
      if(isBtm) calcTL(high,low,close,time,dn_i);
      if(isTop) calcTL(high,low,close,time,up_i);
     }

//---   
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcTL(const double &hi[],const double &lo[],const double &cl[],const datetime &t[],const int i)
  {
   double fits[][4];
   lm(cl,fits,i,InpTLPeriod1,InpTLPeriod2,InpTLSpan);
   double rslt[][2];
   double stdv[][3];
   optimize(hi,lo,fits,rslt,stdv,i);
   int sz=ArraySize(rslt)/2;
   double min= rslt[sz-1][1];
   int best=sz-1;
   for(int j=sz-1;j>=0;j--)
     {
      double tmp= rslt[j][1];
      if(tmp<min)
        {
         min=tmp;
         best=j;
        }
     }
   for(int j=0;j<sz;j++)
     {
      if(j!=best)
        {
         double n=fits[j][0];
         double a=fits[j][1];
         double b=fits[j][2];
         int x0=i-int(n);
         int x1=i;
         double y0=a+(b*n);
         double y1=a;
         double err=rslt[j][0];
         drawTrend(1,j,clrBlue,x0,y0+err,x1,y1+err,t,STYLE_DOT,1,false);
         drawTrend(2,j,clrBlue,x0,y0-err,x1,y1-err,t,STYLE_DOT,1,false);
        }
     }
   int j=best;
     {
      double n=fits[j][0];
      double a=fits[j][1];
      double b=fits[j][2];
      int x0=i-int(n);
      int x1=i;
      double y0=a+(b*n);
      double y1=a;
      double err=rslt[j][0];
      drawTrend(1,j,clrGold,x0,y0+err,x1,y1+err,t,STYLE_SOLID,1,true);
      drawTrend(2,j,clrGold,x0,y0-err,x1,y1-err,t,STYLE_SOLID,1,true);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void optimize(const double &hi[],const double &lo[],const double &fits[][4],double &rslt[][2],double &stdv[][3],int x0)
  {
   int sz=ArraySize(fits);
   if(sz<1)return;
   sz/=4;
   int max=(int)fits[sz-1][0];
//---
   ArrayResize(rslt,sz);
   ArrayInitialize(rslt,0.0);
   ArrayResize(stdv,sz);
   ArrayInitialize(stdv,0.0);
//---   
   for(int x=0;x<=max;x++)
     {
      for(int i=0;i<sz;i++)
        {
         if(x<=fits[i][0])
           {
            //---
            double a=fits[i][1];
            double b=fits[i][2];
            double my=(x*b+a);
            //---
            bool isH = (fabs(my-hi[x0-x])>=fabs(my-lo[x0-x]));
            double y =isH ? hi[x0-x]:lo[x0-x];
            double diff= y-my;
            double err2=fabs(diff);
            //---
            if(err2>rslt[i][0])rslt[i][0]=err2;
            rslt[i][1]+=err2;
            
        
           }
        }
     }
//---
   for(int i=0;i<sz;i++)
     {
      double n=(fits[i][0]+1.0);
      rslt[i][1]=rslt[i][1]/n;

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void lm(const double &src[],double &fits[][4],int x0,int min,int max,int span)
  {
   double Xsum=0.0;
   double Ysum=0.0;
   double XYsum=0.0;
   double X2sum=0.0;
   double Y2sum=0.0;

   int sz=0;
   for(double x=0;x<max;x++)
     {
      double y=src[x0-(int)x];
      XYsum+=x*y;
      Xsum+=x;
      Ysum+=y;
      X2sum+=x*x;
      Y2sum+=y*y;
      if(x+1.0<min)continue;
      double n=(x+1.0);
      if((int(n)%span)==0)
        {
         int rsv = 1+(max-min)/span;
         ArrayResize(fits,sz,rsv);
         double div=(n*X2sum-Xsum*Xsum);
         if(div!=0)
           {
            
            double b=(n*XYsum-Xsum*Ysum)/div; //slope
            double a=(X2sum*Ysum-XYsum*Xsum)/div; //intercept
            double X22=Xsum*Xsum;
            double Y22=Ysum*Ysum;
            double dv=sqrt((n*X2sum-X22)*(n*Y2sum-Y22));
            double r =(dv==0)? 0:(n*XYsum-Xsum*Ysum)/dv;
            ArrayResize(fits,sz+1,rsv);
            fits[sz][0]=x;
            fits[sz][1]=a;
            fits[sz][2]=b;
            fits[sz][3]=r*r;
            sz++;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcZZ(int &dir,int &up_i,int &dn_i,double &zup[],double &zdn[],double h0,double l0,int depth,double size,int r,int bars)
  {
   int DIR=0;
   int H=1;
   int L=2;
   int UP=3;
   int DN=4;
   int iUP=5;
   int iDN=6;
   int iUP2=7;
   int iDN2=8;

   if(ArrayRange(wk2,0)!=bars) ArrayResize(wk2,bars);
   wk2[r][H]=h0;
   wk2[r][L]=l0;
   if(r<2)return;
   if(r==2)
     {
      wk2[r][DIR]=1;
      wk2[r][UP]=h0;
      wk2[r][iUP]=r;
      return;
     }
   wk2[r][DIR] =wk2[r-1][DIR];
   wk2[r][UP]  =wk2[r-1][UP];
   wk2[r][iUP] =wk2[r-1][iUP];
   wk2[r][DN]  =wk2[r-1][DN];
   wk2[r][iDN] =wk2[r-1][iDN];
   wk2[r][iUP2] =wk2[r-1][iUP2];
   wk2[r][iDN2] =wk2[r-1][iDN2];

   if(wk2[r][DIR]==1.0)
     {
      if(h0>wk2[r][UP])
        {
         wk2[r][UP]=h0;
         wk2[r][iUP]=r;
        }

      if(r-wk2[r][iUP]>=depth && wk2[r][UP]-h0>size)
        {
         int iup=(int)wk2[r][iUP];
         zup[iup]=wk2[r][UP];
         wk2[r][iUP2]=iup;
         wk2[r][DN]=l0;
         wk2[r][iDN]=r;
         wk2[r][DIR]=-1.0;
        }
     }
   else if(wk2[r][DIR]==-1.0)
     {
      if(l0<wk2[r][DN])
        {
         wk2[r][DN]=l0;
         wk2[r][iDN]=r;
        }
      if(r-wk2[r][iDN]>=depth && l0-wk2[r][DN]>size)
        {
         int idn=(int)wk2[r][iDN];
         zdn[idn]=wk2[r][DN];
         wk2[r][iDN2]=idn;
         wk2[r][UP]=l0;
         wk2[r][iUP]=r;
         wk2[r][DIR]=1.0;
        }
     }
   dir=(int)wk2[r][DIR];
   up_i=(int)wk2[r][iUP2];
   dn_i=(int)wk2[r][iDN2];
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
void drawTrend(int no1,int no2,
               const color clr,const int x0,const double y0,const int x1,const double y1,
               const datetime &time[],const ENUM_LINE_STYLE style,const int width,const bool isRay)
  {

   if(-1<ObjectFind(0,StringFormat("SnR_%d_%d",no1,no2)))
     {
      ObjectMove(0,StringFormat("SnR_%d_%d",no1,no2),0,time[x0],y0);
      ObjectMove(0,StringFormat("SnR_%d_%d",no1,no2),1,time[x1],y1);
     }
   else
     {
      ObjectCreate(0,StringFormat("SnR_%d_%d",no1,no2),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
      ObjectSetInteger(0,StringFormat("SnR_%d_%d",no1,no2),OBJPROP_COLOR,clr);
      ObjectSetInteger(0,StringFormat("SnR_%d_%d",no1,no2),OBJPROP_STYLE,style);
      ObjectSetInteger(0,StringFormat("SnR_%d_%d",no1,no2),OBJPROP_WIDTH,width);
      ObjectSetInteger(0,StringFormat("SnR_%d_%d",no1,no2),OBJPROP_RAY_RIGHT,isRay);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByName(string prefix)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         ObjectDelete(0,objName);
        }
     }
  }

//+------------------------------------------------------------------+
