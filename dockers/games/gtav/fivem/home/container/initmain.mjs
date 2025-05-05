#!/usr/bin/env node
/**
 * @file initmain.mjs
 * @version 4.9.0
 * @description
 *   DMS FXServer Bootstrapper (setup, firstBoot, start) with correct
 *   extraction from FiveM’s proot Alpine artifact.
 */

import { spawn } from 'node:child_process';
import {
    createWriteStream,
    createReadStream,
    existsSync,
    mkdirSync,
    readdirSync,
    statSync,
    renameSync,
    rmSync,
    readFileSync
} from 'node:fs';
import { access, appendFile, chmod } from 'node:fs/promises';
import { resolve, relative } from 'node:path';
import { networkInterfaces } from 'node:os';
import { get } from 'https';
import { pipeline } from 'node:stream/promises';
import lzma from 'lzma-native';
import * as tar from 'tar';

/** Paths **/
const HOME      = '/home/container';
const BASE      = resolve(HOME, 'opt/cfx-server');
const EXTRACTED = resolve(BASE, 'extracted');
const FX_BIN    = resolve(BASE, 'FXServer');
const LOG_DIR   = resolve(BASE, 'logs');
const LOG_FILE  = resolve(LOG_DIR, 'init.log');
const TXADMIN_DIR    = process.env.TXADMIN_PROFILE_DIR ||= resolve(HOME, 'txData');
const SETUP_MARKER   = resolve(LOG_DIR, '.dms_setup_complete');
const FIRSTBOOT_MARKER = resolve(LOG_DIR, '.dms_firstboot_complete');

/** Artifact **/
const BUILD_ID    = '7290';
const ARTIFACT_URL = `https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${BUILD_ID}-a654bcc2adfa27c4e020fc915a1a6343c3b4f921/fx.tar.xz`;

/** CLI args & colors **/
const ARGS = process.argv.slice(2);
const color = {
    reset: '\x1b[0m',
    bold:  '\x1b[1m',
    red:   '\x1b[1;31m',
    green: '\x1b[1;32m',
    yellow:'\x1b[1;33m',
    cyan:  '\x1b[36m',
    magenta:'\x1b[35m'
};

/** Logger **/
async function log(msg, clr = color.reset) {
    const line = `[${new Date().toISOString()}] ${msg}`;
    console.log(`${clr}${line}${color.reset}`);
    try { await appendFile(LOG_FILE, line + '\n'); } catch {}
}

/** Helpers **/
function getBestIPAddress() {
    for (const addrs of Object.values(networkInterfaces())) {
        for (const net of addrs) {
            if (net.family==='IPv4' && !net.internal) return net.address;
        }
    }
    return '127.0.0.1';
}
function downloadFile(url, dest) {
    return new Promise((res, rej) => {
        const f = createWriteStream(dest);
        get(url, r => {
            if (r.statusCode!==200) return rej(new Error(`HTTP ${r.statusCode}`));
            r.pipe(f);
            f.on('finish', ()=>f.close(res));
        }).on('error', rej);
    });
}
/**
 * Recursively find the FXServer root inside the proot tree.
 * @param {string} dir
 * @returns {string|null} path to directory containing FXServer
 */
function findFXRoot(dir) {
    if (existsSync(resolve(dir, 'opt/cfx-server/FXServer'))) {
        return resolve(dir, 'opt/cfx-server');
    }
    for (const name of readdirSync(dir)) {
        const full = resolve(dir, name);
        if (statSync(full).isDirectory()) {
            const found = findFXRoot(full);
            if (found) return found;
        }
    }
    return null;
}

