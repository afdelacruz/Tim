const MonthlyComparisonService = require('../services/MonthlyComparisonService');
const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

// Mock the repositories
jest.mock('../repositories/AccountRepository');
jest.mock('../repositories/BalanceSnapshotRepository');

describe('MonthlyComparisonService', () => {
    let monthlyComparisonService;
    let mockAccountRepository;
    let mockBalanceSnapshotRepository;

    beforeEach(() => {
        jest.clearAllMocks();
        
        // Create mock instances
        mockAccountRepository = {
            findAccountsByUserId: jest.fn()
        };
        mockBalanceSnapshotRepository = {
            getFirstSnapshotForAccountInMonth: jest.fn(),
            getLatestSnapshotForAccount: jest.fn()
        };

        // Mock the repository modules
        AccountRepository.findAccountsByUserId = mockAccountRepository.findAccountsByUserId;
        BalanceSnapshotRepository.getFirstSnapshotForAccountInMonth = mockBalanceSnapshotRepository.getFirstSnapshotForAccountInMonth;
        BalanceSnapshotRepository.getLatestSnapshotForAccount = mockBalanceSnapshotRepository.getLatestSnapshotForAccount;

        monthlyComparisonService = new MonthlyComparisonService();
    });

    describe('getMonthlyComparison', () => {
        it('testGetMonthlyComparison_withValidUser_returnsComparisonData', async () => {
            // Arrange
            const userId = 'test-user-id';
            const mockAccounts = [
                { id: 'account1', account_name: 'Checking', account_type: 'depository', institution_name: 'Test Bank' },
                { id: 'account2', account_name: 'Savings', account_type: 'depository', institution_name: 'Test Bank' }
            ];

            const currentDate = new Date('2024-02-15');

            // Mock current month snapshots
            mockBalanceSnapshotRepository.getFirstSnapshotForAccountInMonth
                .mockResolvedValueOnce({ balance: '1000.00', snapshot_date: '2024-02-01' }) // account1 current
                .mockResolvedValueOnce({ balance: '2000.00', snapshot_date: '2024-02-01' }) // account2 current
                .mockResolvedValueOnce({ balance: '900.00', snapshot_date: '2024-01-01' })  // account1 previous
                .mockResolvedValueOnce({ balance: '1800.00', snapshot_date: '2024-01-01' }); // account2 previous

            mockAccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);

            // Act
            const result = await monthlyComparisonService.getMonthlyComparison(userId, currentDate);

            // Assert
            expect(result).toEqual({
                currentMonth: {
                    year: 2024,
                    month: 2,
                    monthName: 'February',
                    totalBalance: 3000.00,
                    accounts: [
                        { id: 'account1', name: 'Checking', balance: 1000.00 },
                        { id: 'account2', name: 'Savings', balance: 2000.00 }
                    ]
                },
                previousMonth: {
                    year: 2024,
                    month: 1,
                    monthName: 'January',
                    totalBalance: 2700.00,
                    accounts: [
                        { id: 'account1', name: 'Checking', balance: 900.00 },
                        { id: 'account2', name: 'Savings', balance: 1800.00 }
                    ]
                },
                comparison: {
                    totalChange: 300.00,
                    percentageChange: 11.11,
                    trend: 'increase',
                    accountChanges: [
                        { id: 'account1', name: 'Checking', change: 100.00, percentageChange: 11.11 },
                        { id: 'account2', name: 'Savings', change: 200.00, percentageChange: 11.11 }
                    ]
                }
            });

            expect(mockAccountRepository.findAccountsByUserId).toHaveBeenCalledWith(userId);
            expect(mockBalanceSnapshotRepository.getFirstSnapshotForAccountInMonth).toHaveBeenCalledTimes(4);
        });

        it('testGetMonthlyComparison_withNoAccounts_returnsEmptyComparison', async () => {
            // Arrange
            const userId = 'test-user-id';
            const currentDate = new Date('2024-02-15');
            
            mockAccountRepository.findAccountsByUserId.mockResolvedValue([]);

            // Act
            const result = await monthlyComparisonService.getMonthlyComparison(userId, currentDate);

            // Assert
            expect(result.currentMonth.totalBalance).toBe(0);
            expect(result.previousMonth.totalBalance).toBe(0);
            expect(result.comparison.totalChange).toBe(0);
            expect(result.comparison.percentageChange).toBe(0);
            expect(result.comparison.trend).toBe('no_change');
        });

        it('testGetMonthlyComparison_withMissingPreviousMonthData_handlesGracefully', async () => {
            // Arrange
            const userId = 'test-user-id';
            const mockAccounts = [
                { id: 'account1', account_name: 'Checking', account_type: 'depository', institution_name: 'Test Bank' }
            ];

            const currentDate = new Date('2024-02-15');

            mockAccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
            mockBalanceSnapshotRepository.getFirstSnapshotForAccountInMonth
                .mockResolvedValueOnce({ balance: '1000.00', snapshot_date: '2024-02-01' }) // current month
                .mockResolvedValueOnce(null); // previous month missing

            // Act
            const result = await monthlyComparisonService.getMonthlyComparison(userId, currentDate);

            // Assert
            expect(result.currentMonth.totalBalance).toBe(1000.00);
            expect(result.previousMonth.totalBalance).toBe(0);
            expect(result.comparison.trend).toBe('increase');
        });
    });
}); 