const BalanceSnapshotRepository = require('../repositories/BalanceSnapshotRepository');
const AccountRepository = require('../repositories/AccountRepository');
const UserRepository = require('../repositories/UserRepository');
const db = require('../db');

describe('BalanceSnapshotRepository', () => {
    let testUser;
    let testAccount;

    beforeAll(async () => {
        await UserRepository.deleteAllUsers();
        await AccountRepository.deleteAllAccounts();
        testUser = await UserRepository.createUser('snapshot_user@example.com', 'hashedpin');
        testAccount = await AccountRepository.saveAccount(
            testUser.id, 'item_snap', 'access_snap', 'acc_snap_id', 'Snapshot Test Account', 'depository', 'Bank Snap'
        );
    });

    beforeEach(async () => {
        await BalanceSnapshotRepository.deleteAllBalanceSnapshots();
    });

    afterAll(async () => {
        await BalanceSnapshotRepository.deleteAllBalanceSnapshots();
        await AccountRepository.deleteAllAccounts();
        await UserRepository.deleteAllUsers();
        await db.pool.end();
    });

    const formatDate = (date) => date.toISOString().split('T')[0];

    describe('saveSnapshot', () => {
        it('testSaveSnapshot_withValidData_savesSnapshot', async () => {
            const today = new Date();
            const balance = 1234.56;
            const snapshot = await BalanceSnapshotRepository.saveSnapshot(testAccount.id, balance, today);
            expect(snapshot).toBeDefined();
            expect(snapshot.id).toBeDefined();
            expect(snapshot.account_id).toBe(testAccount.id);
            expect(parseFloat(snapshot.balance)).toBe(balance);
            expect(formatDate(new Date(snapshot.snapshot_date))).toBe(formatDate(today));
        });

        it('should throw an error if saving a snapshot for the same account and date', async () => {
            const today = new Date();
            await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 1000.00, today);
            await expect(BalanceSnapshotRepository.saveSnapshot(testAccount.id, 2000.00, today))
                .rejects
                .toThrow('Snapshot for this account on this date already exists.');
        });
    });

    describe('getLatestSnapshotForAccount', () => {
        it('testGetLatestSnapshotForAccount_returnsCorrectSnapshot', async () => {
            const date1 = new Date('2023-01-01');
            const date2 = new Date('2023-01-02');
            await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 100.00, date1);
            const latestSaved = await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 200.00, date2);
            const found = await BalanceSnapshotRepository.getLatestSnapshotForAccount(testAccount.id);
            expect(found).toBeDefined();
            expect(found.id).toBe(latestSaved.id);
            expect(parseFloat(found.balance)).toBe(200.00);
        });

        it('should return null if no snapshots exist for the account', async () => {
            const found = await BalanceSnapshotRepository.getLatestSnapshotForAccount(testAccount.id);
            expect(found).toBeNull();
        });
    });

    describe('getSnapshotForAccountOnDate', () => {
        it('testGetSnapshotForAccountOnDate_returnsCorrectSnapshot', async () => {
            const date = new Date('2023-02-15');
            const saved = await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 300.00, date);
            await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 400.00, new Date('2023-02-16'));
            const found = await BalanceSnapshotRepository.getSnapshotForAccountOnDate(testAccount.id, date);
            expect(found).toBeDefined();
            expect(found.id).toBe(saved.id);
        });

        it('should return null if no snapshot exists for that specific date', async () => {
            const found = await BalanceSnapshotRepository.getSnapshotForAccountOnDate(testAccount.id, new Date('2000-01-01'));
            expect(found).toBeNull();
        });
    });

    describe('getFirstSnapshotForAccountInMonth', () => {
        it('testGetFirstSnapshotForAccountInMonth_returnsCorrectSnapshot', async () => {
            const firstInMonth = new Date('2023-03-05');
            const laterInMonth = new Date('2023-03-10');
            const differentMonth = new Date('2023-04-01');
            const savedFirst = await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 500.00, firstInMonth);
            await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 600.00, laterInMonth);
            await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 700.00, differentMonth);
            const found = await BalanceSnapshotRepository.getFirstSnapshotForAccountInMonth(testAccount.id, 2023, 3);
            expect(found).toBeDefined();
            expect(found.id).toBe(savedFirst.id);
            expect(parseFloat(found.balance)).toBe(500.00);
        });

        it('should return the snapshot if its the only one and on the 1st', async () => {
            const date = new Date('2023-05-01');
            const saved = await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 800.00, date);
            const found = await BalanceSnapshotRepository.getFirstSnapshotForAccountInMonth(testAccount.id, 2023, 5);
            expect(found.id).toBe(saved.id);
        });

        it('should return null if no snapshots exist in that month', async () => {
            await BalanceSnapshotRepository.saveSnapshot(testAccount.id, 900.00, new Date('2023-06-10'));
            const found = await BalanceSnapshotRepository.getFirstSnapshotForAccountInMonth(testAccount.id, 2023, 7);
            expect(found).toBeNull();
        });
    });
});