/** ========== SETUP MODE ========== */
async function runSetup() {
    mkdirSync(LOG_DIR, { recursive:true });
    await log('🛠️  SETUP: download & extract FXServer…', color.cyan);

    if (existsSync(SETUP_MARKER)) {
        return log('✔ Already setup—skipping.', color.yellow);
    }

    // prepare directories
    mkdirSync(BASE, { recursive:true });
    mkdirSync(TXADMIN_DIR, { recursive:true });
    rmSync(EXTRACTED, { recursive:true, force:true });
    mkdirSync(EXTRACTED, { recursive:true });

    const archive = resolve(BASE, 'fx.tar.xz');
    await log(`↓ Downloading build ${BUILD_ID}…`, color.magenta);
    await downloadFile(ARTIFACT_URL, archive);
    await log(`✓ Downloaded to ${archive}`, color.green);

    const size = statSync(archive).size;
    await log(`ℹ Size: ${size} bytes`, color.yellow);
    const head = readFileSync(archive).slice(0, 16);
    await log(`🔍 Head: ${head.toString('hex').match(/../g).join(' ')}`, color.magenta);

    await log(`⇪ Extracting into ${relative(HOME, EXTRACTED)}…`, color.cyan);
    try {
        await pipeline(
            createReadStream(archive),
            lzma.createDecompressor(),
            tar.extract({ cwd: EXTRACTED })
        );
    } catch (e) {
        await log(`❌ Extraction error: ${e.message}`, color.red);
        process.exit(1);
    }

    // locate FXServer subtree
    const fxRoot = findFXRoot(EXTRACTED);
    if (!fxRoot) {
        await log(`❌ Could not locate opt/cfx-server in ${relative(HOME, EXTRACTED)}`, color.red);
        process.exit(1);
    }
    await log(`ℹ Found cfx folder at ${relative(HOME, fxRoot)}`, color.yellow);

    // move its contents into BASE
    for (const entry of readdirSync(fxRoot)) {
        renameSync(resolve(fxRoot, entry), resolve(BASE, entry));
    }

    // cleanup
    rmSync(archive);
    rmSync(EXTRACTED, { recursive:true, force:true });

    if (!existsSync(FX_BIN)) {
        await log(`❌ FXServer not found at ${relative(HOME, FX_BIN)}`, color.red);
        process.exit(1);
    }
    await chmod(FX_BIN, 0o755);
    await log('✔ FXServer ready!', color.green);
    await appendFile(SETUP_MARKER, 'done\n');
}

/** === FIRSTBOOT MODE === */
async function runFirstBoot() {
    mkdirSync(LOG_DIR, { recursive:true });
    await log('🚀 FIRSTBOOT: user configuration…', color.cyan);

    if (existsSync(FIRSTBOOT_MARKER)) {
        return log('✔ firstBoot already done—skipping.', color.yellow);
    }

    const cfg = resolve(HOME, 'server.cfg');
    if (!existsSync(cfg)) {
        await log('⚠️  server.cfg missing—please upload to /home/container', color.red);
    }

    await log('ℹ ENV summary:', color.yellow);
    for (const key of [
        'FIVEM_LICENSE','STEAM_WEBAPIKEY','ONESYNC','TXADMIN_ENABLE','TXADMIN_PORT'
    ]) {
        await log(` • ${key} = ${process.env[key] || '<unset>'}`, color.magenta);
    }

    await log('✅ firstBoot complete.', color.green);
    await appendFile(FIRSTBOOT_MARKER, 'done\n');
}

/** === START MODE === */
async function runStart() {
    mkdirSync(LOG_DIR, { recursive:true });
    await log('▶ START: launching FXServer…', color.cyan);

    if (!existsSync(FX_BIN)) {
        await log(`❌ FXServer missing: ${relative(HOME, FX_BIN)}`, color.red);
        process.exit(1);
    }
    try {
        await access(FX_BIN);
        await chmod(FX_BIN, 0o755);
    } catch (e) {
        return log(`❌ FXServer not executable: ${e.message}`, color.red), process.exit(1);
    }

    await log(`ℹ Contents of opt/cfx-server:`, color.yellow);
    for (const f of readdirSync(BASE)) {
        const s = statSync(resolve(BASE, f));
        await log(` - ${f} (${s.size} bytes)`, color.green);
    }

    const args = ['+exec','server.cfg'];
    const envMap = new Map([
        ['FIVEM_LICENSE','sv_licenseKey'],
        ['STEAM_WEBAPIKEY','steam_webApiKey'],
        ['ONESYNC','onesync'],
        ['TXADMIN_ENABLE','txAdminEnabled'],
        ['TXADMIN_PORT','txAdminPort'],
        ['MAX_PLAYERS','sv_maxclients'],
        ['PROJECT_NAME','sv_projectName'],
        ['PROJECT_DESCRIPTION','sv_projectDesc']
    ]);

    for (const [e,a] of envMap) {
        const v = process.env[e];
        if (v) {
            args.push(a.startsWith('sv_')||a.startsWith('txAdmin')?'+set':'+sets', a, v);
            await log(`[*] Injected ${e} → ${a}=${v}`, color.green);
        }
    }

    await log(`[*] Final args: ${args.join(' ')}`, color.magenta);
    const fx = spawn(FX_BIN, args, { stdio:'inherit' });
    fx.on('error', async e => { await log(`❌ Spawn error: ${e.message}`, color.red); process.exit(1); });
    fx.on('exit',  async c => { await log(`⚙ Exited ${c}`, c===0?color.green:color.red); process.exit(c); });
}

/** === ENTRYPOINT === */
if (ARGS.includes('-setup')) {
    await runSetup();
} else if (ARGS.includes('-firstBoot')) {
    await runFirstBoot();
} else {
    await runStart();
}
