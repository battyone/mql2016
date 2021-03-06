//+------------------------------------------------------------------+
//|                                             RSI_Switch_v1_00.mq5 |
//| RSI Switch                                Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 10
#property indicator_plots   6
#property indicator_separate_window

#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_width1 1

#property indicator_type2 DRAW_COLOR_LINE
#property indicator_color2  clrDarkGreen,clrYellow,clrMaroon
#property indicator_width2 6

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrSilver
#property indicator_width3 1
#property indicator_style3 STYLE_DOT

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrSilver
#property indicator_width4 1
#property indicator_style4 STYLE_DOT

#property indicator_type5 DRAW_LINE
#property indicator_color5 clrSilver
#property indicator_width5 1
#property indicator_style5 STYLE_DOT

#property indicator_type6 DRAW_LINE
#property indicator_color6 clrSilver
#property indicator_width6 1
#property indicator_style6 STYLE_DOT

//--- input parameters
input int InpRSIPeriod=10; // RSI Period
input double InpUpper=70;       // Brake Level(Upper)
input double InpLower=30;       // Brake Level(Lower)
input double InpFlatH=55;     // Flat Level(Upper)
input double InpFlatL=45;     // Flat Level(Lower)
input double InpStep=5;     // Step Size
input int InpLookBack=35;  // Look Back

double Alpha=2.0/(1.0+InpRSIPeriod);
double Alpha2=2.0/(1.0+InpLookBack);

// alpha

//---- will be used as indicator buffers
double RSI[];
double SRSI[];
double POS[];
double NEG[];
double CLR[];

double H1[];
double L1[];
double H2[];
double L2[];
double FLAT[];

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
   SetIndexBuffer(i++,H1,INDICATOR_DATA);
   SetIndexBuffer(i++,L1,INDICATOR_DATA);
   SetIndexBuffer(i++,H2,INDICATOR_DATA);
   SetIndexBuffer(i++,L2,INDICATOR_DATA);

   SetIndexBuffer(i++,POS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,NEG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SRSI,INDICATOR_CALCULATIONS);

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
      H1[i]=InpFlatH;
      L1[i]=InpFlatL;
      H2[i]=InpUpper;
      L2[i]=InpLower;
      double diff=close[i]-close[i-1];

      double pos=(diff>0) ?  diff : 0;
      double neg=(diff<0) ? -diff: 0;

      POS[i]=pos * Alpha + POS[i-1] * (1.0 - Alpha);
      NEG[i]=neg * Alpha + NEG[i-1] * (1.0 - Alpha);

      RSI[i]=(NEG[i]!=0.0) ? 100-100/(1.0+POS[i]/NEG[i]):
             (POS[i]!=0.0) ? 100.0 :
             50.0;
      if(i<=begin_pos+1)continue;
      SRSI[i]=RSI[i] *Alpha2+SRSI[i-1]*(1.0-Alpha2);

      if((SRSI[i]-InpStep)>FLAT[i-1]) FLAT[i]=SRSI[i]-InpStep;
      else if((SRSI[i]+InpStep)<FLAT[i-1]) FLAT[i]=SRSI[i]+InpStep;
      else FLAT[i]=FLAT[i-1];

      if(FLAT[i]<=InpFlatH && FLAT[i]>=InpFlatL)
         CLR[i]=1;
      else
        {
         if(SRSI[i]>=50)
           {
            if(RSI[i]>InpUpper)CLR[i]=0;
            else if(RSI[i]<=InpLower)CLR[i]=1;
            else CLR[i]=CLR[i-1];

           }
         else
           {
            if(RSI[i]<InpLower)CLR[i]=2;
            else if(RSI[i]>=InpUpper)CLR[i]=1;
            else CLR[i]=CLR[i-1];
           }
        }

     }
//----    

   return(rates_total);
  }
