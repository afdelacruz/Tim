const BalanceUpdateService = require('../services/BalanceUpdateService');

// Mock the dependencies
jest.mock('../repositories/AccountRepository');
jest.mock('../repositories/BalanceSnapshotRepository');
jest.mock('plaid');

const AccountRepository = require('../repositories/AccountRepository');
const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');

describe('BalanceUpdateService', () => {
    let balanceUpdateService;
    let mockPlaidClient;

    beforeEach(() => {
        jest.clearAllMocks();
        
        // Mock Plaid client
        const { PlaidApi } = require('plaid');
        mockPlaidClient = {
            accountsBalanceGet: jest.fn()
        };
        PlaidApi.mockImplementation(() => mockPlaidClient);
        
        balanceUpdateService = new BalanceUpdateService();
    });

    describe('fetchAndStoreBalancesForAllUsers', () => {
        it('testFetchAndStoreBalancesForAllUsers_processesMultipleUsers', async () => {
            // Arrange
            const mockAccounts = [
                {
                    id: 'account1',
                    user_id: 'user1',
                    plaid_access_token: 'access-token-1',
                    plaid_account_id: 'plaid-account-1',
                    plaid_item_id: 'item-1',
                    needs_reauthentication: false
                },
                {
                    id: 'account2',
                    user_id: 'user2',
                    plaid_access_token: 'access-token-2',
                    plaid_account_id: 'plaid-account-2',
                    plaid_item_id: 'item-2',
                    needs_reauthentication: false
                }
            ];

            AccountRepository.findAllActiveAccounts.mockResolvedValue(mockAccounts);
            
            mockPlaidClient.accountsBalanceGet.mockResolvedValue({
                data: {
                    accounts: [
                        { account_id: 'plaid-account-1', balances: { current: 1000.50 } },
                        { account_id: 'plaid-account-2', balances: { current: 2500.75 } }
                    ]
                }
            });

            BalanceSnapshotRepository.saveSnapshot.mockResolvedValue({ id: 'snapshot-id' });
            AccountRepository.setNeedsReauthentication.mockResolvedValue([]);

            // Act
            await balanceUpdateService.fetchAndStoreBalancesForAllUsers();

            // Assert
            expect(AccountRepository.findAllActiveAccounts).toHaveBeenCalled();
            expect(mockPlaidClient.accountsBalanceGet).toHaveBeenCalledTimes(2);
            expect(BalanceSnapshotRepository.saveSnapshot).toHaveBeenCalledTimes(2);
            expect(AccountRepository.setNeedsReauthentication).toHaveBeenCalledWith('item-1', false);
            expect(AccountRepository.setNeedsReauthentication).toHaveBeenCalledWith('item-2', false);
        });

        it('testFetchBalancesForUser_whenPlaidCallSucceeds_savesSnapshotsAndClearsReauthFlag', async () => {
            // Arrange
            const mockAccounts = [
                {
                    id: 'account1',
                    user_id: 'user1',
                    plaid_access_token: 'access-token-1',
                    plaid_account_id: 'plaid-account-1',
                    plaid_item_id: 'item-1',
                    needs_reauthentication: true // Previously needed reauth
                }
            ];

            AccountRepository.findAllActiveAccounts.mockResolvedValue(mockAccounts);
            
            mockPlaidClient.accountsBalanceGet.mockResolvedValue({
                data: {
                    accounts: [
                        { account_id: 'plaid-account-1', balances: { current: 1000.50 } }
                    ]
                }
            });

            BalanceSnapshotRepository.saveSnapshot.mockResolvedValue({ id: 'snapshot-id' });
            AccountRepository.setNeedsReauthentication.mockResolvedValue([]);

            // Act
            await balanceUpdateService.fetchAndStoreBalancesForAllUsers();

            // Assert
            expect(BalanceSnapshotRepository.saveSnapshot).toHaveBeenCalledWith(
                'account1',
                1000.50,
                expect.any(Date)
            );
            expect(AccountRepository.setNeedsReauthentication).toHaveBeenCalledWith('item-1', false);
        });

        it('testFetchBalancesForUser_whenPlaidItemNeedsReauthentication_setsReauthFlagAndLogsError', async () => {
            // Arrange
            const mockAccounts = [
                {
                    id: 'account1',
                    user_id: 'user1',
                    plaid_access_token: 'access-token-1',
                    plaid_account_id: 'plaid-account-1',
                    plaid_item_id: 'item-1',
                    needs_reauthentication: false
                }
            ];

            AccountRepository.findAllActiveAccounts.mockResolvedValue(mockAccounts);
            
            const plaidError = new Error('ITEM_LOGIN_REQUIRED');
            plaidError.error_code = 'ITEM_LOGIN_REQUIRED';
            mockPlaidClient.accountsBalanceGet.mockRejectedValue(plaidError);

            AccountRepository.setNeedsReauthentication.mockResolvedValue([]);
            
            const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

            // Act
            await balanceUpdateService.fetchAndStoreBalancesForAllUsers();

            // Assert
            expect(AccountRepository.setNeedsReauthentication).toHaveBeenCalledWith('item-1', true);
            expect(consoleSpy).toHaveBeenCalledWith(
                expect.stringContaining('Plaid item requires re-authentication'),
                expect.any(String)
            );
            expect(BalanceSnapshotRepository.saveSnapshot).not.toHaveBeenCalled();

            consoleSpy.mockRestore();
        });

        it('testFetchBalancesForUser_whenOtherPlaidErrorOccurs_logsErrorAndDoesNotUpdate', async () => {
            // Arrange
            const mockAccounts = [
                {
                    id: 'account1',
                    user_id: 'user1',
                    plaid_access_token: 'access-token-1',
                    plaid_account_id: 'plaid-account-1',
                    plaid_item_id: 'item-1',
                    needs_reauthentication: false
                }
            ];

            AccountRepository.findAllActiveAccounts.mockResolvedValue(mockAccounts);
            
            const plaidError = new Error('INVALID_ACCESS_TOKEN');
            plaidError.error_code = 'INVALID_ACCESS_TOKEN';
            mockPlaidClient.accountsBalanceGet.mockRejectedValue(plaidError);
            
            const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

            // Act
            await balanceUpdateService.fetchAndStoreBalancesForAllUsers();

            // Assert
            expect(consoleSpy).toHaveBeenCalledWith(
                expect.stringContaining('Error fetching balances'),
                expect.any(String)
            );
            expect(BalanceSnapshotRepository.saveSnapshot).not.toHaveBeenCalled();
            expect(AccountRepository.setNeedsReauthentication).not.toHaveBeenCalled();

            consoleSpy.mockRestore();
        });

        it('testFetchBalancesForUser_withNoAccounts_doesNothingGracefully', async () => {
            // Arrange
            AccountRepository.findAllActiveAccounts.mockResolvedValue([]);

            // Act
            await balanceUpdateService.fetchAndStoreBalancesForAllUsers();

            // Assert
            expect(mockPlaidClient.accountsBalanceGet).not.toHaveBeenCalled();
            expect(BalanceSnapshotRepository.saveSnapshot).not.toHaveBeenCalled();
        });
    });
}); 