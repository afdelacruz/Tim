const UserRepositoryClass = require('../repositories/UserRepository');
const UserRepository = new UserRepositoryClass();
const db = require('../db'); // For direct pool access for teardown

describe('UserRepository', () => {
    beforeEach(async () => {
        // Clean the users table before each test in this suite
        await UserRepositoryClass.deleteAllUsers();
    });

    afterAll(async () => {
        // Ensure all users are cleaned up after the suite and close DB connection
        await UserRepositoryClass.deleteAllUsers();
        await db.pool.end();
    });

    describe('createUser', () => {
        it('testCreateUser_withValidData_savesUserCorrectly', async () => {
            const email = 'test@example.com';
            const pinHash = 'hashedpin123';
            const user = await UserRepository.createUser(email, pinHash);

            expect(user).toBeDefined();
            expect(user.id).toBeDefined();
            expect(user.email).toBe(email);
            expect(user.pin_hash).toBe(pinHash);
            expect(user.created_at).toBeInstanceOf(Date);
        });

        it('testCreateUser_withDuplicateEmail_throwsError', async () => {
            const email = 'duplicate@example.com';
            const pinHash = 'hashedpin123';
            await UserRepository.createUser(email, pinHash); // Create first user

            // Attempt to create another user with the same email
            await expect(UserRepository.createUser(email, 'anotherhash'))
                .rejects
                .toThrow('Email already exists');
        });
    });

    describe('findUserByEmail', () => {
        it('testFindUserByEmail_withExistingEmail_returnsUser', async () => {
            const email = 'findme@example.com';
            const pinHash = 'hashedpin456';
            const createdUser = await UserRepository.createUser(email, pinHash);

            const foundUser = await UserRepository.findUserByEmail(email);
            expect(foundUser).toBeDefined();
            expect(foundUser.id).toBe(createdUser.id);
            expect(foundUser.email).toBe(email);
        });

        it('testFindUserByEmail_withNonExistingEmail_returnsNullOrOptionalEmpty', async () => {
            const foundUser = await UserRepository.findUserByEmail('nonexistent@example.com');
            expect(foundUser).toBeNull();
        });
    });

    describe('findUserById', () => {
        it('should find an existing user by their ID', async () => {
            const email = 'findbyid@example.com';
            const pinHash = 'hashedpin789';
            const createdUser = await UserRepository.createUser(email, pinHash);

            const foundUser = await UserRepository.findUserById(createdUser.id);
            expect(foundUser).toBeDefined();
            expect(foundUser.id).toBe(createdUser.id);
            expect(foundUser.email).toBe(email);
        });

        it('should return null when trying to find a user by a non-existing ID', async () => {
            // Generate a random UUID that is unlikely to exist
            const nonExistentId = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
            const foundUser = await UserRepository.findUserById(nonExistentId);
            expect(foundUser).toBeNull();
        });
    });
});
