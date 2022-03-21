//+------------------------------------------------------------------+
//|                                          RangeExpansionIndex.mq4 |
//|                             Copyright © 2010-2022, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010-2022, EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Range-Expansion-Index/"
#property version   "1.01"
#property strict

#property description "Calculates Tom DeMark's Range Expansion Index."
#property description "Going above 60 and then dropping below 60 signals price weakness."
#property description "Going below -60 and the rising above -60 signals price strength."
#property description "For more info see The New Science of Technical Analysis."

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 clrBlue
#property indicator_type1  DRAW_LINE
#property indicator_level1 60
#property indicator_level2 -60

enum enum_candle_to_check
{
    Current,
    Previous
};

input int REI_Period = 8; // REI Period
input bool EnableNativeAlerts = false;
input bool EnableEmailAlerts = false;
input bool EnablePushAlerts = false;
input enum_candle_to_check TriggerCandle = Previous;

// Buffers:
double REI[];

// Global variables:
datetime LastAlertTime = D'01.01.1970';

void OnInit()
{
    IndicatorShortName("REI(" + IntegerToString(REI_Period) + ")");
    IndicatorSetInteger(INDICATOR_DIGITS, 2);
    SetIndexBuffer(0, REI);
    SetIndexDrawBegin(0, REI_Period + 8);
}

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
    // Too few bars to do anything.
    if (Bars <= 8 + REI_Period) return 0;

    int counted_bars = IndicatorCounted();
    if (counted_bars > 0) counted_bars--;
    int limit = Bars - counted_bars;
    if (limit > Bars - (8 + REI_Period) - 1) limit = Bars - (8 + REI_Period) - 1;

    for (int i = 0; i <= limit; i++)
    {
        double SubValueSum = 0;
        double AbsDailyValueSum = 0;
        for (int j = 0; j < REI_Period; j++)
        {
            SubValueSum += SubValue(i + j);
            AbsDailyValueSum += AbsDailyValue(i + j);
        }
        if (AbsDailyValueSum != 0) REI[i] = SubValueSum / AbsDailyValueSum * 100;
        else REI[i] = 0;
    }

    // Alerts
    if (((TriggerCandle > 0) && (Time[0] > LastAlertTime)) || (TriggerCandle == 0))
    {
        string Text;
        // Level 60
        if ((REI[TriggerCandle] < 60) && (REI[TriggerCandle + 1] >= 60))
        {
            Text = "REI: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Crossed 60 from above.";
            if (EnableNativeAlerts) Alert(Text);
            if (EnableEmailAlerts) SendMail("REI Alert", Text);
            if (EnablePushAlerts) SendNotification(Text);
            LastAlertTime = Time[0];
        }
        // Level -60
        if ((REI[TriggerCandle] > -60) && (REI[TriggerCandle + 1] <= -60))
        {
            Text = "REI: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Crossed -60 from below.";
            if (EnableNativeAlerts) Alert(Text);
            if (EnableEmailAlerts) SendMail("REI Alert", Text);
            if (EnablePushAlerts) SendNotification(Text);
            LastAlertTime = Time[0];
        }
    }

    return rates_total;
}

//+------------------------------------------------------------------+
//| Calculate the Conditional Value                                  |
//+------------------------------------------------------------------+
double SubValue(int i)
{
    double diff1 = High[i] - High[i + 2];
    double diff2 = Low[i] - Low[i + 2];
    int num_zero1, num_zero2;

    if ((High[i + 2] < Close[i + 7]) && (High[i + 2] < Close[i + 8]) && (High[i] < High[i + 5]) && (High[i] < High[i + 6]))
        num_zero1 = 0;
    else
        num_zero1 = 1;

    if ((Low[i + 2] > Close[i + 7]) && (Low[i + 2] > Close[i + 8]) && (Low[i] > Low[i + 5]) && (Low[i] > Low[i + 6]))
        num_zero2 = 0;
    else
        num_zero2 = 1;

    return (num_zero1 * num_zero2 * (diff1 + diff2));
}

//+------------------------------------------------------------------+
//| Calculate the Absolute Value                                     |
//+------------------------------------------------------------------+
double AbsDailyValue(int i = 0)
{
    double diff1 = MathAbs(High[i] - High[i + 2]);
    double diff2 = MathAbs(Low[i] - Low[i + 2]);

    return (diff1 + diff2);
}
//+------------------------------------------------------------------+