const PlaidService = require('../services/PlaidService');

// Mock the plaid client
jest.mock('plaid', () => ({
    PlaidApi: jest.fn().mockImplementation(() => ({
        linkTokenCreate: jest.fn(),
        itemPublicTokenExchange: jest.fn(),
        accountsGet: jest.fn()
    })),
    Configuration: jest.fn(),
    PlaidEnvironments: {
        sandbox: 'sandbox'
    },
    Products: {
        Transactions: 'transactions'
    },
    CountryCodes: {
        US: 'US'
    }
}));

// Mock the AccountRepository
jest.mock('../repositories/AccountRepository');
const AccountRepository = require('../repositories/AccountRepository');

describe('PlaidService', () => {
    let plaidService;
    let mockPlaidClient;

    beforeEach(() => {
        // Reset mocks
        jest.clearAllMocks();
        
        // Get the mocked PlaidApi constructor
        const { PlaidApi } = require('plaid');
        mockPlaidClient = {
            linkTokenCreate: jest.fn(),
            itemPublicTokenExchange: jest.fn(),
            accountsGet: jest.fn()
        };
        PlaidApi.mockImplementation(() => mockPlaidClient);
        
        plaidService = new PlaidService();
    });

    describe('createLinkToken', () => {
        it('testCreateLinkToken_forUser_callsPlaidClientCorrectlyAndReturnsToken', async () => {
            // Arrange
            const userId = 'test-user-id';
            const expectedLinkToken = 'link-sandbox-test-token';
            
            mockPlaidClient.linkTokenCreate.mockResolvedValue({
                data: {
                    link_token: expectedLinkToken
                }
            });

            // Act
            const result = await plaidService.createLinkToken(userId);

            // Assert
            expect(mockPlaidClient.linkTokenCreate).toHaveBeenCalledWith({
                user: {
                    client_user_id: userId
                },
                client_name: 'Tim',
                products: ['transactions'],
                country_codes: ['US'],
                language: 'en'
            });
            expect(result).toBe(expectedLinkToken);
        });

        it('testCreateLinkToken_whenPlaidClientFails_throwsError', async () => {
            // Arrange
            const userId = 'test-user-id';
            const plaidError = new Error('Plaid API error');
            
            mockPlaidClient.linkTokenCreate.mockRejectedValue(plaidError);

            // Act & Assert
            await expect(plaidService.createLinkToken(userId)).rejects.toThrow('Plaid API error');
        });
    });

    describe('exchangePublicToken', () => {
        it('testExchangePublicToken_withValidToken_getsAccessAndItemIdFromPlaid', async () => {
            // Arrange
            const userId = 'test-user-id';
            const publicToken = 'public-sandbox-test-token';
            const expectedAccessToken = 'access-sandbox-test-token';
            const expectedItemId = 'item-sandbox-test-id';
            
            mockPlaidClient.itemPublicTokenExchange.mockResolvedValue({
                data: {
                    access_token: expectedAccessToken,
                    item_id: expectedItemId
                }
            });

            const mockAccounts = [
                {
                    account_id: 'account1',
                    name: 'Checking Account',
                    type: 'depository',
                    subtype: 'checking'
                },
                {
                    account_id: 'account2', 
                    name: 'Savings Account',
                    type: 'depository',
                    subtype: 'savings'
                }
            ];

            mockPlaidClient.accountsGet.mockResolvedValue({
                data: {
                    accounts: mockAccounts,
                    item: {
                        institution_id: 'ins_1'
                    }
                }
            });

            AccountRepository.saveAccount.mockResolvedValue({ id: 'saved-account-id' });

            // Act
            const result = await plaidService.exchangePublicToken(userId, publicToken);

            // Assert
            expect(mockPlaidClient.itemPublicTokenExchange).toHaveBeenCalledWith({
                public_token: publicToken
            });
            expect(mockPlaidClient.accountsGet).toHaveBeenCalledWith({
                access_token: expectedAccessToken
            });
            expect(AccountRepository.saveAccount).toHaveBeenCalledTimes(2);
            expect(result).toEqual({
                accessToken: expectedAccessToken,
                itemId: expectedItemId,
                accounts: mockAccounts
            });
        });

        it('testExchangePublicToken_whenPlaidClientFailsExchange_throwsError', async () => {
            // Arrange
            const userId = 'test-user-id';
            const publicToken = 'invalid-token';
            const plaidError = new Error('Invalid public token');
            
            mockPlaidClient.itemPublicTokenExchange.mockRejectedValue(plaidError);

            // Act & Assert
            await expect(plaidService.exchangePublicToken(userId, publicToken)).rejects.toThrow('Invalid public token');
        });

        it('testExchangePublicToken_whenPlaidClientFailsAccountsFetch_throwsError', async () => {
            // Arrange
            const userId = 'test-user-id';
            const publicToken = 'public-sandbox-test-token';
            
            mockPlaidClient.itemPublicTokenExchange.mockResolvedValue({
                data: {
                    access_token: 'access-token',
                    item_id: 'item-id'
                }
            });
            
            const plaidError = new Error('Failed to fetch accounts');
            mockPlaidClient.accountsGet.mockRejectedValue(plaidError);

            // Act & Assert
            await expect(plaidService.exchangePublicToken(userId, publicToken)).rejects.toThrow('Failed to fetch accounts');
        });

        it('testExchangePublicToken_savesCorrectPlaidItemAndAccessTokensToDb', async () => {
            // Arrange
            const userId = 'test-user-id';
            const publicToken = 'public-sandbox-test-token';
            const accessToken = 'access-sandbox-test-token';
            const itemId = 'item-sandbox-test-id';
            
            mockPlaidClient.itemPublicTokenExchange.mockResolvedValue({
                data: {
                    access_token: accessToken,
                    item_id: itemId
                }
            });

            const mockAccounts = [
                {
                    account_id: 'account1',
                    name: 'Test Account',
                    type: 'depository',
                    subtype: 'checking'
                }
            ];

            mockPlaidClient.accountsGet.mockResolvedValue({
                data: {
                    accounts: mockAccounts,
                    item: {
                        institution_id: 'ins_1'
                    }
                }
            });

            AccountRepository.saveAccount.mockResolvedValue({ id: 'saved-account-id' });

            // Act
            await plaidService.exchangePublicToken(userId, publicToken);

            // Assert
            expect(AccountRepository.saveAccount).toHaveBeenCalledWith(
                userId,
                itemId,
                accessToken,
                'account1',
                'Test Account',
                'depository',
                'ins_1'
            );
        });
    });
}); 