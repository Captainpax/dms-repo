#!/usr/bin/env node
import { execFile, exec } from 'node:child_process';
import {
    access, chmod, mkdir, readFile, writeFile,
    cp as copyDir, rm, appendFile
} from 'node:fs/promises';
import { existsSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { platform } from 'node:os';
import { createInterface } from 'node:readline/promises';
import process from 'node:process';
import tar from 'tar';
import { promisify } from 'node:util';

const execAsync = promisify(exec);

// === Constants ===
const INSTALL_BASE = '/home/container';
const INSTALL_DIR = resolve(INSTALL_BASE, 'opt/cfx-server');
const FXSERVER_BIN = resolve(INSTALL_DIR, 'FXServer');
const SERVER_TEMPLATE = resolve(INSTALL_BASE, 'server.cfg');
const SERVER_TARGET = resolve(INSTALL_DIR, 'server.cfg');
const RESOURCES_DIR = resolve(INSTALL_BASE, 'resources');
const LOG_FILE = resolve(INSTALL_BASE, 'logs/init.log');

const ARCHIVE_LINUX = resolve(INSTALL_BASE, 'linux.tar.xz');
const ARCHIVE_WINDOWS = resolve(INSTALL_BASE, 'windows.7z');

// === Console Colors ===
const color = {
    reset: '\x1b[0m',
    bold: '\x1b[1m',
    cyan: '\x1b[36m',
    green: '\x1b[1;32m',
    yellow: '\x1b[1;33m',
    red: '\x1b[1;31m',
    blue: '\x1b[1;34m',
};

// Create logs folder if it doesn't exist
mkdirSync(resolve(INSTALL_BASE, 'logs'), { recursive: true });

/**
 * Writes log messages to both console and logs/init.log
 * @param {string} msg - Message to print
 * @param {string} [clr] - Optional ANSI color
 */
async function log(msg, clr = color.reset) {
    console.log(`${clr}${msg}${color.reset}`);
    try {
        await appendFile(LOG_FILE, `[${new Date().toISOString()}] ${msg}\n`);
    } catch {
        console.warn('⚠️ Failed to write to init.log');
    }
}

/**
 * Prompt for env var if missing
 */
async function promptMissing(varName, prompt, fallback = '') {
    if (!process.env[varName]) {
        const rl = createInterface({ input: process.stdin, output: process.stdout });
        const val = await rl.question(`${prompt}${fallback ? ` [${fallback}]` : ''}: `);
        rl.close();
        process.env[varName] = val || fallback;
    }
}

/**
 * Extracts the correct FXServer archive depending on host OS
 */
async function extractFXServer() {
    const isWindows = platform() === 'win32';

    await log(`[*] Host platform: ${platform()}`, color.cyan);
    await log(`[*] Preparing to extract FXServer for ${isWindows ? 'Windows' : 'Linux'}...`, color.blue);

    if (isWindows) {
        if (!existsSync(ARCHIVE_WINDOWS)) {
            await log(`[-] windows.7z not found at ${ARCHIVE_WINDOWS}`, color.red);
            process.exit(1);
        }
        await log('[*] Extracting windows.7z with 7z...', color.blue);
        try {
            await execAsync(`7z x "${ARCHIVE_WINDOWS}" -o"${INSTALL_DIR}" -y`);
        } catch (err) {
            await log(`[-] Failed to extract windows.7z: ${err}`, color.red);
            process.exit(1);
        }
    } else {
        const tarPath = ARCHIVE_LINUX.replace(/\.xz$/, '');
        if (!existsSync(ARCHIVE_LINUX)) {
            await log(`[-] linux.tar.xz not found at ${ARCHIVE_LINUX}`, color.red);
            process.exit(1);
        }

        await log('[*] Decompressing linux.tar.xz with xz...', color.blue);
        try {
            await execAsync(`xz -d -k "${ARCHIVE_LINUX}"`);
        } catch (err) {
            await log(`[-] Failed to decompress: ${err}`, color.red);
            process.exit(1);
        }

        await log('[*] Extracting linux.tar...', color.blue);
        await mkdir(INSTALL_DIR, { recursive: true });
        try {
            await tar.x({
                file: tarPath,
                cwd: INSTALL_DIR,
                strict: true,
            });
        } catch (err) {
            await log(`[-] Failed to extract linux.tar: ${err}`, color.red);
            process.exit(1);
        }

        const nested = resolve(INSTALL_DIR, 'alpine/opt/cfx-server');
        if (existsSync(nested)) {
            await log('[*] Detected nested structure — flattening...', color.yellow);
            await copyDir(nested, INSTALL_DIR, { recursive: true });
            await rm(resolve(INSTALL_DIR, 'alpine'), { recursive: true, force: true });
        }
    }

    await log('[+] FXServer extracted successfully.', color.green);
}

/**
 * Ensures FXServer is ready and executable
 */
async function verifyFXServerBinary() {
    if (!existsSync(FXSERVER_BIN)) {
        await log('[*] FXServer not found — extracting...', color.yellow);
        await extractFXServer();
    }

    try {
        await access(FXSERVER_BIN);
        if (platform() !== 'win32') {
            try {
                await execAsync(`find "${INSTALL_DIR}" -type f -iname FXServer -exec chmod +x {} \\;`);
                await log('[+] FXServer binary permissions set (chmod +x)', color.green);
            } catch {
                await log('[!] Warning: Failed to chmod FXServer. It may not be executable.', color.yellow);
            }
        }
        await log(`[✔] FXServer binary ready: ${FXSERVER_BIN}`, color.green);
    } catch {
        await log(`[-] FXServer binary still missing or not executable at ${FXSERVER_BIN}`, color.red);
        process.exit(1);
    }
}

/**
 * Renders server.cfg using env vars
 */
async function renderServerCfg() {
    if (!existsSync(SERVER_TEMPLATE)) {
        await log(`[!] Warning: server.cfg not found at ${SERVER_TEMPLATE}`, color.red);
        return;
    }

    await log('[*] Rendering server.cfg...', color.blue);
    let cfg = await readFile(SERVER_TEMPLATE, 'utf8');

    const vars = [
        'FIVEM_PORT', 'SERVER_HOSTNAME', 'PROJECT_NAME', 'PROJECT_DESCRIPTION',
        'MAX_PLAYERS', 'FIVEM_LICENSE', 'STEAM_WEBAPIKEY', 'RCON_PASSWORD',
        'GAME_BUILD', 'ONESYNC_STATE', 'TXADMIN_PORT', 'TXADMIN_ENABLE'
    ];

    for (const name of vars) {
        cfg = cfg.replaceAll(new RegExp(`\\$\\{?${name}\\}?`, 'g'), process.env[name] || '');
    }

    await writeFile(SERVER_TARGET, cfg);
    await log('[+] server.cfg rendered successfully.', color.green);
}

/**
 * Starts FXServer with basic +exec command and pipes output
 */
async function launchFXServer() {
    const cmd = [FXSERVER_BIN, '+exec', 'server.cfg'];
    await log(`[*] Launching FXServer:`, color.cyan);
    console.log(`${color.bold}:/home/container$ ${cmd.join(' ')}${color.reset}\n`);

    const child = execFile(cmd[0], cmd.slice(1));

    child.stdout?.pipe(process.stdout);
    child.stderr?.pipe(process.stderr);

    child.on('exit', async code => {
        await log(`[!] FXServer exited with code ${code}`, code === 0 ? color.green : color.red);
        process.exit(code);
    });
}

// === MAIN ===
(async () => {
    await log('==========================================', color.cyan);
    await log('  [*] DMS FiveM Node Entrypoint Launcher  ', color.cyan);
    await log('==========================================\n', color.cyan);

    await promptMissing('FIVEM_LICENSE', 'Enter your FiveM License Key');
    await promptMissing('STEAM_WEBAPIKEY', 'Enter your Steam Web API Key', 'changeme');
    await promptMissing('ONESYNC_STATE', 'Enable OneSync? (on/off)', 'on');
    await promptMissing('PROJECT_NAME', 'Enter Project Name', 'Darkmatter Server');
    await promptMissing('PROJECT_DESCRIPTION', 'Enter Project Description', 'Welcome to Darkmatter!');
    await promptMissing('TXADMIN_PORT', 'Enter txAdmin Port', '40120');
    await promptMissing('TXADMIN_ENABLE', 'Enable txAdmin? (1 = yes, 0 = no)', '1');
    await promptMissing('FIVEM_PORT', 'Enter base FiveM port', '30120');
    if (!process.env.GAME_BUILD) {
        const rl = createInterface({ input: process.stdin, output: process.stdout });
        process.env.GAME_BUILD = await rl.question('Enter Game Build Number (or leave blank): ');
        rl.close();
    }

    await verifyFXServerBinary();
    await renderServerCfg();

    if (!existsSync(RESOURCES_DIR)) {
        await log(`[!] Warning: resources/ folder missing`, color.yellow);
    }

    await launchFXServer();
})();