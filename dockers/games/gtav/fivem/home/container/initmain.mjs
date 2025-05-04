#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { access, appendFile, chmod } from 'node:fs/promises';
import { existsSync, mkdirSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

// Constants
const BASE = '/opt/cfx-server';
const FX_BIN = resolve(BASE, 'FXServer');
const LOG_DIR = resolve(BASE, 'logs');
const LOG_FILE = resolve(LOG_DIR, 'init.log');

// Console Colors
const color = {
    reset: '\x1b[0m', bold: '\x1b[1m',
    red: '\x1b[1;31m', green: '\x1b[1;32m',
    yellow: '\x1b[1;33m', cyan: '\x1b[36m'
};

// Logging
mkdirSync(LOG_DIR, { recursive: true });
async function log(msg, clr = color.reset) {
    console.log(`${clr}${msg}${color.reset}`);
    await appendFile(LOG_FILE, `[${new Date().toISOString()}] ${msg}\n`).catch(() => {});
}

// Main startup
(async () => {
    await log('==========================================', color.cyan);
    await log('  [*] DMS FiveM Node Entrypoint Launcher  ', color.cyan);
    await log('==========================================\n', color.cyan);

    if (!existsSync(FX_BIN)) {
        await log(`[✖] FXServer binary missing: ${FX_BIN}`, color.red);
        process.exit(1);
    }

    try {
        await access(FX_BIN);
        await chmod(FX_BIN, 0o755);
        await log(`[✔] FXServer ready: ${FX_BIN}`, color.green);
    } catch (err) {
        await log(`[✖] FXServer not executable: ${err}`, color.red);
        process.exit(1);
    }

    // Debug: show directory contents before launch
    await log('[*] Listing cfx-server dir before spawn:', color.yellow);
    for (const file of readdirSync(BASE)) console.log(`- ${file}`);

    // Construct FiveM args
    const fxArgs = [
        '+exec', 'server.cfg',
        '+set', 'sv_licenseKey', process.env.FIVEM_LICENSE ?? '',
        '+set', 'steam_webApiKey', process.env.STEAM_WEBAPIKEY ?? '',
        '+set', 'onesync', process.env.ONESYNC ?? 'on',
        '+set', 'txAdminEnabled', process.env.TXADMIN_ENABLE ?? '1',
        '+set', 'txAdminPort', process.env.TXADMIN_PORT ?? '40120',
        '+set', 'sv_maxclients', process.env.MAX_PLAYERS ?? '32',
        '+set', 'sv_enforceGameBuild', process.env.GAME_BUILD_NUMBER ?? '',
        '+sets', 'sv_projectName', process.env.PROJECT_NAME ?? 'Darkmatter Server',
        '+sets', 'sv_projectDesc', process.env.PROJECT_DESCRIPTION ?? 'Welcome to Darkmatter!'
    ];

    await log(`[*] Starting FXServer (PID handoff): ${FX_BIN}`, color.cyan);
    const fx = spawn(FX_BIN, fxArgs, { stdio: 'inherit' });

    fx.on('error', async err => {
        await log(`[✖] Spawn failed: ${err.message}`, color.red);
        process.exit(1);
    });

    fx.on('exit', async code => {
        await log(`[!] FXServer exited with code ${code}`, code === 0 ? color.green : color.red);
        process.exit(code);
    });
})();
