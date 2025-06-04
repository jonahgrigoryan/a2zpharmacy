#property copyright ""
#property link      "https://"
#property version   "1.00"
#property strict

//--- Expert Advisor for EUR/USD
// Implements a multi–time-frame breakout strategy described in eurusd.md
// Timeframes:
//   • Trend filter  : H1 200-period EMA
//   • Entry/Signals : M15 breakout of last N bars with RSI mean-reversion filter
// Indicators:
//   • ATR(14) on M15 for adaptive SL/TP (1.2× ATR stop, 2× risk TP)
//   • RSI(14) on M15 must be inside neutral zone (40–60) *before* breakout
// Risk management:
//   • 1 % equity risk per trade (dynamic volume sizing)
//   • Only one open position at a time
//   • Optional daily loss cut-off
//   • Optional trading hours filter

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//|   Input parameters                                              |
//+------------------------------------------------------------------+
input double InpRiskPercent        = 1.5;     // Risk per trade (% equity)
input double InpStopATRMultiplier  = 2.0;     // Stop = ATR × factor (default)
input bool   InpUseTakeProfit      = true;    // Use fixed take-profit
input double InpTP_RR              = 2.5;     // Reward/Risk ratio (ignored if TP disabled)
input int    InpLookbackBars       = 12;      // Breakout look-back bars (M15)
input int    InpRSIPeriod          = 14;      // RSI period (M15)
input double InpRSILower           = 40.0;    // Lower RSI bound (neutral)
input double InpRSIUpper           = 60.0;    // Upper RSI bound (neutral)
input bool   InpUseRSIFilter       = true;    // Enable RSI neutral-zone filter
input double InpBreakoutBufferPips = 2.0;     // Extra buffer beyond high/low (pips)
input double InpBreakoutBufferATR  = 0.35;    // Or ATR × factor (increased from 0.2)
input double InpMinATRPips         = 5.0;     // Minimum ATR in pips to allow trading
input double InpMaxSpreadPips      = 2.0;     // Maximum spread in pips to allow trading

// Short-term momentum filter on M15
input bool   InpUseM15ADXFilter    = true;    // Require ADX on M15
input int    InpM15ADXPeriod       = 14;
input double InpM15ADXMin          = 20.0;    // Reduced from 25.0
input int    InpTrendMAPeriod      = 200;     // EMA period for H1 trend filter
input int    InpEMASlopeBars       = 10;      // Bars back to measure EMA slope (H1)
input double InpEMASlopeMinPips    = 7.0;     // Minimum EMA slope (reduced from 10.0)
input bool   InpUseADXFilter       = true;    // Require ADX trending filter
input int    InpADXPeriod          = 14;      // ADX period (H1)
input double InpADXMin             = 25.0;    // Reduced from 30.0
input bool   InpUseDirectionalDI   = true;    // Require DI+>DI- for longs etc.

// Trailing stop parameters
input bool   InpUseTrailing        = true;    // Enable ATR-based trailing
input double InpTrailATRMultiplier = 1.0;     // Trail distance = ATR × factor
input double InpTrailStartRR       = 2.0;     // Begin trailing after price >= RR × SL (increased from 1.8)
input double InpBreakevenATR       = 1.0;     // Move SL to BE at +ATR×factor

// Partial-close parameters
input bool   InpUsePartialClose   = true;     // Enable partial profit taking
input double InpPartialRR         = 1.0;      // RR level to trigger partial (e.g. 1.0 = 1× risk)
input double InpPartialPercent    = 25.0;     // Percent of volume to close at partial (0-100)
input bool   InpUseTradeHours      = true;    // Restrict trading hours
input int    InpTradeStartHour     = 6;       // Hour to start trading (server time)
input int    InpTradeEndHour       = 23;      // Hour to stop  trading (server time)
input bool   InpUseDailyLossCut    = true;    // Enable daily loss cut-off
input double InpDailyLossPct       = 3.0;     // Max daily loss (% equity)

