const request = require('supertest');
const app = require('../server'); // Our Express app
const UserRepositoryClass = require('../repositories/UserRepository');
const UserRepository = new UserRepositoryClass();
const db = require('../db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

describe('Auth Routes - /api/auth', () => {
    // Note: No top-level beforeEach here.
    // Cleanup for users created by these specific auth tests is handled by
    // the beforeEach within each nested describe block, and the afterAll for the suite.

    afterAll(async () => {
        // Clean up users potentially created by any auth tests and close DB connection
        await UserRepositoryClass.deleteAllUsers();
        await db.pool.end();
    });

    describe('POST /register', () => {
        // beforeEach for /register tests: ensure a clean slate for users
        beforeEach(async () => {
            await UserRepositoryClass.deleteAllUsers();
        });

        const validUserData = { email: 'test@example.com', pin: '1234' };
        const invalidPinUserData = { email: 'testpin@example.com', pin: '123' }; // Invalid PIN
        const noEmailUserData = { pin: '5678' };
        const noPinUserData = { email: 'testnopin@example.com' };

        it('should register a new user with valid data and return 201', async () => {
            const response = await request(app)
                .post('/api/auth/register')
                .send(validUserData);

            expect(response.statusCode).toBe(201);
            expect(response.body.success).toBe(true);
            expect(response.body.message).toBe('User registered successfully');
            expect(response.body.user).toBeDefined();
            expect(response.body.user.email).toBe(validUserData.email);
            expect(response.body.user.id).toBeDefined();
            expect(response.body.user.pin_hash).toBeUndefined();

            const dbUser = await UserRepository.findUserByEmail(validUserData.email);
            expect(dbUser).toBeDefined();
            expect(dbUser.email).toBe(validUserData.email);
            const isPinValid = await bcrypt.compare(validUserData.pin, dbUser.pin_hash);
            expect(isPinValid).toBe(true);
        });

        it('should return 409 if email already exists', async () => {
            await request(app).post('/api/auth/register').send(validUserData);
            const response = await request(app)
                .post('/api/auth/register')
                .send({ ...validUserData, pin: '4321' });

            expect(response.statusCode).toBe(409);
            expect(response.body.success).toBe(false);
            expect(response.body.error.code).toBe('EMAIL_EXISTS');
        });

        it('should return 400 if PIN is not 4 digits', async () => {
            const response = await request(app)
                .post('/api/auth/register')
                .send(invalidPinUserData);
            
            expect(response.statusCode).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.error.code).toBe('INVALID_PIN_FORMAT');
        });

        it('should return 400 if email is missing', async () => {
            const response = await request(app).post('/api/auth/register').send(noEmailUserData);
            expect(response.statusCode).toBe(400);
            expect(response.body.error.code).toBe('BAD_REQUEST');
        });

        it('should return 400 if PIN is missing', async () => {
            const response = await request(app).post('/api/auth/register').send(noPinUserData);
            expect(response.statusCode).toBe(400);
            expect(response.body.error.code).toBe('BAD_REQUEST');
        });
    });

    describe('POST /login', () => {
        const loginTestUser = { email: 'logintest.auth@example.com', pin: '1234' };

        beforeEach(async () => {
            // Delete only the specific test user if it exists, then recreate
            await UserRepositoryClass.deleteUserByEmail(loginTestUser.email);
            const hashedPin = await bcrypt.hash(loginTestUser.pin, 10);
            await UserRepository.createUser(loginTestUser.email, hashedPin);
        });

        it('should login an existing user with valid credentials and return tokens', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({ email: loginTestUser.email, pin: loginTestUser.pin });

            expect(response.statusCode).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.accessToken).toBeDefined();
            expect(response.body.refreshToken).toBeDefined();
            expect(response.body.user).toBeDefined();
            expect(response.body.user.email).toBe(loginTestUser.email);
            expect(response.body.user.pin_hash).toBeUndefined();
        });

        it('should return 401 for an unregistered email', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({ email: 'nouser@example.com', pin: '1234' });

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('INVALID_CREDENTIALS');
        });

        it('should return 401 for an incorrect PIN', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({ email: loginTestUser.email, pin: '0000' });

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('INVALID_CREDENTIALS');
        });

        it('should return 400 if email is missing', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({ pin: '1234' });
            
            expect(response.statusCode).toBe(400);
            expect(response.body.error.code).toBe('BAD_REQUEST');
        });

        it('should return 400 if PIN is missing', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({ email: loginTestUser.email });

            expect(response.statusCode).toBe(400);
            expect(response.body.error.code).toBe('BAD_REQUEST');
        });
    });

    describe('POST /refresh-token', () => {
        const refreshTestUser = { email: 'refreshtest.auth@example.com', pin: '1234' };
        let validRefreshToken;
        let userId;

        beforeEach(async () => {
            await UserRepositoryClass.deleteUserByEmail(refreshTestUser.email);
            const hashedPin = await bcrypt.hash(refreshTestUser.pin, 10);
            const user = await UserRepository.createUser(refreshTestUser.email, hashedPin);
            userId = user.id;

            const loginResponse = await request(app)
                .post('/api/auth/login')
                .send(refreshTestUser);
            validRefreshToken = loginResponse.body.refreshToken;
        });

        it('should return a new access token with a valid refresh token', async () => {
            const response = await request(app)
                .post('/api/auth/refresh-token')
                .send({ refreshToken: validRefreshToken });

            expect(response.statusCode).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.accessToken).toBeDefined();

            try {
                const decoded = jwt.verify(response.body.accessToken, process.env.JWT_ACCESS_SECRET || 'your-default-access-secret');
                expect(decoded.sub).toBe(userId);
                expect(decoded.type).toBe('ACCESS');
            } catch (err) {
                throw new Error('New access token is invalid or could not be verified: ' + err.message);
            }
        });

        it('should return 401 if refresh token is expired', async () => {
            const expiredToken = jwt.sign(
                { sub: userId, type: 'REFRESH' }, 
                process.env.JWT_REFRESH_SECRET || 'your-default-refresh-secret', 
                { expiresIn: '-1s' } 
            );

            const response = await request(app)
                .post('/api/auth/refresh-token')
                .send({ refreshToken: expiredToken });

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('TOKEN_EXPIRED');
        });

        it('should return 401 if refresh token is invalid (e.g., wrong secret, malformed)', async () => {
            const response = await request(app)
                .post('/api/auth/refresh-token')
                .send({ refreshToken: 'invalid.token.string' });

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('INVALID_TOKEN');
        });

        it('should return 401 if refresh token is an access token type', async () => {
            const accessTokenAsRefreshToken = jwt.sign(
                { sub: userId, type: 'ACCESS' }, 
                process.env.JWT_REFRESH_SECRET || 'your-default-refresh-secret',
                { expiresIn: '1h' }
            );
            const response = await request(app)
                .post('/api/auth/refresh-token')
                .send({ refreshToken: accessTokenAsRefreshToken });
            
            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('INVALID_TOKEN'); 
        });

        it('should return 400 if refresh token is missing', async () => {
            const response = await request(app).post('/api/auth/refresh-token').send({});
            expect(response.statusCode).toBe(400);
            expect(response.body.error.code).toBe('BAD_REQUEST');
        });
    });

    describe('GET /me', () => {
        const meTestUser = { email: 'metest.auth@example.com', pin: '1234' };
        let validAccessToken;
        let userId;

        beforeEach(async () => {
            await UserRepositoryClass.deleteUserByEmail(meTestUser.email);
            const hashedPin = await bcrypt.hash(meTestUser.pin, 10);
            const user = await UserRepository.createUser(meTestUser.email, hashedPin);
            userId = user.id;

            const loginResponse = await request(app)
                .post('/api/auth/login')
                .send(meTestUser);
            validAccessToken = loginResponse.body.accessToken;
        });

        it('should return current user info with valid access token', async () => {
            const response = await request(app)
                .get('/api/auth/me')
                .set('Authorization', `Bearer ${validAccessToken}`);

            expect(response.statusCode).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.user).toBeDefined();
            expect(response.body.user.id).toBe(userId);
            expect(response.body.user.email).toBe(meTestUser.email);
            expect(response.body.user.pin_hash).toBeUndefined();
        });

        it('should return 401 if no authorization header is provided', async () => {
            const response = await request(app).get('/api/auth/me');

            expect(response.statusCode).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.error.code).toBe('MISSING_TOKEN');
        });

        it('should return 401 if authorization header is malformed', async () => {
            const response = await request(app)
                .get('/api/auth/me')
                .set('Authorization', 'InvalidFormat');

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('MISSING_TOKEN');
        });

        it('should return 401 if access token is expired', async () => {
            const expiredToken = jwt.sign(
                { sub: userId, type: 'ACCESS' },
                process.env.JWT_ACCESS_SECRET || 'your-default-access-secret',
                { expiresIn: '-1s' }
            );

            const response = await request(app)
                .get('/api/auth/me')
                .set('Authorization', `Bearer ${expiredToken}`);

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('TOKEN_EXPIRED');
        });

        it('should return 401 if access token has invalid signature', async () => {
            const invalidToken = jwt.sign(
                { sub: userId, type: 'ACCESS' },
                'wrong-secret',
                { expiresIn: '15m' }
            );

            const response = await request(app)
                .get('/api/auth/me')
                .set('Authorization', `Bearer ${invalidToken}`);

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('INVALID_TOKEN');
        });

        it('should return 401 if refresh token is used instead of access token', async () => {
            const refreshToken = jwt.sign(
                { sub: userId, type: 'REFRESH' },
                process.env.JWT_ACCESS_SECRET || 'your-default-access-secret',
                { expiresIn: '7d' }
            );

            const response = await request(app)
                .get('/api/auth/me')
                .set('Authorization', `Bearer ${refreshToken}`);

            expect(response.statusCode).toBe(401);
            expect(response.body.error.code).toBe('INVALID_TOKEN_TYPE');
        });
    });
});
