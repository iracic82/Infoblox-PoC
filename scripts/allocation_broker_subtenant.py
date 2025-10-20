#!/usr/bin/env python3
"""
Instruqt Sandbox Allocation via Broker API

This script allocates a pre-created sandbox from the broker instead of
creating a new one directly in CSP.

Usage in Instruqt:
1. Set environment variables:
   - BROKER_API_URL (default: https://api-sandbox-broker.highvelocitynetworking.com/v1)
   - BROKER_API_TOKEN (required)
   - INSTRUQT_PARTICIPANT_ID (provided by Instruqt)
   - INSTRUQT_TRACK_SLUG (provided by Instruqt - lab identifier)

2. Run this script in your Instruqt track setup
3. Script will allocate a sandbox and save IDs to files
"""

import os
import sys
import time
import random
import requests

# ----------------------------------
# Configuration
# ----------------------------------
BROKER_API_URL = os.environ.get(
    "BROKER_API_URL",
    "https://api-sandbox-broker.highvelocitynetworking.com/v1"
)
BROKER_API_TOKEN = os.environ.get("BROKER_API_TOKEN")

# Instruqt provides these automatically
INSTRUQT_SANDBOX_ID = os.environ.get("INSTRUQT_PARTICIPANT_ID")
INSTRUQT_TRACK_ID = os.environ.get("INSTRUQT_TRACK_SLUG", "unknown-lab")

# Optional: Filter sandboxes by name prefix (e.g., "lab-adventure")
SANDBOX_NAME_PREFIX = os.environ.get("SANDBOX_NAME_PREFIX", "lab")

# Startup jitter (avoid collision when multiple students start simultaneously)
time.sleep(random.uniform(1, 5))

# ----------------------------------
# Validation
# ----------------------------------
if not BROKER_API_TOKEN:
    print("❌ BROKER_API_TOKEN environment variable not set", flush=True)
    sys.exit(1)

if not INSTRUQT_SANDBOX_ID:
    print("❌ INSTRUQT_PARTICIPANT_ID not found (are you running in Instruqt?)", flush=True)
    sys.exit(1)

print(f"🎓 Student: {INSTRUQT_SANDBOX_ID}", flush=True)
print(f"📚 Lab: {INSTRUQT_TRACK_ID}", flush=True)
if SANDBOX_NAME_PREFIX:
    print(f"🔍 Filter: Only allocate sandboxes starting with '{SANDBOX_NAME_PREFIX}'", flush=True)

# ----------------------------------
# Allocate Sandbox from Broker
# ----------------------------------
allocate_url = f"{BROKER_API_URL}/allocate"
headers = {
    "Authorization": f"Bearer {BROKER_API_TOKEN}",
    "Content-Type": "application/json",
    "X-Instruqt-Sandbox-ID": INSTRUQT_SANDBOX_ID,
    "X-Instruqt-Track-ID": INSTRUQT_TRACK_ID,
}

# Add optional name prefix filter
if SANDBOX_NAME_PREFIX:
    headers["X-Sandbox-Name-Prefix"] = SANDBOX_NAME_PREFIX

max_retries = 5
retryable_statuses = {500, 502, 503, 504}