// Volatility filter (skip low-volatility breakout attempts)
input bool   InpUseATRVolFilter    = true;    // Enable ATR vs average filter
input int    InpATRVolLookback     = 96;      // How many M15 bars to average (~1 month = 96 per day)
input double InpATRVolFactorMin    = 1.0;     // Require ATR >= factor × average ATR

// Weekday trading filter (allows finer control than hours only)
input bool   InpTradeMonday        = true;    // Changed from false - will add time check
input bool   InpTradeTuesday       = true;
input bool   InpTradeWednesday     = true;
input bool   InpTradeThursday      = true;
input bool   InpTradeFriday        = true;    // Changed from false - will add time check

// Time-stop: close positions that stagnate too long
input bool   InpUseTimeStop        = true;    // Enable time-based exit
input int    InpMaxHoldingBars     = 32;      // Max bars to keep a trade (reduced from 64) ≈ 8 h
input double InpTimeStopProfitRR   = 0.3;     // Require at least this RR, else close

// Loss-streak guard: pause trading after consecutive losing trades
input bool   InpUseLossStreakGuard = true;
input int    InpMaxLossStreak      = 5;       // e.g. 5 consecutive losses
input int    InpCooldownHours      = 24;      // pause trading for this many hours
input int    InpTradeCooldownBars  = 4;       // Minimum bars between trades (M15)

// Evaluation-protection parameters (FundingPips style)
input bool   InpUseGlobalDDGuard   = true;    // Stop new trades if equity DD from peak exceeds limit
input double InpMaxTotalDDPct      = 9.5;     // Maximum total drawdown allowed (%)
input bool   InpScaleRiskOnDD      = true;    // Dynamically scale risk down when in drawdown
input double InpRiskMinPercent     = 0.25;    // Lower bound for dynamic risk (%)

//+------------------------------------------------------------------+
//|   Global objects / variables                                     |
//+------------------------------------------------------------------+
CTrade        trade;                    // Trading object
datetime      last_m15_bar_time = 0;    // For new-bar detection

//--- runtime flags for the currently tracked position
static ulong  tracked_ticket   = 0;     // ticket of open position we manage
static bool   partial_done     = false; // whether partial take-profit already executed
static int    g_loss_streak    = 0;     // consecutive losing trades
datetime      g_cooldown_until = 0;     // time until which trading is paused
static datetime g_last_trade_time = 0;  // time of last trade entry

//--- Performance tracking
double        g_equity_peak   = 0.0;   // highest equity seen since EA start

//--- handles for indicators (created in OnInit)
int handleATR  = INVALID_HANDLE;
int handleRSI  = INVALID_HANDLE;
int handleEMA  = INVALID_HANDLE;
int handleADX  = INVALID_HANDLE;
int handleADX_M15 = INVALID_HANDLE;
// Buffer indexes for ADX indicator
const int ADX_MAIN   = 0;
const int ADX_PLUSDI = 1;
const int ADX_MINUSDI= 2;

//+------------------------------------------------------------------+
//|   Helper: Calculate today P/L in account currency                |
//+------------------------------------------------------------------+
double GetTodayProfitLoss()
  {
   datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE)); // midnight of server time

   // ensure history data is loaded
   HistorySelect(today_start, TimeCurrent());

   double profit = 0.0;
   uint total = HistoryDealsTotal();
   for(uint i = 0; i < total; ++i)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      if(deal_time < today_start) continue;
      long   deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);
      if(deal_type != DEAL_TYPE_BALANCE && deal_type != DEAL_TYPE_CREDIT)
         profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
     }

  return profit;
 }

//+------------------------------------------------------------------+
//|   Helper: check if trading is allowed today (weekday filter)      |
//+------------------------------------------------------------------+
bool IsTradingAllowedToday()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int wd = (int)dt.day_of_week; // 0 = Sun
   int hour = dt.hour;
   
   switch(wd)
     {
      case 1: // Monday - only after 12 UTC
         return InpTradeMonday && (hour >= 12);
      case 2: 
         return InpTradeTuesday;
      case 3: 
         return InpTradeWednesday;
      case 4: 
         return InpTradeThursday;
      case 5: // Friday - only until 12 UTC
         return InpTradeFriday && (hour < 12);
      default: 
         return false; // Sun/Sat
     }
  }
  
