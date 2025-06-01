const AccountRepository = require('../repositories/AccountRepository');
const UserRepositoryClass = require('../repositories/UserRepository');
const UserRepository = new UserRepositoryClass();
const db = require('../db');

describe('AccountRepository', () => {
    let testUser;
    const testUserEmail = 'accounttest.repo@example.com';

    beforeAll(async () => {
        await UserRepositoryClass.deleteUserByEmail(testUserEmail); // Clean up this specific user before creating
        testUser = await UserRepository.createUser(testUserEmail, 'hashedpin');
    });

    beforeEach(async () => {
        if (testUser && testUser.id) {
            await AccountRepository.deleteAccountsByUserId(testUser.id);
        } else {
            console.warn('[AccountRepoTests] testUser not defined in beforeEach, resorting to deleteAllAccounts');
            await AccountRepository.deleteAllAccounts();
        }
    });

    afterAll(async () => {
        if (testUser && testUser.id) {
            await AccountRepository.deleteAccountsByUserId(testUser.id);
        }
        await UserRepositoryClass.deleteUserByEmail(testUserEmail); // Clean up the specific user
        await db.pool.end();
    });

    const accountData1 = {
        plaidItemId: 'item_123',
        plaidAccessToken: 'access_token_123',
        plaidAccountId: 'plaid_account_id_1',
        accountName: 'Checking',
        accountType: 'depository',
        institutionName: 'Bank A'
    };

    const accountData2 = {
        plaidItemId: 'item_123', // Same item, different account
        plaidAccessToken: 'access_token_123',
        plaidAccountId: 'plaid_account_id_2',
        accountName: 'Savings',
        accountType: 'depository',
        institutionName: 'Bank A'
    };

    const accountData3 = {
        plaidItemId: 'item_456',
        plaidAccessToken: 'access_token_456',
        plaidAccountId: 'plaid_account_id_3',
        accountName: 'Credit Card',
        accountType: 'credit',
        institutionName: 'Bank B'
    };

    describe('saveAccount', () => {
        it('testSaveAccount_withValidData_savesAccount', async () => {
            const savedAccount = await AccountRepository.saveAccount(
                testUser.id, 
                accountData1.plaidItemId, 
                accountData1.plaidAccessToken, 
                accountData1.plaidAccountId, 
                accountData1.accountName, 
                accountData1.accountType, 
                accountData1.institutionName
            );
            expect(savedAccount).toBeDefined();
            expect(savedAccount.id).toBeDefined();
            expect(savedAccount.user_id).toBe(testUser.id);
            expect(savedAccount.plaid_item_id).toBe(accountData1.plaidItemId);
            expect(savedAccount.plaid_access_token).toBe(accountData1.plaidAccessToken);
            expect(savedAccount.plaid_account_id).toBe(accountData1.plaidAccountId);
            expect(savedAccount.account_name).toBe(accountData1.accountName);
            expect(savedAccount.account_type).toBe(accountData1.accountType);
            expect(savedAccount.institution_name).toBe(accountData1.institutionName);
            expect(savedAccount.is_inflow).toBe(false);
            expect(savedAccount.is_outflow).toBe(false);
            expect(savedAccount.needs_reauthentication).toBe(false);
        });
    });

    describe('findAccountsByUserId', () => {
        it('testFindAccountsByUserId_returnsCorrectAccounts', async () => {
            await AccountRepository.saveAccount(testUser.id, accountData1.plaidItemId, accountData1.plaidAccessToken, accountData1.plaidAccountId, accountData1.accountName, accountData1.accountType, accountData1.institutionName);
            await AccountRepository.saveAccount(testUser.id, accountData2.plaidItemId, accountData2.plaidAccessToken, accountData2.plaidAccountId, accountData2.accountName, accountData2.accountType, accountData2.institutionName);
            
            const accounts = await AccountRepository.findAccountsByUserId(testUser.id);
            expect(accounts).toBeDefined();
            expect(accounts.length).toBe(2);
            expect(accounts.some(acc => acc.plaid_account_id === accountData1.plaidAccountId)).toBe(true);
            expect(accounts.some(acc => acc.plaid_account_id === accountData2.plaidAccountId)).toBe(true);
        });

        it('should return an empty array if user has no accounts', async () => {
            const accounts = await AccountRepository.findAccountsByUserId(testUser.id);
            expect(accounts).toEqual([]);
        });
    });

    describe('updateAccountCategories', () => {
        it('testUpdateAccountCategories_updatesFlagsCorrectly', async () => {
            const savedAccount = await AccountRepository.saveAccount(testUser.id, accountData1.plaidItemId, accountData1.plaidAccessToken, accountData1.plaidAccountId, accountData1.accountName, accountData1.accountType, accountData1.institutionName);
            
            const updatedAccount = await AccountRepository.updateAccountCategories(savedAccount.id, true, false);
            expect(updatedAccount).toBeDefined();
            expect(updatedAccount.is_inflow).toBe(true);
            expect(updatedAccount.is_outflow).toBe(false);

            const reFetchedAccount = await AccountRepository.findAccountById(savedAccount.id);
            expect(reFetchedAccount.is_inflow).toBe(true);
            expect(reFetchedAccount.is_outflow).toBe(false);
        });
    });

    describe('findAllActiveAccounts', () => {
        it('testFindAllActiveAccounts_returnsOnlyActiveAccounts', async () => {
            // Get initial count of active accounts (from other tests)
            const initialActiveAccounts = await AccountRepository.findAllActiveAccounts();
            const initialCount = initialActiveAccounts.length;

            // Create accounts with different items
            const acc1 = await AccountRepository.saveAccount(testUser.id, accountData1.plaidItemId, accountData1.plaidAccessToken, accountData1.plaidAccountId, accountData1.accountName, accountData1.accountType, accountData1.institutionName);
            const acc2 = await AccountRepository.saveAccount(testUser.id, accountData3.plaidItemId, accountData3.plaidAccessToken, accountData3.plaidAccountId, accountData3.accountName, accountData3.accountType, accountData3.institutionName);

            // Verify both accounts are initially active
            const afterCreateAccounts = await AccountRepository.findAllActiveAccounts();
            expect(afterCreateAccounts.length).toBe(initialCount + 2);

            // Set one item to need re-authentication
            await AccountRepository.setNeedsReauthentication(accountData1.plaidItemId, true);

            // Test finding only active accounts
            const activeAccounts = await AccountRepository.findAllActiveAccounts();

            // Should have one less active account now
            expect(activeAccounts).toBeDefined();
            expect(activeAccounts.length).toBe(initialCount + 1);
            
            // Verify the remaining active account is the one we expect
            const ourActiveAccount = activeAccounts.find(acc => acc.plaid_account_id === accountData3.plaidAccountId);
            expect(ourActiveAccount).toBeDefined();
            expect(ourActiveAccount.needs_reauthentication).toBe(false);
        });
    });

    describe('setNeedsReauthentication', () => {
        it('testSetNeedsReauthentication_forItem_updatesFlagsOnAssociatedAccounts', async () => {
            const acc1 = await AccountRepository.saveAccount(testUser.id, accountData1.plaidItemId, accountData1.plaidAccessToken, accountData1.plaidAccountId, accountData1.accountName, accountData1.accountType, accountData1.institutionName);
            const acc2 = await AccountRepository.saveAccount(testUser.id, accountData2.plaidItemId, accountData2.plaidAccessToken, accountData2.plaidAccountId, accountData2.accountName, accountData2.accountType, accountData2.institutionName); // Same item_id
            const acc3 = await AccountRepository.saveAccount(testUser.id, accountData3.plaidItemId, accountData3.plaidAccessToken, accountData3.plaidAccountId, accountData3.accountName, accountData3.accountType, accountData3.institutionName); // Different item_id

            const updatedAccountsForItem1 = await AccountRepository.setNeedsReauthentication(accountData1.plaidItemId, true);
            expect(updatedAccountsForItem1).toBeDefined();
            expect(updatedAccountsForItem1.length).toBe(2);
            updatedAccountsForItem1.forEach(acc => expect(acc.needs_reauthentication).toBe(true));

            const acc1Updated = await AccountRepository.findAccountById(acc1.id);
            const acc2Updated = await AccountRepository.findAccountById(acc2.id);
            const acc3NotUpdated = await AccountRepository.findAccountById(acc3.id);

            expect(acc1Updated.needs_reauthentication).toBe(true);
            expect(acc2Updated.needs_reauthentication).toBe(true);
            expect(acc3NotUpdated.needs_reauthentication).toBe(false); // Should not have changed
        });
    });
});