allocation_response = None
for attempt in range(max_retries):
    try:
        print(f"🔄 Allocation attempt {attempt + 1}/{max_retries}...", flush=True)

        resp = requests.post(
            allocate_url,
            headers=headers,
            timeout=(5, 30),  # connect=5s, read=30s
        )

        if resp.status_code in (200, 201):
            allocation_response = resp.json()
            status_emoji = "✅" if resp.status_code == 201 else "🔄"
            print(f"{status_emoji} Sandbox allocated (HTTP {resp.status_code})", flush=True)
            break

        elif resp.status_code == 409:
            print("❌ Pool exhausted: No sandboxes available", flush=True)
            sys.exit(1)

        elif resp.status_code == 403:
            print("⚠️ Rate limited by WAF, waiting before retry...", flush=True)
            time.sleep(10)
            continue

        elif resp.status_code in retryable_statuses:
            print(f"⚠️ Server error {resp.status_code}, retrying...", flush=True)
            sleep_time = min(2 ** attempt + random.uniform(0, 1), 30)
            time.sleep(sleep_time)
            continue

        else:
            print(f"❌ Allocation failed with HTTP {resp.status_code}", flush=True)
            print(f"   Response: {resp.text}", flush=True)
            sys.exit(1)

    except requests.exceptions.Timeout:
        print(f"⚠️ Request timeout, retrying...", flush=True)
        sleep_time = min(2 ** attempt + random.uniform(0, 1), 30)
        time.sleep(sleep_time)

    except Exception as e:
        print(f"⚠️ Unexpected error: {e}", flush=True)
        sleep_time = min(2 ** attempt + random.uniform(0, 1), 30)
        time.sleep(sleep_time)

else:
    print("❌ Sandbox allocation failed after all retries", flush=True)
    sys.exit(1)

# ----------------------------------
# Extract IDs from Response
# ----------------------------------
sandbox_id = allocation_response.get("sandbox_id")
external_id = allocation_response.get("external_id")
sandbox_name = allocation_response.get("name")
expires_at = allocation_response.get("expires_at")

if not sandbox_id or not external_id:
    print("❌ Invalid response: missing sandbox_id or external_id", flush=True)
    print(f"   Response: {allocation_response}", flush=True)
    sys.exit(1)

if external_id and "/" in external_id:
    external_id = external_id.split("/")[-1]

# ----------------------------------
# Save to Files (UPDATED)
# ----------------------------------

# 1️⃣ Save sandbox_id to subtenant_id.txt
with open("subtenant_id.txt", "w") as f:
    f.write(sandbox_id)
print(f"✅ Subtenant ID saved to subtenant_id.txt: {sandbox_id}", flush=True)

# 2️⃣ Save external_id to external_id.txt
with open("external_id.txt", "w") as f:
    f.write(external_id)
print(f"✅ External ID saved to external_id.txt: {external_id}", flush=True)

# 3️⃣ Also save external_id again into sandbox_id.txt
with open("sandbox_id.txt", "w") as f:
    f.write(external_id)
print(f"✅ Sandbox ID saved to sandbox_id.txt (same as external_id): {external_id}", flush=True)

# 4️⃣ Save sandbox name
with open("sandbox_name.txt", "w") as f:
    f.write(sandbox_name)
print(f"✅ Sandbox name saved to sandbox_name.txt: {sandbox_name}", flush=True)

# ----------------------------------
# Export as Environment Variables
# ----------------------------------
ENV_SCRIPT = "sandbox_env.sh"
with open(ENV_SCRIPT, "w") as f:
    f.write(f"#!/bin/bash\n")
    f.write(f"# Auto-generated by instruqt_broker_allocation.py\n")
    f.write(f"export STUDENT_TENANT={sandbox_name}\n")
    f.write(f"export CSP_ACCOUNT_ID={external_id}\n")
    f.write(f"export BROKER_SANDBOX_ID={sandbox_id}\n")

print(f"\n💡 To use these variables in bash:", flush=True)
print(f"   source {ENV_SCRIPT}", flush=True)
print(f"\n   Or for Instruqt (persists across steps):", flush=True)
print(f"   set-var STUDENT_TENANT {sandbox_name}", flush=True)
print(f"   set-var CSP_ACCOUNT_ID {external_id}", flush=True)
print(f"   set-var BROKER_SANDBOX_ID {sandbox_id}", flush=True)

# ----------------------------------
# Summary
# ----------------------------------
print("\n" + "="*60, flush=True)
print("🎉 Sandbox Allocation Complete!", flush=True)
print(f"   Name: {sandbox_name}", flush=True)
print(f"   Subtenant ID: {sandbox_id}", flush=True)
print(f"   External ID: {external_id} (use this to connect to CSP)", flush=True)
print(f"   Expires: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime(expires_at))}", flush=True)
print("="*60, flush=True)