// 

//+------------------------------------------------------------------+
//|   Helper: Return current open position ticket (if any)           |
//+------------------------------------------------------------------+
ulong CurrentPositionTicket()
  {
   if(!PositionSelect(_Symbol))
      return 0;

   return (ulong)PositionGetInteger(POSITION_TICKET);
  }

//+------------------------------------------------------------------+
//|   Lot calculation based on SL distance (points)                  |
//+------------------------------------------------------------------+
double CalcVolumeByRisk(double sl_points)
  {
   if(sl_points <= 0) return 0.0;

   double equity      = AccountInfoDouble(ACCOUNT_EQUITY);

   double risk_pct = InpRiskPercent;

   // Step-down risk scaling with step-up on new equity highs
   if(InpScaleRiskOnDD)
     {
      // Update equity peak if we've made a new high
      if(equity > g_equity_peak)
        {
         g_equity_peak = equity;  // Reset peak, allowing risk to step back up
        }
        
      if(g_equity_peak > 0.0)
        {
         double dd_pct = (g_equity_peak - equity) / g_equity_peak * 100.0;
         if(dd_pct >= 5.0)  // Step down at 5% DD
           {
            risk_pct = InpRiskPercent * 0.5;  // 1.5% becomes 0.75%
            if(risk_pct < InpRiskMinPercent)
               risk_pct = InpRiskMinPercent;
           }
         // When DD < 5%, risk automatically returns to full InpRiskPercent (1.5%)
        }
     }

   double risk_money  = equity * risk_pct / 100.0;

   // Tick parameters
   double tick_value  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick_value <= 0 || tick_size <= 0)
      return 0.0;

   // Value per point = tick_value / (tick_size / _Point);
   double point_value = tick_value / (tick_size / _Point);
   double volume      = risk_money / (sl_points * point_value);

   // Normalize to volume step and min / max boundaries
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   volume = MathFloor(volume / lot_step) * lot_step;
   if(volume < min_lot) volume = min_lot;
   if(volume > max_lot) volume = max_lot;

   return volume;
  }

//+------------------------------------------------------------------+
//|   Indicator buffers fetch (wrapper)                               |
//+------------------------------------------------------------------+
bool CopyBufferValue(int handle, int buffer_index, int shift, double &value)
  {
   double tmp[1];
   if(CopyBuffer(handle, buffer_index, shift, 1, tmp) != 1)
     {
      Print("Failed CopyBuffer handle=", handle, " err=", GetLastError());
      return false;
     }
   value = tmp[0];
   return true;
  }

//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- Create indicator handles
   handleATR = iATR(_Symbol, PERIOD_M15, 14);
   if(handleATR == INVALID_HANDLE)
     {
      Print("Failed to create ATR handle. Error ", GetLastError());
      return INIT_FAILED;
     }

   handleRSI = iRSI(_Symbol, PERIOD_M15, InpRSIPeriod, PRICE_CLOSE);
   if(handleRSI == INVALID_HANDLE)
     {
      Print("Failed to create RSI handle. Error ", GetLastError());
      return INIT_FAILED;
     }

   handleEMA = iMA(_Symbol, PERIOD_H1, InpTrendMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(handleEMA == INVALID_HANDLE)
     {
      Print("Failed to create EMA handle. Error ", GetLastError());
      return INIT_FAILED;
     }

   if(InpUseADXFilter)
     {
       handleADX = iADX(_Symbol, PERIOD_H1, InpADXPeriod);
       if(handleADX == INVALID_HANDLE)
         {
          Print("Failed to create ADX handle. Error ", GetLastError());
          return INIT_FAILED;
         }
     }

   if(InpUseM15ADXFilter)
     {
      handleADX_M15 = iADX(_Symbol, PERIOD_M15, InpM15ADXPeriod);
      if(handleADX_M15 == INVALID_HANDLE)
        {
         Print("Failed to create M15 ADX handle. Error ", GetLastError());
         return INIT_FAILED;
        }
     }

   // Record starting equity as peak
   g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|   OnDeinit                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handleATR  != INVALID_HANDLE) IndicatorRelease(handleATR);
   if(handleRSI  != INVALID_HANDLE) IndicatorRelease(handleRSI);
   if(handleEMA  != INVALID_HANDLE) IndicatorRelease(handleEMA);
   if(handleADX  != INVALID_HANDLE) IndicatorRelease(handleADX);
   if(handleADX_M15 != INVALID_HANDLE) IndicatorRelease(handleADX_M15);
  }

