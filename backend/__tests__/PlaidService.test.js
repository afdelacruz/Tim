const PlaidService = require('../services/PlaidService');

// Mock the plaid client
jest.mock('plaid', () => ({
    PlaidApi: jest.fn().mockImplementation(() => ({
        linkTokenCreate: jest.fn()
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

describe('PlaidService', () => {
    let plaidService;
    let mockPlaidClient;

    beforeEach(() => {
        // Reset mocks
        jest.clearAllMocks();
        
        // Get the mocked PlaidApi constructor
        const { PlaidApi } = require('plaid');
        mockPlaidClient = {
            linkTokenCreate: jest.fn()
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
}); 