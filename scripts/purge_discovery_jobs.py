import os
import json
import argparse
import requests
from typing import Iterable, List, Optional, Tuple

class InfobloxSession:
    def __init__(self):
        self.base_url = "https://csp.infoblox.com"
        self.email = os.getenv("INFOBLOX_EMAIL")
        self.password = os.getenv("INFOBLOX_PASSWORD")
        if not self.email or not self.password:
            raise RuntimeError("Set INFOBLOX_EMAIL and INFOBLOX_PASSWORD env vars.")
        self.jwt = None
        self.session = requests.Session()

    # ---------- auth ----------
    def login(self):
        r = self.session.post(
            f"{self.base_url}/v2/session/users/sign_in",
            headers={"Content-Type": "application/json"},
            json={"email": self.email, "password": self.password},
        )
        r.raise_for_status()
        self.jwt = r.json().get("jwt")
        if not self.jwt:
            raise RuntimeError("Login succeeded but no JWT returned.")
        print("✅ Logged in.")

    def switch_account(self, sandbox_id_file: str = "sandbox_id.txt"):
        with open(sandbox_id_file, "r") as f:
            sandbox_id = f.read().strip()
        r = self.session.post(
            f"{self.base_url}/v2/session/account_switch",
            headers=self._auth_headers(),
            json={"id": f"identity/accounts/{sandbox_id}"},
        )
        r.raise_for_status()
        self.jwt = r.json().get("jwt")
        if not self.jwt:
            raise RuntimeError("Account switch succeeded but no JWT returned.")
        print(f"✅ Switched to sandbox {sandbox_id}.")

    def _auth_headers(self):
        return {"Content-Type": "application/json", "Authorization": f"Bearer {self.jwt}"}

    # ---------- discovery providers ----------
    def list_providers(self) -> List[dict]:
        """
        GET /api/cloud_discovery/v2/providers
        Handles both {"results":[...]} and raw list responses.
        Adds naive pagination support if API returns 'next' or 'page_token'.
        """
        url = f"{self.base_url}/api/cloud_discovery/v2/providers"
        providers: List[dict] = []
        params = {}

        while True:
            r = self.session.get(url, headers=self._auth_headers(), params=params)
            r.raise_for_status()
            data = r.json()

            if isinstance(data, dict):
                items = data.get("results", data.get("items", []))
                providers.extend(items if isinstance(items, list) else [])
                # common pagination keys; keep it defensive
                next_token = data.get("next") or data.get("next_page_token")
                if next_token:
                    params["page_token"] = next_token
                    continue
            elif isinstance(data, list):
                providers.extend(data)
            break

        return providers

    def delete_provider(self, provider_id: str,
                        delete_ipam: bool = True,
                        delete_asset: bool = True) -> Tuple[int, str]:
        """
        DELETE /providers/{id}?deletion_objects=ipam_data&deletion_objects=asset_data
        Returns (status_code, message).
        """
        if not delete_ipam and not delete_asset:
            return (0, "Skipped (no deletion objects selected)")

        params = []
        if delete_ipam:
            params.append(("deletion_objects", "ipam_data"))
        if delete_asset:
            params.append(("deletion_objects", "asset_data"))

        url = f"{self.base_url}/api/cloud_discovery/v2/providers/{provider_id}"
        r = self.session.delete(url, headers=self._auth_headers(), params=params)

        if r.status_code in (200, 202, 204):
            return (r.status_code, "Deleted")
        if r.status_code == 404:
            return (r.status_code, "Not found (already deleted?)")

        try:
            detail = r.json()
        except Exception:
            detail = r.text
        return (r.status_code, f"Failed: {detail}")

def filter_providers(providers: Iterable[dict],
                     name_exact: Optional[str],
                     name_contains: Optional[str]) -> List[dict]:
    out = []
    for p in providers:
        pid = p.get("id", "")
        # try several name fields; different payloads use different keys
        pname = p.get("name") or p.get("display_name") or p.get("config", {}).get("name") or ""
        if name_exact and pname == name_exact:
            out.append(p)
        elif name_contains and name_contains.lower() in pname.lower():
            out.append(p)
        elif not name_exact and not name_contains:
            out.append(p)  # no filter => include all
    return out

def main():
    ap = argparse.ArgumentParser(description="List and delete Cloud Discovery providers (jobs).")
    ap.add_argument("--no-switch", action="store_true",
                    help="Skip account switch via sandbox_id.txt.")
    ap.add_argument("--list", action="store_true",
                    help="Only list providers and exit.")
    ap.add_argument("--name", help="Delete providers with exact name match.")
    ap.add_argument("--contains", help="Delete providers whose name contains this substring.")
    ap.add_argument("--keep-ipam", action="store_true",
                    help="Do NOT delete IPAM data.")
    ap.add_argument("--keep-asset", action="store_true",
                    help="Do NOT delete Asset data.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Show what would be deleted without deleting.")
    args = ap.parse_args()

    s = InfobloxSession()
    s.login()
    if not args.no_switch:
        s.switch_account()

    providers = s.list_providers()
    # Pretty print current state
    print("📋 Providers:")
    for p in providers:
        pid = p.get("id")
        pname = p.get("name") or p.get("display_name") or p.get("config", {}).get("name")
        print(f"- id: {pid} | name: {pname}")

    if args.list:
        return

    targets = filter_providers(providers, args.name, args.contains)
    if not targets:
        print("ℹ️ No providers matched the filter; nothing to do.")
        return

    print(f"\n🎯 Candidates to delete: {len(targets)}")
    for p in targets:
        pid = p.get("id")
        pname = p.get("name") or p.get("display_name") or p.get("config", {}).get("name")
        if args.dry_run:
            print(f"DRY-RUN: would delete id={pid} name={pname}")
            continue

        code, msg = s.delete_provider(
            provider_id=pid,
            delete_ipam=not args.keep_ipam,
            delete_asset=not args.keep_asset
        )
        print(f"id={pid} name={pname} -> {msg} (HTTP {code})")

if __name__ == "__main__":
    main()
