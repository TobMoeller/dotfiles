"""NixOS generation retention. Default action is a read-only preview."""

import argparse
import fcntl
import os
from pathlib import Path
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta
from uuid import uuid4
from zoneinfo import ZoneInfo


PROFILE = Path("/nix/var/nix/profiles/system")
CURRENT = Path("/run/current-system")
BOOTED = Path("/run/booted-system")
PIN = Path("/nix/var/nix/gcroots/dotfiles-known-good")
LOCK = Path("/run/lock/dotfiles-system.lock")


def local_now():
    # Keep historical DST offsets when classifying calendar boundaries.
    with Path("/etc/localtime").open("rb") as zone:
        return datetime.now(ZoneInfo.from_file(zone))


@dataclass(frozen=True)
class Generation:
    number: int
    created: datetime
    target: Path


def snapshot():
    """Read symlinks directly: nix-env --list-generations needs a root lock."""
    generations = []
    for link in PROFILE.parent.glob("system-*-link"):
        match = re.fullmatch(r"system-(\d+)-link", link.name)
        if match and link.is_symlink():
            generations.append(Generation(
                int(match[1]),
                datetime.fromtimestamp(link.lstat().st_mtime).astimezone(),
                link.resolve(strict=True),
            ))
    if not generations:
        raise RuntimeError("No system generations found; refusing cleanup.")
    protected = {
        "boot target": PROFILE.resolve(strict=True),
        "running": CURRENT.resolve(strict=True),
        "booted": BOOTED.resolve(strict=True),
    }
    if PIN.is_symlink():
        protected["known-good"] = PIN.resolve(strict=True)
    elif PIN.exists():
        raise RuntimeError(f"Expected a symlink at {PIN}.")
    return tuple(sorted(generations, key=lambda g: g.number, reverse=True)), protected


def retention(generations, protected, now):
    """Union of latest 5, 3 daily, 4 weekly and 3 monthly calendar buckets."""
    keep = {}
    seen = {"daily": set(), "weekly": set(), "monthly": set()}
    today = now.date()
    monday = today - timedelta(days=today.weekday())
    for index, generation in enumerate(sorted(
        generations, key=lambda g: g.number, reverse=True
    )):
        reasons = []
        if index < 5:
            reasons.append("latest 5")
        reasons.extend(name for name, target in protected.items()
                       if generation.target == target)
        date = generation.created.astimezone(now.tzinfo).date()
        if generation.created > now:
            reasons.append("future timestamp")
        week = date - timedelta(days=date.weekday())
        buckets = [
            ("daily", date, 0 <= (today - date).days < 3),
            ("weekly", week, 0 <= (monday - week).days < 28),
            ("monthly", (date.year, date.month),
             0 <= (today.year - date.year) * 12 + today.month - date.month < 3),
        ]
        for name, bucket, eligible in buckets:
            if eligible and bucket not in seen[name]:
                seen[name].add(bucket)
                reasons.append(name)
        if reasons:
            keep[generation.number] = reasons
    return keep


def preview(generations, protected, now):
    keep = retention(generations, protected, now)
    for generation in generations:
        reasons = keep.get(generation.number)
        print(f"{'KEEP  ' if reasons else 'DELETE'} {generation.number:4}  "
              f"{generation.created:%Y-%m-%d %H:%M}  "
              f"{', '.join(reasons) if reasons else 'outside retention'}")
    print(f"Keep {len(keep)} / delete {len(generations) - len(keep)} generations.")
    if "known-good" not in protected:
        print("No known-good generation pinned: apply is blocked; timer skips cleanup.")
    return [g.number for g in generations if g.number not in keep]


def pin(generations, protected, number):
    if number is None:
        matches = [g for g in generations if g.target == protected["booted"]]
    else:
        matches = [g for g in generations if g.number == number]
    if not matches:
        raise RuntimeError("Requested generation is absent; specify an existing number.")
    generation = max(matches, key=lambda g: g.number)
    temporary = PIN.with_name(f"{PIN.name}-{uuid4().hex}.tmp")
    try:
        temporary.symlink_to(generation.target)
        temporary.replace(PIN)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Pinned known-good generation {generation.number}: {generation.target}")


def apply(state, now):
    generations, protected = state
    if "known-good" not in protected:
        raise RuntimeError("Pin a tested generation before applying cleanup.")
    if not any(g.target == protected["known-good"] for g in generations):
        raise RuntimeError("Pinned system has no generation/boot entry; pin an existing one.")
    boot_command = protected["boot target"] / "bin/switch-to-configuration"
    if not boot_command.is_file() or not os.access(boot_command, os.X_OK):
        raise RuntimeError("Boot target has no executable switch-to-configuration.")
    delete = preview(generations, protected, now)
    if snapshot() != state:
        raise RuntimeError("System/profile changed during planning; retry after rebuild.")
    if delete:
        subprocess.run([
            "nix-env", "--profile", str(PROFILE), "--delete-generations",
            *map(str, delete),
        ], check=True)
    # Regenerate the menu using the selected boot target, including after
    # `nixos-rebuild boot`; never switch running services or create a generation.
    if snapshot()[1] != protected:
        raise RuntimeError("System/profile changed during cleanup; GC was not run.")
    subprocess.run([str(boot_command), "boot"], check=True)
    if snapshot()[1] != protected:
        raise RuntimeError("System/profile changed while updating boot menu; GC was not run.")
    subprocess.run(["nix-store", "--gc"], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action")
    commands.add_parser("preview", help="Show retention decisions without changing anything")
    commands.add_parser("apply", help="Prune, update boot menu, then collect garbage (root)")
    pin_parser = commands.add_parser("pin", help="Mark a tested generation (default: booted)")
    pin_parser.add_argument("generation", nargs="?", type=int)
    args = parser.parse_args()
    if args.action in (None, "preview"):
        preview(*snapshot(), local_now())
        return
    if os.geteuid() != 0:
        raise RuntimeError("Use sudo for apply/pin; preview works without root.")
    with LOCK.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = snapshot()
        if args.action == "pin":
            pin(*state, args.generation)
        else:
            apply(state, local_now())


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"nixos-generations: {error}", file=sys.stderr)
        sys.exit(1)
