#!/usr/bin/env node
import { exec, spawn } from 'node:child_process';
import { mkdir, chmod, cp as copy, rm, appendFile } from 'node:fs/promises';
import { existsSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { platform } from 'node:os';
import { promisify } from 'node:util';

const execAsync = promisify(exec);

// === Paths ===
const BASE = '/home/container';
const FX_DIR = resolve(BASE, 'opt/cfx-server');
const FX_BIN = resolve(FX_DIR, 'FXServer');
const ARCHIVE = resolve(BASE, 'linux.tar.xz');
const LOG_FILE = resolve(BASE, 'logs/init.log');

// === Colors ===
const color = {
    reset: '\x1b[0m', bold: '\x1b[1m',
    red: '\x1b[1;31m', green: '\x1b[1;32m',
    yellow: '\x1b[1;33m', blue: '\x1b[1;34m',
    cyan: '\x1b[36m'
};

// === Logging ===
mkdirSync(resolve(BASE, 'logs'), { recursive: true });
async function log(msg, clr = color.reset) {
    console.log(`${clr}${msg}${color.reset}`);
    await appendFile(LOG_FILE, `[${new Date().toISOString()}] ${msg}\n`).catch(() => {});
}
function exitError(msg) {
    log(`[-] ${msg}`, color.red).then(() => process.exit(1));
}

// === Extract FXServer if not ready ===
async function extractFX() {
    await log(`[*] Extracting FXServer for ${platform()}...`, color.cyan);
    if (!existsSync(ARCHIVE)) exitError(`Missing archive: ${ARCHIVE}`);
    const tarPath = ARCHIVE.replace(/\.xz$/, '');

    try {
        await execAsync(`xz -d -k "${ARCHIVE}"`);
        await mkdir(FX_DIR, { recursive: true });
        await execAsync(`tar -xf "${tarPath}" -C "${FX_DIR}"`);
    } catch (err) {
        exitError(`Extraction failed: ${err}`);
    }

    const nested = resolve(FX_DIR, 'alpine/opt/cfx-server');
    if (existsSync(nested)) {
        await log('[*] Flattening nested structure...', color.yellow);
        await copy(nested, FX_DIR, { recursive: true });
        await rm(resolve(FX_DIR, 'alpine'), { recursive: true, force: true });
    }

    await log('[+] FXServer extracted.', color.green);
}

// === Verify and Launch FXServer ===
async function startFX() {
    if (!existsSync(FX_BIN)) {
        await log('[*] FXServer not found — extracting...', color.yellow);
        await extractFX();
    }

    try {
        await chmod(FX_BIN, 0o755);
        await log(`[✔] FXServer ready: ${FX_BIN}`, color.green);
    } catch {
        exitError(`FXServer not executable at ${FX_BIN}`);
    }

    await log(`[*] Starting FXServer (PID handoff)...`, color.cyan);
    const fx = spawn(FX_BIN, [], { stdio: 'inherit' });

    fx.on('exit', code => {
        log(`[!] FXServer exited with code ${code}`, code === 0 ? color.green : color.red)
            .finally(() => process.exit(code));
    });
}

// === Run ===
(async () => {
    await log('==========================================', color.cyan);
    await log('  [*] DMS FiveM Node Entrypoint Launcher  ', color.cyan);
    await log('==========================================\n', color.cyan);
    await startFX();
})();