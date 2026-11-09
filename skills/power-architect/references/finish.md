# /power-architect:finish

Adapted from Superpowers `finishing-a-development-branch`. Announce: "I'm finishing this development branch."

1. **Verify tests.** Run the full suite. If anything fails, report the failures and stop; the options come only after a green suite.
2. **Detect the environment.** Capture `GIT_DIR`, `GIT_COMMON` (`git rev-parse --git-dir` / `--git-common-dir`, resolved to absolute paths), and `WORKTREE_PATH` (`git rev-parse --show-toplevel`) *now*, before changing directory.
   - Normal repo, or a worktree on a named branch → 3 options.
   - Detached HEAD → 2 options (no merge); the workspace is externally managed.
3. **Determine the base branch** the work forked from. If it isn't known, ask: "This branch split from <guess> — is that correct?"
4. **Present exactly these options** and wait. Integration is the user's decision.

   ```
   Implementation complete. What would you like to do?

   1. Merge back to <base-branch> locally
   2. Push and create a Pull Request
   3. Keep the branch as-is (I'll handle it later)

   Which option?
   ```

   For a detached HEAD: 1. Push as a new branch and create a PR · 2. Keep as-is.
5. **Execute the choice.**
   - **Merge:** from the main repo root, `git checkout <base>`, `git pull`, `git merge <branch>`, then run the tests **on the merged result**. If they fail, stop and leave the branch and worktree in place. If they're green, clean up the worktree (step 6), then `git branch -d <branch>`.
   - **PR:** `git push -u origin <branch>`, then open the PR with the forge's tooling, following the repo's PR template, and report the URL. **Keep the worktree** for PR feedback.
   - **Keep:** report "Keeping branch <name>. Worktree preserved at <path>."
   - **Discard** happens only if the user explicitly asks. List the branch, commits, and worktree that will be deleted, and require them to type `discard`. Then clean up and `git branch -D`.
6. **Clean up** (merge or confirmed discard only). For a normal repo there's nothing to do. A worktree under `.worktrees/` or `worktrees/` is ours: `git worktree remove "$WORKTREE_PATH" && git worktree prune`. If removal is refused because of uncommitted files, **never use `--force`**: show the files and ask whether to commit, move, or delete them. Any other worktree belongs to the host, so leave it.

Never force-push unless the user explicitly asks. A rejected push means the remote moved, so investigate.

Then recommend `/power-architect:retro` (optional).

---

## Common rationalizations (verbatim from Superpowers `finishing-a-development-branch`)


| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to integrate. A green run only proves the tree it ran on. |
| "They obviously want it merged" | Integration is your human partner's decision. Present the menu and wait. |
| "They seem done with this feature — I'll offer to discard it" | The menu is complete as written. Discard happens only when your human partner asks for it in so many words. |
| "'Yeah, get rid of it' counts as confirmation" | Only the typed word `discard` authorizes deletion. |
| "The PR is up, so the worktree is clutter now" | PR feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale — I'll clean it too" | Clean up only worktrees under `.worktrees/` or `worktrees/`. Everything else belongs to the host. |
| "Removal refused — `--force` is just finishing the cleanup" | The refusal means files exist only in that worktree. `--force` destroys them permanently. Show your human partner and ask. |
| "The merged-result failure is probably flaky" | A failing merged result stops everything. Branch and worktree stay put while you investigate. |
| "The base branch is obviously main" | Confirm the fork point or ask. Merging into the wrong base is expensive to undo. |
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only on your human partner's explicit request. |