//+------------------------------------------------------------------+
//|   Trade management: BE / trailing                                |
//+------------------------------------------------------------------+
void ManageOpenPosition()
  {
   if(!PositionSelect(_Symbol))
     {
      tracked_ticket = 0;
      partial_done   = false;
      return; // no position
     }

   // Track ticket & reset per new position
   ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);
   if(ticket != tracked_ticket)
     {
      tracked_ticket = ticket;
      partial_done   = false; // reset for the new trade
     }

   double atr_prev;
   if(!CopyBufferValue(handleATR, 0, 1, atr_prev)) return;

   // Short-term ADX (M15) momentum filter
   if(InpUseM15ADXFilter && handleADX_M15 != INVALID_HANDLE)
     {
      double adx_m15;
      if(!CopyBufferValue(handleADX_M15, 0, 0, adx_m15)) return;
      if(adx_m15 < InpM15ADXMin)
         return; // skip if low momentum on execution timeframe
     }

   // Volatility filter: require current ATR above average of last N bars
   if(InpUseATRVolFilter && InpATRVolLookback > 1)
     {
      int lookback = InpATRVolLookback;
      if(lookback > 1000) lookback = 1000;
      double atr_array[];
      ArrayResize(atr_array, lookback);
      int copied = CopyBuffer(handleATR, 0, 1, lookback, atr_array);
      if(copied != lookback) return;

      double sum_atr = 0.0;
      for(int i=0;i<lookback;i++) sum_atr += atr_array[i];
      double atr_avg = sum_atr / lookback;
      if(atr_prev < atr_avg * InpATRVolFactorMin)
         return; // low volatility, skip breakout attempt
     }

   double be_distance = atr_prev * InpBreakevenATR;

   if(!PositionSelect(_Symbol)) return; // no position (redundant safety)

   double open_price   = PositionGetDouble(POSITION_PRICE_OPEN);
   double stop_price   = PositionGetDouble(POSITION_SL);
   double take_price   = PositionGetDouble(POSITION_TP);
   double current_bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double current_ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   long   position_type = PositionGetInteger(POSITION_TYPE);

   double new_sl = stop_price; // initialize

   // -------------------------------------------------------------
   // 0)  Time-stop exit                                           
   // -------------------------------------------------------------
   if(InpUseTimeStop && InpMaxHoldingBars > 0)
     {
       datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
       int bars_held = int((TimeCurrent() - open_time) / (PeriodSeconds(PERIOD_M15)));
       if(bars_held >= InpMaxHoldingBars)
         {
           double risk_dist = (position_type==POSITION_TYPE_BUY) ? (open_price - stop_price)
                                                                : (stop_price - open_price);
           double move_dist = (position_type==POSITION_TYPE_BUY) ? (current_bid - open_price)
                                                                : (open_price - current_ask);
           double rr = risk_dist>0 ? (move_dist / risk_dist) : 0;
           if(rr < InpTimeStopProfitRR)
              trade.PositionClose(_Symbol);
         }
     }

   // -------------------------------------------------------------
   // 1)  Partial profit taking at defined RR multiple             
   // -------------------------------------------------------------
   if(InpUsePartialClose && !partial_done)
     {
      double risk_dist, move_dist;
      if(position_type == POSITION_TYPE_BUY)
        {
         risk_dist = open_price - stop_price;
         move_dist = current_bid - open_price;
        }
      else // sell
        {
         risk_dist = stop_price - open_price;
         move_dist = open_price - current_ask;
        }

      if(risk_dist > 0 && move_dist >= InpPartialRR * risk_dist)
        {
         double vol_total   = PositionGetDouble(POSITION_VOLUME);
         double vol_to_close= vol_total * (InpPartialPercent/100.0);

         double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         vol_to_close = MathFloor(vol_to_close / lot_step) * lot_step;

         if(vol_to_close >= lot_step && vol_to_close < vol_total)
           {
            if(trade.PositionClosePartial(_Symbol, vol_to_close))
               partial_done = true;
           }
        }
     }

   if(position_type == POSITION_TYPE_BUY)
     {
      if((current_bid - open_price) > be_distance && stop_price < open_price)
         new_sl = open_price;

      // Trailing stop after reaching defined RR multiple
      if(InpUseTrailing)
        {
         double trail_distance = atr_prev * InpTrailATRMultiplier;
         double start_distance = atr_prev * InpStopATRMultiplier * InpTrailStartRR;
         if((current_bid - open_price) >= start_distance)
           {
            double candidate_sl = current_bid - trail_distance;
            if(candidate_sl > new_sl && candidate_sl > stop_price && candidate_sl < current_bid)
               new_sl = candidate_sl;
           }
        }
     }
   else if(position_type == POSITION_TYPE_SELL)
     {
      if((open_price - current_ask) > be_distance && stop_price > open_price)
         new_sl = open_price;

       if(InpUseTrailing)
         {
          double trail_distance = atr_prev * InpTrailATRMultiplier;
          double start_distance = atr_prev * InpStopATRMultiplier * InpTrailStartRR;
          if((open_price - current_ask) >= start_distance)
            {
             double candidate_sl = current_ask + trail_distance;
             if(candidate_sl < new_sl && candidate_sl < stop_price && candidate_sl > current_ask)
                new_sl = candidate_sl;
            }
         }
     }

   if(new_sl != stop_price)
     {
      trade.PositionModify(_Symbol, new_sl, take_price);
     }
  }

