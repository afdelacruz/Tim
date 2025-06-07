# Monthly Cash Flow Tracking System Design

*Design Decision Documentation - January 2025*

## Overview

This document captures the design decision and implementation approach for Tim's core widget functionality: tracking monthly cash flow changes rather than displaying static account balances.

## The Core Design Question

**What should the Tim widget display?**

During development, we discovered a fundamental question about what "inflow" and "outflow" should represent in the widget display.

### Initial Approach (Rejected)
**Static Balance Display**: Show current account balances categorized by inflow/outflow
- Inflow: +$320 (current positive balances in inflow-categorized accounts)
- Outflow: -$410 (current debt balances in outflow-categorized accounts)
- **Problem**: This is just a snapshot of current balances, not actual money movement

### Final Approach (Implemented)
**Monthly Cash Flow Tracking**: Show actual money movement since beginning of current month
- Inflow: $0 (no positive changes since account connection)
- Outflow: $0 (no negative changes since account connection)
- **Logic**: Track actual financial activity, not static positions

## Design Decision Rationale

### Why Monthly Cash Flow Over Static Balances?

1. **Meaningful Financial Insight**: Users want to know "how am I doing this month?" not "what do I currently have?"

2. **Actionable Information**: Cash flow changes indicate spending patterns and income trends

3. **Time-Relevant Context**: Monthly reset provides a clear, recurring baseline for financial awareness

4. **Behavioral Alignment**: Matches how people naturally think about their finances ("I've spent $X this month")

## Implementation Logic

### Monthly Rolling Baseline System

#### Core Principles:
1. **Monthly Reset**: Every 1st of the month, all inflow/outflow counters reset to $0
2. **Mid-Month Connection**: If user connects accounts mid-month, backfill transactions from month start
3. **Widget Display**: Net money movement since beginning of current month

#### Calculation Method:

```javascript
// Monthly cash flow calculation logic
const getMonthlyTransactions = async (accessToken) => {
  const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  const today = new Date();
  
  return await plaidClient.transactionsGet({
    access_token: accessToken,
    start_date: monthStart.toISOString().split('T')[0], // '2024-01-01'
    end_date: today.toISOString().split('T')[0]         // today
  });
};

// Process transactions by account category
// Inflow accounts: positive transactions = money coming in
// Outflow accounts: negative transactions = money going out
```

### User Experience Scenarios

#### Scenario 1: New User (Mid-Month Connection)
- **User Action**: Connects accounts on January 15th
- **System Behavior**: Fetches all transactions from January 1st-15th
- **Widget Display**: Shows actual money movement since Jan 1st
- **Example**: Salary deposit (+$3000) vs Credit card payments (-$500)
- **Result**: Widget shows +$3000 / -$500

#### Scenario 2: Monthly Reset
- **System Behavior**: On February 1st, counters reset to $0
- **Widget Display**: Shows +$0 / -$0 initially
- **Accumulation**: New transactions start building totals from Feb 1st

#### Scenario 3: Established User
- **Ongoing Behavior**: Widget continuously shows month-to-date totals
- **User Benefit**: Clear view of current month's financial activity

## Technical Implementation Components

### 1. Transaction Fetching Service
- Plaid API integration for historical transaction data
- Date range management (month start to present)
- Error handling for API limitations

### 2. Cash Flow Calculator
- Transaction categorization by account type
- Inflow/outflow summation logic
- Account category application

### 3. Monthly Reset System
- Automated reset on 1st of each month
- Railway scheduled task or cron job
- Baseline recalculation

### 4. Widget Data Endpoint
- Real-time cash flow calculation
- Replace balance-based widget data
- Month-to-date totals API

## Data Requirements

### Plaid Transaction API Capabilities
- ✅ Fetch transactions for specific date ranges
- ✅ Up to 2 years of historical data (institution-dependent)
- ✅ Transaction amounts, dates, and account associations
- ✅ Real-time updates via webhooks or periodic syncing

### Database Schema Considerations
```sql
-- May need additional transaction storage for caching
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES accounts(id),
  plaid_transaction_id VARCHAR(255) UNIQUE,
  amount DECIMAL(12,2),
  transaction_date DATE,
  description TEXT,
  category VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Alternative Approaches Considered

### Option 1: Balance Change Tracking
- **Method**: Store daily balance snapshots, calculate differences
- **Pros**: Less API calls, works with existing balance system
- **Cons**: Doesn't capture transaction-level detail, less accurate

### Option 2: Hybrid Approach
- **Method**: Use transactions for recent data, balance changes for older periods
- **Pros**: Balances API limitations and transaction detail
- **Cons**: Complex logic, potential inconsistencies

### Option 3: User-Configurable Baseline
- **Method**: Let users set their own tracking start date
- **Pros**: Maximum flexibility
- **Cons**: Adds complexity, reduces simplicity of monthly reset

## Implementation Phases

### Phase 1: Transaction Service Foundation
1. Build Plaid transaction fetching service
2. Implement date range management
3. Create transaction categorization logic
4. Test with sandbox data

### Phase 2: Cash Flow Calculation
1. Develop monthly calculation engine
2. Apply account categorization rules
3. Handle edge cases (mid-month connections, etc.)
4. Create widget data endpoint

### Phase 3: Monthly Reset Automation
1. Implement scheduled reset job
2. Configure Railway automation
3. Add logging and monitoring
4. Test reset behavior

### Phase 4: Widget Integration
1. Update widget to use new endpoint
2. Replace balance-based display
3. Test real-time updates
4. Verify monthly reset behavior

## Success Metrics

### User Experience Metrics
- **Clarity**: Users understand what the numbers represent
- **Relevance**: Numbers reflect actual financial activity
- **Timeliness**: Data updates reflect recent transactions

### Technical Metrics
- **Accuracy**: Calculations match actual transaction data
- **Performance**: Widget updates within acceptable timeframes
- **Reliability**: Monthly resets occur consistently

## Risk Mitigation

### Plaid API Limitations
- **Risk**: Transaction history may be limited for some institutions
- **Mitigation**: Graceful fallback to available data, clear user communication

### Data Consistency
- **Risk**: Transaction timing vs balance updates may create discrepancies
- **Mitigation**: Use transaction data as source of truth, validate against balances

### User Confusion
- **Risk**: Users may expect balance display instead of cash flow
- **Mitigation**: Clear UI labeling, onboarding explanation

## Future Enhancements

### Advanced Features (Post-MVP)
1. **Custom Date Ranges**: Allow users to view different time periods
2. **Category Breakdown**: Show spending by transaction category
3. **Trend Analysis**: Compare month-over-month changes
4. **Budget Integration**: Set monthly targets vs actual performance

### Technical Improvements
1. **Caching Strategy**: Store processed transactions to reduce API calls
2. **Real-time Updates**: Webhook integration for immediate transaction updates
3. **Offline Support**: Cache recent data for offline widget updates

## Conclusion

The monthly cash flow tracking approach provides users with meaningful, actionable financial insights while maintaining the simplicity that makes Tim valuable. By focusing on actual money movement rather than static balances, the widget becomes a tool for financial awareness and behavioral change.

This design decision aligns with Tim's core value proposition: "Time is money - check your money as quickly as checking the time." Users get immediate insight into their monthly financial activity without the complexity of full financial management apps.

---

*This document should be updated as implementation progresses and user feedback is incorporated.* 