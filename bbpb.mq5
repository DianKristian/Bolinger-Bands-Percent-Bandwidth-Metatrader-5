//+------------------------------------------------------------------+
//|                                BolingerBandsPercentBandwidth.mq5 |
//|                                     Copyright 2022,Dian Kristian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <MovingAverages.mqh>

#define BBPB_DEFAULT_PERIOD 20;
#define BBPB_DEFAULT_SHIFT 0;
#define BBPB_DEFAULT_DEVIATION 2.0;

#property copyright "Copyright 2022,Dian Kristian"
#property link      "https://www.mql5.com"
#property description "Bollinger Bands Percent Bandwidth"
#property version   "1.00"
#property indicator_separate_window
#property indicator_level1 0.00
#property indicator_level2 0.20
#property indicator_level3 0.50
#property indicator_level4 0.80
#property indicator_level5 1.00
#property indicator_levelcolor Silver
#property indicator_levelstyle 0
#property indicator_levelwidth 1
#property indicator_type1 DRAW_LINE

#property indicator_color1 DodgerBlue

#property indicator_buffers 5
#property indicator_plots 1

//--- input parameters
input int InpBandsPeriod = BBPB_DEFAULT_PERIOD;       // Period
input int InpBandsShift = BBPB_DEFAULT_SHIFT;         // Shift
input double InpBandsDeviations = BBPB_DEFAULT_DEVIATION;  // Deviation

int bbpbPeriod, bbpbShift, bbpbPlotBegin;
double bbpbDeviation,
       bbpbPercentBandwidth[],
       bbpbMiddleBuffer[],
       bbpbTopBuffer[],
       bbpbBottomBuffer[],
       bbpbStdDevBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   bbpbPeriod = InpBandsPeriod;
   bbpbShift = InpBandsShift;
   bbpbDeviation = InpBandsDeviations;

   if(InpBandsPeriod < 2)
     {
      bbpbPeriod = BBPB_DEFAULT_PERIOD;
      PrintFormat("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.", InpBandsPeriod, bbpbPeriod);
     }

   bbpbPlotBegin = bbpbPeriod - 1;

   if(InpBandsShift < 0)
     {
      bbpbShift = BBPB_DEFAULT_SHIFT;
      PrintFormat("Incorrect value for input variable InpBandsShift=%d. Indicator will use value=%d for calculations.", InpBandsShift, bbpbShift);
     }

   if(InpBandsDeviations <= 0.0)
     {
      bbpbDeviation = BBPB_DEFAULT_DEVIATION;
      PrintFormat("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.", InpBandsDeviations, bbpbDeviation);
     }

   SetIndexBuffer(0, bbpbPercentBandwidth, INDICATOR_DATA);
   SetIndexBuffer(1, bbpbMiddleBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, bbpbTopBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, bbpbBottomBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, bbpbStdDevBuffer, INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME,"Bolinger Bands %B (" + string(bbpbPeriod) + ")");

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, bbpbPeriod);
   PlotIndexSetInteger(0, PLOT_SHIFT, bbpbShift);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
  {
//---
   if(rates_total < bbpbPlotBegin)
     {
      return(0);
     }

   if(bbpbPlotBegin != bbpbPeriod + begin)
     {
      bbpbPlotBegin = bbpbPeriod + begin;
     }

   int pos = 0;
   double _res1, _res2, _res3;

   if(prev_calculated > 1)
     {
      pos = prev_calculated - 1;
     }

   for(int i = pos; i < rates_total && !IsStopped(); i++)
     {
      //--- middle line
      bbpbMiddleBuffer[i] = SimpleMA(i, bbpbPeriod, price);
      //--- calculate and write down StdDev
      bbpbStdDevBuffer[i] = StdDev_Func(i, price, bbpbMiddleBuffer, bbpbPeriod);
      //--- upper line
      bbpbTopBuffer[i] = bbpbMiddleBuffer[i] + bbpbDeviation * bbpbStdDevBuffer[i];
      //--- lower line
      bbpbBottomBuffer[i] = bbpbMiddleBuffer[i] - bbpbDeviation * bbpbStdDevBuffer[i];

      _res1 = price[i] - bbpbBottomBuffer[i];
      _res2 = bbpbTopBuffer[i] - bbpbBottomBuffer[i];
      _res3 = _res1 / _res2;
      bbpbPercentBandwidth[i] = NormalizeDouble(_res3, 2);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double StdDev_Func(const int position,const double &price[],const double &ma_price[],const int period)
  {
   double std_dev=0.0;
//--- calcualte StdDev
   if(position>=period)
     {
      for(int i=0; i<period; i++)
         std_dev+=MathPow(price[position-i]-ma_price[position],2.0);
      std_dev=MathSqrt(std_dev/period);
     }
//--- return calculated value
   return(std_dev);
  }
//+------------------------------------------------------------------+
