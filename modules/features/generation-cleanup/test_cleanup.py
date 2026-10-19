"""Retention and destructive-command ordering, using only disposable profiles."""

from contextlib import redirect_stdout
from datetime import datetime, timedelta, timezone
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import cleanup


NOW = datetime(2026, 10, 19, 12, tzinfo=timezone.utc)


def generation(number, age):
    return cleanup.Generation(number, NOW - timedelta(days=age), Path(f"/store/{number}"))


class RetentionTests(unittest.TestCase):
    def test_five_latest_survive_even_when_very_old(self):
        generations = [generation(n, 200) for n in range(1, 11)]
        self.assertEqual(set(cleanup.retention(generations, {}, NOW)), set(range(6, 11)))

    def test_newest_representative_per_calendar_bucket(self):
        generations = [generation(n, age) for n, age in [
            (100, 0), (99, 0), (98, 0), (97, 0), (96, 0),
            (90, 1), (89, 1), (80, 2), (70, 3), (60, 8),
            (50, 15), (40, 22), (30, 29), (20, 40), (10, 70), (1, 100),
        ]]
        keep = cleanup.retention(generations, {}, NOW)
        self.assertIn("daily", keep[90])
        self.assertIn("daily", keep[80])
        self.assertNotIn(89, keep)
        self.assertNotIn(70, keep)
        self.assertIn("weekly", keep[60])
        self.assertIn("weekly", keep[50])
        self.assertNotIn("weekly", keep[40])  # Outside four calendar weeks.
        self.assertIn("monthly", keep[40])  # Still the newest September entry.
        self.assertNotIn(20, keep)
        self.assertIn("monthly", keep[10])
        self.assertNotIn(1, keep)

    def test_regular_selection_is_bounded(self):
        generations = [generation(1000 - day * 2 - i, day)
                       for day in range(300) for i in range(2)]
        self.assertLessEqual(len(cleanup.retention(generations, {}, NOW)), 15)

    def test_protected_old_targets_and_duplicates_survive(self):
        generations = [generation(n, 200) for n in range(1, 12)]
        generations.append(cleanup.Generation(12, NOW, generations[0].target))
        protected = {"running": Path("/store/2"), "booted": Path("/store/3"),
                     "boot target": Path("/store/4"), "known-good": Path("/store/1")}
        keep = cleanup.retention(generations, protected, NOW)
        for n in (1, 2, 3, 4, 12):
            self.assertIn(n, keep)

    def test_future_timestamp_is_not_deleted(self):
        generations = [generation(n, 0) for n in range(10, 15)] + [generation(1, -1)]
        self.assertIn("future timestamp", cleanup.retention(generations, {}, NOW)[1])

    def test_year_boundary_uses_calendar_months_and_mondays(self):
        now = datetime(2027, 1, 1, 12, tzinfo=timezone.utc)
        generations = [cleanup.Generation(n, now, Path(f"/{n}")) for n in range(10, 15)]
        generations += [cleanup.Generation(1, now - timedelta(days=2), Path("/old"))]
        keep = cleanup.retention(generations, {}, now)
        self.assertIn("daily", keep[1])
        self.assertIn("monthly", keep[1])
        self.assertNotIn("weekly", keep[1])  # December/January share this week.

    def test_calendar_buckets_use_selected_timezone(self):
        now = NOW.astimezone(timezone(timedelta(hours=2)))
        generations = [generation(n, 0) for n in range(10, 15)]
        generations += [
            cleanup.Generation(2, datetime(2026, 10, 18, 22, 30, tzinfo=timezone.utc), Path("/a")),
            cleanup.Generation(1, datetime(2026, 10, 18, 21, 30, tzinfo=timezone.utc), Path("/b")),
        ]
        keep = cleanup.retention(generations, {}, now)
        self.assertNotIn(2, keep)  # Already October 19 in the chosen timezone.
        self.assertIn("daily", keep[1])


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.profile = self.root / "system"
        self.current = self.root / "current"
        self.booted = self.root / "booted"
        self.pin = self.root / "known-good"
        self.paths = {}
        for number in range(1, 10):
            target = self.root / f"store-{number}"
            (target / "bin").mkdir(parents=True)
            command = target / "bin/switch-to-configuration"
            command.write_text("#!/bin/sh\nexit 0\n")
            command.chmod(0o755)
            link = self.root / f"system-{number}-link"
            link.symlink_to(target)
            old = (NOW - timedelta(days=200)).timestamp()
            os.utime(link, (old, old), follow_symlinks=False)
            self.paths[number] = target
        self.profile.symlink_to("system-9-link")
        self.current.symlink_to(self.paths[8])
        self.booted.symlink_to(self.paths[7])
        self.pin.symlink_to(self.paths[1])
        patcher = patch.multiple(cleanup, PROFILE=self.profile, CURRENT=self.current,
                                BOOTED=self.booted, PIN=self.pin)
        patcher.start()
        self.addCleanup(patcher.stop)

    def quiet_apply(self, state):
        with redirect_stdout(io.StringIO()):
            cleanup.apply(state, NOW)

    def delete_fixture_links(self, command, **kwargs):
        if command[0] == "nix-env":
            for number in command[4:]:
                (self.root / f"system-{number}-link").unlink()

    def test_preview_does_not_write(self):
        state = cleanup.snapshot()
        with redirect_stdout(io.StringIO()):
            deleted = cleanup.preview(*state, NOW)
        self.assertEqual(deleted, [4, 3, 2])
        self.assertEqual(cleanup.snapshot(), state)

    def test_delete_then_refresh_selected_boot_target_then_gc(self):
        with patch.object(cleanup.subprocess, "run", side_effect=self.delete_fixture_links) as run:
            self.quiet_apply(cleanup.snapshot())
        commands = [c.args[0] for c in run.call_args_list]
        self.assertEqual(commands, [
            ["nix-env", "--profile", str(self.profile), "--delete-generations", "4", "3", "2"],
            [str(self.paths[9] / "bin/switch-to-configuration"), "boot"],
            ["nix-store", "--gc"],
        ])
        for number in (1, 5, 6, 7, 8, 9):
            self.assertTrue((self.root / f"system-{number}-link").exists())

    def test_missing_pin_blocks_every_mutation(self):
        self.pin.unlink()
        with patch.object(cleanup.subprocess, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "Pin a tested"):
                self.quiet_apply(cleanup.snapshot())
            run.assert_not_called()

    def test_no_candidates_still_updates_menu_before_gc(self):
        for number in (2, 3, 4):
            (self.root / f"system-{number}-link").unlink()
        with patch.object(cleanup.subprocess, "run") as run:
            self.quiet_apply(cleanup.snapshot())
        self.assertEqual([c.args[0] for c in run.call_args_list], [
            [str(self.paths[9] / "bin/switch-to-configuration"), "boot"],
            ["nix-store", "--gc"],
        ])

    def test_missing_boot_command_blocks_every_mutation(self):
        (self.paths[9] / "bin/switch-to-configuration").unlink()
        with patch.object(cleanup.subprocess, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "no executable"):
                self.quiet_apply(cleanup.snapshot())
            run.assert_not_called()

    def test_pin_without_profile_generation_blocks_cleanup(self):
        (self.root / "system-1-link").unlink()
        with patch.object(cleanup.subprocess, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "no generation/boot entry"):
                self.quiet_apply(cleanup.snapshot())
            run.assert_not_called()

    def test_changed_profile_aborts_before_deleting(self):
        state = cleanup.snapshot()
        self.profile.unlink()
        self.profile.symlink_to("system-6-link")
        with patch.object(cleanup.subprocess, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "changed during planning"):
                self.quiet_apply(state)
            run.assert_not_called()

    def test_boot_menu_failure_prevents_gc(self):
        def fail_boot(command, **kwargs):
            self.delete_fixture_links(command, **kwargs)
            if command[-1] == "boot":
                raise subprocess.CalledProcessError(1, command)
        with patch.object(cleanup.subprocess, "run", side_effect=fail_boot) as run:
            with self.assertRaises(subprocess.CalledProcessError):
                self.quiet_apply(cleanup.snapshot())
        self.assertEqual(run.call_count, 2)

    def test_delete_failure_prevents_boot_update_and_gc(self):
        with patch.object(cleanup.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "nix-env")) as run:
            with self.assertRaises(subprocess.CalledProcessError):
                self.quiet_apply(cleanup.snapshot())
        self.assertEqual(run.call_count, 1)

    def test_changed_boot_target_after_delete_blocks_boot_update_and_gc(self):
        def change_profile(command, **kwargs):
            self.delete_fixture_links(command, **kwargs)
            self.profile.unlink()
            self.profile.symlink_to("system-6-link")
        with patch.object(cleanup.subprocess, "run", side_effect=change_profile) as run:
            with self.assertRaisesRegex(RuntimeError, "changed during cleanup"):
                self.quiet_apply(cleanup.snapshot())
        self.assertEqual(run.call_count, 1)

    def test_changed_boot_target_after_menu_update_blocks_gc(self):
        def change_after_boot(command, **kwargs):
            self.delete_fixture_links(command, **kwargs)
            if command[-1] == "boot":
                self.profile.unlink()
                self.profile.symlink_to("system-6-link")
        with patch.object(cleanup.subprocess, "run", side_effect=change_after_boot) as run:
            with self.assertRaisesRegex(RuntimeError, "changed while updating"):
                self.quiet_apply(cleanup.snapshot())
        self.assertEqual(run.call_count, 2)

    def test_dangling_generation_aborts_snapshot(self):
        (self.root / "system-99-link").symlink_to(self.root / "missing")
        with self.assertRaises(FileNotFoundError):
            cleanup.snapshot()

    def test_default_pin_uses_booted_not_newer_running_system(self):
        with redirect_stdout(io.StringIO()):
            cleanup.pin(*cleanup.snapshot(), None)
        self.assertEqual(self.pin.resolve(), self.paths[7])

    def test_pin_can_be_replaced_without_extra_roots(self):
        with redirect_stdout(io.StringIO()):
            cleanup.pin(*cleanup.snapshot(), 5)
        self.assertEqual(self.pin.resolve(), self.paths[5])
        self.assertFalse(list(self.root.glob("known-good-*.tmp")))

    def test_unknown_pin_number_leaves_old_pin_untouched(self):
        with self.assertRaises(RuntimeError):
            cleanup.pin(*cleanup.snapshot(), 123)
        self.assertEqual(self.pin.resolve(), self.paths[1])


if __name__ == "__main__":
    unittest.main()
