const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const UserRepositoryClass = require('../repositories/UserRepository');
const { AppError, handleRouteError } = require('../utils/errorHandler');
const { authenticateToken } = require('../utils/authMiddleware');

const router = express.Router();

const SALT_ROUNDS = 10;
// JWT secrets and expirations - now properly using environment variables
const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'your-default-access-secret';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-default-refresh-secret';
const JWT_ACCESS_EXPIRATION = process.env.JWT_ACCESS_EXPIRATION || '15m';
const JWT_REFRESH_EXPIRATION = process.env.JWT_REFRESH_EXPIRATION || '7d';

const userRepository = new UserRepositoryClass();

// POST /api/auth/register
router.post('/register', async (req, res, next) => {
    try {
        const { email, pin } = req.body;

        // Validation
        if (!email || !pin) {
            throw new AppError('Email and PIN are required.', 400, 'BAD_REQUEST');
        }

        if (!/^\d{4}$/.test(pin)) {
            throw new AppError('PIN must be 4 digits.', 400, 'INVALID_PIN_FORMAT');
        }

        // Check if user already exists
        const existingUser = await userRepository.findUserByEmail(email);
        if (existingUser) {
            throw new AppError('Email already registered.', 409, 'EMAIL_EXISTS');
        }

        // Create user
        const pinHash = await bcrypt.hash(pin, SALT_ROUNDS);
        const newUser = await userRepository.createUser(email, pinHash);

        // Exclude pin_hash from response
        const { pin_hash, ...userWithoutPin } = newUser;

        res.status(201).json({ 
            success: true, 
            message: 'User registered successfully', 
            user: userWithoutPin 
        });
    } catch (error) {
        handleRouteError(error, res, next);
    }
});

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
    try {
        const { email, pin } = req.body;

        // Validation
        if (!email || !pin) {
            throw new AppError('Email and PIN are required.', 400, 'BAD_REQUEST');
        }

        // Find user and verify credentials
        const user = await userRepository.findUserByEmail(email);
        if (!user) {
            throw new AppError('Invalid email or PIN.', 401, 'INVALID_CREDENTIALS');
        }

        const isPinValid = await bcrypt.compare(pin, user.pin_hash);
        if (!isPinValid) {
            throw new AppError('Invalid email or PIN.', 401, 'INVALID_CREDENTIALS');
        }

        // Generate tokens
        const accessTokenPayload = { sub: user.id, type: 'ACCESS' };
        const refreshTokenPayload = { sub: user.id, type: 'REFRESH' }; 

        const accessToken = jwt.sign(accessTokenPayload, JWT_ACCESS_SECRET, { expiresIn: JWT_ACCESS_EXPIRATION });
        const refreshToken = jwt.sign(refreshTokenPayload, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRATION });

        // Exclude pin_hash from response
        const { pin_hash, ...userWithoutPin } = user;

        res.json({
            success: true,
            accessToken,
            refreshToken,
            user: userWithoutPin
        });
    } catch (error) {
        handleRouteError(error, res, next);
    }
});

// POST /api/auth/refresh-token
router.post('/refresh-token', async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            throw new AppError('Refresh token is required.', 400, 'BAD_REQUEST');
        }

        // Verify refresh token
        const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);

        // Check token type
        if (decoded.type !== 'REFRESH') {
            throw new AppError('Invalid token type.', 401, 'INVALID_TOKEN');
        }

        // Verify user still exists
        const user = await userRepository.findUserById(decoded.sub);
        if (!user) {
            throw new AppError('User associated with token not found.', 401, 'INVALID_TOKEN');
        }

        // Issue new access token
        const accessTokenPayload = { sub: user.id, type: 'ACCESS' };
        const newAccessToken = jwt.sign(accessTokenPayload, JWT_ACCESS_SECRET, { expiresIn: JWT_ACCESS_EXPIRATION });

        res.json({
            success: true,
            accessToken: newAccessToken
        });
    } catch (error) {
        // Handle JWT-specific errors
        if (error instanceof jwt.TokenExpiredError) {
            return handleRouteError(new AppError('Refresh token has expired.', 401, 'TOKEN_EXPIRED'), res, next);
        }
        if (error instanceof jwt.JsonWebTokenError) {
            return handleRouteError(new AppError('Invalid refresh token.', 401, 'INVALID_TOKEN'), res, next);
        }
        
        handleRouteError(error, res, next);
    }
});

// GET /api/auth/me - Get current user info (protected route)
router.get('/me', authenticateToken, async (req, res, next) => {
    try {
        // User is already attached to req.user by authenticateToken middleware
        res.json({
            success: true,
            user: req.user
        });
    } catch (error) {
        handleRouteError(error, res, next);
    }
});

module.exports = router;
