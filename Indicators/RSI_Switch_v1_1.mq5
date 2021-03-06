//+------------------------------------------------------------------+
//|                                              RSI_Switch_v1_1.mq5 |
//| RSI Switch                                Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"

#property indicator_buffers 15
#property indicator_plots   6
#property indicator_separate_window

#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_width1 1

#property indicator_type2 DRAW_COLOR_LINE
#property indicator_color2 clrDarkGreen,clrYellow,clrMaroon
#property indicator_width2 3

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrSilver
#property indicator_width3 1
#property indicator_style3 STYLE_DOT

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrSilver
#property indicator_width4 1
#property indicator_style4 STYLE_DOT


//--- input parameters
input int InpRSIPeriod=14; // RSI Period(10 - 25)
input int InpAvgPeriod=50;  // Avg Period(30 - 60)
input double InpLevel=20;       // Level (15 - 25)
double InpStep=2.5;     // Step Size

double Size1=1.0;
double Size2=1.25;
double Size3=1.5;
double Size4=1.75;
double Size5=2.0;
double Size6=2.25;


double Alpha=2.0/(1.0+InpRSIPeriod);
double Alpha2=2.0/(1.0+InpAvgPeriod);

// alpha

//---- will be used as indicator buffers
double RSI[];
double SRSI[];
double POS[];
double NEG[];
double CLR[];

double H2[];
double L2[];
double FLAT[];
double TREND[];
double STEP1[];
double STEP2[];
double STEP3[];
double STEP4[];
double STEP5[];
double STEP6[];

int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=2;
//--- indicator buffers mapping
   int i=0;
//--- indicator buffers
   SetIndexBuffer(i++,RSI,INDICATOR_DATA);
   SetIndexBuffer(i++,FLAT,INDICATOR_DATA);
   SetIndexBuffer(i++,CLR,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,H2,INDICATOR_DATA);
   SetIndexBuffer(i++,L2,INDICATOR_DATA);

   SetIndexBuffer(i++,POS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,NEG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SRSI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,STEP1,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP2,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP3,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP4,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP5,INDICATOR_DATA);
   SetIndexBuffer(i++,STEP6,INDICATOR_DATA);
   SetIndexBuffer(i++,TREND,INDICATOR_DATA);

//---
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---
   int i,first;
   if(rates_total<=min_rates_total)
      return(0);
//---

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      RSI[i]=50;
      POS[i]=0;
      NEG[i]=0;
      H2[i]=50+InpLevel;
      L2[i]=50-InpLevel;

      double diff=close[i]-close[i-1];

      double pos=(diff>0) ?  diff : 0;
      double neg=(diff<0) ? -diff: 0;

      POS[i]=pos * Alpha + POS[i-1] * (1.0 - Alpha);
      NEG[i]=neg * Alpha + NEG[i-1] * (1.0 - Alpha);

      RSI[i]=(NEG[i]!=0.0) ? 100-100/(1.0+POS[i]/NEG[i]):
             (POS[i]!=0.0) ? 100.0 :
             50.0;
      if(i<=begin_pos+1)continue;
      SRSI[i]=RSI[i]*Alpha2+SRSI[i-1]*(1.0-Alpha2);

      double price=SRSI[i];
      //--- 
      iStepMa(STEP1,price,Size1*InpStep,i);
      iStepMa(STEP2,price,Size2*InpStep,i);
      iStepMa(STEP3,price,Size3*InpStep,i);
      iStepMa(STEP4,price,Size4*InpStep,i);
      iStepMa(STEP5,price,Size5*InpStep,i);
      iStepMa(STEP6,price,Size6*InpStep,i);
      FLAT[i]=(STEP1[i]+STEP2[i]+STEP3[i]+STEP4[i]+STEP5[i]+STEP6[i])/6;

      TREND[i]=(FLAT[i]>FLAT[i-1]) ? 1:
               (FLAT[i]<FLAT[i-1]) ? -1:
               TREND[i-1];

      if(CLR[i-1]!=0 && FLAT[i]>50 && TREND[i]==1 && RSI[i]>H2[i])
        {
         CLR[i]=0;
        }
      else if(CLR[i-1]!=2 && FLAT[i]<50 && TREND[i]==-1 && RSI[i]<L2[i])
        {
         CLR[i]=2;
        }
      else if(CLR[i-1]==0 && RSI[i]<=L2[i])
        {
         CLR[i]=1;
        }
      else if(CLR[i-1]==2 && RSI[i]>=H2[i])
        {
         CLR[i]=1;
        }
      else
        {
         CLR[i]=CLR[i-1];
        }

     }
//----    

   return(rates_total);
  }
//+----------------------------------------------------+
//|                                                    |
//+----------------------------------------------------+
void iStepMa(double &step[],const double price,const double size,const int i)
  {
   if((price-size)>step[i-1]) step[i]=price-size;
   else if((price+size)<step[i-1]) step[i]=price+size;
   else step[i]=step[i-1];

  }
//+------------------------------------------------------------------+
