const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const UserRepositoryClass = require('../repositories/UserRepository');
const router = express.Router();

const SALT_ROUNDS = 10;
// TODO: Move JWT secrets and expirations to .env
const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'your-default-access-secret'; // Replace with a strong secret
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-default-refresh-secret'; // Replace with a strong secret
const JWT_ACCESS_EXPIRATION = '15m'; // e.g., 15 minutes
const JWT_REFRESH_EXPIRATION = '7d'; // e.g., 7 days

const userRepository = new UserRepositoryClass();

// POST /api/auth/register
router.post('/register', async (req, res, next) => {
    const { email, pin } = req.body;

    // Basic validation
    if (!email || !pin) {
        return res.status(400).json({
            success: false,
            error: { code: 'BAD_REQUEST', message: 'Email and PIN are required.' }
        });
    }

    // Validate PIN format (e.g., 4 digits)
    if (!/^\d{4}$/.test(pin)) {
        return res.status(400).json({
            success: false,
            error: { code: 'INVALID_PIN_FORMAT', message: 'PIN must be 4 digits.' }
        });
    }

    try {
        const existingUser = await userRepository.findUserByEmail(email);
        if (existingUser) {
            return res.status(409).json({ // 409 Conflict
                success: false,
                error: { code: 'EMAIL_EXISTS', message: 'Email already registered.' }
            });
        }

        const pinHash = await bcrypt.hash(pin, SALT_ROUNDS);
        const newUser = await userRepository.createUser(email, pinHash);

        // Exclude pin_hash from the response
        const { pin_hash, ...userWithoutPin } = newUser;

        res.status(201).json({ 
            success: true, 
            message: 'User registered successfully', 
            user: userWithoutPin 
        });
    } catch (error) {
        // if (error.message === 'Email already exists') { // This check is now done above
        //     return res.status(409).json({ 
        //         success: false,
        //         error: { code: 'EMAIL_EXISTS', message: 'Email already registered.' }
        //     });
        // }
        next(error); // Pass other errors to the global error handler
    }
});

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
    const { email, pin } = req.body;

    if (!email || !pin) {
        return res.status(400).json({
            success: false,
            error: { code: 'BAD_REQUEST', message: 'Email and PIN are required.' }
        });
    }

    try {
        const user = await userRepository.findUserByEmail(email);
        if (!user) {
            return res.status(401).json({
                success: false,
                error: { code: 'INVALID_CREDENTIALS', message: 'Invalid email or PIN.' }
            });
        }

        const isPinValid = await bcrypt.compare(pin, user.pin_hash);
        if (!isPinValid) {
            return res.status(401).json({
                success: false,
                error: { code: 'INVALID_CREDENTIALS', message: 'Invalid email or PIN.' }
            });
        }

        // User authenticated, generate tokens
        const accessTokenPayload = { sub: user.id, type: 'ACCESS' };
        const refreshTokenPayload = { sub: user.id, type: 'REFRESH' }; 

        const accessToken = jwt.sign(accessTokenPayload, JWT_ACCESS_SECRET, { expiresIn: JWT_ACCESS_EXPIRATION });
        const refreshToken = jwt.sign(refreshTokenPayload, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRATION });

        // Exclude pin_hash from the user object in response
        const userResponse = { ...user };
        delete userResponse.pin_hash;

        res.json({
            success: true,
            accessToken,
            refreshToken,
            user: userResponse
        });

    } catch (error) {
        next(error);
    }
});

// POST /api/auth/refresh-token
router.post('/refresh-token', async (req, res, next) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(400).json({
            success: false,
            error: { code: 'BAD_REQUEST', message: 'Refresh token is required.' }
        });
    }

    try {
        const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);

        // Check if the token type is REFRESH
        if (decoded.type !== 'REFRESH') {
             return res.status(401).json({
                success: false,
                error: { code: 'INVALID_TOKEN', message: 'Invalid token type.' }
            });
        }

        const user = await userRepository.findUserById(decoded.sub);
        if (!user) {
            return res.status(401).json({
                success: false,
                error: { code: 'USER_NOT_FOUND', message: 'User associated with token not found.' }
            });
        }

        // Issue new access token
        const accessTokenPayload = { sub: user.id, type: 'ACCESS' };
        const newAccessToken = jwt.sign(accessTokenPayload, JWT_ACCESS_SECRET, { expiresIn: JWT_ACCESS_EXPIRATION });

        res.json({
            success: true,
            accessToken: newAccessToken
        });

    } catch (error) {
        // Handle JWT errors (e.g., expired, invalid signature)
        if (error instanceof jwt.TokenExpiredError) {
            return res.status(401).json({
                success: false,
                error: { code: 'TOKEN_EXPIRED', message: 'Refresh token has expired.' }
            });
        }
        if (error instanceof jwt.JsonWebTokenError) {
            return res.status(401).json({
                success: false,
                error: { code: 'INVALID_TOKEN', message: 'Invalid refresh token.' }
            });
        }
        next(error); // Pass other errors to global error handler
    }
});

// Placeholder for GET /api/auth/me
router.get('/me', (req, res) => {
    res.status(501).json({ message: 'Me endpoint not implemented yet' });
});

module.exports = router;
