const BalanceService = require('../services/BalanceService');

// Mock the dependencies
jest.mock('../repositories/AccountRepository');
jest.mock('../repositories/BalanceSnapshotRepository');

const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

describe('BalanceService', () => {
    let balanceService;

    beforeEach(() => {
        jest.clearAllMocks();
        balanceService = new BalanceService();
    });

    describe('getCurrentBalancesForUser', () => {
        it('testGetCurrentBalancesForUser_withMultipleAccounts_returnsLatestBalances', async () => {
            // Arrange
            const userId = 'test-user-id';
            const mockAccounts = [
                {
                    id: 'account1',
                    account_name: 'Checking Account',
                    account_type: 'depository',
                    institution_name: 'Test Bank',
                    needs_reauthentication: false
                },
                {
                    id: 'account2',
                    account_name: 'Savings Account',
                    account_type: 'depository',
                    institution_name: 'Test Bank',
                    needs_reauthentication: false
                }
            ];

            const mockSnapshots = [
                {
                    account_id: 'account1',
                    balance: 1500.75,
                    snapshot_date: '2024-01-15'
                },
                {
                    account_id: 'account2',
                    balance: 5000.00,
                    snapshot_date: '2024-01-15'
                }
            ];

            AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
            BalanceSnapshotRepository.getLatestSnapshotForAccount
                .mockResolvedValueOnce(mockSnapshots[0])
                .mockResolvedValueOnce(mockSnapshots[1]);

            // Act
            const result = await balanceService.getCurrentBalancesForUser(userId);

            // Assert
            expect(AccountRepository.findAccountsByUserId).toHaveBeenCalledWith(userId);
            expect(BalanceSnapshotRepository.getLatestSnapshotForAccount).toHaveBeenCalledTimes(2);
            expect(BalanceSnapshotRepository.getLatestSnapshotForAccount).toHaveBeenCalledWith('account1');
            expect(BalanceSnapshotRepository.getLatestSnapshotForAccount).toHaveBeenCalledWith('account2');
            
            expect(result).toEqual({
                accounts: [
                    {
                        id: 'account1',
                        name: 'Checking Account',
                        type: 'depository',
                        institution: 'Test Bank',
                        currentBalance: 1500.75,
                        lastUpdated: '2024-01-15',
                        needsReauthentication: false
                    },
                    {
                        id: 'account2',
                        name: 'Savings Account',
                        type: 'depository',
                        institution: 'Test Bank',
                        currentBalance: 5000.00,
                        lastUpdated: '2024-01-15',
                        needsReauthentication: false
                    }
                ],
                totalBalance: 6500.75
            });
        });

        it('testGetCurrentBalancesForUser_withAccountsNeedingReauth_includesReauthFlag', async () => {
            // Arrange
            const userId = 'test-user-id';
            const mockAccounts = [
                {
                    id: 'account1',
                    account_name: 'Checking Account',
                    account_type: 'depository',
                    institution_name: 'Test Bank',
                    needs_reauthentication: true
                }
            ];

            const mockSnapshot = {
                account_id: 'account1',
                balance: 1500.75,
                snapshot_date: '2024-01-15'
            };

            AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
            BalanceSnapshotRepository.getLatestSnapshotForAccount.mockResolvedValue(mockSnapshot);

            // Act
            const result = await balanceService.getCurrentBalancesForUser(userId);

            // Assert
            expect(result.accounts[0].needsReauthentication).toBe(true);
        });

        it('testGetCurrentBalancesForUser_withAccountsWithoutSnapshots_showsZeroBalance', async () => {
            // Arrange
            const userId = 'test-user-id';
            const mockAccounts = [
                {
                    id: 'account1',
                    account_name: 'New Account',
                    account_type: 'depository',
                    institution_name: 'Test Bank',
                    needs_reauthentication: false
                }
            ];

            AccountRepository.findAccountsByUserId.mockResolvedValue(mockAccounts);
            BalanceSnapshotRepository.getLatestSnapshotForAccount.mockResolvedValue(null);

            // Act
            const result = await balanceService.getCurrentBalancesForUser(userId);

            // Assert
            expect(result.accounts[0].currentBalance).toBe(0);
            expect(result.accounts[0].lastUpdated).toBeNull();
            expect(result.totalBalance).toBe(0);
        });

        it('testGetCurrentBalancesForUser_withNoAccounts_returnsEmptyResult', async () => {
            // Arrange
            const userId = 'test-user-id';
            AccountRepository.findAccountsByUserId.mockResolvedValue([]);

            // Act
            const result = await balanceService.getCurrentBalancesForUser(userId);

            // Assert
            expect(result).toEqual({
                accounts: [],
                totalBalance: 0
            });
            expect(BalanceSnapshotRepository.getLatestSnapshotForAccount).not.toHaveBeenCalled();
        });
    });
}); 