//+------------------------------------------------------------------+
//|   Main: OnTick                                                   |
//+------------------------------------------------------------------+
void OnTick()
  {
   // -------------------------------------------------------------
   // Detect position closure to update loss streak stats
   // -------------------------------------------------------------
   if(tracked_ticket != 0 && !PositionSelectByTicket(tracked_ticket))
     {
       double pos_profit = 0.0;
       // search deal profit for that ticket
       ulong deals = HistoryDealsTotal();
       for(long i=(long)deals-1;i>=0 && i>= (long)deals-1000;i--) // scan recent deals
         {
           ulong d_ticket = HistoryDealGetTicket((uint)i);
           if(d_ticket==0) continue;
           ulong d_pos_id = (ulong)HistoryDealGetInteger(d_ticket, DEAL_POSITION_ID);
           if(d_pos_id == tracked_ticket)
             {
               pos_profit += HistoryDealGetDouble(d_ticket, DEAL_PROFIT);
             }
         }

       if(InpUseLossStreakGuard)
         {
           if(pos_profit < 0)
              g_loss_streak++;
           else if(pos_profit > 0)
              g_loss_streak = 0;

           if(g_loss_streak >= InpMaxLossStreak)
             {
               g_cooldown_until = TimeCurrent() + InpCooldownHours * 3600;
               g_loss_streak = 0; // reset streak
             }
         }

       tracked_ticket = 0; // reset
       partial_done   = false;
     }

   // Update peak equity and apply global drawdown guard
   double equity_now = AccountInfoDouble(ACCOUNT_EQUITY);
   // Peak update now handled in CalcVolumeByRisk for risk step-up/down control

   if(InpUseGlobalDDGuard && g_equity_peak > 0.0)
     {
      double dd_pct = (g_equity_peak - equity_now) / g_equity_peak * 100.0;
      if(dd_pct >= InpMaxTotalDDPct)
        {
         // Halt all new trading but still manage open position
         ManageOpenPosition();
         return;
        }
     }

   // Cooldown after loss streak
   if(InpUseLossStreakGuard && TimeCurrent() < g_cooldown_until)
     {
       ManageOpenPosition();
       return;
     }
   // Manage existing position (trailing / breakeven)
   ManageOpenPosition();

   // Return if a position is already open (one trade at a time)
   if(PositionSelect(_Symbol))
      return;

   // Check trade cooldown period
   if(g_last_trade_time > 0)
     {
      int bars_since_trade = int((TimeCurrent() - g_last_trade_time) / PeriodSeconds(PERIOD_M15));
      if(bars_since_trade < InpTradeCooldownBars)
         return;
     }

   // Check trading hours filter
   if(InpUseTradeHours)
     {
      MqlDateTime tmstruct;
      TimeToStruct(TimeCurrent(), tmstruct);
      int hour = (int)tmstruct.hour;
      if(hour < InpTradeStartHour || hour >= InpTradeEndHour)
         return;
     }

   // Weekday trading filter
   if(!IsTradingAllowedToday())
      return;

   // Daily loss cut-off
   if(InpUseDailyLossCut)
     {
      double today_pl = GetTodayProfitLoss();
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity == 0) return;
      if( (today_pl / equity * 100.0) <= (-InpDailyLossPct) )
        {
         // Stop trading for today
         return;
        }
     }

   // New-bar detection on M15 to compute breakout levels once per bar
   datetime current_bar_time = iTime(_Symbol, PERIOD_M15, 0);
   static double   breakout_high = 0.0;
   static double   breakout_low  = 0.0;
   static bool     breakout_levels_valid = false;
   static datetime bar_time_levels = 0;
   static bool     tradeExecutedThisBar = false;

   if(current_bar_time != bar_time_levels)
     {
      // Update levels at the very first tick of the new bar
      bar_time_levels = current_bar_time;

      // Breakout levels using lookback bars (exclude current forming bar)
      int highest_index = iHighest(_Symbol, PERIOD_M15, MODE_HIGH, InpLookbackBars, 1);
      int lowest_index  = iLowest (_Symbol, PERIOD_M15, MODE_LOW , InpLookbackBars, 1);
      if(highest_index == -1 || lowest_index == -1)
        {
         breakout_levels_valid = false;
        }
      else
        {
         breakout_high = iHigh(_Symbol, PERIOD_M15, highest_index);
         breakout_low  = iLow (_Symbol, PERIOD_M15, lowest_index );
         
         // Check minimum range width (must be >= 1 × ATR)
         double atr_check;
         if(CopyBufferValue(handleATR, 0, 1, atr_check))
           {
            double range_width = breakout_high - breakout_low;
            if(range_width < atr_check * 1.0)  // Minimum 1 ATR range
              {
               breakout_levels_valid = false;
              }
            else
              {
               breakout_levels_valid = true;
              }
           }
         else
           {
            breakout_levels_valid = false;
           }
        }

      // Reset trade execution flag for new bar
      tradeExecutedThisBar = false;
     }

   if(!breakout_levels_valid) return;

   // Fetch indicator data (previous closed bar shift = 1)
   double atr_prev;
   if(!CopyBufferValue(handleATR, 0, 1, atr_prev)) return;
   
   // Check minimum ATR requirement
   int pip_divisor = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   double atr_in_pips = atr_prev / (_Point * pip_divisor);
   if(atr_in_pips < InpMinATRPips) return; // Skip if volatility too low

   double rsi_prev;
   if(!CopyBufferValue(handleRSI, 0, 1, rsi_prev)) return;

   // Trend filter (current H1 close vs EMA)
   double ema_h1;
   if(!CopyBufferValue(handleEMA, 0, 0, ema_h1)) return;

   double price_h1 = iClose(_Symbol, PERIOD_H1, 0);
   int trend_dir = 0; // 1 = up, -1 = down
   if(price_h1 > ema_h1) trend_dir = 1;
   else if(price_h1 < ema_h1) trend_dir = -1;

   if(trend_dir == 0) return; // No clear trend

   // EMA slope filter
   double ema_old;
   if(!CopyBufferValue(handleEMA, 0, InpEMASlopeBars, ema_old)) return;

   double ema_diff = (ema_h1 - ema_old) / _Point;  // still "points"

   // Replace the MathPow formula with a simple 5-digit / 4-digit check:
   int pip_in_points = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   double slope_min_points = InpEMASlopeMinPips * pip_in_points;
   
   if(trend_dir == 1 && ema_diff < slope_min_points) return;
   if(trend_dir == -1 && (-ema_diff) < slope_min_points) return;

   // ADX filter
   if(InpUseADXFilter && handleADX != INVALID_HANDLE)
     {
      double adx_value;
      if(!CopyBufferValue(handleADX, ADX_MAIN, 0, adx_value)) return;
      if(adx_value < InpADXMin) return; // Weak trend, skip trading

      if(InpUseDirectionalDI)
        {
         double di_plus, di_minus;
         if(!CopyBufferValue(handleADX, ADX_PLUSDI, 0, di_plus)) return;
         if(!CopyBufferValue(handleADX, ADX_MINUSDI, 0, di_minus)) return;
         if(trend_dir == 1 && di_plus <= di_minus) return; // long but DI+ not dominant
         if(trend_dir == -1 && di_minus <= di_plus) return; // short but DI- not dominant
        }
     }

   if(InpUseRSIFilter)
     {
       bool rsi_ok = (rsi_prev >= InpRSILower && rsi_prev <= InpRSIUpper);
       if(!rsi_ok) return;
     }

   // Exit if already executed a trade this bar
   if(tradeExecutedThisBar) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Check spread filter
   double spread = ask - bid;
   double spread_pips = spread / (_Point * pip_divisor);
   if(spread_pips > InpMaxSpreadPips) return; // Skip if spread too wide
   
   // Momentum confirmation: Check last 3 candles are trending in breakout direction
   double close1 = iClose(_Symbol, PERIOD_M15, 1);
   double close2 = iClose(_Symbol, PERIOD_M15, 2);
   double close3 = iClose(_Symbol, PERIOD_M15, 3);
   double open1  = iOpen(_Symbol, PERIOD_M15, 1);
   double open2  = iOpen(_Symbol, PERIOD_M15, 2);
   double open3  = iOpen(_Symbol, PERIOD_M15, 3);
   
   bool bullish_momentum = (close1 > open1) && (close2 > open2) && (close1 > close2);
   bool bearish_momentum = (close1 < open1) && (close2 < open2) && (close1 < close2);

   // Adaptive breakout buffer: max(fixed pips, ATR×factor)
   double fixed_buf_price = InpBreakoutBufferPips * 10 * _Point; // pips->price assuming 5-digit
   double atr_buf_price   = (InpBreakoutBufferATR>0 ? atr_prev * InpBreakoutBufferATR : 0);
   double brk_buffer = MathMax(fixed_buf_price, atr_buf_price);

   double sl_price = 0.0;
   double tp_price = 0.0;
   double volume   = 0.0;

   // Long breakout condition: price crosses above breakout_high + buffer
   if(trend_dir == 1 && ask >= breakout_high + brk_buffer && bullish_momentum)
     {
      double sl_distance = atr_prev * InpStopATRMultiplier;
      sl_price = ask - sl_distance;
      if(InpUseTakeProfit)
         tp_price = ask + sl_distance * InpTP_RR;
      else
         tp_price = 0.0;
      volume   = CalcVolumeByRisk(sl_distance / _Point);

      if(volume > 0 && trade.Buy(volume, _Symbol, ask, sl_price, tp_price, "EURUSD_breakout_buy"))
        {
         tradeExecutedThisBar = true;
         g_last_trade_time = TimeCurrent();
        }
     }

   // Short breakout condition: price falls below breakout_low
   if(!tradeExecutedThisBar && trend_dir == -1 && bid <= breakout_low - brk_buffer && bearish_momentum)
     {
      double sl_distance = atr_prev * InpStopATRMultiplier;
      sl_price = bid + sl_distance;
      if(InpUseTakeProfit)
         tp_price = bid - sl_distance * InpTP_RR;
      else
         tp_price = 0.0;
      volume   = CalcVolumeByRisk(sl_distance / _Point);

      if(volume > 0 && trade.Sell(volume, _Symbol, bid, sl_price, tp_price, "EURUSD_breakout_sell"))
        {
         tradeExecutedThisBar = true;
         g_last_trade_time = TimeCurrent();
        }
     }
  }


// 


